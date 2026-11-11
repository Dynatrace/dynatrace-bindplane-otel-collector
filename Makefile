# All source code and documents, used when checking for misspellings
ALLDOC := $(shell find . \( -name "*.md" -o -name "*.yaml" \) \
                                -type f | sort)
# Exclude the ocb-generated ./build/ and ./build-slim/ trees — they are
# throwaway modules, not part of the repo.
ALL_MODULES := $(shell find . -type f -name "go.mod" -not -path "./build/*" -not -path "./build-slim/*" -exec dirname {} \; | sort )
# End-to-end test modules. They need a built collector binary (and, for some
# suites, Docker or a kind cluster), so the unit-test targets skip them. They are
# run by .github/workflows/e2e.yaml.
E2E_MODULES := ./internal/testbed/integration
# Internal-only modules that are never published, so `make release` doesn't tag them.
UNRELEASED_MODULES := ./internal/testbed/integration ./internal/testcommon
ALL_MDATAGEN_MODULES := $(shell find . -type f -name "metadata.yaml" -exec dirname {} \; | sort )

# All source code files
ALL_SRC := $(shell find . -name '*.go' -o -name '*.sh' -o -name '*.ps1' -o -name 'Dockerfile*' -type f | sort)

OUTDIR=./dist
GOOS ?= $(shell go env GOOS)
GOARCH ?= $(shell go env GOARCH)

# Private Dynatrace modules (e.g. dt-otelcol-edge-processing-components) are
# not on the public module proxy or checksum database; fetch them directly
# from git. Requires git credentials with read access to the Dynatrace org.
export GOPRIVATE ?= github.com/Dynatrace/*

INTEGRATION_TEST_ARGS?=-tags integration

TOOLS_MOD_DIR := ./internal/tools


ifeq ($(GOOS), windows)
EXT?=.exe
else
EXT?=
endif

SNAPSHOT := $(shell git rev-parse --short HEAD)
PREVIOUS_TAG := $(shell git tag --sort=v:refname --no-contains HEAD | grep -E "[0-9]+\.[0-9]+\.[0-9]+$$" | grep -v 'version' | tail -n1)
CURRENT_TAG := $(shell git tag --sort=v:refname --points-at HEAD | grep -E "v[0-9]+\.[0-9]+\.[0-9]+$$" | grep -v 'version' | tail -n1)
# Version will be the tag pointing to the current commit, or the previous version tag if there is no such tag
VERSION ?= $(if $(CURRENT_TAG),$(CURRENT_TAG),$(PREVIOUS_TAG)-SNAPSHOT-$(SNAPSHOT))
# Tag passed to goreleaser in --snapshot mode. Must be the bare tag; goreleaser's snapshot
# template appends its own -SNAPSHOT-<sha> suffix, so passing VERSION here would double it.
SNAPSHOT_TAG := $(if $(CURRENT_TAG),$(CURRENT_TAG),$(PREVIOUS_TAG))

# Timeout for the local snapshot goreleaser targets. goreleaser defaults to 1h, which a
# full cross-compile can exceed on a slower workstation, so the run gets killed partway
# through. CI uses 120m on larger runners; local gets more headroom. Override on the
# command line if your machine needs a different budget.
GORELEASER_TIMEOUT ?= 180m

# Build-info stamps. These get linked into the binary via -ldflags so
# `collector --version` shows real values instead of "unknown".
GIT_HASH ?= $(shell git rev-parse HEAD)
BUILD_DATE ?= $(shell date -u +%Y-%m-%dT%H:%M:%SZ)

# DISTRO selects which distribution the agent targets (build, verify-manifest).
# It defaults to the fully-featured DBDOT build, so a plain `make agent` is
# unchanged. Select another one with e.g. `make agent DISTRO=slim`.
#
# Per-distro settings:
#   MANIFEST           ocb manifest, the source of truth for the components.
#   BUILD_DIR          where ocb generates the sources. Must be a sibling of the
#                      other build dirs: the manifests' local replaces are
#                      written relative to it (../extension/...).
#   AGENT_NAME         populates component.BuildInfo and is the OpAMP agent type
#                      (service.name) Bindplane uses to identify the build.
#   AGENT_DESCRIPTION  populates component.BuildInfo.
#   AGENT_ARTIFACT     base name of the binary written to $(OUTDIR).
#   PRODUCT_NAME       product slug (see below).
#   PLIST_SRC          launchd plist packaged into the macOS archives.
#   DISTRO_BUILD_TAGS  extra build tags for the distro, added to AGENT_BUILD_TAGS.
#   GORELEASER_DIR     directory holding the goreleaser configs of the build.
#                      Goreleaser still runs from the repository root; only the
#                      config files live there.
#   RELEASE_TEST_SKIP  extra goreleaser --skip steps of the local `release-test`
#                      snapshot. The slim build skips the container images and
#                      SBOMs by default, they need docker buildx and
#                      cyclonedx-gomod. Run
#                      `make release-test DISTRO=slim RELEASE_TEST_SKIP=` for all.
DISTRO ?= full
ifeq ($(DISTRO),full)
MANIFEST ?= manifests/dynatrace-bindplane-otel-collector/manifest.yaml
BUILD_DIR ?= ./build
AGENT_NAME = com.dynatrace.bindplane.otel.collector
AGENT_DESCRIPTION = Dynatrace Bindplane Distribution of OpenTelemetry Collector
AGENT_ARTIFACT = collector
PRODUCT_NAME = dynatrace-bindplane-otel-collector
PLIST_SRC = service/com.dynatrace.bindplane.otel.collector.plist
DISTRO_BUILD_TAGS =
GORELEASER_DIR = manifests/dynatrace-bindplane-otel-collector
RELEASE_TEST_SKIP ?=
else ifeq ($(DISTRO),slim)
MANIFEST ?= manifests/dynatrace-bindplane-otel-collector-slim/manifest.yaml
BUILD_DIR ?= ./build-slim
AGENT_NAME = com.dynatrace.bindplane.otel.collector-slim
AGENT_DESCRIPTION = Dynatrace Bindplane Distribution of OpenTelemetry Collector (slim)
AGENT_ARTIFACT = collector-slim
PRODUCT_NAME = dynatrace-bindplane-otel-collector-slim
PLIST_SRC = manifests/dynatrace-bindplane-otel-collector-slim/service/com.dynatrace.bindplane.otel.collector-slim.plist
# Selects the slim feature gate skip list (see
# extension/opampconnectionextension/internal/collector/featuregates_slim.go).
DISTRO_BUILD_TAGS = dbdot_slim
GORELEASER_DIR = manifests/dynatrace-bindplane-otel-collector-slim
RELEASE_TEST_SKIP ?= docker,sbom
else
$(error Unknown DISTRO '$(DISTRO)'. Supported: full, slim)
endif

# PRODUCT_NAME is the product slug: the OpAMP package key the collector and
# updater agree on, the User-Agent prefix, and (underscored) the stderr log
# file name that the installers and support scripts reference. Set per DISTRO
# above.
STDERR_LOG_NAME = $(subst -,_,$(PRODUCT_NAME)).err
OPAMP_EXT_MODULE = github.com/dynatrace/dynatrace-bindplane-otel-collector/extension/opampconnectionextension
OPAMP_EXT_COLLECTOR_PKG = $(OPAMP_EXT_MODULE)/internal/collector
OPAMP_EXT_SERVICE_PKG = $(OPAMP_EXT_MODULE)/internal/service
OPAMP_EXT_PACKAGESTATE_PKG = $(OPAMP_EXT_MODULE)/packagestate

# AGENT_LDFLAGS stamps version + git hash + build date into the v1 collector
# binaries (both consume github.com/dynatrace/dynatrace-bindplane-otel-contrib/pkg/version),
# plus the DBDOT identity values into the opamp connection extension.
AGENT_LDFLAGS = -s -w \
	-X github.com/dynatrace/dynatrace-bindplane-otel-contrib/pkg/version.version=$(VERSION) \
	-X github.com/dynatrace/dynatrace-bindplane-otel-contrib/pkg/version.gitHash=$(GIT_HASH) \
	-X github.com/dynatrace/dynatrace-bindplane-otel-contrib/pkg/version.date=$(BUILD_DATE) \
	-X $(OPAMP_EXT_COLLECTOR_PKG).buildName=$(AGENT_NAME) \
	-X '$(OPAMP_EXT_COLLECTOR_PKG).buildDescription=$(AGENT_DESCRIPTION)' \
	-X $(OPAMP_EXT_PACKAGESTATE_PKG).collectorPackageName=$(PRODUCT_NAME) \
	-X $(OPAMP_EXT_SERVICE_PKG).stderrLogName=$(STDERR_LOG_NAME)

# AGENT_BUILD_TAGS are the build tags that should be used when building DBDOT
# 'embed_library' used by the telemetry generator receiver to use blitz (PR#3525)
AGENT_BUILD_TAGS = embed_library $(DISTRO_BUILD_TAGS)

# UPDATER_LDFLAGS stamps the same values into the updater binary. The package
# name must match the collector's or the updater never sees the install finish.
UPDATER_LDFLAGS = -s -w \
	-X github.com/dynatrace/dynatrace-bindplane-otel-collector/updater/internal/version.version=$(VERSION) \
	-X github.com/dynatrace/dynatrace-bindplane-otel-collector/updater/internal/version.gitHash=$(GIT_HASH) \
	-X github.com/dynatrace/dynatrace-bindplane-otel-collector/updater/internal/version.date=$(BUILD_DATE) \
	-X $(OPAMP_EXT_PACKAGESTATE_PKG).collectorPackageName=$(PRODUCT_NAME)

.PHONY: version
version:
	@printf $(VERSION)

# Build binaries for current GOOS/GOARCH by default
.DEFAULT_GOAL := build-binaries

# ocb-driven build:
#   1. Run the OTel collector builder against the manifest of the selected
#      DISTRO (see above) to generate its BUILD_DIR (components.go, go.mod,
#      etc).
#   2. Overwrite the generated main.go with the v1 entry point shipped by
#      the opampconnectionextension at cmd/main/main.go. That entry point
#      wires ocb's factories into the managed/standalone runtime via
#      runtime.Run.
#   3. go mod tidy + go build inside BUILD_DIR.
#
# Resolve ocb to the first of:
#   - the OCB env var
#   - `builder` on PATH
#   - $(GOBIN)/builder (else $$HOME/go/bin/builder)
#
# Install with: make install-ocb
OCB_VERSION ?= v0.164.0
OCB ?= $(shell command -v $${OCB:-builder} 2>/dev/null || echo $${GOBIN:-$$HOME/go/bin}/builder)

# Installs the ocb builder at the pinned version. The single source of truth
# for the ocb version — CI workflows call this instead of pinning their own.
.PHONY: install-ocb
install-ocb:
	go install go.opentelemetry.io/collector/cmd/builder@$(OCB_VERSION)
AGENT_MAIN ?= extension/opampconnectionextension/cmd/main/main.go
MANIFEST_AIX ?= manifests/dynatrace-bindplane-otel-collector/manifest-aix.yaml

# verify-manifest is the CI gate: regenerate sources from the manifest and
# compile them. Fails on any unresolvable component, missing replace, or
# version drift between sibling deps. Runs against every PR that touches
# the manifest or any sub-module.
.PHONY: verify-manifest
verify-manifest:
	@if [ ! -x "$(OCB)" ]; then \
		echo "ocb not found at $(OCB). Install with: make install-ocb"; \
		exit 1; \
	fi
	rm -rf $(BUILD_DIR)
	$(OCB) --config $(MANIFEST) --skip-compilation
	cp $(AGENT_MAIN) $(BUILD_DIR)/main.go
	rm -f $(BUILD_DIR)/main_others.go $(BUILD_DIR)/main_windows.go
	cd $(BUILD_DIR) && go mod tidy
	# Compile with the same build tags as the release build ($(AGENT_BUILD_TAGS))
	# so the gate exercises exactly what `make agent` ships.
	cd $(BUILD_DIR) && CGO_ENABLED=0 go build -tags "$(AGENT_BUILD_TAGS)" -o /dev/null .

# Builds the collector of the selected DISTRO for the current GOOS/GOARCH pair
# using ocb.
.PHONY: agent
agent:
	@if [ ! -x "$(OCB)" ]; then \
		echo "ocb not found at $(OCB). Install with: make install-ocb"; \
		exit 1; \
	fi
	$(OCB) --config $(MANIFEST) --skip-compilation
	cp $(AGENT_MAIN) $(BUILD_DIR)/main.go
	# Drop ocb's run/runInteractive helpers — our main.go owns startup.
	rm -f $(BUILD_DIR)/main_others.go $(BUILD_DIR)/main_windows.go
	cd $(BUILD_DIR) && go mod tidy
	cd $(BUILD_DIR) && CGO_ENABLED=0 go build -tags "$(AGENT_BUILD_TAGS)" -ldflags "$(AGENT_LDFLAGS)" -o ../$(OUTDIR)/$(AGENT_ARTIFACT)_$(GOOS)_$(GOARCH)$(EXT) .

.PHONY: collector
collector: agent

# Builds just the updater for current GOOS/GOARCH pair
.PHONY: updater
updater:
	cd ./updater/; CGO_ENABLED=0 go build -ldflags "$(UPDATER_LDFLAGS)" -o ../$(OUTDIR)/updater_$(GOOS)_$(GOARCH)$(EXT) ./cmd/updater

# Builds the container-init binary for current GOOS/GOARCH pair
.PHONY: container-init
container-init:
	cd ./cmd/container-init/; CGO_ENABLED=0 go build -ldflags "-s -w" -o ../../$(OUTDIR)/container-init_$(GOOS)_$(GOARCH)$(EXT) .

# Builds the updater + agent + container-init for current GOOS/GOARCH pair
# TODO: the slim build skips the updater until it can handle updates of the slim
# build, see the commented `updater` build in the slim .goreleaser.yml.
.PHONY: build-binaries
build-binaries: agent $(if $(filter slim,$(DISTRO)),,updater) container-init

.PHONY: build-all
build-all: build-linux build-darwin build-windows

# AIX builds from its own manifest and ships through manifests/dynatrace-bindplane-otel-collector/.goreleaser-aix.yml, so the
# main goreleaser before-hook builds every other platform with this target.
.PHONY: build-all-non-aix
build-all-non-aix: build-all

.PHONY: build-aix
build-aix: build-aix-ppc64

# Builds the AIX collector from the AIX manifest, plus the updater. AIX has no container-init.
.PHONY: build-aix-ppc64
build-aix-ppc64:
	CGO_ENABLED=0 GOOS=aix GOARCH=ppc64 $(MAKE) agent MANIFEST=$(MANIFEST_AIX)
	CGO_ENABLED=0 GOOS=aix GOARCH=ppc64 $(MAKE) updater

# Generates and compiles the AIX build the same way verify-manifest does for the main manifest.
.PHONY: verify-manifest-aix
verify-manifest-aix:
	GOOS=aix GOARCH=ppc64 $(MAKE) verify-manifest MANIFEST=$(MANIFEST_AIX)

# Checks that every component in the AIX manifest is in the main manifest at the same version
.PHONY: check-aix-manifest
check-aix-manifest:
	./scripts/check-aix-manifest.sh

# Checks the AIX feature gate skip list against the gates the AIX components register:
# every hardcoded gate is registered or skipped, and no skipped gate is registered.
.PHONY: check-aix-feature-gates
check-aix-feature-gates:
	rm -rf $(BUILD_DIR)
	$(OCB) --config $(MANIFEST_AIX) --skip-compilation
	cp $(AGENT_MAIN) $(BUILD_DIR)/main.go
	cp $(dir $(AGENT_MAIN))aix_feature_gates_test.go $(BUILD_DIR)/
	rm -f $(BUILD_DIR)/main_others.go $(BUILD_DIR)/main_windows.go
	cd $(BUILD_DIR) && go mod tidy
	cd $(BUILD_DIR) && CGO_ENABLED=0 go test -tags "aixgates $(AGENT_BUILD_TAGS)" -run TestAIXFeatureGates .

# Checks the slim feature gate skip list against the gates the slim components register:
# every hardcoded gate is registered or skipped, and no skipped gate is registered.
# Re-runs itself with DISTRO=slim so it uses the slim manifest, build dir and tags.
.PHONY: check-slim-feature-gates
check-slim-feature-gates:
ifneq ($(DISTRO),slim)
	$(MAKE) check-slim-feature-gates DISTRO=slim
else
	rm -rf $(BUILD_DIR)
	$(OCB) --config $(MANIFEST) --skip-compilation
	cp $(AGENT_MAIN) $(BUILD_DIR)/main.go
	cp $(dir $(AGENT_MAIN))slim_feature_gates_test.go $(BUILD_DIR)/
	rm -f $(BUILD_DIR)/main_others.go $(BUILD_DIR)/main_windows.go
	cd $(BUILD_DIR) && go mod tidy
	cd $(BUILD_DIR) && CGO_ENABLED=0 go test -tags "slimgates $(AGENT_BUILD_TAGS)" -run TestSlimFeatureGates .
endif

.PHONY: build-linux
build-linux: build-linux-amd64 build-linux-arm64 build-linux-arm build-linux-ppc64 build-linux-ppc64le

.PHONY: build-darwin
build-darwin: build-darwin-amd64 build-darwin-arm64

.PHONY: build-windows
build-windows: build-windows-amd64 build-windows-arm64

.PHONY: build-linux-ppc64
build-linux-ppc64:
	CGO_ENABLED=0 GOOS=linux GOARCH=ppc64 $(MAKE) build-binaries -j2

.PHONY: build-linux-ppc64le
build-linux-ppc64le:
	CGO_ENABLED=0 GOOS=linux GOARCH=ppc64le $(MAKE) build-binaries -j2

.PHONY: build-linux-amd64
build-linux-amd64:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(MAKE) build-binaries -j2

.PHONY: build-linux-arm64
build-linux-arm64:
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 $(MAKE) build-binaries -j2

.PHONY: build-linux-arm
build-linux-arm:
	CGO_ENABLED=0 GOOS=linux GOARCH=arm $(MAKE) build-binaries -j2

.PHONY: build-darwin-amd64
build-darwin-amd64:
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 $(MAKE) build-binaries -j2

.PHONY: build-darwin-arm64
build-darwin-arm64:
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 $(MAKE) build-binaries -j2

.PHONY: build-windows-amd64
build-windows-amd64:
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 $(MAKE) build-binaries -j2

.PHONY: build-windows-arm64
build-windows-arm64:
	CGO_ENABLED=0 GOOS=windows GOARCH=arm64 $(MAKE) build-binaries -j2

# Platforms the slim build is released for. Goreleaser's before hook in the slim
# config calls build-all-slim. Unlike the full build there is no windows/arm64
# binary: the slim Windows artifact is the amd64 zip only.
SLIM_RELEASE_PLATFORMS := linux-amd64 linux-arm64 linux-arm linux-ppc64 linux-ppc64le darwin-amd64 darwin-arm64 windows-amd64

.PHONY: build-all-slim
build-all-slim:
	$(MAKE) DISTRO=slim $(addprefix build-,$(SLIM_RELEASE_PLATFORMS))

# tool-related commands
.PHONY: install-tools
install-tools:
	cd $(TOOLS_MOD_DIR) && go install github.com/client9/misspell/cmd/misspell
	cd $(TOOLS_MOD_DIR) && go install github.com/google/addlicense
	cd $(TOOLS_MOD_DIR) && go install github.com/mgechev/revive
	cd $(TOOLS_MOD_DIR) && go install go.opentelemetry.io/collector/cmd/mdatagen
	cd $(TOOLS_MOD_DIR) && go install github.com/securego/gosec/v2/cmd/gosec
# update cosign in base-release.yml when updating this version
# update cosign in docs/verify-signature.md when updating this version
	go install github.com/sigstore/cosign/cmd/cosign@v1.13.1
	cd $(TOOLS_MOD_DIR) && go install github.com/uw-labs/lichen
	cd $(TOOLS_MOD_DIR) && go install github.com/vektra/mockery/v2
	cd $(TOOLS_MOD_DIR) && go install golang.org/x/tools/cmd/goimports
	cd $(TOOLS_MOD_DIR) && go install gotest.tools/gotestsum

# Fast install that checks if tools exist (for CI with cache)
.PHONY: install-tools-ci
install-tools-ci:
	@command -v misspell > /dev/null 2>&1 || (cd $(TOOLS_MOD_DIR) && go install github.com/client9/misspell/cmd/misspell)
	@command -v addlicense > /dev/null 2>&1 || (cd $(TOOLS_MOD_DIR) && go install github.com/google/addlicense)
	@command -v revive > /dev/null 2>&1 || (cd $(TOOLS_MOD_DIR) && go install github.com/mgechev/revive)
	@command -v mdatagen > /dev/null 2>&1 || (cd $(TOOLS_MOD_DIR) && go install go.opentelemetry.io/collector/cmd/mdatagen)
	@command -v gosec > /dev/null 2>&1 || (cd $(TOOLS_MOD_DIR) && go install github.com/securego/gosec/v2/cmd/gosec)
	@command -v cosign > /dev/null 2>&1 || go install github.com/sigstore/cosign/cmd/cosign@v1.13.1
	@command -v lichen > /dev/null 2>&1 || (cd $(TOOLS_MOD_DIR) && go install github.com/uw-labs/lichen)
	@command -v mockery > /dev/null 2>&1 || (cd $(TOOLS_MOD_DIR) && go install github.com/vektra/mockery/v2)
	@command -v goimports > /dev/null 2>&1 || (cd $(TOOLS_MOD_DIR) && go install golang.org/x/tools/cmd/goimports)
	@command -v gotestsum > /dev/null 2>&1 || (cd $(TOOLS_MOD_DIR) && go install gotest.tools/gotestsum)

.PHONY: lint
lint:
	revive -config revive/config.toml -formatter friendly ./...

.PHONY: misspell
misspell:
	misspell -error $(ALLDOC)

.PHONY: misspell-fix
misspell-fix:
	misspell -w $(ALLDOC)

# TEMPORARY: E2E_UNADAPTED_MODULES are skipped until their go.mod matches the repo Go version.
.PHONY: test
test:
	@if [ -n "$$(go list ./... 2>/dev/null)" ]; then \
		echo "running tests in root"; \
		gotestsum --rerun-fails --packages="./..." -- -race; \
	fi
	@set -e; for dir in $(ALL_MODULES); do \
		if [ "$${dir}" = "." ]; then continue; fi; \
		case " $(E2E_MODULES) " in *" $${dir} "*) continue ;; esac; \
		case " $(E2E_UNADAPTED_MODULES) " in *" $${dir} "*) continue ;; esac; \
		(cd "$${dir}" && \
			echo "running tests in $${dir}" && \
			gotestsum --rerun-fails --packages="./..." -- -race) || exit 1; \
	done

.PHONY: test-no-race
test-no-race:
	$(MAKE) for-all SKIP_MODULES="$(E2E_MODULES)" CMD="gotestsum --rerun-fails --packages="./..." "

.PHONY: test-with-cover
test-with-cover:
	$(MAKE) for-all SKIP_MODULES="$(E2E_MODULES)" CMD="go test -coverprofile=cover.out ./..."
	$(MAKE) for-all SKIP_MODULES="$(E2E_MODULES)" CMD="go tool cover -html=cover.out -o cover.html"

# Fetches the config examples the e2e tests run against from the
# dynatrace-otel-collector repo. DTOC_REF defaults to main; set it to a commit
# SHA or tag to pin the examples, e.g. if they drift from the tests copied into
# internal/testbed.
DTOC_REPO ?= https://github.com/Dynatrace/dynatrace-otel-collector.git
DTOC_REF ?= main
E2E_CONFIG_EXAMPLES_DIR := internal/testbed/config_examples

.PHONY: e2e-config-examples
e2e-config-examples:
	@set -e; tmp=$$(mktemp -d); trap 'rm -rf "$$tmp"' EXIT; \
	git -C "$$tmp" init -q; \
	git -C "$$tmp" remote add origin "$(DTOC_REPO)"; \
	git -C "$$tmp" sparse-checkout set config_examples; \
	git -C "$$tmp" fetch -q --depth 1 --filter=blob:none origin "$(DTOC_REF)"; \
	git -C "$$tmp" checkout -q FETCH_HEAD; \
	rm -rf $(E2E_CONFIG_EXAMPLES_DIR); \
	cp -R "$$tmp/config_examples" $(E2E_CONFIG_EXAMPLES_DIR); \
	echo "Fetched config_examples from $(DTOC_REPO) at $(DTOC_REF) into $(E2E_CONFIG_EXAMPLES_DIR)"

# Builds the e2e container images from the linux binaries in dist/ (run
# `GOOS=linux GOARCH=<arch> make agent` first). The tests expect these tags.
E2E_IMAGE_ARCH ?= $(shell go env GOARCH)
.PHONY: e2e-images
e2e-images:
	docker build --platform linux/$(E2E_IMAGE_ARCH) --build-arg TARGETARCH=$(E2E_IMAGE_ARCH) \
		-t dynatrace-bindplane-otel-collector:e2e-test -f internal/testbed/docker/Dockerfile ./dist
	docker build --platform linux/$(E2E_IMAGE_ARCH) --build-arg TARGETARCH=$(E2E_IMAGE_ARCH) \
		-t dynatrace-bindplane-otel-collector-journald:e2e-test -f internal/testbed/docker/Dockerfile-journald ./dist

.PHONY: test-updater-integration
test-updater-integration:
	cd updater; gotestsum --rerun-fails --packages="./..." -- \
		$(INTEGRATION_TEST_ARGS) -race

.PHONY: bench
bench:
	$(MAKE) for-all SKIP_MODULES="$(E2E_MODULES)" CMD="go test -benchmem -run=^$$ -bench ^* ./..."

.PHONY: check-fmt
check-fmt:
	goimports -d ./ | diff -u /dev/null -

.PHONY: fmt
fmt:
	goimports -w .

.PHONY: tidy
tidy:
	$(MAKE) for-all-modules CMD="go mod tidy -compat=1.26.10"

.PHONY: gosec
gosec:
	@set -e; for dir in $(ALL_MODULES); do \
		case "$${dir}" in \
			"."|"./updater"|"./internal/tools"|"./cmd/plugindocgen") continue;; \
		esac; \
		(cd "$${dir}" && \
			echo "running gosec in $${dir}" && \
			gosec ./...) || exit 1; \
	done
# exclude the testdata dir; it contains a go program for testing.
	cd updater; gosec -exclude-dir internal/service/testdata ./...

# This target performs all checks that CI will do (excluding the build itself)
.PHONY: ci-checks
ci-checks: check-fmt check-license check-mod-paths check-dependabot misspell lint gosec test

# This target checks that every go.mod has the correct module path.
# Root must be github.com/dynatrace/dynatrace-bindplane-otel-collector.
# Subdirectories must be github.com/dynatrace/dynatrace-bindplane-otel-collector/<relative-path>.
# Modules with legacy paths that cannot be renamed are excluded.
MOD_PATH_EXCLUDES := ./cmd/plugindocgen
.PHONY: check-mod-paths
check-mod-paths:
	@FAILED=0; \
	for dir in $(ALL_MODULES); do \
		case " $(MOD_PATH_EXCLUDES) " in *" $${dir} "*) continue ;; esac; \
		MOD=$$(head -1 "$${dir}/go.mod" | sed 's/^module //'); \
		if [ "$${dir}" = "." ]; then \
			EXPECTED="github.com/dynatrace/dynatrace-bindplane-otel-collector"; \
		else \
			RELPATH=$$(echo "$${dir}" | sed 's|^\./||'); \
			EXPECTED="github.com/dynatrace/dynatrace-bindplane-otel-collector/$${RELPATH}"; \
		fi; \
		if [ "$${MOD}" != "$${EXPECTED}" ]; then \
			echo "MISMATCH: $${dir}/go.mod"; \
			echo "  got:      $${MOD}"; \
			echo "  expected: $${EXPECTED}"; \
			FAILED=1; \
		fi; \
	done; \
	if [ "$${FAILED}" -eq 1 ]; then \
		echo ""; \
		echo "check-mod-paths FAILED: module paths must match directory structure."; \
		exit 1; \
	else \
		echo "Check module paths finished successfully"; \
	fi

# This target checks that every directory with a go.mod has an entry in dependabot.yml
.PHONY: check-dependabot
check-dependabot:
	@FAILED=0; \
	DEPENDABOT_DIRS=$$(grep 'directory:' .github/dependabot.yml | sed 's/.*directory: *"\(.*\)"/\1/'); \
	for dir in $(ALL_MODULES); do \
		if [ "$${dir}" = "." ]; then \
			EXPECTED="/"; \
		else \
			EXPECTED=$$(echo "$${dir}" | sed 's|^\./|/|'); \
		fi; \
		if ! echo "$${DEPENDABOT_DIRS}" | grep -qx "$${EXPECTED}"; then \
			echo "MISSING: $${dir}/go.mod has no entry in .github/dependabot.yml (expected directory: \"$${EXPECTED}\")"; \
			FAILED=1; \
		fi; \
	done; \
	if [ "$${FAILED}" -eq 1 ]; then \
		echo ""; \
		echo "check-dependabot FAILED: add missing entries to .github/dependabot.yml"; \
		exit 1; \
	else \
		echo "Check dependabot finished successfully"; \
	fi

# This target lints the unix install scripts and runs their tests
# Runs in CI rather than ci-checks, since the tests need rpm, gpg, and the de_DE.UTF-8 locale
# with gpg's German translations.
.PHONY: check-install-scripts
check-install-scripts:
	shellcheck -S warning scripts/install/install_unix.sh scripts/install/install_macos.sh scripts/install/test/*.sh scripts/install/test/testdata/*.sh
	sh scripts/install/test/run_tests.sh

.PHONY: check-support-scripts
check-support-scripts:
	shellcheck -s sh -S warning scripts/support/create-support-bundle.sh scripts/support/test/*.sh
	sh scripts/support/test/run_tests.sh

# This target checks that license copyright header is on every source file
.PHONY: check-license
check-license:
	@ADDLICENSEOUT=`addlicense -check $(ALL_SRC) 2>&1`; \
		if [ "$$ADDLICENSEOUT" ]; then \
			echo "addlicense FAILED => add License errors:\n"; \
			echo "$$ADDLICENSEOUT\n"; \
			echo "Use 'make add-license' to fix this."; \
			exit 1; \
		else \
			echo "Check License finished successfully"; \
		fi

# This target adds a license copyright header is on every source file that is missing one
.PHONY: add-license
add-license:
	@ADDLICENSEOUT=`addlicense -y "" -c "Dynatrace LLC" $(ALL_SRC) 2>&1`; \
		if [ "$$ADDLICENSEOUT" ]; then \
			echo "addlicense FAILED => add License errors:\n"; \
			echo "$$ADDLICENSEOUT\n"; \
			exit 1; \
		else \
			echo "Add License finished successfully"; \
		fi

# update-otel attempts to update otel dependencies in go.mods,
# and update the otel versions in the docs and all manifests.
# Usage: make update-otel OTEL_VERSION=vx.x.x CONTRIB_VERSION=vx.x.x PDATA_VERSION=vx.x.x-rcx DBDOT_CONTRIB_VERSION=vx.x.x CONTRIB_STABLE_VERSION=vx.x.x
.PHONY: update-otel
update-otel:
	./scripts/update-otel.sh "$(OTEL_VERSION)" "$(CONTRIB_VERSION)" "$(PDATA_VERSION)" "$(CONTRIB_STABLE_VERSION)"
	./scripts/update-docs.sh "$(OTEL_VERSION)" "$(CONTRIB_VERSION)" "$(DBDOT_CONTRIB_VERSION)" "$(CONTRIB_STABLE_VERSION)"
	OTEL_VERSION="$(OTEL_VERSION)" CONTRIB_VERSION="$(CONTRIB_VERSION)" PDATA_VERSION="$(PDATA_VERSION)" CONTRIB_STABLE_VERSION="$(CONTRIB_STABLE_VERSION)" DBDOT_CONTRIB_VERSION="$(DBDOT_CONTRIB_VERSION)" ./scripts/update-manifest.sh
	$(MAKE) tidy
# Double make tidy - this unfortunately is needed due to the order in which modules are tidied.
# The modules this seems to effect are plugindocgen and bindplaneextension
	$(MAKE) tidy

# update-modules updates all submodules, and the in-tree module lines of all manifests, to be the new version.
# Usage: make update-modules NEW_VERSION=vx.x.x
.PHONY: update-modules
update-modules:
	./scripts/update-module-version.sh "$(NEW_VERSION)"
	MODULE_VERSION="$(NEW_VERSION)" ./scripts/update-manifest.sh
	$(MAKE) tidy

# update-contrib updates all bindplane-otel-contrib dependencies, in go.mods, all manifests and the doc links, to the new version.
# Usage: make update-contrib DBDOT_CONTRIB_VERSION=vx.x.x
.PHONY: update-contrib
update-contrib:
	./scripts/update-dbdot-contrib.sh "$(DBDOT_CONTRIB_VERSION)"
	DBDOT_CONTRIB_VERSION="$(DBDOT_CONTRIB_VERSION)" ./scripts/update-manifest.sh
	sed -i '' -E 's#(dynatrace-bindplane-otel-contrib/(blob|tree)/)[^/]*#\1$(DBDOT_CONTRIB_VERSION)#g' docs/*.md
	$(MAKE) tidy

# Downloads and setups dependencies that are packaged with binary. The launchd
# plist follows the selected DISTRO. The Windows service definition is only
# needed by the full build's MSI and archives.
.PHONY: release-prep
release-prep:
	@rm -rf release_deps
	@mkdir release_deps
	@echo 'v$(CURR_VERSION)' > release_deps/VERSION.txt
	./buildscripts/download-dependencies.sh release_deps
	@cp -r ./plugins release_deps/
	@cp config/example.yaml release_deps/config.yaml
	@cp config/logging.yaml release_deps/logging.yaml
	@cp $(PLIST_SRC) release_deps/$(notdir $(PLIST_SRC))
	@if [ "$(DISTRO)" = "full" ]; then jq ".files[] | select(.service != null)" windows/wix.json >> release_deps/windows_service.json; fi

# Downloads and sets up the dependencies packaged with the AIX binaries
.PHONY: release-prep-aix
release-prep-aix:
	@rm -rf release_deps
	@mkdir release_deps
	@echo 'v$(CURR_VERSION)' > release_deps/VERSION.txt
	./buildscripts/download-dependencies.sh release_deps
	@cp -r ./plugins release_deps/
	@cp config/example.yaml release_deps/config.yaml
	@cp config/logging.yaml release_deps/logging.yaml
	@cp service/dynatrace-bindplane-otel-collector.env release_deps/dynatrace-bindplane-otel-collector.env
	@cp -r ./signature/gpg release_deps/gpg
	@rm release_deps/gpg/revocations.md
	@rm release_deps/gpg/deb-revocations/.keep
	@cd release_deps/gpg && tar -czf ../gpg-keys.tar.gz .

.PHONY: release-prep-gpg
release-prep-gpg:
	$(MAKE) release-prep
	@cp -r ./signature/gpg release_deps/gpg
	@rm release_deps/gpg/revocations.md
	@rm release_deps/gpg/deb-revocations/.keep
	@cd release_deps/gpg && tar -czf ../gpg-keys.tar.gz .

# Build and sign, skip release and ignore dirty git tree
.PHONY: release-test
release-test:
# The full build also publishes the MSIs. If there are none in the root dir, we'll create dummy ones so that goreleaser can complete successfully
	@if [ "$(DISTRO)" = "full" ]; then \
		if [ ! -e "./dynatrace-bindplane-otel-collector-amd64.msi" ]; then touch ./dynatrace-bindplane-otel-collector-amd64.msi; fi; \
		if [ ! -e "./dynatrace-bindplane-otel-collector-arm64.msi" ]; then touch ./dynatrace-bindplane-otel-collector-arm64.msi; fi; \
	fi
# The full release lists the AIX package in its SHA256SUMS, so AIX builds first. The slim build has no AIX package.
	@if [ "$(DISTRO)" = "full" ]; then \
		$(MAKE) release-test-aix && rm -rf aix-dist && mkdir aix-dist && cp dist/*.tar.gz aix-dist/; \
	fi
	SIGNING_KEY_FILE="fake-file" GORELEASER_CURRENT_TAG=$(SNAPSHOT_TAG) goreleaser release --parallelism 4 --timeout $(GORELEASER_TIMEOUT) --skip=publish --skip=validate --skip=sign $(if $(RELEASE_TEST_SKIP),--skip=$(RELEASE_TEST_SKIP)) --clean --snapshot --config $(GORELEASER_DIR)/.goreleaser.yml

# Build AIX, skip release and signing, and ignore a dirty git tree
.PHONY: release-test-aix
release-test-aix:
	GORELEASER_CURRENT_TAG=$(SNAPSHOT_TAG) goreleaser release --config manifests/dynatrace-bindplane-otel-collector/.goreleaser-aix.yml --parallelism 4 --timeout $(GORELEASER_TIMEOUT) --skip=publish --skip=validate --skip=sign --clean --snapshot

.PHONY: release-containers-test
release-containers-test:
	$(MAKE) -j3 agent-linux-amd64 agent-linux-arm64 agent-linux-ppc64le
	mkdir -p tmp
	mv ./dist/collector_linux_amd64 ./tmp/collector_linux_amd64
	mv ./dist/collector_linux_arm64 ./tmp/collector_linux_arm64
	mv ./dist/collector_linux_ppc64le ./tmp/collector_linux_ppc64le
	GORELEASER_CURRENT_TAG=$(SNAPSHOT_TAG) goreleaser release --parallelism 4 --timeout $(GORELEASER_TIMEOUT) --skip=publish --skip=validate --skip=sign --clean --snapshot --config $(GORELEASER_DIR)/.goreleaser-docker.yml

.PHONY: agent-linux-amd64 agent-linux-arm64 agent-linux-arm agent-linux-ppc64 agent-linux-ppc64le
agent-linux-amd64:
	GOARCH=amd64 GOOS=linux $(MAKE) agent
agent-linux-arm64:
	GOARCH=arm64 GOOS=linux $(MAKE) agent
agent-linux-arm:
	GOARCH=arm GOOS=linux $(MAKE) agent
agent-linux-ppc64:
	GOARCH=ppc64 GOOS=linux $(MAKE) agent
agent-linux-ppc64le:
	GOARCH=ppc64le GOOS=linux $(MAKE) agent

.PHONY: agent-darwin-amd64 agent-darwin-arm64
agent-darwin-amd64:
	GOARCH=amd64 GOOS=darwin $(MAKE) agent
agent-darwin-arm64:
	GOARCH=arm64 GOOS=darwin $(MAKE) agent

# build-all-agent builds only the collector binary (no updater) for every
# release platform. Keep this list in sync with build-all.
.PHONY: build-all-agent
build-all-agent: agent-linux-amd64 agent-linux-arm64 agent-linux-arm agent-linux-ppc64 agent-linux-ppc64le agent-darwin-amd64 agent-darwin-arm64 agent-windows-amd64 agent-windows-arm64

# agent-clean wipes the ocb-generated output tree of the selected DISTRO
# (BUILD_DIR). The ocb step is platform-agnostic Go-source generation, so
# subsequent platform builds reuse the generated tree until you clean it.
.PHONY: agent-clean
agent-clean:
	rm -rf $(BUILD_DIR) ./builder

.PHONY: agent-windows-amd64 agent-windows-arm64
agent-windows-amd64:
	GOARCH=amd64 GOOS=windows $(MAKE) agent
agent-windows-arm64:
	GOARCH=arm64 GOOS=windows $(MAKE) agent


build-single:
	$(MAKE)
	SIGNING_KEY_FILE="fake-file" GORELEASER_CURRENT_TAG=$(SNAPSHOT_TAG) goreleaser release --timeout $(GORELEASER_TIMEOUT) --skip=publish --skip=sign --clean --skip=validate --snapshot --single-target --config $(GORELEASER_DIR)/.goreleaser.yml

.PHONY: release-test-single
release-test-single:
	GORELEASER_CURRENT_TAG=$(SNAPSHOT_TAG) goreleaser release -f $(GORELEASER_DIR)/.goreleaser.arm64.yml --timeout $(GORELEASER_TIMEOUT) --skip=publish --clean --skip=validate --snapshot

.PHONY: for-all
for-all:
	@if [ -n "$$(go list ./... 2>/dev/null)" ]; then \
		echo "running $${CMD} in root"; \
		$${CMD}; \
	fi
	@set -e; for dir in $(ALL_MODULES); do \
	  if [ "$${dir}" = "." ]; then continue; fi; \
	  case " $${SKIP_MODULES} " in *" $${dir} "*) continue ;; esac; \
	  (cd "$${dir}" && \
	    echo "running $${CMD} in $${dir}" && \
	    $${CMD} ); \
	done

.PHONY: for-all-modules
for-all-modules:
	@set -e; for dir in $(ALL_MODULES); do \
	  if [ "$${dir}" = "." ]; then continue; fi; \
	  (cd "$${dir}" && \
	    echo "running $${CMD} in $${dir}" && \
	    $${CMD} ); \
	done

# Release a new version of the agent. This will also tag all submodules, except for
# RC versions (vX.Y.Z-rc.N) which only tag the root.
.PHONY: release
release:
	@if [ -z "$(version)" ]; then \
		echo "version was not set"; \
		exit 1; \
	fi
	@if ! echo "$(version)" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+(-rc\.[0-9]+)?$$'; then \
		echo "version $(version) is invalid semver (expected vX.Y.Z or vX.Y.Z-rc.N)"; \
		exit 1; \
	fi
	# Tag the root and every module, then push only those tags. A checkout of
	# this fork carries thousands of tags inherited from upstream; `git push
	# --tags` would push all of them. RC versions release the slim build only,
	# which needs no module tags, so only the root is tagged for them.
	@set -e; tags="$(version)"; git tag "$(version)"; \
	for dir in $(ALL_MODULES); do \
		if echo "$(version)" | grep -q -- '-rc\.'; then break; fi; \
		if [ "$${dir}" = "." ]; then continue; fi; \
		case " $(UNRELEASED_MODULES) " in *" $${dir} "*) continue ;; esac; \
		tag="$${dir#./}/$(version)"; \
		git tag "$${tag}"; \
		tags="$${tags} $${tag}"; \
	done; \
	git push origin $${tags}

.PHONY: clean
clean:
	rm -rf $(OUTDIR)

.PHONY: scan-licenses
scan-licenses:
	lichen --config=./license.yaml $$(find dist/collector_* dist/updater_*)

.PHONY: generate
generate:
	$(MAKE) for-all CMD="go generate ./..."
	$(MAKE) fmt

.PHONY: create-plugin-docs
create-plugin-docs:
	cd cmd/plugindocgen; go run .
