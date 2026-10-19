# DBDOT slim manifest

`manifest.yaml` drives the slim build of the Dynatrace Bindplane Distribution of OpenTelemetry Collector. The fully-featured build in [`../dynatrace-bindplane-otel-collector/`](../dynatrace-bindplane-otel-collector/README.md) stays the default.

## Components

The slim build contains:

- the components of the Dynatrace OpenTelemetry Collector distribution (`dynatrace-otel-collector`)
- the minimum set of components needed to be compatible with Bindplane.

All component versions are the ones used by the full manifest. The slim manifest only has its own `dist` section, a smaller component list, and the local `replaces` for the internal modules (`opampconnectionextension`, `snapshotprocessor`, `report`).

## Identity

The slim build reports its own OpAMP agent name and `service.name`, `com.dynatrace.bindplane.otel.collector.slim`, set by the root `Makefile` for `DISTRO=slim`.

## Building

From the repo root:

```
make agent DISTRO=slim
make verify-manifest DISTRO=slim
```

The binary is `./dist/collector-slim_<os>_<arch>`. ocb writes its sources to `./build-slim/` (gitignored); `make agent-clean` removes it. See [Choosing a distro](../dynatrace-bindplane-otel-collector/README.md#choosing-a-distro) for how `DISTRO` works.

The slim build does not depend on the private `dt-otelcol-edge-processing-components` module, so it builds without `GOPRIVATE` or Dynatrace org git credentials.

## Editing the manifest

Component versions are not bumped automatically. When the OTel version or a Bindplane contrib version changes in the full manifest, update the same entries here.
