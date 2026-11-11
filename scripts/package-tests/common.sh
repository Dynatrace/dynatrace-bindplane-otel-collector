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
        apk)
            # The apk is not signed.
            podman exec "$container" apk add --allow-untrusted /tmp/"$pkg_base"
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
        apk)
            podman exec "$container" apk del "$pkg_name"
            ;;
    esac
}
