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

# Whether or not to run the collector as an unprivileged user. When the
# overrides leave it unset, resolve_unprivileged sets it.

# Configurable runtime user/group
: "${DBDOT_USER:=dbdot}"
: "${DBDOT_GROUP:=dbdot}"

# The collectors installation directory
: "${DBDOT_CONFIG_HOME:=/opt/dynatrace-bindplane-otel-collector}"

# check_user_name fails the install before anything is changed when an
# unprivileged install's DBDOT_USER can't be used in the sudoers drop-in that
# postinstall writes. install_sudoers in postinstall.sh runs the same check,
# so keep the two the same.
check_user_name() {
    if [ "$DBDOT_UNPRIVILEGED" != "true" ] || ! command -v systemctl > /dev/null 2>&1; then
        return
    fi

    # Only allow plain user names so DBDOT_USER can't be parsed as sudoers syntax
    # (%group, #uid, +netgroup, lists, whitespace). The characters are listed
    # explicitly because bracket ranges such as A-Z depend on the locale.
    case "$DBDOT_USER" in
        ""|-*|*[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.-]*)
            echo "ERROR: DBDOT_USER \"${DBDOT_USER}\" can't be used in a sudoers rule" >&2
            exit 1
            ;;
    esac
    # sudoers parses an upper case word such as ALL or ADMINS as a reserved word
    # or an alias, not as a user name.
    case "$DBDOT_USER" in
        *[!ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_]*) ;;
        [ABCDEFGHIJKLMNOPQRSTUVWXYZ]*)
            echo "ERROR: DBDOT_USER \"${DBDOT_USER}\" can't be used in a sudoers rule" >&2
            exit 1
            ;;
    esac
}

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

# resolve_unprivileged sets DBDOT_UNPRIVILEGED when the package overrides
# leave it unset or set it to something other than true or false. A new
# install runs the collector as DBDOT_USER. An existing install keeps the user
# it runs as, so the default never changes it and check_runtime_user_change
# never refuses it. Without systemd the collector runs as root. It refuses the
# install when an existing install has no User= drop-in from the package but
# doesn't run as root, since the user it runs as is then unknown: a unit file
# or drop-in the package didn't write sets another user, or the updater shows
# the install was made to run as another user. It decides only from files
# that root owns, which the runtime user can't create. It prints nothing else;
# postinstall.sh prints what it decided.
# preinstall.sh and postinstall.sh run the same check, so keep the two the
# same.
# shellcheck disable=SC2034 # postinstall.sh reads kept_root and ignored_value.
resolve_unprivileged() {
    unit_file="/usr/lib/systemd/system/dynatrace-bindplane-otel-collector.service"
    unit_override="/etc/systemd/system/dynatrace-bindplane-otel-collector.service"
    dropin_dir="/etc/systemd/system/dynatrace-bindplane-otel-collector.service.d"
    run_dropin_dir="/run/systemd/system/dynatrace-bindplane-otel-collector.service.d"
    user_dropin="${dropin_dir}/10-package-customizations-username.conf"
    binary="${DBDOT_CONFIG_HOME}/dynatrace-bindplane-otel-collector"
    updater="${DBDOT_CONFIG_HOME}/updater"

    # The last user other than root that a unit file or drop-in the package
    # didn't write runs the service as, for example from `systemctl edit`.
    other_user="$(cat "$unit_override" "$dropin_dir"/*.conf "$run_dropin_dir"/*.conf 2> /dev/null |
        sed -n 's/^[[:space:]]*User=[[:space:]]*//p' | grep -v -x -e root -e '' | tail -n 1)" || true

    # How the installed collector runs. Root installs leave the updater a
    # regular file owned by root, and unprivileged installs leave it owned by
    # the runtime user. Removing the package deletes the unit and the
    # collector binary.
    if ! command -v systemctl > /dev/null 2>&1; then
        installed_runtime="sysv"
    elif [ -f "$user_dropin" ]; then
        installed_runtime="user"
    elif [ ! -f "$unit_file" ] && [ ! -e "$binary" ] && [ ! -L "$binary" ]; then
        installed_runtime="none"
    elif [ -z "$other_user" ] && [ ! -L "$updater" ] && [ -f "$updater" ] && [ "$(stat -c %u "$updater")" = "0" ]; then
        installed_runtime="root"
    else
        installed_runtime="unknown"
    fi

    if [ "$installed_runtime" = "unknown" ]; then
        if [ -n "$other_user" ]; then
            echo "ERROR: The collector service has no ${user_dropin}, but a unit file or drop-in that the package didn't write runs it as \"${other_user}\"." >&2
        else
            echo "ERROR: The collector service has no ${user_dropin}, so it runs as root, but ${updater} is missing or not owned by root, so it was installed to run as another user." >&2
        fi
        echo "The package can't tell which user to run the collector as. Restore the drop-in and remove other User= settings, or uninstall the package, remove ${DBDOT_CONFIG_HOME}, and install it again, as described at https://github.com/dynatrace/dynatrace-bindplane-otel-collector/blob/main/docs/installation-linux.md#package-configuration." >&2
        exit 1
    fi

    kept_root=false
    ignored_value=""
    case "${DBDOT_UNPRIVILEGED:-}" in
        true)
            if [ "$installed_runtime" = "sysv" ]; then
                ignored_value="true"
                DBDOT_UNPRIVILEGED=false
            fi
            ;;
        false) ;;
        "")
            case "$installed_runtime" in
                sysv)
                    DBDOT_UNPRIVILEGED=false
                    ;;
                root)
                    DBDOT_UNPRIVILEGED=false
                    kept_root=true
                    ;;
                *)
                    DBDOT_UNPRIVILEGED=true
                    ;;
            esac
            ;;
        *)
            # Released versions ran the collector as root for any value but
            # true, so an upgrade must keep doing that.
            ignored_value="$DBDOT_UNPRIVILEGED"
            DBDOT_UNPRIVILEGED=false
            ;;
    esac
}

# check_leftover_files fails a new unprivileged install before anything is
# changed when DBDOT_CONFIG_HOME holds files that root owns, such as files in
# storage/ that a removed root install left behind. The collector runs as
# DBDOT_USER and can't use them. preinstall.sh and postinstall.sh run the same
# check, so keep the two the same.
check_leftover_files() {
    if [ "$DBDOT_UNPRIVILEGED" != "true" ] || [ "$installed_runtime" != "none" ] || [ ! -d "$DBDOT_CONFIG_HOME" ]; then
        return 0
    fi

    # -H looks into DBDOT_CONFIG_HOME when it is a link to a directory. A
    # file system mounted there has a lost+found that root owns.
    root_file="$(find -H "$DBDOT_CONFIG_HOME" -mindepth 1 -path "$DBDOT_CONFIG_HOME/lost+found" -prune -o -user 0 -print -quit 2> /dev/null)" || true
    if [ -z "$root_file" ]; then
        return 0
    fi

    echo "ERROR: ${DBDOT_CONFIG_HOME} holds files that root owns, such as ${root_file}, probably from an earlier install that ran the collector as root." >&2
    echo "The collector runs as ${DBDOT_USER} and can't use them. Back up the files you want to keep, such as manager.yaml, remove ${DBDOT_CONFIG_HOME}, and install the package again." >&2
    echo "To run the collector as root instead, set DBDOT_UNPRIVILEGED=false in the package override file before you install, as described at https://github.com/dynatrace/dynatrace-bindplane-otel-collector/blob/main/docs/installation-linux.md#package-configuration." >&2
    exit 1
}

resolve_unprivileged
check_user_name
check_runtime_user_change "$@"
check_leftover_files
install
