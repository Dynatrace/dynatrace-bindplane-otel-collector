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

# Installs a Linux package of a DBDOT build in a container, checks the
# installed collector and uninstalls it again. Ported from the Dynatrace OTel
# Collector's internal/testbed/linux-services/package-tests.sh.
#
# deb and rpm run in a systemd container: the service must be installed but
# neither enabled nor started (postinstall.sh only configures it), must stay up
# once started, and must be gone after uninstall. Alpine has no systemd, so the
# apk test checks the installed binary and its removal only.
#
# usage: package-tests.sh PACKAGE_PATH ARCH PACKAGE_NAME
#   PACKAGE_NAME is the nfpm package_name of the build, which is also the name
#   of its service, binary and install directory under /opt.

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PKG_PATH="${1:-}"
ARCH="${2:-}"
PKG_NAME="${3:-}"

# shellcheck source=scripts/package-tests/common.sh
source "$SCRIPT_DIR"/common.sh

if [[ -z "$PKG_PATH" || -z "$ARCH" || -z "$PKG_NAME" ]]; then
    echo "usage: ${BASH_SOURCE[0]} PACKAGE_PATH ARCH PACKAGE_NAME" >&2
    exit 1
fi

if [[ ! -f "$PKG_PATH" ]]; then
    echo "$PKG_PATH not found!" >&2
    exit 1
fi

pkg_base="$( basename "$PKG_PATH" )"
pkg_type="${pkg_base##*.}"
if [[ ! "$pkg_type" =~ ^(deb|rpm|apk)$ ]]; then
    echo "$PKG_PATH not supported!" >&2
    exit 1
fi

SERVICE_NAME="$PKG_NAME"
BINARY="/opt/$PKG_NAME/$PKG_NAME"

image_name="$PKG_NAME-$pkg_type-test"
container_name="$image_name"
container_exec="podman exec $container_name"

trap 'podman rm -fv $container_name >/dev/null 2>&1 || true' EXIT

podman build -t "$image_name" --arch "$ARCH" -f "$SCRIPT_DIR/Dockerfile.test.$pkg_type" "$SCRIPT_DIR"
podman rm -fv "$container_name" >/dev/null 2>&1 || true

podman run --name "$container_name" --arch "$ARCH" -d "$image_name"
install_pkg "$container_name" "$PKG_PATH"

echo "Checking $BINARY ..."
$container_exec "$BINARY" --version

if [[ "$pkg_type" != "apk" ]]; then
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

    $container_exec systemctl start "$SERVICE_NAME"

    # ensure service has started and still running after 5 seconds
    sleep 5
    echo "Checking $SERVICE_NAME service status ..."
    $container_exec systemctl --no-pager status "$SERVICE_NAME"

    echo "Checking $BINARY process ..."
    $container_exec pgrep -f -a "$BINARY"
fi

# test uninstall
uninstall_pkg "$container_name" "$pkg_type" "$PKG_NAME"

if [[ "$pkg_type" != "apk" ]]; then
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
fi

echo "Checking $BINARY after uninstall ..."
if $container_exec test -e "$BINARY"; then
    echo "$BINARY still exists after uninstall" >&2
    exit 1
fi
echo "$BINARY successfully removed after uninstall"
