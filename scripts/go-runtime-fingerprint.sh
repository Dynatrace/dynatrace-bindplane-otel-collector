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

# Prints the Go runtime fingerprint of a built collector binary: the inputs that
# decide Go's default runtime behavior (GOMAXPROCS, TLS defaults, ...).
#   toolchain          Go minor version the binary was compiled with
#   main module go     minor version of the go directive of the generated main module
#   DefaultGODEBUG     GODEBUG defaults embedded in the binary, sorted, or "none"
# Patch levels are dropped so security patch bumps do not change the fingerprint.
# Usage: go-runtime-fingerprint.sh <binary> <build dir with the generated go.mod>
set -eu

if [ $# -ne 2 ] || [ ! -f "$1" ] || [ ! -f "$2/go.mod" ]; then
	echo "usage: $0 <collector binary> <generated build dir>" >&2
	exit 2
fi
BIN=$1
GOMOD=$2/go.mod

# GOTOOLCHAIN=local: only read the binary. Without it, a go.mod in the current
# directory can make the go command try to switch (and download) toolchains.
info=$(GOTOOLCHAIN=local go version -m "$BIN")
toolchain=$(printf '%s\n' "$info" | sed -n '1s/^.*: \(go[0-9][0-9]*\.[0-9][0-9]*\).*$/\1/p')
modgo=$(awk '$1 == "go" { split($2, v, "."); sub(/[^0-9].*$/, "", v[2]); print v[1] "." v[2]; exit }' "$GOMOD")
godebug=$(printf '%s\n' "$info" | sed -n 's/^[[:space:]]*build[[:space:]]*DefaultGODEBUG=//p' | tr ',' '\n' | LC_ALL=C sort)

if [ -z "$toolchain" ] || [ -z "$modgo" ]; then
	echo "could not read the toolchain or main module go version" >&2
	exit 1
fi

echo "toolchain: $toolchain"
echo "main module go: $modgo"
echo "DefaultGODEBUG:"
if [ -n "$godebug" ]; then
	printf '%s\n' "$godebug" | sed 's/^/  /'
else
	echo "  none"
fi
