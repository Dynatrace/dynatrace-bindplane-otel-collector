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

By default, the `dynatrace-bindplane-otel-collector` service runs as the "root" user. Some OpenTelemetry components require root permissions in order to read log files owned by other users.

It may be desirable to run the agent as an unprivileged user. For example, a metrics only agent does not require root access.

To run the agent as the `dbdot` user, set `DBDOT_UNPRIVILEGED=true` in the package override file before you install the package. See [Package configuration](#package-configuration).

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
| `DBDOT_UNPRIVILEGED` | `false` | When `true`, the collector runs as `DBDOT_USER` instead of root. Requires systemd. |
| `DBDOT_SKIP_RUNTIME_USER_CREATION` | `false` | When `true`, the package does not create `DBDOT_USER` and `DBDOT_GROUP`, and the install fails if the user does not exist. |

For example, to run the collector as the `dbdot` user on a deb system:

```sh
echo 'DBDOT_UNPRIVILEGED=true' | sudo tee /etc/default/dynatrace-bindplane-otel-collector
```

### Changing the runtime user

An existing install that runs the collector as `DBDOT_USER` can't be changed
to run it as root or as another user, and an existing install that runs the
collector as root can't be made unprivileged. When the runtime user owns the
install directory, it can replace any file in it with a symbolic link, which a
later install as another user would follow, and a collector that starts as the
runtime user can't use the files that root created. The package refuses such an
install or upgrade before it changes anything, and prints the values to restore.

To change them:

1. Uninstall the package.
2. Back up the files you want to keep, such as `manager.yaml`, and remove
   `/opt/dynatrace-bindplane-otel-collector`.
3. Change the values in the package override file.
4. Install the package again.

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
