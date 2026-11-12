# Development

## Initial Setup

Clone this repository, and run `make install-tools`

## Building

To create a build for your current machine, run `make agent`

To build the slim distro instead of the full one, run `make agent DISTRO=slim`. See the [manifests README](../manifests/dynatrace-bindplane-otel-collector/README.md#choosing-a-distro)

To build for a specific architecture, see the [Makefile](../Makefile)

To build all targets, run `make build-all`

Build files will show up in the `./dist` directory

## Running Tests

Tests can be run with `make test`.

## Testing Linux packages

The deb and rpm packages can be tested in systemd-enabled distro containers. The suite covers fresh install, upgrade from a previous release, and uninstall. It requires Docker.

```sh
make release-test   # builds the packages into ./dist
make test-packages  # runs the package tests against ./dist
```

See [test/packaging](../test/packaging/README.md) for options and for how to add a distribution.

## Running CI checks locally

The CI runs the `ci-checks` make target, which includes linting, testing, and checking documentation for misspelling.
CI also does a build of all targets (`make build-all`)

The Go runtime fingerprint gate is not part of `ci-checks` (it needs ocb and the generated build). Run it with `make verify-manifest verify-go-runtime`.

## Updating to latest OTEL version

Read through the release notes for the versions of contrib and core that are being updated to. If doing multiple versions look at all version included, i.e. if going from v0.120.0 to v0.122.0 look at v0.121.0 as well. Look for any potential deprecations or breaking changes that could affect Bindplane resources (these are typically in the "End User Changelog" but check the "API Changelog" as well). 

If there are any potential issues with the update, raise concerns in the team channel and coordinate an update plan if necessary.

Most of the process for updating the OTEL dependency is automated with scripts. If at any point there is a failure, try running `make tidy` to see if updating the `go.mod` is able to resolve the issue.
The steps are as follows:

1. Run:
    ```sh
    ./scripts/update-otel.sh {COLLECTOR_VERSION} {CONTRIB_VERSION} {PDATA_VERSION} {CONTRIB_STABLE_VERSION}
    ```
    Grab the different versions from OTEL's GitHub by checking the latest release versions of [collector-contrib](https://github.com/open-telemetry/opentelemetry-collector-contrib) and the [collector](https://github.com/open-telemetry/opentelemetry-collector). They should be the same.
    The pdata version can be found by checking the latest release notes of the collector in a header with {PDATA_VERSION}/{COLLECTOR_VERSION}. The `CONTRIB_STABLE_VERSION` is the version of contrib's stable (v1.0.0+) modules, which are versioned independently of the main contrib release (e.g. the k8sattributes processor). All version arguments should include the v - an example run of the script would look like this:
    ```sh
    ./scripts/update-otel.sh v0.114.0 v0.114.0 v1.20.0 v1.0.0
    ```
    The stable contrib modules are tracked in an allowlist near the top of `update-otel.sh` (and `update-docs.sh`). When a new contrib component reaches v1.0.0, add its module path to both lists. Note: `make update-otel` also bumps the manifest through `scripts/update-manifest.sh`; when running the scripts by hand, run that one too.

2. Run `make tidy`

3. Run:
    ```sh
    ./scripts/update-docs.sh {COLLECTOR_VERSION} {CONTRIB_VERSION} {DBDOT_CONTRIB_VERSION} {CONTRIB_STABLE_VERSION}
    ```
    The collector and contrib versions should be the same as in step 1. The `DBDOT_CONTRIB_VERSION` is the latest release version of [bindplane-otel-contrib](https://github.com/dynatrace/dynatrace-bindplane-otel-contrib). The `CONTRIB_STABLE_VERSION` is the same value passed in step 1.

4. Run `make install-tools`

5. Run `make generate`

6. Run `make tidy`

7. Run `make ci-checks`

If all was successful, the repo has had its OTEL dependencies updated to the latest version. 

There is potential for tests to fail, deprecation issues, code changes, or a variety of other problems to arise, but once the above steps are successful the repo can be updated.

## Updating bindplane-otel-contrib dependencies

When [bindplane-otel-contrib](https://github.com/dynatrace/dynatrace-bindplane-otel-contrib) publishes a new release, update the Go module dependencies in this repo:

1. Run:
    ```sh
    make update-contrib DBDOT_CONTRIB_VERSION=vx.x.x
    ```
    where `vx.x.x` is the new version of bindplane-otel-contrib.

2. Run `make ci-checks` to verify the update.

## Changing the Go version

The Go version that decides Go's default runtime behavior is the `go` line of the *main module* of the collector binary. That module is generated at build time by the OpenTelemetry Collector Builder (ocb) into `build/` (or `build-slim/`), which is not in git. `make verify-manifest` followed by `make verify-go-runtime` compares the binary's Go runtime fingerprint with `go-runtime-baseline.txt`:

- `toolchain`: Go minor version the binary was compiled with (patch levels are ignored).
- `main module go`: minor version of the `go` directive of the generated main module.
- `DefaultGODEBUG`: GODEBUG defaults embedded in the binary (`go version -m <binary>`), or `none`.

The fingerprint changes in three ways:

1. The toolchain moves, for example the `go` line in `extension/opampconnectionextension/go.mod` (which CI uses to pick the compiler) goes to a new minor.
2. An upstream dependency raises its own minimum Go version. `go mod tidy` raises the generated main module's `go` line to match, so a plain dependency bump (including an OpenTelemetry update) can trip the gate with no go.mod change in the diff.
3. A `//go:debug` directive (or `godebug` block) is added to or removed from the main package or the generated go.mod. A main module older than the toolchain also makes `DefaultGODEBUG` appear, listing the old defaults it keeps.

Go gates many behavior changes on these values (see [GODEBUG history](https://go.dev/doc/godebug)). For example Go 1.25 made the default GOMAXPROCS follow the container CPU limit. When the gate fails:

1. Read the Go release notes for every minor crossed. Check the Runtime, Ports (minimum OS and kernel versions), `crypto/tls` and `net/http` sections.
2. Open <https://go.dev/doc/godebug> and list every setting whose default changes at each version crossed (the table below is a starting point). For each, decide to accept the new default or pin the old one. To pin, add `//go:debug name=value` to the distribution `main.go` files. Each distribution ships its own `main.go`, so the same change is needed in this repo (`extension/opampconnectionextension/cmd/main/main.go`) and in the BDOT repo. Write each decision in the PR description.
3. Check the supported OS list against the new minimum OS and kernel requirements.
4. Run the CPU-limit startup smoke test (see [CPU-limit smoke test](#cpu-limit-smoke-test)).
5. Run the performance comparison (see [Performance comparison](#performance-comparison)).
6. Note customer-visible runtime changes in the release notes.
7. Run `make update-go-runtime-baseline` and commit the new `go-runtime-baseline.txt` in the same PR.

### CPU-limit smoke test

`scripts/ci/check-gomaxprocs-startup.sh <image>` starts the collector image under several CPU limits and environments (no limit, `--cpus=0.5`, `2`, `3` and `4`, with and without `GOMAXPROCS` and `GODEBUG=containermaxprocs=0`) and checks the `Go runtime CPU settings` startup log line and its warnings against the values the Go runtime is expected to choose. It builds nothing, needs a Docker host with at least 4 CPUs, and exits non-zero on any mismatch.

The e2e workflow runs it on every pull request against the image it builds. To run it locally:

```sh
GOOS=linux make agent
docker build -f internal/testbed/docker/Dockerfile -t collector:gomaxprocs-check dist
scripts/ci/check-gomaxprocs-startup.sh collector:gomaxprocs-check
```

If a Go version change makes a case fail, the runtime's default changed. Decide whether the new behavior is wanted (see step 2), then update the expected values in the script in the same PR.

### Performance comparison

A manual check for a Go minor version change. Build the same commit with the old and the new toolchain and compare them under a fixed CPU limit.

1. Generate the sources once: `make verify-manifest` (or `builder --config manifests/<distro>/manifest.yaml --skip-compilation`).
2. Copy `./build` once per variant and build each copy for linux with an explicit toolchain: `GOTOOLCHAIN=go1.X.Y CGO_ENABLED=0 go build -tags "embed_library" -o collector-<variant> .` (the tags are `AGENT_BUILD_TAGS` in the Makefile)
   - A: the old toolchain.
   - B: the new toolchain, generated go.mod unchanged. This is what a compiler-only bump ships.
   - C: the new toolchain, and `go mod edit -go=1.X && go mod tidy` in the copy first. This is what ships once the main module's `go` line moves, and it is the variant that adopts the new runtime defaults.
3. Record `go version -m <binary> | head -1` and the output of `scripts/go-runtime-fingerprint.sh` for each variant. A compile error is a finding.
4. Run each binary in a container with `--cpus=2`: a load generator (for example `telemetrygen`, pinned to a version) sending OTLP logs to the collector, which batches and exports with gzip to a second collector that discards them. Use an image with a shell so `/sys/fs/cgroup/cpu.stat` can be read.
   - Fixed rate: a rate that keeps variant A at 40-60% of the CPU limit.
   - Saturation: generators unthrottled and a limit low enough that the collector is pinned and throttled.
5. For each run, after a 20 second warm-up and over 60 seconds, record the change in `usage_usec` and `nr_throttled` from `cpu.stat`, the receiver's accepted-records counter from the collector's own metrics, and `memory.peak`.
6. Interleave the variants (A, B, C, A, B, C, ...) and repeat at least three times.
7. Run existing benchmarks on the hot paths you care about with both toolchains (`go test -run '^$' -bench . -count 6`) and compare them with `benchstat`.
8. Report the mean and the min-max range per metric and the difference from A. A difference smaller than the spread between repetitions of the same variant is "no measurable change". Confirm the effective GOMAXPROCS under the limit is the same for all variants.
9. Put the raw table in the PR description.

### GODEBUG settings gated by the go.mod version

Settings whose default changes with the main module's `go` line. Below the listed version the old behavior applies. Source: the `Changed:` entries of the `internal/godebugs` tables of the Go 1.26.10 and 1.27.4 toolchains (which include the 1.25 entries). Some settings are marked opaque in the table and have no runtime metric.

| Go | Settings |
|---|---|
| 1.21 | `panicnil` |
| 1.22 | `httplaxcontentlength`, `httpmuxgo121`, `tls10server`, `tlsrsakex`, `tlsunsafeekm` |
| 1.23 | `asynctimerchan`, `gotypesalias`, `tls3des`, `x509keypairleaf`, `x509negativeserial`, `httpservecontentkeepheaders`, `winsymlink`, `winreadlinkvolume` |
| 1.24 | `randseednop`, `multipathtcp`, `rsa1024min`, `tlsmlkem`, `x509rsacrt`, `x509usepolicies`, `gotestjsonbuildtext`, `httpcookiemaxnum`, `urlmaxqueryparams` |
| 1.25 | `containermaxprocs` (GOMAXPROCS follows the cgroup CPU limit), `updatemaxprocs` (GOMAXPROCS re-evaluated periodically), `decoratemappings`, `tlssha1`, `x509sha256skid` |
| 1.26 | `cryptocustomrand`, `httpservecontentmaxranges`, `tlssecpmlkem`, `urlstrictcolons` |
| 1.27 | `tracebacklabels`, `x509sslcertoverrideplatform`; also removes `gotypesalias`, `tlsunsafeekm`, `tlsrsakex`, `tls3des`, `tls10server`, `x509keypairleaf`, `asynctimerchan` (no opt-out left) |

`gotypesalias` and `gotestjsonbuildtext` affect go/types and cmd/go, not the shipped binary.

Runtime, garbage collector and scheduler changes that are not GODEBUG settings do not show up here. They are what the performance comparison is for.

## Releasing
To cut a patch release, see the [patch release guide](releasing.md).
