#!/bin/sh
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

# Usage: update-module-version.sh <version> <module dir>...
# The module dirs come from RELEASED_MODULES in the Makefile.
set -e

TARGET_VERSION=$1
if [ -z "$TARGET_VERSION" ] || [ $# -lt 2 ]; then
    echo "Usage: $0 <version> <module dir>..."
    exit 1
fi
shift

for local_mod in "$@"; do
    # Run in a subshell so that the CD doesn't change this shell's current directory
    (
        echo "Updating version in $local_mod"
        cd "$local_mod"
        go mod tidy
        OTEL_MODULES=$(go list -m -f '{{if not (or .Indirect .Main)}}{{.Path}}{{end}}' all |
            grep -E -e '^github.com/dynatrace/dynatrace-bindplane-otel-collector' || true)

        for mod in $OTEL_MODULES; do
            echo "$local_mod: $mod@$TARGET_VERSION"
            go mod edit -require "$mod@$TARGET_VERSION"
        done
    )
done
