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

# Never create a file that group or others can write, whatever umask the
# package manager runs with. This keeps the systemd unit and drop-ins and
# the sudoers drop-in root-only from the moment they are created.
umask go-w

# Read's optional package overrides. Users should deploy the override
# file before installing DBDOT for the first time. The override should
# not be modified unless uninstalling and re-installing.
[ -f /etc/default/dynatrace-bindplane-otel-collector ] && . /etc/default/dynatrace-bindplane-otel-collector
[ -f /etc/sysconfig/dynatrace-bindplane-otel-collector ] && . /etc/sysconfig/dynatrace-bindplane-otel-collector

# The collectors installation directory
: "${DBDOT_CONFIG_HOME:=/opt/dynatrace-bindplane-otel-collector}"

# Whether or not to run the collector as an unprivileged user. When the
# overrides leave it unset, resolve_unprivileged sets it.

# Configurable runtime user/group
: "${DBDOT_USER:=dbdot}"
: "${DBDOT_GROUP:=dbdot}"


# run_as_home_owner runs a command that writes in DBDOT_CONFIG_HOME. When
# unprivileged, the runtime user owns DBDOT_CONFIG_HOME and can replace any
# entry in it with a symbolic link, which root would follow. So the command
# runs as that user and can only reach files the user could already change.
# Otherwise nothing runs as the runtime user, and the command runs as root.
run_as_home_owner() {
    if [ "${DBDOT_UNPRIVILEGED}" = "true" ]; then
        runuser -u "$DBDOT_USER" -g "$DBDOT_GROUP" -- "$@"
    else
        "$@"
    fi
}

install() {
    mkdir -p "${DBDOT_CONFIG_HOME}"
    chmod 0755 "${DBDOT_CONFIG_HOME}"
    chown "$DBDOT_USER:$DBDOT_GROUP" "${DBDOT_CONFIG_HOME}"

    share_dir="/usr/share/dynatrace-bindplane-otel-collector"
    stage_dir="${share_dir}/stage/dynatrace-bindplane-otel-collector"

    # The package manager unpacks the stage owned by root, and this function
    # gives it to the runtime user below. If this script failed after that and
    # runs again, for example with "dpkg --configure", the runtime user may
    # have replaced entries in the stage with symbolic links. Take the stage
    # back first. chown -R changes links themselves and doesn't follow them.
    chown -R root:root "$stage_dir"

    # Rename binaries in staging directory to avoid Linux binary locking issues
    # during copy operation
    mv "${stage_dir}/dynatrace-bindplane-otel-collector" "${stage_dir}/dynatrace-bindplane-otel-collector.new"

    # Goreleaser does not set plugin file permissions. When unprivileged,
    # finish_permissions doesn't change files in DBDOT_CONFIG_HOME, so set them
    # here while root still owns the stage. find doesn't follow links.
    if [ "${DBDOT_UNPRIVILEGED}" = "true" ]; then
        find "$stage_dir/plugins" -type f -exec chmod 0640 {} +
    fi

    # Prepare staged files with runtime ownership so destination does not need
    # post-copy ownership changes. This helps to ensure permissions do not flap
    # between root and the runtime user.
    chown -R "$DBDOT_USER:$DBDOT_GROUP" "$stage_dir"

    # Ensure updater is owned by root. When unprivileged, the runtime user
    # copies the files into DBDOT_CONFIG_HOME, so it owns the updater anyway.
    if [ "${DBDOT_UNPRIVILEGED}" != "true" ]; then
        chown root:root "$stage_dir/updater"
    fi

    # Seed default configs only when absent so upgrades/reinstalls preserve
    # user edits. The stage dir is ephemeral, so pruning it here is safe.
    for cfg in config.yaml logging.yaml; do
        if [ -f "${DBDOT_CONFIG_HOME}/${cfg}" ]; then
            rm -f "${stage_dir}/${cfg}"
        fi
    done

    # Remove each existing file before copying over it instead of writing
    # into it. A root install leaves the updater owned by root, which the
    # runtime user can't write but can remove, since it owns
    # DBDOT_CONFIG_HOME. A symbolic link in place of a file is replaced, not
    # followed.
    run_as_home_owner cp -r --preserve --remove-destination \
      "$stage_dir"/* \
      "${DBDOT_CONFIG_HOME}"

    # Perform atomic moves for binary files to replace running binaries
    run_as_home_owner mv "${DBDOT_CONFIG_HOME}/dynatrace-bindplane-otel-collector.new" "${DBDOT_CONFIG_HOME}/dynatrace-bindplane-otel-collector"

    rm -rf "$share_dir"
}

install_service() {
  if command -v systemctl > /dev/null 2>&1; then
    install_systemd_service
  else
    install_initd_service
  fi
}

# PATH for the collector service. The updater inherits it and runs sudo and
# systemctl through it.
service_path="/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"

install_systemd_service() {
  config_file="/usr/lib/systemd/system/dynatrace-bindplane-otel-collector.service"

  if [ ! -f "$config_file" ]; then
    echo "Installing systemd service to $config_file"
  else
    echo "Updating systemd service to $config_file"
  fi

  mkdir -p "$(dirname "$config_file")"

  cat << EOF > "$config_file"
[Unit]
Description=Dynatrace Bindplane Distribution of OpenTelemetry Collector
After=network.target
StartLimitIntervalSec=120
StartLimitBurst=5
[Service]
Type=simple
User=root
Group=${DBDOT_GROUP}
Environment=PATH=${service_path}
Environment=BINDPLANE_COLLECTOR_HOME=${DBDOT_CONFIG_HOME}
Environment=BINDPLANE_COLLECTOR_STORAGE=${DBDOT_CONFIG_HOME}/storage
WorkingDirectory=${DBDOT_CONFIG_HOME}
ExecStart=${DBDOT_CONFIG_HOME}/dynatrace-bindplane-otel-collector --config config.yaml
LimitNOFILE=65000
SuccessExitStatus=0
TimeoutSec=20
StandardOutput=journal
Restart=on-failure
RestartSec=5s
KillMode=process
[Install]
WantedBy=multi-user.target
EOF

  chown root:root "$config_file"
  chmod 0640 "$config_file"

  # Ensure the override dir exists.
  override_dir="/etc/systemd/system/dynatrace-bindplane-otel-collector.service.d"
  if [ ! -d "$override_dir" ]; then
    mkdir -p "$override_dir"
    echo "Created systemd override directory at $override_dir"
  fi
  # systemd applies these drop-ins to the service, so only root may change them.
  chown root:root "$override_dir"
  chmod 0755 "$override_dir"

  # Write the User= drop-in when DBDOT_UNPRIVILEGED is true. Otherwise there is
  # none to remove: check_runtime_user_change refuses the install when one is
  # present, and preremove.sh removes it on uninstall.
  override_user_path="${override_dir}/10-package-customizations-username.conf"
  if [ "${DBDOT_UNPRIVILEGED}" = "true" ]; then
    cat << EOF > "${override_user_path}"
[Service]
User=${DBDOT_USER}
EOF
    chown root:root "${override_user_path}"
    chmod 0644 "${override_user_path}"
    echo "Configured systemd service to run as ${DBDOT_USER} user in ${override_user_path}"
  fi
}

install_initd_service() {
  config_file="/etc/init.d/dynatrace-bindplane-otel-collector"

  if [ ! -f "$config_file" ]; then
    echo "Installing init.d service to $config_file"
  else
    echo "Updating init.d service to $config_file"
  fi

  mkdir -p "$(dirname "$config_file")"

  cat << EOF > "$config_file"
#!/bin/sh
# DBDOT OTEL daemon
# chkconfig: 2345 99 05
# description: Dynatrace Bindplane Distribution of OpenTelemetry Collector
# processname: dynatrace-bindplane-otel-collector
# pidfile: /var/run/dynatrace-bindplane-otel-collector.pid

### BEGIN INIT INFO
# Provides: dynatrace-bindplane-otel-collector
# Required-Start:
# Required-Stop:
# Should-Start:
# Default-Start: 3 5
# Default-Stop: 0 1 2 6  
# Description: Start the dynatrace-bindplane-otel-collector service
### END INIT INFO

# Source function library.
# RHEL
if [ -e /etc/init.d/functions ]; then
  STATUS=true
  # shellcheck disable=SC1091
  . /etc/init.d/functions
fi
# SUSE
if [ -e /etc/rc.status ]; then
  RCSTATUS=true
  # Shell functions sourced from /etc/rc.status:
  #      rc_check         check and set local and overall rc status
  #      rc_status        check and set local and overall rc status
  #      rc_status -v     ditto but be verbose in local rc status
  #      rc_status -v -r  ditto and clear the local rc status
  #      rc_failed        set local and overall rc status to failed
  #      rc_failed <num>  set local and overall rc status to <num><num>
  #      rc_reset         clear local rc status (overall remains)
  #      rc_exit          exit appropriate to overall rc status
  # shellcheck disable=SC1091
  . /etc/rc.status

  # First reset status of this service
  rc_reset
fi
# LSB Capable
if [ -e /lib/lsb/init-functions ]; then
  PROC=true
  # shellcheck disable=SC1091
  . /lib/lsb/init-functions
fi

# Return values acc. to LSB for all commands but status:
# 0 - success
# 1 - generic or unspecified error
# 2 - invalid or excess argument(s)
# 3 - unimplemented feature (e.g. "reload")
# 4 - insufficient privilege
# 5 - program is not installed
# 6 - program is not configured
# 7 - program is not running
#
# Note that, for LSB, starting an already running service, stopping
# or restarting a not-running service as well as the restart
# with force-reload (in case signalling is not supported) are
# considered a success.

BINARY=dynatrace-bindplane-otel-collector
PROGRAM=${DBDOT_CONFIG_HOME}/"\$BINARY"
START_CMD="nohup ${DBDOT_CONFIG_HOME}/\$BINARY > /dev/null 2>&1 &"
LOCKFILE=/var/lock/"\$BINARY"
PIDFILE=/var/run/"\$BINARY".pid

# Exported variables are used by the collector process.
export BINDPLANE_COLLECTOR_HOME=${DBDOT_CONFIG_HOME}
export BINDPLANE_COLLECTOR_STORAGE=${DBDOT_CONFIG_HOME}/storage

RETVAL=0
start() {
  [ -x "\$PROGRAM" ] || exit 5

  # shellcheck disable=SC3037
  echo -n "Starting \$0: "

  # RHEL
  if [ "\$STATUS" ]; then
    umask 077

    daemon --pidfile="\$PIDFILE" "\$START_CMD"
    RETVAL=\$?
    # truncate the pid file, just in case
    : > "\$PIDFILE"
    # shellcheck disable=SC2005
    echo "\$(pidof "\$BINARY")" > "\$PIDFILE"
    [ "\$RETVAL" -eq 0 ] && touch "\$LOCKFILE"
  # SUSE
  elif [ "\$RCSTATUS" ]; then
    ## Start daemon with startproc(8). If this fails
    ## the echo return value is set appropriate.

    # NOTE: startproc return 0, even if service is
    # already running to match LSB spec.
    nohup "\$PROGRAM" --config config.yaml > /dev/null 2>&1 &

    # Remember status and be verbose
    rc_status -v

    # truncate the pid file, just in case
    : > "\$PIDFILE"
    # shellcheck disable=SC2005
    echo "\$(pidof "\$BINARY")" > "\$PIDFILE"
  fi
  echo
}

stop() {
  # shellcheck disable=SC3037
  echo -n "Shutting down \$0: "
  # RHEL
  if [ "\$STATUS" ]; then
      killproc -p "\$PIDFILE" -d30 "\$BINARY"
      RETVAL=\$?
      echo
      [ "\$RETVAL" -eq 0 ] && rm -f "\$LOCKFILE"
      return "\$RETVAL"
  # SUSE
  elif [ "\$RCSTATUS" ]; then
      ## Stop daemon with killproc(8) and if this fails
      ## set echo the echo return value.
      killproc -t30 -p "\$PIDFILE" "\$BINARY"

      # Remember status and be verbose
      rc_status -v
  fi
  echo
}

# Currently unimplemented
reload() {
  # RHEL
  #if [ \$STATUS ]; then
  # SUSE
  #elif [ \$RCSTATUS ]; then
  #fi
  echo "Reload is not currently implemented for \$0"
  RETVAL=3
}

# Currently unimplemented
force_reload() {
  # RHEL
  #if [ \$STATUS ]; then
  # SUSE
  #elif [ \$RCSTATUS ]; then
  #fi
  echo "Reload is not currently implemented for \$0, redirecting to restart"
  restart
}

pid_not_running() {
  echo " * \$PROGRAM is not running"
  RETVAL=7
}

pid_status() {
  if [ -e "\$PIDFILE" ]; then
    if ps -p "\$(cat "\$PIDFILE")" > /dev/null; then
      echo " * \$PROGRAM" is running, pid="\$(cat "\$PIDFILE")"
    else
      pid_not_running
    fi
  else
    pid_not_running
  fi
}

otel_status() {
  if [ -e "\$PIDFILE" ]; then
    # shellcheck disable=SC3037
    echo -n "Status of \$0 (\$(cat "\$PIDFILE")) "
  else
    # shellcheck disable=SC3037
    echo -n "Status of \$0 (no pidfile found) "
  fi

  if [ "\$STATUS" ]; then
    status -p "\$PIDFILE" "\$PROGRAM"
    RETVAL=\$?
  elif [ "\$RCSTATUS" ]; then
    ## Check status with checkproc(8), if process is running
    ## checkproc will return with exit status 0.

    # Status has a slightly different for the status command:
    # 0 - service running
    # 1 - service dead, but /var/run/  pid  file exists
    # 2 - service dead, but /var/lock/ lock file exists
    # 3 - service not running

    # NOTE: checkproc returns LSB compliant status values.
    checkproc -p "\$PIDFILE" "\$PROGRAM"
    rc_status -v
  elif [ "\$PROC" ]; then
    status_of_proc -p "\$PIDFILE" "\$PROGRAM" "\$PROGRAM"
    RETVAL=\$?
  else
    pid_status
  fi
  echo
}

cd "\$BINDPLANE_COLLECTOR_HOME" || exit 1
case "\$1" in
  # Start the service
  start)
    start
    ;;
  # Stop the service
  stop)
    stop
    ;;
  # Get the status of the service
  status)
    otel_status
    ;;
  # Restart the service by stop, then restart
  restart)
    stop
    # sleep for 1 second to prevent false starts leaving us in a bad state
    sleep 1
    start
    ;;
  # Not currently implemented, but should reload the config file
  reload)
    reload
    ;;
  # Not currently implemented, but should reload the config file.
  # If it fails, restart
  force-reload)
    force_reload
    ;;
  # Conditionally restart the service (only if running already)
  condrestart|try-restart)
    otel_status >/dev/null 2>&1 || exit 0
    restart
    ;;
  *)
    echo "Usage: \$0 {start|stop|restart|condrestart|try-restart|reload|force-reload|status}"
    RETVAL=3
    ;;
esac
cd "\$OLDPWD" || exit 1

if [ "\$RCSTATUS" ]; then
  rc_exit
fi

exit "\$RETVAL"
EOF

  chown root:root "$config_file"
  chmod 0755 "$config_file"
}

manage_systemd_service() {
  # Ensure sysv script isn't present, and if it is remove it
  if [ -f /etc/init.d/dynatrace-bindplane-otel-collector ]; then
    rm -f /etc/init.d/dynatrace-bindplane-otel-collector
  fi

  systemctl daemon-reload

  echo "configured systemd service"

  runtime_user="root"
  if [ "${DBDOT_UNPRIVILEGED}" = "true" ]; then
    runtime_user="${DBDOT_USER}"
  fi

  cat << EOF

The "dynatrace-bindplane-otel-collector" service has been configured!

The collector runs as the "${runtime_user}" user.

The collector's config file can be found here: 
  ${DBDOT_CONFIG_HOME}/config.yaml

To view logs from the collector, run:
  sudo tail -F ${DBDOT_CONFIG_HOME}/log/collector.log

For more information on configuring the collector, see the docs:
  https://github.com/dynatrace/dynatrace-bindplane-otel-collector/tree/main

To stop the dynatrace-bindplane-otel-collector service, run:
  sudo systemctl stop dynatrace-bindplane-otel-collector

To start the dynatrace-bindplane-otel-collector service, run:
  sudo systemctl start dynatrace-bindplane-otel-collector

To restart the dynatrace-bindplane-otel-collector service, run:
  sudo systemctl restart dynatrace-bindplane-otel-collector

To enable the service on startup, run:
  sudo systemctl enable dynatrace-bindplane-otel-collector

If you have any other questions please contact us at support@bindplane.com
EOF
}

manage_sysv_service() {
  chmod 755 /etc/init.d/dynatrace-bindplane-otel-collector
  echo "configured sysv service"
}

init_type() {
  # Determine if we need service or systemctl for prereqs
  if command -v systemctl > /dev/null 2>&1; then
    command printf "systemd"
    return
  elif command -v service > /dev/null 2>&1; then
    command printf "service"
    return
  fi

  command printf "unknown"
  return
}

manage_service() {
  service_type="$(init_type)"
  case "$service_type" in
    systemd)
      manage_systemd_service
      ;;
    service)
      manage_sysv_service
      ;;
    *)
      echo "could not detect init system, skipping service configuration"
  esac
}

finish_permissions() {
  # When unprivileged, root must not change files in DBDOT_CONFIG_HOME, because
  # the runtime user owns it and can replace any entry with a symbolic link.
  # install already copied the files as that user and set the plugin modes in
  # the stage, and the collector creates its own log file.
  if [ "${DBDOT_UNPRIVILEGED}" = "true" ]; then
    return 0
  fi

  # Goreleaser does not set plugin file permissions, so do them here
  # We also change the owner of the binary to dynatrace-bindplane-otel-collector
  chown -R "$DBDOT_USER:$DBDOT_GROUP" ${DBDOT_CONFIG_HOME}/dynatrace-bindplane-otel-collector ${DBDOT_CONFIG_HOME}/plugins/*
  chmod 0640 ${DBDOT_CONFIG_HOME}/plugins/*

  # Initialize the log file to ensure it is owned by dynatrace-bindplane-otel-collector.
  # This prevents the service (running as root) from assigning ownership to
  # the root user. By doing so, we allow the user to switch to dynatrace-bindplane-otel-collector
  # user for 'non root' installs.
  touch ${DBDOT_CONFIG_HOME}/log/collector.log
  chown "$DBDOT_USER:$DBDOT_GROUP" ${DBDOT_CONFIG_HOME}/log/collector.log
}

sudoers_file="/etc/sudoers.d/dynatrace-bindplane-otel-collector"

remove_sudoers() {
  if [ -f "$sudoers_file" ]; then
    echo "Removing sudoers drop-in: $sudoers_file"
    rm -f "$sudoers_file"
  fi
}

# install_sudoers lets DBDOT_USER stop and start the collector service so the
# updater can replace the collector's files. Any process running as DBDOT_USER
# can run these commands, so they must never take a path, file content or
# argument that DBDOT_USER controls. The drop-in holds these two commands and
# a single Defaults line that turns off requiretty. Don't add other commands
# or Defaults.
install_sudoers() {
  if ! command -v systemctl > /dev/null 2>&1; then
    echo "systemd not found, skipping sudoers drop-in"
    remove_sudoers
    return 0
  fi
  if ! command -v visudo > /dev/null 2>&1; then
    echo "WARNING: sudo is not installed (visudo not found), so the sudoers drop-in was not written and remote updates will fail. Install sudo, then reinstall or upgrade this package." >&2
    remove_sudoers
    return 0
  fi
  if [ "$DBDOT_USER" = "root" ]; then
    remove_sudoers
    return 0
  fi

  # Only allow plain user names so DBDOT_USER can't be parsed as sudoers syntax
  # (%group, #uid, +netgroup, lists, whitespace). The characters are listed
  # explicitly because bracket ranges such as A-Z depend on the locale.
  # check_user_name in preinstall.sh runs the same check before anything is
  # installed, so keep the two the same.
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

  systemctl_path="$(command -v systemctl)"
  case "$systemctl_path" in
    /*) ;;
    *)
      echo "ERROR: could not resolve an absolute path for systemctl" >&2
      exit 1
      ;;
  esac

  # sudo skips files in /etc/sudoers.d whose names contain a ".", so the
  # file isn't read until it has passed validation and been renamed.
  tmp_file="${sudoers_file}.tmp"
  mkdir -p "$(dirname "$sudoers_file")"
  rm -f "$tmp_file"
  cat << EOF > "$tmp_file"
# Sudoers drop-in for the Dynatrace Bindplane Distribution of OpenTelemetry Collector.
# Generated by the package for runtime user "${DBDOT_USER}". It lets the updater
# stop and start the collector service while it replaces the collector's files.
# Any process running as "${DBDOT_USER}" can run these commands. Don't add others.
# The updater has no TTY, so requiretty is off for this user. It grants nothing.
Defaults:${DBDOT_USER} !requiretty
${DBDOT_USER} ALL=(root) NOPASSWD: ${systemctl_path} start dynatrace-bindplane-otel-collector.service
${DBDOT_USER} ALL=(root) NOPASSWD: ${systemctl_path} stop dynatrace-bindplane-otel-collector.service
EOF
  chown root:root "$tmp_file"
  chmod 0440 "$tmp_file"

  if ! visudo -cf "$tmp_file" > /dev/null 2>&1; then
    rm -f "$tmp_file"
    echo "ERROR: generated sudoers drop-in failed validation" >&2
    exit 1
  fi

  echo "Installing sudoers drop-in to $sudoers_file"
  mv -f "$tmp_file" "$sudoers_file"
}

# check_sudo_grant warns when the host stops DBDOT_USER from using the sudoers
# drop-in from inside the service, which makes every remote update fail at
# "systemctl stop". It only warns and never fails the install. It must run
# after manage_service so systemd has loaded the current unit and drop-ins.
check_sudo_grant() {
  # The drop-in exists only when install_sudoers wrote it during this run.
  if [ ! -f "$sudoers_file" ] || [ -z "$systemctl_path" ]; then
    return 0
  fi

  if ! command -v sudo > /dev/null 2>&1; then
    echo "WARNING: sudo is not installed, so remote updates will fail. Install sudo." >&2
    return 0
  fi

  # Ask sudo as DBDOT_USER, in a new session without a TTY, as the updater
  # runs. Asking as root with "sudo -l -U" would apply root's Defaults, such as
  # requiretty, instead of DBDOT_USER's. Like the updater, pass a bare
  # systemctl with the service's PATH. sudo then looks it up in secure_path, or
  # in that PATH when secure_path isn't set, and must find the file named in
  # the drop-in.
  if command -v runuser > /dev/null 2>&1 && command -v setsid > /dev/null 2>&1; then
    grant_ok=true
    grant_err=""
    for action in start stop; do
      if ! action_err="$(LC_ALL=C setsid runuser -u "$DBDOT_USER" -- env PATH="$service_path" sudo -n -l systemctl "$action" dynatrace-bindplane-otel-collector.service 2>&1 > /dev/null)"; then
        grant_ok=false
        grant_err="${grant_err}${action_err}"
      fi
    done
  else
    echo "WARNING: runuser or setsid not found, so the sudoers drop-in could not be checked." >&2
    grant_ok=true
  fi
  if [ "$grant_ok" = "false" ]; then
    echo "WARNING: sudo does not allow ${DBDOT_USER} to run the commands in ${sudoers_file}, so remote updates will fail." >&2
    case "$grant_err" in
      *"must have a tty"*)
        echo "  sudo requires a TTY (requiretty) for ${DBDOT_USER}. A \"Defaults requiretty\" line that sudo reads after the drop-in overrides its \"!requiretty\"." >&2
        ;;
    esac
    if ! grep -Eq '^[[:space:]]*[@#]includedir[[:space:]]+/etc/sudoers\.d/?[[:space:]]*$' /etc/sudoers 2> /dev/null; then
      echo "  /etc/sudoers has no \"@includedir /etc/sudoers.d\" line, so sudo does not read the drop-in." >&2
    fi
    nsswitch_sudoers="$(grep -E '^[[:space:]]*sudoers:' /etc/nsswitch.conf 2> /dev/null | head -n 1)" || true
    if [ -n "$nsswitch_sudoers" ] && ! echo "$nsswitch_sudoers" | grep -qw files; then
      echo "  /etc/nsswitch.conf has \"${nsswitch_sudoers}\" without \"files\", so sudo does not read /etc/sudoers.d." >&2
    fi
    echo "  Run \"sudo -l -U ${DBDOT_USER}\" to see the rules sudo applies to ${DBDOT_USER}." >&2
  fi

  # With no_new_privs set, sudo can't gain root inside the service. systemd
  # sets it for NoNewPrivileges=yes and, for a non-root service, for each of
  # these other settings. systemctl show reports each setting as written, so
  # check them all. An unset list prints as empty or as "~" (an empty deny
  # list). Older systemd prints some lists as "[unprintable]", which can't be
  # checked.
  nnp_bool_props="NoNewPrivileges RestrictSUIDSGID PrivateDevices ProtectKernelTunables ProtectKernelModules ProtectKernelLogs ProtectClock MemoryDenyWriteExecute RestrictRealtime LockPersonality DynamicUser"
  nnp_list_props="SystemCallFilter SystemCallArchitectures RestrictAddressFamilies"
  set --
  for prop in $nnp_bool_props $nnp_list_props; do
    set -- "$@" -p "$prop"
  done
  if ! unit_props="$(systemctl show "$@" dynatrace-bindplane-otel-collector.service 2> /dev/null)"; then
    return 0
  fi

  nnp_set=""
  while IFS='=' read -r key value; do
    case " $nnp_list_props " in
      *" $key "*)
        case "$value" in
          ""|"~"|"[unprintable]") ;;
          *) nnp_set="${nnp_set} ${key}=" ;;
        esac
        ;;
      *)
        if [ "$value" = "yes" ]; then
          nnp_set="${nnp_set} ${key}=yes"
        fi
        ;;
    esac
  done << EOF
$unit_props
EOF
  if [ -n "$nnp_set" ]; then
    echo "WARNING: dynatrace-bindplane-otel-collector.service sets${nnp_set}, which turns on no_new_privs and stops sudo from working inside the service, so remote updates will fail. Remove these settings from the service's drop-ins." >&2
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
# preinstall.sh runs the same check, so keep the two the same. This script
# runs it too because dpkg can run it again, for example with
# "dpkg --configure", after the overrides changed.
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

# print_runtime_notes says which user the collector runs as when
# resolve_unprivileged chose it or ignored DBDOT_UNPRIVILEGED. It writes to
# stderr, which install_unix.sh shows.
print_runtime_notes() {
    if [ "$kept_root" = "true" ]; then
        echo "NOTE: The collector keeps running as root, because this install already ran it as root. New installs run it as ${DBDOT_USER}. To run it as ${DBDOT_USER}, see https://github.com/dynatrace/dynatrace-bindplane-otel-collector/blob/main/docs/installation-linux.md#changing-the-runtime-user." >&2
    fi
    if [ -n "$ignored_value" ]; then
        if [ "$installed_runtime" = "sysv" ]; then
            echo "WARNING: DBDOT_UNPRIVILEGED is \"${ignored_value}\", but running the collector as another user requires systemd. The collector runs as root." >&2
        else
            echo "WARNING: DBDOT_UNPRIVILEGED is \"${ignored_value}\", not true or false. The collector runs as root." >&2
        fi
    fi
}

# dpkg runs the installed package's postinst with abort-upgrade, abort-remove
# or abort-deconfigure when the new package's preinst or the prerm failed,
# for example when check_runtime_user_change refused the upgrade. The
# installed files are untouched and the stage directory is gone, so there is
# nothing to do, and failing here would leave the package half-installed.
# rpm passes a number instead.
case "$1" in
    abort-*)
        exit 0
        ;;
esac

resolve_unprivileged
check_runtime_user_change "$@"
check_leftover_files
print_runtime_notes
install
install_service
finish_permissions
if [ "${DBDOT_UNPRIVILEGED}" = "true" ]; then
  install_sudoers
else
  remove_sudoers
fi
manage_service
if [ "${DBDOT_UNPRIVILEGED}" = "true" ]; then
  check_sudo_grant
fi
