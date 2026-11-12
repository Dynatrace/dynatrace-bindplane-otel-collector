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

# Tests for check-tag-version.sh. Run from anywhere: scripts/ci/check-tag-version_test.sh

set -uo pipefail

script="$(cd "$(dirname "$0")" && pwd)/check-tag-version.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/manifest.yaml" <<'YAML'
dist:
  name: example
  module: example.com/build
  version: 1.2.3 # comment
  output_path: ./build

extensions:
  - gomod: example.com/ext v9.9.9
YAML

cat > "$tmp/no-version.yaml" <<'YAML'
dist:
  name: example
other:
  version: 1.2.3
YAML

failures=0

# expect <expected exit code> <description> <args...>
expect() {
  local want="$1" desc="$2"
  shift 2
  "$script" "$@" >/dev/null 2>&1
  local got=$?
  if [ "$got" -ne "$want" ]; then
    echo "FAIL: $desc (want exit $want, got $got)"
    failures=$((failures + 1))
  else
    echo "ok:   $desc"
  fi
}

expect 0 "exact: matching tag"            v1.2.3        "$tmp/manifest.yaml" exact
expect 1 "exact: patch mismatch"          v1.2.4        "$tmp/manifest.yaml" exact
expect 1 "exact: RC tag is not exact"     slim/v1.2.3-rc.1  "$tmp/manifest.yaml" exact
expect 0 "core: matching RC tag"          slim/v1.2.3-rc.1  "$tmp/manifest.yaml" core
expect 0 "core: later RC of same version" slim/v1.2.3-rc.12 "$tmp/manifest.yaml" core
expect 0 "core: plain tag also matches"   v1.2.3            "$tmp/manifest.yaml" core
expect 1 "core: RC of other version"      slim/v1.2.4-rc.1  "$tmp/manifest.yaml" core
expect 1 "invalid tag: RC without prefix" v1.2.3-rc.1       "$tmp/manifest.yaml" core
expect 1 "invalid tag: prefix without RC" slim/v1.2.3       "$tmp/manifest.yaml" core
expect 1 "invalid tag: no v prefix"       1.2.3         "$tmp/manifest.yaml" exact
expect 1 "invalid tag: other suffix"      v1.2.3-beta.1 "$tmp/manifest.yaml" core
expect 1 "invalid tag: submodule tag"     extension/opampconnectionextension/v1.2.3 "$tmp/manifest.yaml" exact
expect 2 "unknown mode"                   v1.2.3        "$tmp/manifest.yaml" fuzzy
expect 2 "missing manifest"               v1.2.3        "$tmp/missing.yaml" exact
expect 2 "version only outside dist"      v1.2.3        "$tmp/no-version.yaml" exact
expect 2 "wrong argument count"           v1.2.3

if [ "$failures" -ne 0 ]; then
  echo "$failures test(s) failed"
  exit 1
fi
echo "all tests passed"
