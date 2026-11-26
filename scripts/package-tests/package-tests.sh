#!/bin/bash
# Copyright  Dynatrace LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Tests a Linux package of a DBDOT build in containers. Ported from the
# Dynatrace OTel Collector's internal/testbed/linux-services/package-tests.sh,
# which is based on the OpenTelemetry Collector Releases package tests;
# the upgrade scenario and the file and uninstall state checks follow the
# Bindplane collector's containerized package test suite (test/packaging).
#
# Scenarios, each in a fresh container and ending with an uninstall:
#   install: installs the package and checks the installed files, their owner
#            and mode, the dbdot (system) user and the service, which must
#            stay up without restarts.
#   upgrade: only with UPGRADE_FROM_PATH. Installs that released package,
#            starts it and edits the user files, upgrades to the package under
#            test and checks that the edits survived and the service runs.
#   uninstall (both): removes the package and checks what is removed and what
#            is kept (configs, manager.yaml, storage, the override file).
#
# deb and rpm run in a systemd container: after install the service must be
# installed but neither enabled nor started (postinstall.sh only configures
# it), must stay up once started, and must be gone after uninstall.
#
# usage: package-tests.sh PACKAGE_PATH ARCH PACKAGE_NAME [UPGRADE_FROM_PATH]
#   PACKAGE_NAME is the nfpm package_name of the build, which is also the name
#   of its service, binary and install directory under /opt.
#   UPGRADE_FROM_PATH is a released package of the same build and type.

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PKG_PATH="${1:-}"
ARCH="${2:-}"
PKG_NAME="${3:-}"
UPGRADE_FROM_PATH="${4:-}"

# shellcheck source=scripts/package-tests/common.sh
source "$SCRIPT_DIR"/common.sh

# Global array for trap functions
TRAP_FUNCS=()

# Helper to add functions to the trap list
add_trap_func() {
	TRAP_FUNCS+=("$1")
}

# Wrapper that calls each trap'ed function.
# It uses LIFO order, like Go's `defer`.
run_traps() {
	if [ "${#TRAP_FUNCS[@]}" -gt 0 ]; then
		for ((i = ${#TRAP_FUNCS[@]} - 1; i >= 0; i--)); do
			"${TRAP_FUNCS[i]}"
		done
	fi
}
trap 'run_traps' EXIT

if [[ -z "$PKG_PATH" || -z "$ARCH" || -z "$PKG_NAME" ]]; then
    echo "usage: ${BASH_SOURCE[0]} PACKAGE_PATH ARCH PACKAGE_NAME [UPGRADE_FROM_PATH]" >&2
    exit 1
fi

for path in "$PKG_PATH" ${UPGRADE_FROM_PATH:+"$UPGRADE_FROM_PATH"}; do
    if [[ ! -f "$path" ]]; then
        echo "$path not found!" >&2
        exit 1
    fi
done

pkg_base="$( basename "$PKG_PATH" )"
pkg_type="${pkg_base##*.}"
if [[ ! "$pkg_type" =~ ^(deb|rpm)$ ]]; then
    echo "$PKG_PATH not supported!" >&2
    exit 1
fi
if [[ -n "$UPGRADE_FROM_PATH" && "${UPGRADE_FROM_PATH##*.}" != "$pkg_type" ]]; then
    echo "$UPGRADE_FROM_PATH is not a $pkg_type package!" >&2
    exit 1
fi

SERVICE_NAME="$PKG_NAME"
HOME_DIR="/opt/$PKG_NAME"
BINARY="$HOME_DIR/$PKG_NAME"
# Defaults of the package scripts (DBDOT_USER, DBDOT_GROUP).
RUNTIME_USER="dbdot"
OWNER="$RUNTIME_USER:$RUNTIME_USER"
# Only the full build ships the plugins (see the nfpms section of each build's
# .goreleaser.yml). Both builds ship the updater.
FULL_BUILD=false
if [[ "$PKG_NAME" != *-slim ]]; then
    FULL_BUILD=true
fi
# The package scripts source this file; it belongs to the user, not the package.
if [[ "$pkg_type" == "rpm" ]]; then
    OVERRIDE_FILE="/etc/sysconfig/$PKG_NAME"
else
    OVERRIDE_FILE="/etc/default/$PKG_NAME"
fi

image_name="$PKG_NAME-$pkg_type-test"
container_name="$image_name"
container_exec="podman exec $container_name"

podman_cleanup() {
	podman rm -fv "$container_name" >/dev/null 2>&1 || true
}
add_trap_func podman_cleanup

podman_logs() {
    echo "Container logs:"
    podman logs "$container_name" || true
}
add_trap_func podman_logs

# If a check fails, print the logs of the systemd service as well. Runs before
# the container is removed (LIFO).
journalctl_logs() {
	$container_exec journalctl -u "$SERVICE_NAME" --no-pager || true
}
add_trap_func journalctl_logs

podman build -t "$image_name" --arch "$ARCH" -f "$SCRIPT_DIR/Dockerfile.test.$pkg_type" "$SCRIPT_DIR"

start_container() {
    podman rm -fv "$container_name" >/dev/null 2>&1 || true
    podman run --name "$container_name" --arch "$ARCH" --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro -d "$image_name"
}

# check_installed checks the files, owners and modes that the package and its
# postinstall.sh leave behind.
check_installed() {
    echo "Checking $BINARY ..."
    $container_exec "$BINARY" --version

    echo "Checking $RUNTIME_USER user ..."
    local group shell
    group="$( $container_exec id -gn "$RUNTIME_USER" )"
    if [[ "$group" != "$RUNTIME_USER" ]]; then
        echo "$RUNTIME_USER user: expected group $RUNTIME_USER, got $group" >&2
        exit 1
    fi
    shell="$( $container_exec getent passwd "$RUNTIME_USER" | cut -d: -f7 )"
    if [[ "$shell" != "/sbin/nologin" ]]; then
        echo "$RUNTIME_USER user: expected shell /sbin/nologin, got $shell" >&2
        exit 1
    fi
    # useradd --system allocates a UID below the distro's UID_MIN.
    local uid uid_min
    uid="$( $container_exec id -u "$RUNTIME_USER" )"
    uid_min="$( $container_exec awk '$1 == "UID_MIN" {print $2; exit}' /etc/login.defs )"
    if [[ -z "$uid_min" || "$uid" -ge "$uid_min" ]]; then
        echo "$RUNTIME_USER user: expected a system user (UID below UID_MIN $uid_min), got UID $uid" >&2
        exit 1
    fi

    echo "Checking installed files ..."
    assert_stat "$container_name" "$HOME_DIR" "$OWNER 755"
    assert_stat "$container_name" "$BINARY" "$OWNER 755"
    assert_stat "$container_name" "$HOME_DIR/config.yaml" "$OWNER 640"
    assert_stat "$container_name" "$HOME_DIR/logging.yaml" "$OWNER 640"
    assert_stat "$container_name" "$HOME_DIR/LICENSE" "$OWNER 644"
    assert_stat "$container_name" "$HOME_DIR/VERSION.txt" "$OWNER 644"
    assert_stat "$container_name" "$HOME_DIR/storage" "$OWNER 750"
    assert_stat "$container_name" "$HOME_DIR/log" "$OWNER 750"
    assert_stat "$container_name" "$HOME_DIR/log/collector.log" "$OWNER -"
    assert_stat "$container_name" "$HOME_DIR/updater" "root:root 755"
    if [[ "$FULL_BUILD" == "true" ]]; then
        assert_stat "$container_name" "$HOME_DIR/plugins" "$OWNER 750"
        local plugin
        plugin="$( $container_exec sh -c "ls $HOME_DIR/plugins/* | head -n 1" )"
        assert_stat "$container_name" "$plugin" "$OWNER 640"
    else
        assert_absent "$container_name" "$HOME_DIR/plugins"
    fi
    # postinstall.sh copies the staged files to $HOME_DIR and removes them.
    assert_absent "$container_name" "/usr/share/$PKG_NAME"

    assert_stat "$container_name" "/usr/lib/systemd/system/$SERVICE_NAME.service" "root:root 640"
    assert_exists "$container_name" "/etc/systemd/system/$SERVICE_NAME.service.d"
    assert_absent "$container_name" "/etc/init.d/$SERVICE_NAME"
}

# check_service_stopped checks that the package did not enable or start the
# service.
check_service_stopped() {
    echo "Checking $SERVICE_NAME service state after install ..."
    if $container_exec systemctl is-active "$SERVICE_NAME"; then
        echo "$SERVICE_NAME service running after install" >&2
        exit 1
    fi
    echo "$SERVICE_NAME service correctly not running after install"

    if $container_exec systemctl is-enabled "$SERVICE_NAME"; then
        echo "$SERVICE_NAME service enabled after install" >&2
        exit 1
    fi
    echo "$SERVICE_NAME service correctly not enabled after install"
}

# check_service_runs (re)starts the service and checks that it stays up.
check_service_runs() {
    $container_exec systemctl restart "$SERVICE_NAME"

    # ensure service has started and still running after 5 seconds
    sleep 5
    echo "Checking $SERVICE_NAME service status ..."
    $container_exec systemctl --no-pager status "$SERVICE_NAME"

    # Outlast RestartSec=5s once more: a crash loop shows up as restarts.
    sleep 6
    local restarts
    restarts="$( $container_exec systemctl show -p NRestarts --value "$SERVICE_NAME" )"
    if [[ "$restarts" != "0" ]]; then
        echo "$SERVICE_NAME service: expected no restarts, got $restarts" >&2
        exit 1
    fi

    echo "Checking $BINARY process ..."
    $container_exec pgrep -f -a "$BINARY"
}

# seed_user_files creates the files that the collector, the user or Bindplane
# create next to the package files, which upgrades and uninstalls must keep.
seed_user_files() {
    echo "Creating user files ..."
    $container_exec sh -c "echo '# pkgtest' > $HOME_DIR/manager.yaml"
    $container_exec sh -c "echo pkgtest > $HOME_DIR/storage/pkgtest"
    $container_exec sh -c "echo '# pkgtest' > $OVERRIDE_FILE"
}

check_user_files() {
    echo "Checking user files ..."
    assert_exists "$container_name" "$HOME_DIR/manager.yaml"
    assert_exists "$container_name" "$HOME_DIR/storage/pkgtest"
    assert_exists "$container_name" "$OVERRIDE_FILE"
}

# uninstall removes the package and checks what is removed and what is kept,
# following postremove.sh.
uninstall() {
    uninstall_pkg "$container_name" "$pkg_type" "$PKG_NAME"

    echo "Checking $PKG_NAME package state after uninstall ..."
    local installed=false
    case "$pkg_type" in
        deb)
            # Without conffiles dpkg -r leaves nothing, with them state "rc".
            if [[ "$( $container_exec dpkg-query -W -f='${db:Status-Status}' "$PKG_NAME" 2>/dev/null || true )" == "installed" ]]; then
                installed=true
            fi
            ;;
        rpm)
            if $container_exec rpm -q "$PKG_NAME"; then
                installed=true
            fi
            ;;
    esac
    if [[ "$installed" == "true" ]]; then
        echo "$PKG_NAME package still installed after uninstall" >&2
        exit 1
    fi

    echo "Checking $SERVICE_NAME service status after uninstall ..."
    if $container_exec systemctl --no-pager status "$SERVICE_NAME"; then
        echo "$SERVICE_NAME service still running after uninstall" >&2
        exit 1
    fi
    echo "$SERVICE_NAME service successfully stopped after uninstall"

    echo "Checking $SERVICE_NAME service existence after uninstall ..."
    if $container_exec systemctl list-unit-files --all | grep "$SERVICE_NAME"; then
        echo "$SERVICE_NAME service still exists after uninstall" >&2
        exit 1
    fi
    echo "$SERVICE_NAME service successfully removed after uninstall"

    echo "Checking $BINARY process after uninstall ..."
    if $container_exec pgrep -f "$BINARY"; then
        echo "$BINARY process still running after uninstall" >&2
        exit 1
    fi
    echo "$BINARY process successfully killed after uninstall"

    echo "Checking removed files ..."
    local path
    for path in "$BINARY" "$HOME_DIR/VERSION.txt" "$HOME_DIR/log" \
        "$HOME_DIR/updater" "$HOME_DIR/plugins" \
        "/usr/lib/systemd/system/$SERVICE_NAME.service" \
        "/etc/systemd/system/$SERVICE_NAME.service.d" \
        "/etc/init.d/$SERVICE_NAME" "/usr/share/$PKG_NAME"; do
        assert_absent "$container_name" "$path"
    done

    echo "Checking kept files ..."
    for path in "$HOME_DIR/config.yaml" "$HOME_DIR/logging.yaml" "$HOME_DIR/LICENSE"; do
        assert_exists "$container_name" "$path"
    done
    check_user_files
}

echo "=== Scenario: install ==="
start_container
install_pkg "$container_name" "$PKG_PATH"
check_installed
check_service_stopped
check_service_runs
seed_user_files
uninstall

if [[ -z "$UPGRADE_FROM_PATH" ]]; then
    echo "No UPGRADE_FROM_PATH given, skipping the upgrade scenario"
    exit 0
fi

echo "=== Scenario: upgrade from $( basename "$UPGRADE_FROM_PATH" ) ==="
start_container
install_pkg "$container_name" "$UPGRADE_FROM_PATH"
# Wait until it runs: a collector still starting would read manager.yaml.
check_service_runs
seed_user_files
echo "Editing configs ..."
$container_exec sh -c "echo '# pkgtest' >> $HOME_DIR/config.yaml"
$container_exec sh -c "echo '# pkgtest' >> $HOME_DIR/logging.yaml"
config_sum="$( file_sum "$container_name" "$HOME_DIR/config.yaml" )"
logging_sum="$( file_sum "$container_name" "$HOME_DIR/logging.yaml" )"
binary_sum="$( file_sum "$container_name" "$BINARY" )"
old_pid="$( $container_exec systemctl show -p MainPID --value "$SERVICE_NAME" )"

upgrade_pkg "$container_name" "$PKG_PATH"

# The package does not restart the service; the old binary keeps running
# until the user (or install_unix.sh) restarts it.
echo "Checking $SERVICE_NAME service was not restarted by the upgrade ..."
new_pid="$( $container_exec systemctl show -p MainPID --value "$SERVICE_NAME" )"
if [[ "$old_pid" == "0" || "$new_pid" != "$old_pid" ]]; then
    echo "$SERVICE_NAME service: expected PID $old_pid to keep running, got $new_pid" >&2
    exit 1
fi
echo "$SERVICE_NAME service kept running as PID $old_pid"

echo "Checking edited configs after upgrade ..."
if [[ "$( file_sum "$container_name" "$HOME_DIR/config.yaml" )" != "$config_sum" ]]; then
    echo "$HOME_DIR/config.yaml changed by the upgrade" >&2
    exit 1
fi
if [[ "$( file_sum "$container_name" "$HOME_DIR/logging.yaml" )" != "$logging_sum" ]]; then
    echo "$HOME_DIR/logging.yaml changed by the upgrade" >&2
    exit 1
fi
echo "Edited configs kept"
if [[ "$( file_sum "$container_name" "$BINARY" )" == "$binary_sum" ]]; then
    echo "$BINARY not replaced by the upgrade" >&2
    exit 1
fi
echo "$BINARY replaced"
check_user_files
check_installed
# manager.yaml switches the collector to managed (OpAMP) mode, which the
# placeholder cannot serve, so restart in standalone mode like the
# Bindplane collector's package tests and seed it again for the uninstall.
$container_exec rm "$HOME_DIR/manager.yaml"
check_service_runs
seed_user_files
uninstall
