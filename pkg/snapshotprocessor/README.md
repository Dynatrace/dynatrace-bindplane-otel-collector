# Snapshot Processor

Supported pipelines: logs, metrics, traces

This processor saves OTLP payloads into snapshots that can be reported to [Bindplane](https://bindplane.com/).

Use the [snapshotprocessor from bindplane-otel-contrib](https://github.com/observIQ/bindplane-otel-contrib/tree/main/processor/snapshotprocessor) unless your Bindplane server predates snapshot custom messages. This copy exists only for that case.

## Why this exists

Two snapshot transports exist:

- **OpAMP custom messages.** The processor registers the snapshot capability on the named `opamp_connection` extension and answers snapshot requests over the existing OpAMP connection. This is all the contrib processor does.
- **Report manager.** The server pushes a `snapshotConfig` via the `report.yaml` managed config and the collector POSTs the payload out of band through [`pkg/report`](../report). Older Bindplane servers support only this.

This processor always serves the report-manager path, and additionally serves custom messages when `opamp` is set. It differs from the contrib processor only by that legacy path. A distro managed by a server that still needs it must ship this processor and `pkg/report`; every other distro should take the contrib one.

There is no removal date. It stays until every Bindplane server this distro is managed by supports snapshot custom messages.

## Removal

1. In the manifest, replace this module's `gomod` entry with `github.com/observiq/bindplane-otel-contrib/processor/snapshotprocessor` and delete the local `replace` for it.
2. Set `opamp: <opamp_connection extension id>` on every `snapshot` processor in shipped configs; the contrib processor requires it.
3. Delete this module and its `directory:` entry in `.github/dependabot.yml`.
4. Follow the "Removal" section in [`pkg/report`](../report/README.md).

## Configuration

The following options may be configured:
- `enabled` (default: true): When `true` signals that snapshots are being taken of data passing through this processor. If false this processor acts as a no-op.
- `opamp` (optional): Component ID of the `opamp_connection` extension. When set, the processor also registers the snapshot custom capability and answers snapshot requests over OpAMP custom messages.

### Example configuration

```yaml
processors:
  snapshot:
    enabled: true
```

