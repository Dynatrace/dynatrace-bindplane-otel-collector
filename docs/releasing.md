# Releasing
Releases are managed through GitHub releases. This repository releases two builds, and the tag decides which one. The guide below describes the full build, [Slim releases](#slim-releases) describes the slim build:

| Build | Tag | Workflow | Manifest |
|---|---|---|---|
| full | `vX.Y.Z` | `release-full` | `manifests/dynatrace-bindplane-otel-collector/manifest.yaml` |
| slim | `vX.Y.Z-rc.N` | `release-slim` | `manifests/dynatrace-bindplane-otel-collector-slim/manifest.yaml` |

Both workflows are thin callers of the reusable `base-release` workflow. Each build has its own goreleaser configuration next to its manifest.

Before tagging, set `dist.version` in the manifest of the build you are releasing to the version without the leading `v`. The first job of the release workflow compares the tag with it and fails on a mismatch: a full tag (`v1.2.3`) must equal `dist.version`, a slim RC tag (`v1.2.3-rc.1`) must equal it once `-rc.N` is removed, so several RCs can share one manifest version. The checks live in `scripts/ci/check-tag-version.sh`.

# Patch releases

A patch release ships fixes on the OTel version DBDOT is already on. It does not change the OTel version.

Every component in the manifest must be built on the same OTel version. If one component is built on a newer OTel, the build pulls every other component up to it. That is an OTel update, not a patch, and this guide does not cover it.

Steps 1 to 3 are each their own PR, merged to `main` before the next one.

## Check it's a patch

A patch can include fixes merged to `main`, security fixes, and new component versions that are built on DBDOT's current OTel. The Honeycomb exporter is the exception: bump it only in a minor release.

DBDOT's OTel version is `OCB_VERSION` in the Makefile.

Most lines are the OTel unstable version (`v0.x`). A few core modules are on the stable version (`v1.x`). The rest are dbdot-contrib, the `jmxreceiver` pin, Honeycomb's exporter, and DT edge components.

To see which OTel a dbdot-contrib release uses, read one of its `go.mod` files at that tag.

If the versions don't match DBDOT's, stop. Use an older dbdot-contrib release that matches, or else a minor release is required.

## 1. Bump component versions

Skip this if nothing in the manifest needs to change.

For dbdot-contrib:

```sh
make update-contrib DBDOT_CONTRIB_VERSION=v1.2.0
```

This updates the `go.mod` files, the full and slim manifests and the doc links. For anything else, edit the manifest line (in both manifests), its doc entry and any `replaces:` pin by hand.

Then check nothing moved OTel:

```sh
make verify-manifest
cd build && go list -m -f '{{.Path}} {{.Version}}' all | grep -E '^(go.opentelemetry.io/collector/|github.com/open-telemetry/opentelemetry-collector-contrib/)' | awk '{print $2}' | sort | uniq -c
```

This lists the OTel version Go picked for every module in the build. You should see the manifest's `v0.x` and `v1.x` with big counts. A few older ones are fine: the `jmxreceiver` pin, `k8sattributesprocessor` on its own `v1` line, and a couple of old transitive modules. Anything newer than the manifest's version means a component was built on a newer OTel. Back it out.

PR title: `fix: ...` if the bump is a fix users should see in the changelog, otherwise `deps: ...`.

## 2. Resolve security alerts

Every open alert on the [security page](https://github.com/Dynatrace/dynatrace-bindplane-otel-collector/security) must be resolved before the release. Merge only the dependabot PRs that fix an alert. Leave the rest for the next minor release to keep the patch small. If no dependabot PR covers an alert, fix it in its own PR.

## 3. Release prep

The in-tree modules depend on each other by version. Set them to the version you're about to release:

```sh
NEXT=v1.110.1
make update-modules NEW_VERSION=$NEXT
```

This also updates the in-tree module line in the full and slim manifests.

Also set `dist.version` in `manifests/dynatrace-bindplane-otel-collector/manifest.yaml` to the release version without the leading `v` (`1.110.1` for `v1.110.1`). `update-modules` does not change it. The `release-full` workflow fails if the tag does not match `dist.version` exactly.

PR title: `chore: vX.Y.Z release prep`. Merge it.

## 4. Tag and release

1. On an up-to-date `main`:

   ```sh
   make release version=vX.Y.Z
   ```

   This tags and pushes `vX.Y.Z`, plus `<module dir>/vX.Y.Z` for every in-tree module. Only `vX.Y.Z` triggers the `release-full` workflow. RC tags (`vX.Y.Z-rc.N`) are accepted by `make release` but only tag the root, since they are reserved for the slim build.

2. The `release-full` workflow (a thin caller of the reusable `base-release` workflow) runs on the tag. It builds the signed Windows MSI, then goreleaser builds every platform, creates a GitHub pre-release with a changelog from commit titles, attaches the packages, and uploads them to Google Cloud Storage.

3. When `release-full` is green, run the `release-containers` workflow on the `vX.Y.Z` tag, not on a branch, and enter the same tag as the version input. It builds the images and pushes them to `ghcr.io/dynatrace/dynatrace-bindplane-otel-collector`.

4. Read and verify the release notes generated by Goreleaser are accurate. Make changes as needed. If the release bumps a component, link to that component's release notes.

## 5. Verify and mark latest

Install the new version on a machine, connect it to Bindplane, and push a configuration to it. Confirm the collector starts, shows as connected, and the configuration runs.

Then edit the GitHub release, clear the pre-release flag, and set it as the latest release.

## Checklist

- [ ] Every component bump is on DBDOT's current OTel
- [ ] Component bump PR merged (if any)
- [ ] Security alerts resolved
- [ ] `chore: vX.Y.Z release prep` merged, with `dist.version` set to the release version
- [ ] `make release version=vX.Y.Z` run from up-to-date `main`
- [ ] `release-full` workflow green
- [ ] `release-containers` run on the tag and green
- [ ] Release notes checked, component release notes linked
- [ ] Installed, connected to Bindplane, tested with a configuration
- [ ] Pre-release flag cleared and release marked latest

## Testing a release locally

1. Run `make install-tools`
2. Run `make release-test`, or `make release-test DISTRO=slim` for the slim build. The slim snapshot skips the container images and SBOMs by default because they need docker buildx and cyclonedx-gomod, run `make release-test DISTRO=slim RELEASE_TEST_SKIP=` to include them.

To rehearse a release in GitHub Actions, run the `release-test` workflow and select the `distro`. It runs the release pipeline with `--skip=publish`, so nothing is published. Slim skips signing in the rehearsal because keyless signing needs the identity of a real release run.

To test the Docker release of the full build, run the `release-containers-test` workflow with an existing release version. It runs the full build with `--skip=publish`, so nothing is pushed.

# Slim releases

1. Set `dist.version` in the slim manifest to the version the RC is for, without `-rc.N`. The component versions follow the full manifest: `make update-otel`, `make update-contrib` and `make update-modules` bump both manifests. Only components you change by hand in the full manifest need the same change in the slim one.

2. Run `make release version=vX.Y.Z-rc.N`. Only the root tag is created and pushed, RC versions do not tag the Go modules.

3. The `release-slim` workflow triggers on the tag push and, without user intervention:
  - Checks the tag against the slim manifest
  - Builds the slim binaries and updater (linux, darwin and windows/amd64) with the slim OpAMP agent identity (`com.dynatrace.bindplane.otel.collector-slim`)
  - Creates the archives (`dynatrace-bindplane-otel-collector-slim-*`), the `apk`, `deb` and `rpm` packages. The `deb` and `rpm` packages are signed with the GPG key, the `apk` is not signed.
  - Creates a CycloneDX SBOM per collector binary (`cyclonedx-gomod`), like the Dynatrace OTel Collector
  - Creates the checksums file and signs it and the archives keyless with cosign (`*.sigstore.json` bundles)
  - Builds and pushes the container images for amd64, arm64 and ppc64le with multi-arch manifests to Docker Hub (`dynatrace/dynatrace-bindplane-otel-collector-slim`), AWS ECR public (`public.ecr.aws/dynatrace/dynatrace-bindplane-otel-collector-slim`) and GHCR (`ghcr.io/dynatrace/dynatrace-bindplane-otel-collector-slim`), signs them keyless and writes `digests.txt`
  - Attests the checksums and the image digests
  - Publishes the GitHub release as a pre-release and uploads the artifact bundles

There is no Windows MSI and no install script for the slim build, and there are no `latest` image tags: an RC release never moves them. The slim artifacts are not uploaded to GCS yet, because the bucket for them does not exist. The `release-slim` workflow does not authenticate to GCP, and the goreleaser config has no `blobs` section until the bucket exists.

Verifying the keyless signatures is described in [Verifying Artifact Signatures](./verify-signature.md).
