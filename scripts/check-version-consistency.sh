#!/bin/sh
# Copyright  Dynatrace LLC
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

# Fails if the OpenTelemetry core or contrib components, or the Dynatrace
# bindplane-otel-contrib components, across all manifests (full, slim, AIX) do
# not share one version per group. Adapted from the upstream
# opentelemetry-collector-releases scripts/validate-version-consistency.sh,
# which checks core and contrib only.
# bindplane-otel-contrib is released as one set and `make update-contrib` bumps
# it in all manifests, so it is checked as well.
#
# Groups, each of which must have exactly one version:
#   core v0.x, core v1+, contrib v0.x, contrib v1+,
#   bindplane-otel-contrib v0.x, bindplane-otel-contrib v1+
# v1+ modules have graduated and are versioned separately from the v0.x ones.
# Only the component sections are checked; replaces: and dist: are not components.
# Versions pinned through replaces: are therefore not checked here.
#
# Usage: check-version-consistency.sh [manifest...]
# Without arguments, every manifests/*/manifest*.yaml is checked.
set -eu

# Modules deliberately pinned to another version. Keep the reason next to the
# pin in the manifests.
EXEMPT="
github.com/open-telemetry/opentelemetry-collector-contrib/receiver/jmxreceiver
"

if [ "$#" -eq 0 ]; then
	set -- manifests/*/manifest*.yaml
fi

for f in "$@"; do
	[ -f "$f" ] || { echo "manifest not found: $f"; exit 1; }
done

# Prints "<group> <version> <file> <module>" for every checked component.
components() {
	for f in "$@"; do
		awk -v file="$f" '
			/^[a-z_]+:/ { s = $1 }
			s ~ /^(extensions|exporters|processors|receivers|connectors|providers):$/ && $1 == "-" && $2 == "gomod:" {
				line = $0; gsub(/"/, "", line); split(line, f, " ")
				mod = f[3]; ver = f[4]
				if (ver == "" || ver == "#") { print "missing version: " file ": " mod > "/dev/stderr"; exit 2 }
				if (mod ~ /^go\.opentelemetry\.io\/collector\//) ns = "core"
				else if (mod ~ /^github\.com\/open-telemetry\/opentelemetry-collector-contrib\//) ns = "contrib"
				else if (mod ~ /^github\.com\/dynatrace\/dynatrace-bindplane-otel-contrib\//) ns = "bindplane-otel-contrib"
				else next
				major = (ver ~ /^v0\./) ? "v0" : "v1+"
				print ns "-" major, ver, file, mod
			}' "$f"
	done
}

tmp=$(mktemp)
raw=$(mktemp)
trap 'rm -f "$tmp" "$raw"' EXIT

# Not piped, so set -e stops the script when awk fails on a missing version.
components "$@" > "$raw"
while read -r group ver file mod; do
	case "$EXEMPT" in
		*"
$mod
"*) continue ;;
	esac
	echo "$group $ver $file $mod"
done < "$raw" > "$tmp"

failed=0
for group in $(awk '{ print $1 }' "$tmp" | sort -u); do
	versions=$(awk -v g="$group" '$1 == g { print $2 }' "$tmp" | sort -u)
	if [ "$(echo "$versions" | wc -l)" -gt 1 ]; then
		failed=1
		echo "$group components have more than one version:"
		for v in $versions; do
			echo "  $v:"
			awk -v g="$group" -v v="$v" '$1 == g && $2 == v { print "    " $3 ": " $4 }' "$tmp"
		done
	fi
done

if [ "$failed" -ne 0 ]; then
	echo "Align the versions above, or add a deliberately pinned module to EXEMPT in $0."
	exit 1
fi
echo "Component versions are consistent across: $*"
