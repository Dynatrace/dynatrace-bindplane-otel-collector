# report

Report manager for the legacy Bindplane snapshot path. Not for direct use.

## Why this exists

Older Bindplane servers request snapshots by pushing a `snapshotConfig` block
in the `report.yaml` managed config, and expect the payload to arrive as an
out-of-band HTTP POST rather than as an OpAMP custom message. This module is
that transport: `Manager` receives the config from the OpAMP client, and
`SnapshotReporter` buffers pipeline data and POSTs it to the endpoint the
server named.

The [`pkg/snapshotprocessor`](../snapshotprocessor) processor writes into
these buffers, and the [`opampconnectionextension`](../../extension/opampconnectionextension)
OpAMP client wires the manager up and reloads it on `report.yaml` changes.
Nothing else should import this module. Newer servers use OpAMP custom
messages via the contrib `snapshotprocessor` and never touch this path.

There is no removal date. It stays until every Bindplane server this distro is
managed by supports snapshot custom messages.

## Removal

1. Delete this module and its `directory:` entry in `.github/dependabot.yml`.
2. In `extension/opampconnectionextension`, follow the "Removal" section of its
   README to drop the `report.yaml` wiring, then remove the `pkg/report`
   `require` and `replace` from its `go.mod`.
3. Delete `pkg/snapshotprocessor` per its README, which is the other consumer.
4. Remove the `pkg/report` replace from the manifest and from `updater/go.mod`.
