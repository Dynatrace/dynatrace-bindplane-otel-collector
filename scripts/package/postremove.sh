#!/bin/sh
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


set -e

# Read's optional package overrides. Users should deploy the override
# file before installing DBDOT for the first time. The override should
# not be modified unless uninstalling and re-installing.
[ -f /etc/default/dynatrace-bindplane-otel-collector ] && . /etc/default/dynatrace-bindplane-otel-collector
[ -f /etc/sysconfig/dynatrace-bindplane-otel-collector ] && . /etc/sysconfig/dynatrace-bindplane-otel-collector

# The collectors installation directory
: "${DBDOT_CONFIG_HOME:=/opt/dynatrace-bindplane-otel-collector}"

# Check if this is an uninstall or an upgrade
# RPM: $1 is the number of packages remaining that provide this package
#      If $1 == 0, it's a complete uninstall; if $1 > 0, it's an upgrade
# DEB: $1 is "remove", "purge", or "upgrade"
#      If $1 is "remove" or "purge", it's an uninstall; if "upgrade", it's an upgrade
is_uninstall() {
    # Check for DEB format first (string arguments)
    case "$1" in
        remove|purge)
            return 0  # uninstall
            ;;
        upgrade)
            return 1  # upgrade
            ;;
    esac
    
    # Check for RPM format (numeric argument)
    # If $1 is numeric and equals 0, it's an uninstall
    if [ -n "$1" ] && [ "$1" -eq 0 ] 2>/dev/null; then
        return 0  # uninstall
    fi
    
    # Default to upgrade if we can't determine
    return 1  # upgrade
}

remove_file_or_dir() {
    path="$1"
    if [ -f "$path" ]; then
        echo "Removing file: $path"
        rm -f "$path"
    elif [ -d "$path" ]; then
        echo "Removing directory: $path"
        rm -rf "$path"
    else
        echo "File or directory not found, skipping cleanup: $path"
    fi
}

# Only perform cleanup on uninstall, not on upgrade
if is_uninstall "$1"; then
    remove_file_or_dir "${DBDOT_CONFIG_HOME}/package_statuses.json"
    remove_file_or_dir "${DBDOT_CONFIG_HOME}/plugins"
    remove_file_or_dir "${DBDOT_CONFIG_HOME}/log"
    remove_file_or_dir "${DBDOT_CONFIG_HOME}/VERSION.txt"
    remove_file_or_dir "${DBDOT_CONFIG_HOME}/updater"
    remove_file_or_dir "${DBDOT_CONFIG_HOME}/dynatrace-bindplane-otel-collector"
    remove_file_or_dir "${DBDOT_CONFIG_HOME}/install"

    # Remove the service definitions written by postinstall.sh.
    remove_file_or_dir "/usr/lib/systemd/system/dynatrace-bindplane-otel-collector.service"
    remove_file_or_dir "/etc/systemd/system/dynatrace-bindplane-otel-collector.service.d"
    remove_file_or_dir "/etc/init.d/dynatrace-bindplane-otel-collector"
    if command -v systemctl > /dev/null 2>&1; then
        systemctl daemon-reload || true
    fi
else
    echo "Upgrade detected, skipping cleanup"
fi

