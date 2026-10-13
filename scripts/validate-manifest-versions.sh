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

# validate-manifest-versions.sh — fail when an ocb manifest carries inconsistent
# component versions, or when the Makefile's OCB_VERSION drifts from the
# manifest's core version. Dependency-free (bash, awk, sort, uniq) and written
# for BSD and GNU tools alike, so it runs on a developer mac and on ubuntu.
#
# Only `- gomod:` lines under extensions/exporters/processors/receivers/
# connectors/providers are bucketed, by module-path prefix. The match is
# case-sensitive: github.com/dynatrace/ and github.com/Dynatrace/ are different
# orgs.
#   core-v0, core-v1         go.opentelemetry.io/collector/
#   contrib-v0, contrib-v1   github.com/open-telemetry/opentelemetry-collector-contrib/
#   bindplane-contrib        github.com/dynatrace/dynatrace-bindplane-otel-contrib/
#   dt-edge                  github.com/Dynatrace/dt-otelcol-edge-processing-components/
#   internal                 github.com/dynatrace/dynatrace-bindplane-otel-collector/
# Anything else (third-party components) is ignored.
#
# Rules; every violation names the manifest, the bucket and the versions found:
#   1. Every bucket has at most one distinct version per manifest.
#   2. OCB_VERSION in the Makefile equals every manifest's core-v0 version.
#   3. dt-edge equals core-v0 in the same manifest. The gomod version on the DT
#      edge components is a convention marker: the replace pseudo-version wins
#      at build time and is never compared. Delete this rule if those
#      components ever get their own version line.
#   4. Under replaces:, entries whose right-hand side points into the same
#      module root (first three path segments) share one version string, so a
#      half-bumped fork fails. Local-path replaces and single-member groups are
#      skipped.
# Each manifest is validated on its own; nothing is pooled across manifests.
#
# Usage: ./scripts/validate-manifest-versions.sh [manifest...]   (from the repo root)
# Env:   MANIFESTS  space-separated manifests (default manifests/*/manifest.yaml)
#        MAKEFILE   where to read OCB_VERSION from (default Makefile)
set -euo pipefail

# Modules exempt from rule 1, one module path per line, each with its reason.
EXEMPT='
# Removed upstream in v0.157.0; frozen at v0.156.0 and fork-replaced (see replaces:).
github.com/open-telemetry/opentelemetry-collector-contrib/receiver/jmxreceiver
'

MAKEFILE="${MAKEFILE:-Makefile}"
if [ "$#" -gt 0 ]; then
  manifests=("$@")
elif [ -n "${MANIFESTS:-}" ]; then
  read -r -a manifests <<<"$MANIFESTS"
else
  shopt -s nullglob
  manifests=(manifests/*/manifest.yaml)
  shopt -u nullglob
fi
[ "${#manifests[@]}" -gt 0 ] || { echo "error: no manifests given (MANIFESTS or arguments)" >&2; exit 2; }
for m in "${manifests[@]}"; do
  [ -f "$m" ] || { echo "error: manifest not found: $m" >&2; exit 2; }
done
ocb_version=$(awk '/^OCB_VERSION \?= / { print $3 }' "$MAKEFILE")
[ -n "$ocb_version" ] || { echo "error: OCB_VERSION not found in $MAKEFILE" >&2; exit 2; }

# Bucketing: one awk pass over the manifests, emitting tab-separated records.
#   G <manifest> <bucket> <module> <version>        component gomod entries
#   R <manifest> <root> <replaced-module> <version>  versioned replaces, keyed by RHS module root
records=$(mktemp)
trap 'rm -f "$records"' EXIT
# EXEMPT goes through the environment: BSD awk rejects a -v value with newlines.
EXEMPT="$EXEMPT" awk '
  function bucket(mod, ver,   v) {
    split(ver, v, ".")
    if (mod ~ /^go\.opentelemetry\.io\/collector\//) return "core-" v[1]
    if (mod ~ /^github\.com\/open-telemetry\/opentelemetry-collector-contrib\//) return "contrib-" v[1]
    if (mod ~ /^github\.com\/dynatrace\/dynatrace-bindplane-otel-contrib\//) return "bindplane-contrib"
    if (mod ~ /^github\.com\/Dynatrace\/dt-otelcol-edge-processing-components\//) return "dt-edge"
    if (mod ~ /^github\.com\/dynatrace\/dynatrace-bindplane-otel-collector\//) return "internal"
    return ""
  }
  BEGIN {
    n = split(ENVIRON["EXEMPT"], line, "\n")
    for (i = 1; i <= n; i++) if (line[i] != "" && line[i] !~ /^#/) skip[line[i]] = 1
  }
  /^[A-Za-z_]+:/ { section = $1; sub(/:$/, "", section); next }
  $1 != "-" { next }
  section ~ /^(extensions|exporters|processors|receivers|connectors|providers)$/ && $2 == "gomod:" && !($3 in skip) {
    b = bucket($3, $4)
    if (b != "") print "G\t" FILENAME "\t" b "\t" $3 "\t" $4
  }
  section == "replaces" && $3 == "=>" && $5 != "" {
    split($4, p, "/")
    print "R\t" FILENAME "\t" p[1] "/" p[2] "/" p[3] "\t" $2 "\t" $5
  }
' "${manifests[@]}" >"$records"

violations=0
fail() { echo "FAIL $*" >&2; violations=$((violations + 1)); }
# rec <type> <manifest> [<key>]: records of that type for that manifest, optionally filtered on field 3.
rec() { awk -F'\t' -v t="$1" -v m="$2" -v k="${3:-}" '$1 == t && $2 == m && (k == "" || $3 == k)' "$records"; }
# versions <manifest> <bucket>: distinct versions in the bucket, most common first.
versions() { rec G "$1" "$2" | cut -f5 | sort | uniq -c | sort -rn | awk '{ print $2 }'; }
join() { awk '{ printf "%s%s", (NR > 1 ? ", " : ""), $0 }'; }

for m in "${manifests[@]}"; do
  echo "$m: $(rec G "$m" | cut -f3,5 | sort | uniq -c | awk '{ print $2 " " $3 " (" $1 ")" }' | join)"
  core=$(versions "$m" core-v0 | head -n1)

  # Rule 1: one version per bucket.
  for b in $(rec G "$m" | cut -f3 | sort -u); do
    found=$(versions "$m" "$b")
    if [ "$(echo "$found" | wc -l)" -gt 1 ]; then
      fail "$m: bucket $b has several versions ($(echo "$found" | join)); not on $(echo "$found" | head -n1):"
      rec G "$m" "$b" | awk -F'\t' -v v="$(echo "$found" | head -n1)" '$5 != v { print "  " $4 " " $5 }' >&2
    fi
  done

  # Rule 2: OCB_VERSION == core-v0.
  for v in $(versions "$m" core-v0); do
    [ "$v" = "$ocb_version" ] || fail "$m: bucket core-v0 is $v but OCB_VERSION in $MAKEFILE is $ocb_version"
  done

  # Rule 3: dt-edge == core-v0.
  for v in $(versions "$m" dt-edge); do
    [ "$v" = "$core" ] || fail "$m: bucket dt-edge is $v but core-v0 is $core"
  done

  # Rule 4: one version per replace group (RHS module root with more than one member).
  for root in $(rec R "$m" | cut -f3 | sort | uniq -d); do
    if [ "$(rec R "$m" "$root" | cut -f5 | sort -u | wc -l)" -gt 1 ]; then
      fail "$m: replaces into $root use several versions:"
      rec R "$m" "$root" | awk -F'\t' '{ print "  " $4 " => " $5 }' >&2
    fi
  done
done

if [ "$violations" -gt 0 ]; then
  echo "validate-manifest-versions: $violations violation(s)" >&2
  exit 1
fi
echo "validate-manifest-versions: OK (OCB_VERSION $ocb_version)"
