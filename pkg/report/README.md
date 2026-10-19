# report

Report manager for the legacy snapshot path. Not for direct use.

## Why this exists

This module facilitates Snapshots using a reporter singleton.

`Manager` receives the config from the OpAMP client, and
`SnapshotReporter` buffers pipeline data and POSTs it to the endpoint the
server named.

Two parties share it, and they must share it through the same import path:

- The `opampconnectionextension` OpAMP client gives `GetManager()` an HTTP
  client, registers `report.yaml` as a managed config, and calls
  `ResetConfig` on every push.
- A snapshot processor that retrieves a reporter via `GetSnapshotReporter()`.

`GetManager()` and `GetSnapshotReporter()` are package-level singletons. The
pathway works only if the extension and the processor link the same module.

Order matters too: `SetClient` does not reach a `SnapshotReporter` that
already exists, because the reporter captures the manager's client when it
is created. The extension calls `SetClient` while constructing its OpAMP
client, before the collector and its processors start, so the first
`GetSnapshotReporter()` call always sees the real client.

This package will be removed at a future date.

## Removal

The extension's `report.yaml` wiring and this module go together; remove
both in one change.

1. In `extension/opampconnectionextension/internal/opamp/bindplane`:
   - `bindplane_client.go`: delete the `reportManager` field, the
     `report.GetManager()` / `SetClient` block in `NewClient`, and the
     `report.yaml` `NewManagedConfig` registration in `addManagedConfigs`.
   - `reload_funcs.go`: delete `reportReload` and the
     `report.GetSnapshotReporter().Reset()` call after collector restart.
2. Remove the `pkg/report` `require` and `replace` from the extension's
   `go.mod`, then `go mod tidy`.
3. Delete this module and its `directory:` entry in `.github/dependabot.yml`.
4. Remove the `pkg/report` replace from the manifest and from `updater/go.mod`.
5. Tell consuming distros: their report-manager snapshot processor loses its
   transport and must be swapped for the contrib `snapshotprocessor`.
