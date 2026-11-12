# Host Metrics with Google Cloud

The Host Metrics Receiver can be used to send system metrics from an agent host to Google Cloud Monitoring.

## Prerequisites

See the [prerequisites](../README.md) doc for Google Cloud prerequisites.

## Configuration

An example configuration is located [here](./config.yaml).

1. Copy [config.yaml](./config.yaml) to `/opt/dynatrace-bindplane-otel-collector/config.yaml`
2. Restart the agent: `sudo systemctl restart dynatrace-bindplane-otel-collector`

## Setup

Host Metrics does not have setup requirements.

## Process metrics

The host metrics receiver supports per process cpu, memory, disk, and network metrics. This feature requires elevated privileges. On Linux, a new install runs the agent as the unprivileged `dbdot` user. To run it as root, set `DBDOT_UNPRIVILEGED=false` before you install the package. See the [package configuration documentation](https://github.com/dynatrace/dynatrace-bindplane-otel-collector/blob/main/docs/installation-linux.md#package-configuration) for instructions.
