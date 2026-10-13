#!/usr/bin/env bash
# Copyright Dynatrace LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# validate-manifest-versions.test.sh — the one runnable check for the
# validator: the real manifest passes, and three variants derived from it with
# sed fail naming the manifest and bucket (a contrib straggler, an OCB_VERSION
# mismatch, a half-bumped fork replace).
#
# Usage: ./scripts/validate-manifest-versions.test.sh   (or make validate-manifest-versions-test)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

validator=./scripts/validate-manifest-versions.sh
manifest=${MANIFEST:-manifests/dynatrace-bindplane-otel-collector/manifest.yaml}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cp "$manifest" "$tmp/manifest.yaml"
cp Makefile "$tmp/Makefile"
core=$(awk '/^OCB_VERSION \?= / { print $3 }' Makefile)

# run <want-exit> <want-output-regex> <name> <manifest> <makefile>
run() {
  local out got=0
  out=$(MANIFESTS="$4" MAKEFILE="$5" "$validator" 2>&1) || got=$?
  if [ "$got" -ne "$1" ] || ! grep -qE "$2" <<<"$out"; then
    printf 'FAIL %s: exit %s (want %s, output matching /%s/), got:\n%s\n' "$3" "$got" "$1" "$2" "$out" >&2
    exit 1
  fi
  echo "ok   $3"
}
# derive <file> <sed-expr> <source>: write $tmp/<file>, refusing an edit that matched nothing.
derive() {
  sed "$2" "$3" >"$tmp/$1"
  if cmp -s "$3" "$tmp/$1"; then
    echo "FAIL $1: sed matched nothing in $3; the fixture has moved, update this test" >&2
    exit 1
  fi
}

run 0 "contrib-v0 $core \(" "real manifest passes" "$tmp/manifest.yaml" "$tmp/Makefile"

derive straggler.yaml "s|\(opentelemetry-collector-contrib/receiver/filelogreceiver\) $core|\1 v0.1.0|" "$tmp/manifest.yaml"
run 1 "straggler.yaml: bucket contrib-v0 " "contrib straggler fails" "$tmp/straggler.yaml" "$tmp/Makefile"

derive Makefile.mismatch "s|^OCB_VERSION ?= .*|OCB_VERSION ?= v0.0.1|" "$tmp/Makefile"
run 1 "manifest.yaml: bucket core-v0 is $core but OCB_VERSION" "OCB_VERSION mismatch fails" "$tmp/manifest.yaml" "$tmp/Makefile.mismatch"

derive halfbump.yaml "/dt-otelcol-edge-processing-components\/exporter\/dtedgeprocessingexporter => / s| v[^ ]*$| v0.0.0-19700101000000-000000000000|" "$tmp/manifest.yaml"
run 1 "halfbump.yaml: replaces into github.com/Dynatrace/dt-otelcol-edge-processing-components " "half-bumped fork replace fails" "$tmp/halfbump.yaml" "$tmp/Makefile"
