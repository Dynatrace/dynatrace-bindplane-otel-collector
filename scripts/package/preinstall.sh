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

: "${DBDOT_CONFIG_HOME:=/opt/dynatrace-bindplane-otel-collector}"
: "${DBDOT_SKIP_RUNTIME_USER_CREATION:=false}"

# Configurable runtime user/group
: "${DBDOT_USER:=dbdot}"
: "${DBDOT_GROUP:=dbdot}"

# install_dir_rejection prints why $DBDOT_CONFIG_HOME isn't safe to install into or
# delete under, or nothing when it is. It matches check_install_path in
# install_unix.sh: an absolute path with no whitespace, double quote, ':', '.' or
# '..', and not a core system directory.
install_dir_rejection() {
    dir="$DBDOT_CONFIG_HOME"
    while :; do
        case "$dir" in
            ?*/) dir=${dir%/} ;;
            *) break ;;
        esac
    done
    case "$dir" in
        /*) ;;
        *) echo "DBDOT_CONFIG_HOME must be an absolute path"; return ;;
    esac
    case "$dir" in
        *[[:space:]]* | *'"'* | *:* | *//* | */./* | */. | */../* | */..)
            echo "DBDOT_CONFIG_HOME can't contain whitespace, a double quote, ':', '.' or '..'"; return ;;
    esac
    case "$dir" in
        / | /bin | /boot | /dev | /etc | /home | /lib | /lib32 | /lib64 | /libx32 | /media | /mnt | /opt | /proc | /root | /run | /sbin | /snap | /srv | /sys | /tmp | \
        /usr | /usr/bin | /usr/include | /usr/lib | /usr/lib32 | /usr/lib64 | /usr/libexec | /usr/local | /usr/local/bin | /usr/local/lib | /usr/sbin | /usr/share | \
        /var | /var/cache | /var/lib | /var/log | /var/opt | /var/run | /var/spool | /var/tmp)
            echo "DBDOT_CONFIG_HOME can't be the system directory $dir" ;;
    esac
}

# Install creates the user and group for the collector
# service. This function is idempotent and safe to call
# multiple times.
install() {
    rejection=$(install_dir_rejection)
    if [ -n "$rejection" ]; then
        echo "ERROR: $rejection"
        exit 1
    fi

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

install
