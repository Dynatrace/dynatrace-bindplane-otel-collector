# Linux Installation

## Installing

Installation is done through deb and rpm packages. Installing the agent will also install the `dynatrace-bindplane-otel-collector` service on systemd systems.

Installation artifacts are signed. Information on verifying the signature can be found at [Verifying Artifact Signatures](./verify-signature.md).

### Install/Update script
The agent may be installed through a shell script which will automatically determine which package to install.

This script may also be used to update an existing installation.

To install using the installation script, you may run:
```sh
sudo sh -c "$(curl -fsSlL https://github.com/dynatrace/dynatrace-bindplane-otel-collector/releases/latest/download/install_unix.sh)" install_unix.sh
```

#### Managed Mode

To install the agent with an OpAMP connection configuration set the following flags. 

```sh
sudo sh -c "$(curl -fsSlL https://github.com/dynatrace/dynatrace-bindplane-otel-collector/releases/latest/download/install_unix.sh)" install_unix.sh -e <your_endpoint> -s <secret-key>
```

To read more about the generated connection configuration file see [OpAMP docs](./opamp.md).

### Installation from local package

To install the agent from a local package use the `-f` with the path to the package.

```sh
sudo sh -c "$(curl -fsSlL https://github.com/dynatrace/dynatrace-bindplane-otel-collector/releases/latest/download/install_unix.sh)" install_unix.sh -f <path_to_package>
```

### RPM Installation
First download the RPM package for your architecture from the [releases page](https://github.com/dynatrace/dynatrace-bindplane-otel-collector/releases/latest).
Then you may install the package using `rpm`, see this example for installing the amd64 package:

**Note**: Replace `${VERSION}` with the version of the package you downloaded.

```sh
sudo rpm -U ./dynatrace-bindplane-otel-collector_v${VERSION}_linux_amd64.rpm
sudo systemctl enable --now dynatrace-bindplane-otel-collector
```

### DEB Installation
First download the DEB package for your architecture from the [releases page](https://github.com/dynatrace/dynatrace-bindplane-otel-collector/releases/latest).
Then you may install the package using `dpkg`, see this example for installing the amd64 package:

**Note**: Replace `${VERSION}` with the version of the package you downloaded.

```sh
sudo dpkg -i ./dynatrace-bindplane-otel-collector_v${VERSION}_linux_amd64.deb
sudo systemctl enable --now dynatrace-bindplane-otel-collector
```

## Configuring the Agent
After installing, systems with systemd installed will have the `dynatrace-bindplane-otel-collector` service up and running!

**Logging**

Logs from the agent will appear in `/opt/dynatrace-bindplane-otel-collector/log`. You may run `sudo tail -F /opt/dynatrace-bindplane-otel-collector/log/collector.log` to view them.

Stdout and stderr for the agent process are recorded via journald. You man run `sudo journalctl -u dynatrace-bindplane-otel-collector.service` to view them.

**Configuration**

The config file for the agent can be found at `/opt/dynatrace-bindplane-otel-collector/config.yaml`. When changing the configuration,the agent service must be restarted in order for config changes to take effect.

For more information on configuring the agent, see the [OpenTelemetry docs](https://opentelemetry.io/docs/collector/configuration/).

**Permissions**

A new install runs the `dynatrace-bindplane-otel-collector` service as the unprivileged `dbdot` user. An install that ran the collector as root, which every version up to v1.3.1 did by default, keeps running it as root when you upgrade it. The package prints a note when it does.

Some OpenTelemetry components need more access than the `dbdot` user has, for example to read log files owned by other users, to read the systemd journal, to collect per process metrics, or to listen on a port below 1024. You can either:

- Grant the access in a systemd drop-in of your own, in its own file in `/etc/systemd/system/dynatrace-bindplane-otel-collector.service.d/`. For example, `SupplementaryGroups=adm systemd-journal` lets the collector read most files in `/var/log` and the journal, and `AmbientCapabilities=CAP_NET_BIND_SERVICE` lets it listen on ports below 1024. Don't add `NoNewPrivileges=yes`, `CapabilityBoundingSet=` or other settings that turn on `no_new_privs`; they break remote updates, see [Remote updates as a non-root user](#remote-updates-as-a-non-root-user).
- Run the collector as root: set `DBDOT_UNPRIVILEGED=false` in the package override file before you install the package. See [Package configuration](#package-configuration).

Membership in the `docker` group is equivalent to root. Don't add the `dbdot` user to it; run the collector as root instead if it must read the Docker socket.

Files you add to `/opt/dynatrace-bindplane-otel-collector`, such as credentials, must be readable by the `dbdot` user. Write them as that user, so that root never writes into the directory the `dbdot` user owns:

```sh
sudo cat sa.json | sudo runuser -u dbdot -- sh -c 'umask 077 && cat > /opt/dynatrace-bindplane-otel-collector/sa.json'
```

## Package configuration

The deb and rpm packages read optional settings from a package override file:
`/etc/default/dynatrace-bindplane-otel-collector` on deb systems, or
`/etc/sysconfig/dynatrace-bindplane-otel-collector` on rpm systems. The package
scripts and the install script read both files, `/etc/sysconfig` last, so it
wins. Create the file before you install the package for the first time.

| Variable | Default | Description |
|---|---|---|
| `DBDOT_CONFIG_HOME` | `/opt/dynatrace-bindplane-otel-collector` | The install directory. |
| `DBDOT_USER` | `dbdot` | The user that owns the install directory. When `DBDOT_UNPRIVILEGED` is `true`, the collector runs as this user. |
| `DBDOT_GROUP` | `dbdot` | The group of `DBDOT_USER`. The collector service always runs with this group. |
| `DBDOT_UNPRIVILEGED` | unset | When `true`, the collector runs as `DBDOT_USER`. When `false`, it runs as root. When unset, a new install runs the collector as `DBDOT_USER`, and an existing install keeps running it as the user it ran as. Requires systemd: without it, the collector always runs as root. |
| `DBDOT_SKIP_RUNTIME_USER_CREATION` | `false` | When `true`, the package does not create `DBDOT_USER` and `DBDOT_GROUP`, and the install fails if the user does not exist. |

For example, to run the collector as root on a deb system:

```sh
echo 'DBDOT_UNPRIVILEGED=false' | sudo tee /etc/default/dynatrace-bindplane-otel-collector
```

### Changing the runtime user

An existing install that runs the collector as `DBDOT_USER` can't be changed
to run it as root or as another user, and an existing install that runs the
collector as root can't be made unprivileged. When the runtime user owns the
install directory, it can replace any file in it with a symbolic link, which a
later install as another user would follow, and a collector that starts as the
runtime user can't use the files that root created. The package refuses such an
install or upgrade before it changes anything, and prints the values to restore.

An existing install that ran the collector as root keeps running it as root
when `DBDOT_UNPRIVILEGED` is unset. To run it as the `dbdot` user instead:

1. Uninstall the package.
2. Back up the files you want to keep, such as `manager.yaml`, and remove
   `/opt/dynatrace-bindplane-otel-collector`. A new unprivileged install
   refuses to install over files that root owns, which a root install leaves
   behind.
3. Change the values in the package override file, or remove them to use the
   defaults.
4. Install the package again.
5. Restore your files as the runtime user, for example:

   ```sh
   sudo cat manager.yaml.bak | sudo runuser -u dbdot -- sh -c 'umask 027 && cat > /opt/dynatrace-bindplane-otel-collector/manager.yaml'
   ```

The package also refuses an install when the service has no `User=` drop-in
from the package but doesn't run as root: when a unit file or drop-in of your
own sets `User=`, for example one written with `systemctl edit`, or when the
files in `/opt/dynatrace-bindplane-otel-collector` show that it was installed
to run as another user, for example after `systemctl revert`. Restore the
package's drop-in and remove the other `User=` settings, or follow the steps
above.

### Downgrades

Don't downgrade an install that runs the collector as `dbdot` to v1.3.1 or
older with `apt`, `dnf`, `zypper` or `rpm`. Those versions' package scripts
run as root over the files that the `dbdot` user owns. Uninstall the package,
remove `/opt/dynatrace-bindplane-otel-collector`, and install the older version
instead. For the same reason, remote updates from Bindplane can't roll an
install that runs as `dbdot` back to v1.3.1 or older.

### Remote updates as a non-root user

When `DBDOT_UNPRIVILEGED` is `true`, the collector's updater runs as
`DBDOT_USER`. It needs root only to stop and start the collector service while
it replaces the collector's files. The package installs a sudoers drop-in at
`/etc/sudoers.d/dynatrace-bindplane-otel-collector` that lets `DBDOT_USER` run
exactly these two commands, and nothing else:

```
systemctl start dynatrace-bindplane-otel-collector.service
systemctl stop dynatrace-bindplane-otel-collector.service
```

The updater never changes the systemd unit file when it runs as a non-root
user. Package installs and upgrades still update it.

An install of v1.3.1 or older that set `DBDOT_UNPRIVILEGED=true` has no
sudoers drop-in. Upgrade it once with the package manager or the install
script; a remote update to this version fails until then.

Remote updates as a non-root user require:

- `sudo`, including `visudo`. If it is missing when the package is installed,
  the package prints a warning and remote updates fail. Install `sudo`, then
  install or upgrade the package again.
- `/etc/sudoers` must read `/etc/sudoers.d` (the `@includedir /etc/sudoers.d`
  line, present by default on most distributions).
- No `NoNewPrivileges=yes`, or other systemd settings that turn on
  `no_new_privs` for a non-root service (such as `RestrictSUIDSGID=yes`,
  `ProtectKernelTunables=yes` or `SystemCallFilter=`), in drop-ins for the
  collector service. They stop `sudo` from working inside the service.

Don't run `systemctl revert dynatrace-bindplane-otel-collector`. It removes the
package's `User=` drop-in along with your own, and the collector then starts as
root. To undo your own changes, remove only your drop-in file.

## Restarting the Agent
On systemd systems, the agent may be restarted with the following command:
```sh
systemctl restart dynatrace-bindplane-otel-collector
```

## Stopping the Agent
On systemd systems, the agent may be stopped with the following command:
```sh
systemctl stop dynatrace-bindplane-otel-collector
```

## Starting the Agent
On systemd systems, the agent may be started with the following command:
```sh
systemctl start dynatrace-bindplane-otel-collector
```

## Uninstalling

Uninstalling the package removes the collector's files, the systemd unit and
the `/etc/systemd/system/dynatrace-bindplane-otel-collector.service.d`
directory, including drop-ins you added. It keeps `config.yaml`,
`logging.yaml`, `manager.yaml`, `storage/` and the package override file.

### RPM Uninstall

To uninstall the rpm package, run:
```sh
sudo rpm -e dynatrace-bindplane-otel-collector
```

### DEB Uninstall

To uninstall the deb package, run:
```sh
sudo dpkg -r dynatrace-bindplane-otel-collector
```

### Uninstall script

To uninstall an installation made with the install script, run:
```sh
sudo sh -c "$(curl -fsSlL https://github.com/dynatrace/dynatrace-bindplane-otel-collector/releases/latest/download/install_unix.sh)" install_unix.sh -r
```
