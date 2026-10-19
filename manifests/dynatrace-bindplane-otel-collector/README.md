# DBDOT manifests

Three manifests live here, all driving ocb builds:

| File | Build target | Output binary | Shape |
|---|---|---|---|
| `manifest.yaml` | `make agent` | `dist/collector_<os>_<arch>` | v1 — in-process managed runtime. `buildscripts/main.go` is overlaid onto ocb's generated `main.go`; the binary owns the OpAMP client and restarts the collector on remote config push. |

The slim build has its own manifest in [`../dynatrace-bindplane-otel-collector-slim/`](../dynatrace-bindplane-otel-collector-slim/README.md). Select it with `DISTRO=slim` (see [Choosing a distro](#choosing-a-distro)).

## Installing ocb

```
make install-ocb
```

The ocb version is pinned via `OCB_VERSION` in the root Makefile and matches the OTel core version pinned in all three manifests.

## Building

From the repo root:

```
make agent          # v1
```

`make agent` runs `builder --skip-compilation` against `manifest.yaml`, overwrites the generated `build/main.go` with `extension/opampconnectionextension/cmd/main/main.go` (so the managed/standalone runtime is wired in), then `go build`s into `./dist/`. `./build/` is gitignored ocb output; the final binary is `./dist/collector_<os>_<arch>`.

`make verify-manifest` regenerates sources from `manifest.yaml` and compiles to `/dev/null` — the CI gate.

`make agent-clean` wipes the ocb output of the selected `DISTRO` (`./build/` for `full`, `./build-slim/` for `slim`) and `./builder/`. Run it once per distro to clean both.

### Choosing a distro

The Makefile builds one distro at a time, selected with `DISTRO`. It defaults to `full`, so the commands above build this manifest unless told otherwise.

| `DISTRO` | Manifest | ocb output | Output binary | OpAMP agent name (`service.name`) |
|---|---|---|---|---|
| `full` (default) | `manifests/dynatrace-bindplane-otel-collector/manifest.yaml` | `./build/` | `dist/collector_<os>_<arch>` | `com.dynatrace.bindplane.otel.collector` |
| `slim` | `manifests/dynatrace-bindplane-otel-collector-slim/manifest.yaml` | `./build-slim/` | `dist/collector-slim_<os>_<arch>` | `com.dynatrace.bindplane.otel.collector.slim` |

```
make agent DISTRO=slim
make verify-manifest DISTRO=slim
```

An unknown `DISTRO` fails with an error. The per-distro settings live at the top of the root `Makefile`.

## Editing a manifest

- **Add a component**: append a `gomod:` entry under the right section. Format: `<module path> <version>`.
- **Bump a dependency**: change the version in `gomod:`. Re-run the build. Commit the manifest change; ocb output dirs are gitignored.
- **Pin a transitive dep or redirect a fork**: add to `replaces:`. These apply to release builds too.

## v1 manifest internals

These Go modules live in this repo:

- `extension/opampconnectionextension` — bindplane's OpAMP connection extension and the full v1 managed-mode runtime cluster (collector lifecycle, OpAMP client, package state, report manager, measurements, service dispatch).
- `pkg/report` — report manager for the legacy `report.yaml` snapshot path; used by the extension and by consuming distros that still carry a report-manager snapshot processor. Not a component.

The v1 manifest references each by its own `gomod:` entry and a narrow local `replace:` pointing at the on-disk path. Other distros consume them by tag.

See [`docs/specs/ocb-canonical-build.md`](../../docs/specs/ocb-canonical-build.md) for the broader design context.
