# DBDOT slim manifest

`manifest.yaml` drives the slim build of the Dynatrace Bindplane Distribution of OpenTelemetry Collector. The fully-featured build in [`../dynatrace-bindplane-otel-collector/`](../dynatrace-bindplane-otel-collector/README.md) stays the default.

## Components

The slim build contains:

- the components of the Dynatrace OpenTelemetry Collector distribution (`dynatrace-otel-collector`)
- the minimum set of components needed to be compatible with Bindplane
- the `dtedgeprocessingexporter` (component type `dynatrace`) for the Operator ingest path.

All component versions are the ones used by the full manifest. The slim manifest only has its own `dist` section, a smaller component list, the local `replaces` for the internal modules (`opampconnectionextension`, `snapshotprocessor`, `report`), and the same temporary `replaces` pin for the `dtedgeprocessingexporter` as the full manifest.

## Identity

The slim build reports its own OpAMP agent name and `service.name`, `com.dynatrace.bindplane.otel.collector-slim`, set by the root `Makefile` for `DISTRO=slim`.

## Building

From the repo root:

```
make agent DISTRO=slim
make verify-manifest DISTRO=slim
```

The binary is `./dist/collector-slim_<os>_<arch>`. ocb writes its sources to `./build-slim/` (gitignored); `make agent-clean DISTRO=slim` removes it. See [Choosing a distro](../dynatrace-bindplane-otel-collector/README.md#choosing-a-distro) for how `DISTRO` works.

The slim build pulls the `dtedgeprocessingexporter` from the private `dt-otelcol-edge-processing-components` module. Building it needs `GOPRIVATE=github.com/Dynatrace/*` (the Makefile exports it) and git credentials with read access to the Dynatrace GitHub org.

## Feature gates

The collector enables a hardcoded set of feature gates at startup. Gates that belong to components the slim build leaves out are listed in `extension/opampconnectionextension/internal/collector/featuregates_slimlist.go` and skipped; `make DISTRO=slim` selects that list with the `dbdot_slim` build tag. `make check-slim-feature-gates` checks the list against the slim components. Run it after adding or removing components here.

## Editing the manifest

`make update-otel`, `make update-contrib` and `make update-modules` bump the components of this manifest together with the full one. Components that exist only in the full build are not touched here. When you add or change a component by hand in the full manifest, make the same change here.
