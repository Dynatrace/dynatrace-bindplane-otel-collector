#!/usr/bin/env bash
# Copyright  Dynatrace LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Bundles the release artifacts into tarballs that get attached to the release.
#
# Produces, in the current directory:
#   <product>-<version>-artifacts-linux.tar.gz    Linux only
#   <product>-<version>-artifacts-darwin.tar.gz   macOS only
#   <product>-<version>-artifacts-windows.tar.gz  Windows only
#   <product>-<version>-artifacts-aix.tar.gz      AIX only
#
# Bindplane merges per-platform bundles uploaded for the same version, so each
# bundle is self-contained: it carries every artifact for its platforms, the
# full SHA256SUMS file, and gpg-keys.tar.gz. Verify a per-platform bundle's
# contents with `sha256sum -c --ignore-missing`.
#
# Usage: create-artifact-bundles.sh <version> [product]
#
# product is the prefix of the bundle names and defaults to
# dynatrace-bindplane-otel-collector.
#
# Run from the repository root after goreleaser has populated ./dist, the
# MSIs have been downloaded to the root, and the AIX packages to ./aix-dist.
# Without an ./aix-dist there are no AIX packages and no AIX bundle.
#
# BUNDLE_INSTALLERS (default true) controls whether the install scripts and the
# MSIs are bundled. Builds that ship neither, like the slim build, set it to
# false. apk packages are bundled when goreleaser produced any.

set -euo pipefail

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "usage: $0 <version> [product]" >&2
  exit 1
fi

version="$1"
product="${2:-dynatrace-bindplane-otel-collector}"
prefix="${product}-${version}"

# Fail on a glob that matches nothing rather than copying the literal pattern.
shopt -s failglob

# bundle <label> <file>... tars the given files into <prefix>-<label>.tar.gz.
bundle() {
  local label="$1"
  shift
  local dir="bundle-${label}"
  rm -rf "$dir"
  mkdir "$dir"
  cp "$@" "$dir"
  tar -czvf "${prefix}-${label}.tar.gz" -C "$dir" .
}

# Files every bundle needs, regardless of platform.
common=(
  ./release_deps/gpg-keys.tar.gz
  ./dist/*SHA256SUMS
)

# Optional files. These are not allowed to fail the run when missing, so they
# are collected with failglob off and nullglob on.
shopt -u failglob
shopt -s nullglob
apks=(./dist/*.apk)
aix=(./aix-dist/*)
shopt -u nullglob
shopt -s failglob

installers_all=()
installers_unix=()
installers_macos=()
installers_windows=()
msis=()
if [ "${BUNDLE_INSTALLERS:-true}" = "true" ]; then
  installers_all=(./scripts/install/*.sh ./scripts/install/*.ps1)
  installers_unix=(./scripts/install/install_unix.sh)
  installers_macos=(./scripts/install/install_macos.sh)
  installers_windows=(./scripts/install/install_windows.ps1)
  msis=(
    ./dynatrace-bindplane-otel-collector-amd64.msi
    ./dynatrace-bindplane-otel-collector-arm64.msi
  )
fi

# "${arr[@]+"${arr[@]}"}" expands an empty array to nothing under set -u on
# every bash version.
bundle artifacts-linux \
  "${common[@]}" \
  ${installers_unix[@]+"${installers_unix[@]}"} \
  ./dist/*-linux-*.tar.gz \
  ./dist/*.rpm \
  ./dist/*.deb \
  ${apks[@]+"${apks[@]}"}

bundle artifacts-darwin \
  "${common[@]}" \
  ${installers_macos[@]+"${installers_macos[@]}"} \
  ./dist/*-darwin-*.tar.gz

bundle artifacts-windows \
  "${common[@]}" \
  ${installers_windows[@]+"${installers_windows[@]}"} \
  ${msis[@]+"${msis[@]}"} \
  ./dist/*-windows-*.zip

# Builds without AIX packages, like the slim build, have no AIX bundle.
if [ "${#aix[@]}" -gt 0 ]; then
  bundle artifacts-aix \
    "${common[@]}" \
    ./scripts/install/install_unix.sh \
    "${aix[@]}"
fi
