# Journald Logging with Google Cloud

The Journald receiver can be used to send [Journald](https://wiki.archlinux.org/title/Systemd/Journal) logs to Google Cloud Logging.

## Limitations

The agent must be installed on the Journald system. The system must use Systemd as the init system, as Journald is the central logging solution for Systemd equipped systems. You can validate by running the `journalctl` command.

A new install runs the agent as the unprivileged `dbdot` user, which can't read the system journal. Add it to the `systemd-journal` group with a systemd drop-in, see [Permissions](https://github.com/dynatrace/dynatrace-bindplane-otel-collector/blob/main/docs/installation-linux.md#configuring-the-agent).

## Prerequisites

See the [prerequisites](../README.md) doc for Google Cloud prerequisites.
