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

# Verifies that a release tag matches the dist.version of an ocb manifest.
#
# Usage: check-tag-version.sh <tag> <manifest> <exact|core>
#
#   exact  the tag without its leading "v" must equal dist.version. Used by the
#          full build, which is released from plain semver tags (v1.2.3).
#   core   the tag without its leading "v" and without a trailing "-rc.N" must
#          equal dist.version. Used by the slim build, which is released from RC
#          tags (v1.2.3-rc.1): several RCs can share one manifest version.
#
# Accepted tags are vX.Y.Z and vX.Y.Z-rc.N. Anything else fails.

set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "usage: $0 <tag> <manifest> <exact|core>" >&2
  exit 2
fi

tag="$1"
manifest="$2"
mode="$3"

if ! [[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-rc\.[0-9]+)?$ ]]; then
  echo "tag '$tag' is not a valid release tag (expected vX.Y.Z or vX.Y.Z-rc.N)" >&2
  exit 1
fi

if [ ! -f "$manifest" ]; then
  echo "manifest '$manifest' does not exist" >&2
  exit 2
fi

# Read dist.version without a YAML dependency: the first top-level "dist:" block's
# first "version:" key. ocb manifests keep dist at the top of the file.
manifest_version="$(awk '
  /^dist:/ { in_dist = 1; next }
  in_dist && /^[^[:space:]#]/ { exit }
  in_dist && /^[[:space:]]+version:/ {
    sub(/^[[:space:]]+version:[[:space:]]*/, "")
    gsub(/["'\'']/, "")
    sub(/[[:space:]]*(#.*)?$/, "")
    print
    exit
  }
' "$manifest")"

if [ -z "$manifest_version" ]; then
  echo "could not read dist.version from '$manifest'" >&2
  exit 2
fi

tag_version="${tag#v}"
case "$mode" in
  exact) ;;
  core) tag_version="${tag_version%-rc.*}" ;;
  *)
    echo "unknown mode '$mode' (expected exact or core)" >&2
    exit 2
    ;;
esac

if [ "$tag_version" != "$manifest_version" ]; then
  echo "tag '$tag' does not match dist.version '$manifest_version' in $manifest (mode: $mode)" >&2
  echo "bump dist.version in the manifest before tagging" >&2
  exit 1
fi

echo "tag '$tag' matches dist.version '$manifest_version' in $manifest (mode: $mode)"
