# opamp_connection Extension — portability to other distros

Status: implemented on branch `opamp-connection` (2026-09-16), pending review and the first tagged release. Decisions recorded 2026-09-09; revised 2026-09-16 against fork tip 289e37b4 (v0.9.1, after #29 renamed the binary, packages, install paths, and agent type to `dynatrace-bindplane-otel-collector` / `com.dynatrace.bindplane.otel.collector`). Deviations from the original proposal are marked **Implemented as:**.

This describes what it takes for another OpenTelemetry Collector distribution to consume the managed-mode runtime from this repo's ocb manifest, using the same `main.go` overlay this repo uses (see `ocb-canonical-build.md`). It records the blockers, the coupling to loosen, the pieces that stay as-is, and the sequence.

## Decisions

1. **The reusable modules live in this repo**, at non-`internal` paths, and are consumed from `github.com/dynatrace/dynatrace-bindplane-otel-collector` via per-module tags. No new repo. The fork's copy is accepted as diverging from `observiq/bindplane-otel-collector`.
2. **Three modules move together:** `opampconnectionextension`, `report`, and `snapshotprocessor`. A consuming distro managed by the same Bindplane servers needs all three.
3. **The legacy report-manager snapshot path stays** (`report.yaml` managed config + out-of-band HTTP POST) for backwards compatibility with older Bindplane servers. No removal date. Every component that exists only for this path must say so in its README, with the concrete removal recipe.
4. **Layout:** the extension goes to `extension/`; `report` and `snapshotprocessor` go under `pkg/` so they are out of the way of the component directories and users do not reach for them by accident. (`pkg/` does not hide anything from the Go toolchain; what keeps users off them is the README wording and not listing them in consumer docs.)
5. **Distro-specific values are link-time variables** (`-X`), following the #28 pattern: generic `otelcol` defaults in code, DBDOT values stamped by this repo's Makefile. An unstamped build is visibly unstamped rather than silently a DBDOT build. Consumers stamp their own values.
6. **`OIQ_*` / `BINDPLANE_*` environment handling is Bindplane-server contract**, not distro identity. It applies to every distro managed by Bindplane and is not configurable.

## Summary

The extension proper — `factory.go`, `extension.go`, `registry.go`, the exported `Client` interface — is already distro-neutral. The fork has also already done part of the identity work that upstream has not: build name and description are ldflags-stamped, and the OpAMP `service.name` derives from `BuildInfo.Command` (#28).

What blocks consumption is one mechanical fact: the module paths contain `internal/`. Beyond that there is a short list of remaining hardcoded identity strings, two hard-wired Bindplane component registries, and a release-tagging lapse. All contained; roughly a week including CI churn.

## Blocker: module paths contain `internal/`

Modules today:

```
github.com/dynatrace/dynatrace-bindplane-otel-collector/internal/extension/opampconnectionextension
github.com/dynatrace/dynatrace-bindplane-otel-collector/internal/report
github.com/dynatrace/dynatrace-bindplane-otel-collector/internal/processor/snapshotprocessor
```

Go enforces the `internal` import rule by import path across module boundaries. It works in-repo only because ocb's generated module is `github.com/dynatrace/dynatrace-bindplane-otel-collector/build`, under the same root. Verified against the upstream copy with a throwaway module named `github.com/otherdistro/build` and a `replace` to the local checkout:

```
main.go:3:8: use of internal package .../internal/extension/opampconnectionextension/runtime not allowed
```

### Target paths

| Today | Proposed | Module path |
|---|---|---|
| `internal/extension/opampconnectionextension` | `extension/opampconnectionextension` | `.../extension/opampconnectionextension` |
| `internal/report` | `pkg/report` | `.../pkg/report` |
| `internal/processor/snapshotprocessor` | `pkg/snapshotprocessor` | `.../pkg/snapshotprocessor` |

Per-module tags follow the directory: `extension/opampconnectionextension/v0.10.0`, `pkg/report/v0.10.0`. `ALL_MODULES` in the Makefile is `find`-based, so `make tidy`, `make release`, and the lint/test loops pick the new paths up without edits.

`extension/` is the one consumers are pointed at. `pkg/` holds the two modules that exist for the legacy snapshot path; their READMEs steer users to the contrib `snapshotprocessor` unless their Bindplane server requires the legacy transport.

This contradicts the current AGENTS.md line "There are no in-tree component directories; new components belong in bindplane-otel-contrib." That rule stays true for general-purpose components. Rewrite it to carve out `extension/` and `pkg/` as the Bindplane-managed-mode runtime that is deliberately published from here.

### Touch points for the move

- `manifests/dynatrace-bindplane-otel-collector/manifest.yaml`: three `gomod` entries and the three `replaces`. The replaces stay (local-checkout builds) but point at the new relative paths.
- `Makefile`: `OPAMP_EXT_COLLECTOR_PKG` (ldflags target) and `AGENT_MAIN`.
- `.github/`: 22 `go-version-file:` and path-filter references across 10 workflows, plus 3 `directory:` entries in `dependabot.yml`.
- `updater/go.mod`: `require` + `replace` for the extension module (it imports `packagestate`), and the transitive `report` replace.
- `pkg/snapshotprocessor/go.mod`: `require` + `replace` for `report`. Also has a dangling `replace` for the extension module with no matching `require`; delete it.
- `AGENTS.md`, `docs/specs/ocb-canonical-build.md`: 5 path references each, plus the rule text above.
- Import paths inside the three modules and their tests.

## Release tagging

`make release` tags every module in `ALL_MODULES` as `<dir>/<version>`, and `docs/releasing.md` names it as step 1. Fork releases `v0.0.1` through `v0.0.6` have per-module tags. `v0.9.0` (2026-08-28) and `v0.9.1` (2026-09) have only the root tag. (`v0.0.7` through `v0.6.0` are inherited observiq tags from 2021–2022, not fork releases.) `snapshotprocessor` requires `internal/report` at the current release version, which resolves solely through the local replace.

`v0.9.0` was tagged and pushed by hand because `make release` was failing, and `v0.9.1` followed the same path. Likely cause: the target runs `git push --tags`, which pushes every local tag. A checkout of this fork carries ~6,200 tags inherited from observiq upstream; the Dynatrace remote has 44. Pushing all of them is slow at best and rejected at worst, and would pollute the remote with upstream `v1.x` / `v2.x` tags that collide with this repo's own version line (the Makefile's `PREVIOUS_TAG` derivation would then pick them up).

Fix in `make release`: push only the tags the target creates. Replace both `git push --tags` with `git push origin $(version)` and, after the loop, `git push origin <dir>/$(version) ...` for each module. Also replace the `[[ =~ ]]` and `[ == ]` bash-isms in the target with POSIX equivalents so it works under dash as well as macOS `/bin/sh`. Add a release-workflow step that fails if `git tag -l '<dir>/<version>'` is empty for any module.

An external consumer resolves only through tags, so this lands before the first consumable release.

Correction to an earlier draft of this document: upstream `observiq/bindplane-otel-collector` does tag these modules through `v1.107.0`. The gap is fork-specific.

## Remaining identity coupling

What #28 already fixed: `BuildInfo.Command` / `Description` via ldflags; `service.name` from `BuildInfo.Command`; `NewClientArgs.BuildInfo` replaces a bare version string.

The distro has two identity values, and they are not the same string:

- **Agent type** — reverse-DNS, `com.dynatrace.bindplane.otel.collector`. Reported to Bindplane as OpAMP `service.name`. Already an `-X` var (`buildName`) stamped from `AGENT_NAME` in the Makefile.
- **Product slug** — `dynatrace-bindplane-otel-collector`. Names the binary, packages, install paths, the OpAMP package key, the User-Agent, and (underscored) the stderr log file. Hardcoded in several places.

#29 renamed both. Its PR description says the agent type was unchanged; a later commit in the same PR ("rename agent type") changed it from `com.dynatrace.dbdot.collector` to `com.dynatrace.bindplane.otel.collector`. Anything that tracks agent types on the server side needs to know the current value is the latter.

What remains hardcoded, all in the extension module:

| Location | Value | Server-visible? | Becomes |
|---|---|---|---|
| `internal/opamp/bindplane/bindplane_client.go:259` | `User-Agent: dynatrace-bindplane-otel-collector/<v>` | Yes | Derived: `collectorPackageName + "/" + BuildInfo.Version` |
| `packagestate/packages_state_manager.go:29` | `CollectorPackageName = "dynatrace-bindplane-otel-collector"` | Yes — package-update contract | `-X` var `packagestate.collectorPackageName` |
| `internal/service/service_darwin.go:31` | `/var/log/dynatrace_bindplane_otel_collector.err` | No | `-X` var `service.stderrLogName` |
| `internal/service/service_windows.go:195` | `dynatrace_bindplane_otel_collector.err` | No | Same `-X` var |
| `cmd/main/main.go:62` | `dynatrace-bindplane-otel-collector version` banner | No | Belongs to the per-distro overlay; fine as-is |

The stderr filename is also hardcoded in `scripts/install/install_macos.sh` (uninstall cleanup) and the Windows support-bundle scripts. Those are this distro's installer files, not part of the published module, but a consumer's equivalents must agree with whatever it stamps into `stderrLogName`. Note it in the consumer contract.

### Link-time variables

Every distro-specific value is a package-level `var` stamped with `-X`. Defaults in code are generic placeholders so an unstamped build is obviously unstamped; this repo's Makefile stamps the DBDOT values. The full set after this work:

| Variable | Package | Code default | DBDOT (Makefile) | Purpose |
|---|---|---|---|---|
| `buildName` | `internal/collector` | `otelcol` | `com.dynatrace.bindplane.otel.collector` | `BuildInfo.Command`; **the agent type** reported to the Bindplane server as OpAMP `service.name` |
| `buildDescription` | `internal/collector` | `OpenTelemetry Collector` | `Dynatrace Bindplane Distribution of OpenTelemetry Collector` | `BuildInfo.Description` |
| `collectorPackageName` | `packagestate` | `otelcol` | `dynatrace-bindplane-otel-collector` | Product slug. Key in `package_statuses.json` and `PackagesAvailable` (must match the updater build); User-Agent prefix |
| `stderrLogName` | `internal/service` | `otelcol.err` | `dynatrace_bindplane_otel_collector.err` | Filename for launchd / Windows stderr capture; must match the distro's installer and support scripts |

The Makefile already has `AGENT_NAME` and `AGENT_DESCRIPTION`. Add `PRODUCT_NAME = dynatrace-bindplane-otel-collector` and derive the stderr filename from it in one place, so the slug is defined once and stamped into both binaries.

`buildName` is not cosmetic: it is the agent type. The Bindplane server classifies every connecting agent by `service.name`, so each distinct `buildName` is a distinct agent type from the server's point of view. Server-side recognition of that type is the server's concern and out of scope here, but the extension README must state this so a consumer knows what they are choosing when they set it.

`buildName` and `buildDescription` exist since #28; the two new vars follow the same pattern. Version is not a `-X` var here: it arrives through `runtime.Options.Version` from the consumer's `main.go`, which stamps it however it likes.

`packagestate` is imported by the updater, so `collectorPackageName` must be stamped into both `AGENT_LDFLAGS` and `UPDATER_LDFLAGS`. The Makefile should define it once and reference it from both.

### Version plumbing

**Implemented as:** `NewManagedCollectorService` takes the version (and factories) as parameters from `runtime.Run`; the client reads `c.ident.version`, which `newIdentity` already fills from `BuildInfo.Version`; the packages-state provider carries the version it was constructed with. `pkg/version` is imported only by the overlay `main.go`.

`runtime.Options.Version` feeds `BuildInfo.Version`, but the client still calls `version.Version()` from `bindplane-otel-contrib/pkg/version` directly at 11 sites (`bindplane_client.go`, `bindplane_packages_state_provider.go`) and `managed.go:74` builds `BuildInfo` from it rather than from `Options.Version`. A consumer that sets `Options.Version` without also stamping `-X github.com/observiq/bindplane-otel-contrib/pkg/version.version` reports one version to its own BuildInfo and another to the server and the package-status handshake.

Fix: `managed.go` takes the version from `Options`; the client reads `c.buildInfo.Version` everywhere it currently calls `version.Version()`. The `pkg/version` dependency then survives only in the overlay `main.go`, which is the consumer's own file.

### `OIQ_*` / `BINDPLANE_*` environment handling (server contract, not distro identity)

`runtime/run.go` mirrors `OIQ_OTEL_COLLECTOR_{HOME,STORAGE}` ⇄ `BINDPLANE_COLLECTOR_*`, and `managed.go` sets `OIQ_OTEL_COLLECTOR_HOME` from `BINDPLANE_COLLECTOR_HOME`. These names belong to the Bindplane server, not to any distro: configurations rendered by Bindplane reference `${OIQ_OTEL_COLLECTOR_HOME}` and `${BINDPLANE_COLLECTOR_HOME}`, so every collector managed by Bindplane must resolve them regardless of what the distro calls itself. They are not `-X` variables and not part of the identity table. A consuming distro's installer sets `BINDPLANE_COLLECTOR_HOME` (and `_STORAGE`) exactly as this repo's does; the runtime fills in the rest. Document this in the extension README under the consumer contract.

## Hard-wired Bindplane component registries

The runtime imports concrete singletons:

- `internal/collector/collector.go` `Stop()` resets `measurements.BindplaneAgentThroughputMeasurementsRegistry` and `topologyprocessor.BindplaneAgentTopologyRegistry`.
- `internal/service/managed.go` passes those registries as `MeasurementsReporter` / `TopologyReporter`.
- `bindplane_client.go` `hardcodedCustomCapabilities` always advertises `ReportMeasurementsV1Capability` and `ReportTopologyCapability`.

A consumer whose manifest includes `throughputmeasurementprocessor` and `topologyprocessor` is fine. One that omits them advertises capabilities it cannot serve and runs senders against empty registries.

Fix: make both reporters nil-able in `NewClientArgs`; derive `hardcodedCustomCapabilities` from which are set; move the `Reset()` calls from `collector.Stop()` to the client's disconnect / restart path where the reporters are known. This changes what the server sees advertised for a consumer that opts out; no change for this repo.

**Implemented as:** `managed.go` derives the reporters from `Options.Factories`: a reporter is wired only if the consumer's factory set contains the matching processor type (`throughputmeasurement`, `topology`). No new `Options` field; a consumer opts out by leaving the processor out of its manifest. `NewClient` creates a sender and advertises its capability only for a non-nil reporter; sender methods are nil-receiver safe so the reload and message paths need no guards. The `Reset()` calls stay in `collector.Stop()`: they are no-ops on empty registries, and moving them around `Restart()` (which is stop+start inside the collector) would race with fresh registrations on the next start. Nothing is gained by moving them.

## Legacy snapshot path (kept)

Two snapshot transports exist:

- **OpAMP custom messages** — the processor registers the snapshot capability on the named `opamp_connection` extension. This is all the contrib `snapshotprocessor` does, and it has no `report` dependency.
- **Report manager** — Bindplane pushes a `snapshotConfig` via the `report.yaml` managed config; `report.Manager` POSTs payloads to Bindplane out of band. Requires `report`, the `report.yaml` wiring in `bindplane_client.go:136,227`, `reportReload` in `reload_funcs.go`, and the internal `snapshotprocessor` (which always serves this path and adds custom messages only when `opamp` is set).

Older Bindplane servers support only the second. Until every targeted server supports the first, the internal processor and `report` must ship, and a consuming distro must use them rather than the contrib processor.

### README deliverables

Each of the following gets a section titled **"Why this exists"** and a section titled **"Removal"**. `report` and `opampconnectionextension` have no README today; write them.

- `pkg/report/README.md`: exists solely for the legacy snapshot path; not for direct use. Removal: delete the module; drop the `report` requires from the extension and processor modules.
- `pkg/snapshotprocessor/README.md` (extend the existing one): differs from contrib only by the report-manager path. Lead with "use the contrib `snapshotprocessor` unless your Bindplane server predates snapshot custom messages." Removal: swap the manifest entry to `github.com/observiq/bindplane-otel-contrib/processor/snapshotprocessor`, delete this module, set `opamp:` on every `snapshot` processor in shipped configs (the contrib processor requires it).
- `extension/opampconnectionextension/README.md`: consumer guide (below) plus the removal recipe for the report wiring: delete `reportManager` and `report.GetManager()` / `SetClient` in `NewClient`, delete the `report.yaml` `NewManagedConfig` and `reportReload`, drop the `report` require.

## Consumer contract

What another distro does once the above lands:

1. Manifest `extensions:` gets `github.com/dynatrace/dynatrace-bindplane-otel-collector/extension/opampconnectionextension vX`. If its Bindplane server needs the legacy snapshot path, `processors:` gets `.../pkg/snapshotprocessor vX`; otherwise the contrib `snapshotprocessor`. `pkg/report` arrives transitively either way.
2. Copy `extension/opampconnectionextension/cmd/main/main.go` over ocb's generated `main.go` (or write an equivalent that calls `runtime.Run`). Delete ocb's `main_others.go` / `main_windows.go`.
3. Stamp the four `-X` variables from the table above into the collector build, and `collectorPackageName` into its updater build. `buildName` is the agent type the Bindplane server sees; choose it deliberately, and keep it distinct from the product slug (`collectorPackageName`). `stderrLogName` must match the filename its installer and support scripts reference. Unstamped values are generic `otelcol` placeholders and will be visibly wrong in Bindplane. Version arrives via `runtime.Options.Version` however the consumer's `main.go` obtains it.
4. Ship its own updater build. The updater is per-distro (install paths, service names); see below.
5. Include `throughputmeasurementprocessor` and `topologyprocessor` from bindplane-otel-contrib, or rely on the optional-reporter change.
6. Its installer sets `BINDPLANE_COLLECTOR_HOME` / `BINDPLANE_COLLECTOR_STORAGE`. The runtime handles the `OIQ_*` mirroring.

## Updater impact

`updater` imports one package from the extension module: `packagestate`, for the `package_statuses.json` format and the collector package-name key (today the exported const `CollectorPackageName`; after this work the `-X` var `collectorPackageName` behind an accessor).

- Import path changes with the move. One go.mod edit.
- `collectorPackageName` is the key the collector writes `Installing` under and the updater reads back to decide whether an install is in flight and to report the outcome. Once it is a `-X` variable, the two binaries must be stamped with the same value or updates silently never complete. Stamping it in both `AGENT_LDFLAGS` and `UPDATER_LDFLAGS` from one Makefile variable is the whole fix; no updater logic changes. (Alternative if the shared-stamp contract proves fragile: have the updater act on whichever top-level entry is in `Installing` state instead of a named key.)
- Unchanged: the launch protocol (collector copies `tmp/latest/updater` and execs it), and the updater's own paths, service names, and `updater/internal/version` ldflags. This work does not make the updater reusable and should not try to.

## Dependency weight

The extension module's `go.mod` requires `spanmetricsconnector`, `prometheusremotewriteexporter`, `filelogreceiver`, `pkg/golden`, `pdatatest`, and `pebbleextension` only from `_test.go` files. `prometheusexporter` appears in non-test code only as a feature-gate string in `featuregates.go`, not an import. Every consumer inherits the full graph of all seven.

Decided: accept the weight. Consumers already pull most of this graph through contrib components, and build-tagging tests means `go test ./...` silently skips them unless the tag is threaded everywhere. No change.

## Sequence

All seven steps are implemented on the branch except cutting the release (step 7, second half). Verified: `make verify-manifest`, module tests, and a scratch module named `github.com/otherdistro/build` compiling against the moved extension through local replaces. The tag-based check waits for the first release.

1. Delete the dangling replace in `snapshotprocessor/go.mod`. Independent, ship first. (The `service_darwin.go` stderr filename that was still `observiq_collector.err` was fixed by #29.)
2. Move the three modules; update manifest, Makefile, CI, dependabot, `updater/go.mod`, AGENTS.md (paths + rule text), `ocb-canonical-build.md`. `make verify-manifest` and `make test` green.
3. Version plumbing: `managed.go` builds `BuildInfo` from `Options.Version`; replace the 12 `version.Version()` call sites with `buildInfo.Version`; derive User-Agent from `collectorPackageName` and `buildInfo.Version`.
4. Link-time variables: add `collectorPackageName` and `stderrLogName` alongside the existing `buildName` / `buildDescription`; stamp all four in `AGENT_LDFLAGS` and `collectorPackageName` in `UPDATER_LDFLAGS` from one shared Makefile variable.
5. Optional reporters; relocate registry resets.
6. Write the three READMEs (why-this-exists + removal).
7. Fix `make release` (targeted pushes, POSIX shell) and add the module-tag check to the release workflow (`make check-release-tags`, run first in `release.yml`); cut the first tagged release; verify a scratch manifest in a foreign-named module builds against the tags with no `replaces`.

Steps 2–3 are what would have let this fork import from upstream instead of carrying a copy.

## Open items

- Cut the first release from this branch and run the tag-only foreign-module build. Note `make check-release-tags` will also demand tags for `cmd/container-init`, `cmd/plugindocgen`, and `internal/tools`; `make release` creates them, as upstream always has.
- The 29 `Client` literals in `bindplane_client_test.go` now carry an `identity` so the version paths have something to read. That is test churn, not a design choice; a `version` field on `Client` would have avoided it at the cost of duplicating what `identity` already holds.
