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

: "${DBDOT_SKIP_RUNTIME_USER_CREATION:=false}"

# Whether or not to run the collector as an unprivileged user.
: "${DBDOT_UNPRIVILEGED:=false}"

# Configurable runtime user/group
: "${DBDOT_USER:=dbdot}"
: "${DBDOT_GROUP:=dbdot}"

# The collectors installation directory
: "${DBDOT_CONFIG_HOME:=/opt/dynatrace-bindplane-otel-collector}"

# Install creates the user and group for the collector
# service. This function is idempotent and safe to call
# multiple times.
install() {
    if [ "$DBDOT_SKIP_RUNTIME_USER_CREATION" = "true" ]; then
        echo "DBDOT_SKIP_RUNTIME_USER_CREATION is set to true, checking if ${DBDOT_USER} user exists"
        if ! id "$DBDOT_USER" > /dev/null 2>&1; then
            echo "ERROR: DBDOT_SKIP_RUNTIME_USER_CREATION is true but user ${DBDOT_USER} does not exist"
            exit 1
        fi
        echo "User ${DBDOT_USER} exists, skipping user and group creation"
    else
        echo "Creating ${DBDOT_USER} user and group"
        install_user
    fi
}

install_user() {
    # Return early without output if the user and group already exist.
    if id "$DBDOT_USER" > /dev/null 2>&1 && getent group "${DBDOT_GROUP}" > /dev/null 2>&1; then
        return
    fi

    if getent group "${DBDOT_GROUP}" > /dev/null 2>&1; then
        echo "Group ${DBDOT_GROUP} already exists."
    else
        groupadd "${DBDOT_GROUP}"
    fi

    if id "$DBDOT_USER" > /dev/null 2>&1; then
        echo "User ${DBDOT_USER} already exists"
        exit 0
    else
        useradd --shell /sbin/nologin --system "$DBDOT_USER" -g "${DBDOT_GROUP}"
    fi
}

# check_runtime_user_change fails the install before anything is changed when
# the package overrides would change the user that an unprivileged install
# runs as. That user owns DBDOT_CONFIG_HOME and can replace any entry in it
# with a symbolic link, and an install for root or for another user would
# follow those links as root. It also refuses to make an existing root
# install unprivileged, which would start the collector as the runtime user
# against files root created, such as those in storage/. The package writes
# the User= drop-in and root owns it, so the runtime user can't change it.
# postinstall.sh runs the same check, so keep the two the same.
check_runtime_user_change() {
    user_dropin="/etc/systemd/system/dynatrace-bindplane-otel-collector.service.d/10-package-customizations-username.conf"

    # Whether this replaces an installed package: dpkg passes "upgrade" to
    # preinst and the previous version to "configure", and rpm counts more
    # than one installed instance. dpkg also passes the previous version to
    # "configure" when it installs a package that was removed but not
    # purged. Removing the package deletes the collector binary, so without
    # it there is no install to replace.
    upgrade=false
    case "$1" in
        upgrade) upgrade=true ;;
        configure) [ -z "$2" ] || upgrade=true ;;
        [0-9]*) [ "$1" -lt 2 ] || upgrade=true ;;
    esac
    if [ ! -e "${DBDOT_CONFIG_HOME}/dynatrace-bindplane-otel-collector" ]; then
        upgrade=false
    fi

    if [ -f "$user_dropin" ]; then
        current_user="$(sed -n 's/^User=//p' "$user_dropin")"
        if [ "$DBDOT_UNPRIVILEGED" = "true" ] && [ "$DBDOT_USER" = "$current_user" ]; then
            return
        fi
        set_by="set by ${user_dropin}"
    elif [ "$DBDOT_UNPRIVILEGED" = "true" ] && [ "$upgrade" = "true" ]; then
        current_user="root"
        set_by="since there is no ${user_dropin}"
    else
        return 0
    fi

    # Name the override file to set the values in. Both are sourced, and
    # /etc/sysconfig last, so it wins. rpm passes a number as $1, dpkg a word.
    override_file="/etc/default/dynatrace-bindplane-otel-collector"
    if [ -f /etc/sysconfig/dynatrace-bindplane-otel-collector ]; then
        override_file="/etc/sysconfig/dynatrace-bindplane-otel-collector"
    elif [ ! -f "$override_file" ]; then
        case "$1" in
            [0-9]*) override_file="/etc/sysconfig/dynatrace-bindplane-otel-collector" ;;
        esac
    fi

    echo "ERROR: The collector service runs as \"${current_user}\", ${set_by}." >&2
    echo "Changing DBDOT_UNPRIVILEGED or DBDOT_USER on an existing install is not supported. To change them, uninstall the package, remove ${DBDOT_CONFIG_HOME}, and install it again." >&2
    echo "To keep the existing install, set these values in ${override_file}, as described at https://github.com/dynatrace/dynatrace-bindplane-otel-collector/blob/main/docs/installation-linux.md#package-configuration:" >&2
    if [ -f "$user_dropin" ]; then
        echo "    DBDOT_UNPRIVILEGED=true" >&2
        echo "    DBDOT_USER=${current_user}" >&2
    else
        echo "    DBDOT_UNPRIVILEGED=false" >&2
    fi
    echo "Then install the package again." >&2
    exit 1
}

check_runtime_user_change "$@"
install
