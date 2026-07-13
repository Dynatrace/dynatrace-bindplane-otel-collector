# Snapshot Processor

Supported pipelines: logs, metrics, traces

This processor saves OTLP payloads into snapshots that can be reported to [Bindplane](https://bindplane.com/).

This processor is internal to the DBDOT Collector. To add snapshot support to a different agent built with OpenTelemetry Collector Builder, use the [snapshotprocessor from bindplane-otel-contrib](https://github.com/observIQ/bindplane-otel-contrib/tree/main/processor/snapshotprocessor) instead.

## Configuration

The following options may be configured:
- `enabled` (default: true): When `true` signals that snapshots are being taken of data passing through this processor. If false this processor acts as a no-op.

### Example configuration

```yaml
processors:
  snapshot:
    enabled: true
```

