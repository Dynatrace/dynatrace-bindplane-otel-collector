# report

Report manager for the legacy Bindplane snapshot path. Not for direct use.

## Why this exists

Older Bindplane servers request snapshots by pushing a `snapshotConfig` block
in the `report.yaml` managed config, and expect the payload to arrive as an
out-of-band HTTP POST rather than as an OpAMP custom message. This module is
that transport: `Manager` receives the config from the OpAMP client, and
`SnapshotReporter` buffers pipeline data and POSTs it to the endpoint the
server named.

Two parties share it, and they must share it through the same import path:

- The `opampconnectionextension` OpAMP client gives `GetManager()` an HTTP
  client, registers `report.yaml` as a managed config, and calls
  `ResetConfig` on every push.
- A snapshot processor that writes into `GetSnapshotReporter()`. This repo
  no longer carries one: this distro ships the contrib `snapshotprocessor`,
  which serves only OpAMP custom messages, so a server that uses `report.yaml`
  gets empty snapshots from this distro. A consuming distro that still needs
  the legacy path keeps its own report-manager processor and points its
  `report` import at this module.

`GetManager()` and `GetSnapshotReporter()` are package-level singletons. The
pathway works only if the extension and the processor link the same copy of
this package, which means the same module path. A processor importing a
different copy of `report` under another module path writes into a reporter
the extension never reports from.

Order matters too: `SetClient` does not reach a `SnapshotReporter` that
already exists, because the reporter captures the manager's client when it
is created. The extension calls `SetClient` while constructing its OpAMP
client, before the collector and its processors start, so the first
`GetSnapshotReporter()` call always sees the real client.

There is no removal date. It stays until every Bindplane server any
consuming distro is managed by supports snapshot custom messages.

## Removal

1. Delete this module and its `directory:` entry in `.github/dependabot.yml`.
2. In `opampconnectionextension`, follow the "Removal" section of its README
   to drop the `report.yaml` wiring, then remove the `report` `require` and
   `replace` from its `go.mod`.
3. Remove the `report` replace from the manifest and from `updater/go.mod`.
4. Tell consuming distros: their report-manager snapshot processor loses its
   transport and must be swapped for the contrib `snapshotprocessor`.
