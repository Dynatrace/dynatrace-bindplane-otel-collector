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

# Helpers for package-tests.sh. Ported from the Dynatrace OTel Collector's
# internal/testbed/linux-services, which is based on the OpenTelemetry
# Collector Releases package tests.

podman_cp() {
    local container="$1"
    local src="$2"
    local dest="$3"
    local dest_dir
    dest_dir="$( dirname "$dest" )"

    echo "Copying $src to $container:$dest ..."
    podman exec "$container" mkdir -p "$dest_dir"
    podman cp "$src" "$container":"$dest"
}

install_pkg() {
    local container="$1"
    local pkg_path="$2"
    local pkg_base
    pkg_base=$( basename "$pkg_path" )

    echo "Installing $pkg_base ..."
    podman_cp "$container" "$pkg_path" /tmp/"$pkg_base"
    case "${pkg_base##*.}" in
        deb)
            podman exec "$container" dpkg -i /tmp/"$pkg_base"
            ;;
        rpm)
            # Snapshot packages are not signed.
            podman exec "$container" rpm -ivh --nosignature /tmp/"$pkg_base"
            ;;
    esac
}

uninstall_pkg() {
    local container="$1"
    local pkg_type="$2"
    local pkg_name="$3"

    echo "Uninstalling $pkg_name ..."
    case "$pkg_type" in
        deb)
            podman exec "$container" dpkg -r "$pkg_name"
            ;;
        rpm)
            podman exec "$container" rpm -e "$pkg_name"
            ;;
    esac
}

# upgrade_pkg installs a newer package over the installed one.
upgrade_pkg() {
    local container="$1"
    local pkg_path="$2"
    local pkg_base
    pkg_base=$( basename "$pkg_path" )

    echo "Upgrading to $pkg_base ..."
    podman_cp "$container" "$pkg_path" /tmp/"$pkg_base"
    case "${pkg_base##*.}" in
        deb)
            podman exec "$container" dpkg -i /tmp/"$pkg_base"
            ;;
        rpm)
            # Snapshot packages are not signed. rpm sorts a snapshot before
            # the release it is based on (1.3.1~SNAPSHOT < 1.3.1).
            podman exec "$container" rpm -Uvh --nosignature --oldpackage /tmp/"$pkg_base"
            ;;
    esac
}

# assert_stat fails unless PATH in the container has the owner, group and octal
# mode given as "owner:group mode", e.g. "dbdot:dbdot 640". A mode of "-" only
# checks the owner and group.
assert_stat() {
    local container="$1"
    local path="$2"
    local expected="$3"
    local actual

    if ! actual=$( podman exec "$container" stat -c '%U:%G %a' "$path" ); then
        echo "$path does not exist" >&2
        return 1
    fi
    if [[ "${expected#* }" == "-" ]]; then
        actual="${actual%% *} -"
    fi
    if [[ "$actual" != "$expected" ]]; then
        echo "$path: expected $expected, got $actual" >&2
        return 1
    fi
    echo "$path: $actual"
}

assert_exists() {
    local container="$1"
    local path="$2"

    if ! podman exec "$container" test -e "$path"; then
        echo "$path does not exist" >&2
        return 1
    fi
    echo "$path exists"
}

assert_absent() {
    local container="$1"
    local path="$2"

    if podman exec "$container" test -e "$path"; then
        echo "$path still exists" >&2
        return 1
    fi
    echo "$path absent"
}

# file_sum prints the checksum of a file in the container.
file_sum() {
    podman exec "$1" sha256sum "$2" | cut -d' ' -f1
}
