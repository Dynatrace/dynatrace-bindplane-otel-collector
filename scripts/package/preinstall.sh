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
[ -f /etc/default/dbdot-collector ] && . /etc/default/dbdot-collector
[ -f /etc/sysconfig/dbdot-collector ] && . /etc/sysconfig/dbdot-collector

: "${DBDOT_SKIP_RUNTIME_USER_CREATION:=false}"

# Configurable runtime user/group
: "${DBDOT_USER:=dbdot}"
: "${DBDOT_GROUP:=dbdot}"

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

install
