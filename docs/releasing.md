# Releasing

There are two kinds of release:

- **No OTel change.** Three small PRs, then tag.
- **OTel update.** The same PRs, plus the OTel bump and the fork pins that come with it.

Each step is a PR merged to `main` before the next one starts. Tag last.

## Next version

The next DBDOT version is a semver bump of the last release: minor for new features or an OTel bump, patch for fixes only. It must be plain `vX.Y.Z`.

## Which kind of release?

If the latest dbdot-contrib release is built on the OTel version DBDOT is already on, there is no OTel change. If not, this is an OTel update. DBDOT has to build on the same OTel version as its contrib components.

DBDOT follows dbdot-contrib. If a new OTel is out but dbdot-contrib hasn't released on it yet, release dbdot-contrib first.

## Release without an OTel change

### 1. Update manifest

Skip this if there are no updates needed in the manifest.

Manually update the component versions in the manifest. Ensure the updated component is still on the same OTel version as the other components. Otherwise a full OTel update may be needed. Ensure the doc entry for the relevant component is updated or added if a new component entry (i.e. `connectors.md`, `extensions.md`, `exporters.md`, `processors.md`, `receivers.md`).

### 2. Aggregate dependabot PRs

In GitHub Actions, run **Aggregate Dependabot PRs** on `main`. It folds every open dependabot PR into one branch and prints a compare link in the job summary. Open the PR from that link yourself; the workflow can't, because a PR opened with `GITHUB_TOKEN` won't run CI. Title: `deps: Dependabot <date>`. Merge when CI is green. Dependabot closes its old PRs on its own.

Read the diff first. When a dependabot diff doesn't apply cleanly, the script falls back to `go mod edit`, which can set an older version. Make sure nothing moved backwards.

To run it locally instead: `./scripts/aggregate-dependabot-prs.sh` on a clean, new branch.

### 3. Update module versions

The in-tree modules depend on each other by version. `make release` tags each module with the release version, so set them to the version you're about to release.

```sh
NEXT=v1.2.0   # the version being released
make update-modules NEW_VERSION=$NEXT
make ci-checks && make verify-manifest
```

This also bumps the in-tree module line in the manifest. A local `replace` overrides that line, but it stays in sync.

PR title: `chore: vX.Y.Z release prep`. Merge it.

### 4. Tag and release

See [Tag and release](#tag-and-release).

## Release with an OTel update

Do the following steps 1a through 1f instead of step 1 above. Then do steps 2 and 3 from above (dependabot PRs and module versions). Finish by following the [Tag and release](#tag-and-release) steps below.

Budget time for this. OTel releases break things, and every fork pin has to be rebuilt.

### 1a. Read the release notes

Read the core and contrib notes for every version you're jumping over, not just the target. Look for removed components, config changes, deprecations and feature gate flips. Raise anything risky in the team channel first.

### 1b. Collect the versions

| Variable | Value |
|---|---|
| `OTEL_VERSION` | OTel core version, e.g. `v0.163.0` |
| `CONTRIB_VERSION` | Same as `OTEL_VERSION` |
| `PDATA_VERSION` | OTel stable module version, e.g. `v1.69.0` |
| `CONTRIB_STABLE_VERSION` | Version of the stable (v1+) contrib modules such as `k8sattributesprocessor`, tagged separately from the contrib release |
| `DBDOT_CONTRIB_VERSION` | dbdot-contrib release being updated to |

### 1c. Update go.mod files, docs, manifest and the builder

```sh
make update-contrib DBDOT_CONTRIB_VERSION=$DBDOT_CONTRIB_VERSION
make update-otel OTEL_VERSION=$OTEL_VERSION CONTRIB_VERSION=$CONTRIB_VERSION PDATA_VERSION=$PDATA_VERSION \
                 DBDOT_CONTRIB_VERSION=$DBDOT_CONTRIB_VERSION CONTRIB_STABLE_VERSION=$CONTRIB_STABLE_VERSION
sed -i '' -E "s|^OCB_VERSION \?= .*|OCB_VERSION ?= $OTEL_VERSION|" Makefile
```

If `make update-contrib` fails in `go mod tidy`, keep going. `make update-otel` fixes it. When a module goes v1, add it to the lists at the top of `scripts/update-otel.sh` and `scripts/update-docs.sh`.

`make update-otel` bumps the manifest with `scripts/update-manifest.sh`. The script moves each group of modules from the version most of them are on now, so a line pinned elsewhere on purpose (`jmxreceiver`) is left alone. It never touches the `replaces:` block.

### 1d. Check the manifest

`make update-otel` ends with a count of every version in the manifest. Read `git diff` on the manifest too. Anything still on an old version is either a deliberate pin (check its comment) or a line the script missed.

### 1e. Rebuild the fork pins

The `replaces:` block pins forks built on the old OTel. Each one needs a rebuild on the new tag, in its own repo, before DBDOT compiles.

- **observIQ contrib fork** (`windowseventlogreceiver`, `pkg/stanza`, `jmxreceiver`, `googlecloudpubsubreceiver`): rebase the `deps/bdot-<version>` branch in `github.com/observiq/opentelemetry-collector-contrib` onto the new upstream tag. Pin to the new head.
- **DT edge components** (`dtedgeprocessingreceiver`, `dtedgeprocessingexporter`): needs a commit of `Dynatrace/dt-otelcol-edge-processing-components` built on the new OTel. The `gomod:` lines (done by `make update-otel` above) and the `replaces:` pseudo-versions both change. The repo is private, so set `GOPRIVATE=github.com/Dynatrace/*` for bare `go` commands.
- **`enhanceindexings3exporter`** (Honeycomb): third-party. Use the release built on the new OTel.
- **`JAVA_CONTRIB_VERSION`**: the JMX metrics jar. Not tied to OTel. Bump only if there's a reason.

To get a pseudo-version for a commit:

```sh
d=$(mktemp -d) && (cd "$d" && go mod init resolve >/dev/null && \
  GOPRIVATE='github.com/Dynatrace/*' go list -m github.com/observiq/opentelemetry-collector-contrib/pkg/stanza@<sha>)
```

Update the comment above each pin so the next person knows which OTel tag it was built on.

### 1f. Verify

```sh
make install-tools
make generate
make tidy
make ci-checks
make install-ocb        # builder at the new OCB_VERSION
make verify-manifest
make agent              # smoke build
```

Expect test failures and deprecation fallout. Fix them in this PR.

## Tag and release

1. On an up-to-date `main`:

   ```sh
   make release version=vX.Y.Z
   ```

   This tags and pushes `vX.Y.Z`, then `<module dir>/vX.Y.Z` for every in-tree module. Those module tags are what step 3 pointed at. Only plain `vX.Y.Z` is accepted.

2. The `release` workflow runs on the tag. It builds the signed Windows MSI first, then goreleaser builds every platform, creates a GitHub pre-release with a changelog from commit titles (so the `feat:`, `fix:` and `deps:` prefixes matter), attaches the packages, and uploads them to GCS and Artifact Registry.

3. When `release` is green, run the `release-containers` workflow by hand with the version tag. It builds the images from the GCS binaries and pushes them to `ghcr.io/dynatrace/dynatrace-bindplane-otel-collector`.

4. Review the release notes that were generated and ensure they are accurate. If doing an OTel update, call out the new version and link to the release notes for it at the top.

## Checklist

- [ ] Kind of release decided
- [ ] Manifest updated and OTel dependencies updated (if needed)
- [ ] `deps: Dependabot <date>` merged
- [ ] `chore: vX.Y.Z release prep` merged
- [ ] `make release version=vX.Y.Z` run from up-to-date `main`
- [ ] `release` workflow green
- [ ] `release-containers` run and green

## Testing a release locally

To run `make release-test`:

1. Run `make install-tools`
2. Run `make release-test`

To test the Docker release, run the `release-containers-test` workflow with an existing release version. It runs the full build with `--skip=publish`, so nothing is pushed.
