# opamp_connection extension and managed-mode runtime

This module is the Bindplane managed-mode runtime for an OpenTelemetry
Collector distribution: the OpAMP client that talks to Bindplane, collector
lifecycle and config rollback, the package-update handshake with the updater,
throughput and topology reporting, and the `opamp_connection` extension that
lets other components send and receive OpAMP custom messages over that
connection. Entry point: `runtime.Run(Options)`.

It is published from this repo so that other distros can consume it from
their ocb manifest. Module path:

```
github.com/dynatrace/dynatrace-bindplane-otel-collector/extension/opampconnectionextension
```

## Consumer contract

What another distro does to run under Bindplane management with this module.

1. **Manifest.** Add the module to `extensions:` at a released tag, with no
   `replace`; tags resolve it. For snapshots use the contrib
   `snapshotprocessor` unless your Bindplane server needs the legacy
   `report.yaml` path (see below).
2. **`main.go` overlay.** ocb's generated `main.go` starts a plain collector.
   Copy [`cmd/main/main.go`](cmd/main/main.go) over it (and delete ocb's
   `main_others.go` / `main_windows.go`), or write an equivalent that builds
   `runtime.Options` from your flags and calls `runtime.Run`. This repo's
   `make agent` shows the sequence.
3. **Link-time identity.** Every distro-specific value is a package-level
   `var` with a generic placeholder default, stamped with `-X`. An unstamped
   build shows up in Bindplane as `otelcol`, which is deliberate: it is
   visibly unstamped rather than silently someone else's distro.

   | Variable | Package (relative to this module) | Default | Purpose |
   |---|---|---|---|
   | `buildName` | `internal/collector` | `otelcol` | `BuildInfo.Command`. **This is the agent type.** Bindplane classifies every connecting agent by this value (OpAMP `service.name`), so each distinct `buildName` is a distinct agent type on the server. Choose it deliberately and keep it distinct from the product slug. Reverse-DNS is the convention. |
   | `buildDescription` | `internal/collector` | `OpenTelemetry Collector` | `BuildInfo.Description`. |
   | `collectorPackageName` | `packagestate` | `otelcol` | Product slug. The key under which the collector's own package is tracked in `package_statuses.json` and offered in `PackagesAvailable`, and the User-Agent prefix. **Must be stamped identically into the updater binary**, or updates never complete. |
   | `stderrLogName` | `internal/service` | `otelcol.err` | File name for stderr capture: `/var/log/<name>` under launchd on macOS, `$BINDPLANE_COLLECTOR_HOME/log/<name>` on Windows. Must match what your installer and support-bundle scripts reference. |

   Version is not a `-X` var here. It arrives through `runtime.Options.Version`
   from your `main.go`, however you stamp it, and feeds `BuildInfo.Version`,
   the `service.version` identity attribute, the `Agent-Version` header, and
   the package-status handshake.

   This repo's `Makefile` (`AGENT_LDFLAGS`, `UPDATER_LDFLAGS`, `PRODUCT_NAME`)
   is the reference for stamping all four.
4. **Updater.** Ship your own updater build. The updater is per-distro
   (install paths, service names). It imports only `packagestate` from this
   module, and the only contract between the two binaries is
   `collectorPackageName`.
5. **Throughput and topology.** The runtime reports to Bindplane from the
   registries in contrib's `throughputmeasurementprocessor` and
   `topologyprocessor`, but only when your factories include those processor
   types (`throughputmeasurement`, `topology`). Omit them and the matching
   sender is not created and its capability is not advertised.
6. **Environment.** Your installer sets `BINDPLANE_COLLECTOR_HOME` and
   `BINDPLANE_COLLECTOR_STORAGE`. The runtime mirrors them to the legacy
   `OIQ_OTEL_COLLECTOR_HOME` / `OIQ_OTEL_COLLECTOR_STORAGE` names and back.
   Configurations rendered by Bindplane reference both spellings, so this is
   part of the Bindplane server contract and applies to every distro; it is
   not configurable and not tied to distro identity.

## Extension configuration

The `opamp_connection` extension takes no configuration. Components that want
to exchange OpAMP custom messages reference it by ID (for example the
`opamp:` field of the snapshot processor).

```yaml
extensions:
  opamp_connection:
service:
  extensions: [opamp_connection]
```

## Legacy snapshot path

`NewClient`, `addManagedConfigs`, and `reportReload` carry the wiring for the
legacy `report.yaml` snapshot path through [`pkg/report`](../../pkg/report),
for consuming distros whose Bindplane servers predate snapshot custom
messages. That module's README owns the deprecation of this path, including
the steps to remove the wiring here.
