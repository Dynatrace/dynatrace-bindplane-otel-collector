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

# Whether or not to run the collector as an unprivileged user. When the
# overrides leave it unset, resolve_unprivileged sets it.

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

# check_install_dir fails the install before anything is changed when
# DBDOT_CONFIG_HOME isn't safe to install into. It runs before the other
# checks, because their errors tell you to remove DBDOT_CONFIG_HOME.
check_install_dir() {
    rejection=$(install_dir_rejection)
    if [ -n "$rejection" ]; then
        echo "ERROR: $rejection"
        exit 1
    fi
}

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
# against files root created, such as those in storage/. It compares the
# user that resolve_unprivileged found in the package's unit or User= drop-in,
# which root owns and the runtime user can't change, so it runs after
# resolve_unprivileged.
# postinstall.sh runs the same check, so keep the two the same.
check_runtime_user_change() {
    case "$installed_runtime" in
        root|user) ;;
        *) return 0 ;;
    esac

    wanted_user="root"
    if [ "$DBDOT_UNPRIVILEGED" = "true" ]; then
        wanted_user="$DBDOT_USER"
    fi
    if [ "$installed_user" = "$wanted_user" ]; then
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

    echo "ERROR: The collector service runs as \"${installed_user}\", set by ${installed_from}." >&2
    echo "Changing DBDOT_UNPRIVILEGED or DBDOT_USER on an existing install is not supported. To change them, uninstall the package, remove ${DBDOT_CONFIG_HOME}, and install it again." >&2
    echo "To keep the existing install, set these values in ${override_file}, as described at https://github.com/dynatrace/dynatrace-bindplane-otel-collector/blob/main/docs/installation-linux.md#package-configuration:" >&2
    if [ "$installed_user" = "root" ]; then
        echo "    DBDOT_UNPRIVILEGED=false" >&2
    else
        echo "    DBDOT_UNPRIVILEGED=true" >&2
        echo "    DBDOT_USER=${installed_user}" >&2
    fi
    echo "Then install the package again." >&2
    exit 1
}

# resolve_unprivileged sets DBDOT_UNPRIVILEGED when the package overrides
# leave it unset or set it to something other than true or false. A new
# install runs the collector as DBDOT_USER. An existing install keeps the user
# it runs as, so the default never changes it and check_runtime_user_change
# never refuses it. Without systemd the collector runs as root. It sets
# installed_user to the user the package runs the service as: the one in the
# package's User= drop-in when there is one, or else the one in the unit. It
# refuses the install when the user the install runs as is unknown: a unit
# file or drop-in the package didn't write sets another user, or the updater
# shows the install was made to run as another user. It decides only from
# files that root owns, which the runtime user can't create. It prints
# nothing else; postinstall.sh prints what it decided.
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

    # The user the package runs the service as: the one in its User= drop-in,
    # or else the one in its unit. systemd runs a service without User= as
    # root.
    installed_from="$unit_file"
    if [ -f "$user_dropin" ]; then
        installed_from="$user_dropin"
    fi
    installed_user="$(sed -n 's/^[[:space:]]*User=[[:space:]]*//p' "$installed_from" 2> /dev/null | tail -n 1)" || true
    if [ -z "$installed_user" ]; then
        installed_user="root"
    fi

    # The last user that a unit file or drop-in the package didn't write runs
    # the service as, for example from `systemctl edit`.
    other_user="$(for f in "$unit_override" "$dropin_dir"/*.conf "$run_dropin_dir"/*.conf; do
        if [ "$f" != "$user_dropin" ]; then
            cat "$f" 2> /dev/null
        fi
    done | sed -n 's/^[[:space:]]*User=[[:space:]]*//p' | grep -v -x -e '' | tail -n 1)" || true

    # Root installs leave the updater a regular file owned by root, and
    # unprivileged installs leave it owned by the runtime user. Releases that
    # ran the collector as root by default left it owned by root in
    # unprivileged installs too, which they gave the User= drop-in.
    updater_root=false
    if [ ! -L "$updater" ] && [ -f "$updater" ] && [ "$(stat -c %u "$updater")" = "0" ]; then
        updater_root=true
    fi

    # How the installed collector runs. Removing the package deletes the unit
    # and the collector binary.
    if ! command -v systemctl > /dev/null 2>&1; then
        installed_runtime="sysv"
    elif [ ! -f "$unit_file" ] && [ ! -e "$binary" ] && [ ! -L "$binary" ]; then
        installed_runtime="none"
    elif [ -n "$other_user" ] && [ "$other_user" != "$installed_user" ]; then
        installed_runtime="unknown"
    elif [ "$installed_user" = "root" ]; then
        if [ "$updater_root" = "true" ]; then
            installed_runtime="root"
        else
            installed_runtime="unknown"
        fi
    elif [ -f "$user_dropin" ] || [ "$updater_root" = "false" ]; then
        installed_runtime="user"
    else
        installed_runtime="unknown"
    fi

    if [ "$installed_runtime" = "unknown" ]; then
        if [ -n "$other_user" ] && [ "$other_user" != "$installed_user" ]; then
            echo "ERROR: ${installed_from} runs the collector service as \"${installed_user}\", but a unit file or drop-in that the package didn't write runs it as \"${other_user}\"." >&2
        elif [ "$installed_user" = "root" ]; then
            echo "ERROR: The collector service runs as root, but ${updater} is missing or not owned by root, so it was installed to run as another user." >&2
        else
            echo "ERROR: ${installed_from} runs the collector service as \"${installed_user}\", but ${updater} is owned by root, so it was installed to run as root. Its User= drop-in ${user_dropin} may have been removed, for example by \"systemctl revert\"." >&2
        fi
        echo "The package can't tell which user to run the collector as. Remove the User= settings that the package didn't write, restore ${user_dropin} with \"User=root\" if the collector ran as root, or uninstall the package, remove ${DBDOT_CONFIG_HOME}, and install it again, as described at https://github.com/dynatrace/dynatrace-bindplane-otel-collector/blob/main/docs/installation-linux.md#package-configuration." >&2
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

check_install_dir
resolve_unprivileged
check_user_name
check_runtime_user_change "$@"
check_leftover_files
install
