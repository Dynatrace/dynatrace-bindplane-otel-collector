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

# Tests for create-support-bundle.sh install detection on AIX and Linux.
# Usage: test_detect.sh [path-to-create-support-bundle.sh]
SCRIPT=${1:-$(dirname "$0")/../create-support-bundle.sh}
. "$(dirname "$0")/stubs.sh"
WORK=$(mktemp -d 2>/dev/null) || { WORK=/tmp/sbtest.$$; mkdir "$WORK"; }   # AIX has no mktemp
sed '$d' "$SCRIPT" > "$WORK/lib.sh"   # drop trailing main "$@"
pass=0; fail=0
n=0

# run_case <name> <os> <"svc=path pid" ...> -- <stdin> <expected "service dir pid">
run_case() {
  name=$1 os=$2; shift 2
  n=$((n+1)); bin="$WORK/bin$n"; state="$WORK/state$n"
  make_stubs "$bin" "$state" "$os"
  while [ "$1" != -- ]; do echo "${1#*=}" > "$state/${1%%=*}"; shift; done
  input=$2 want=$3
  got=$(printf '%s\n' "$input" | PATH="$bin:$PATH" sh -c ". '$WORK/lib.sh'; detect_install; echo \"\$collector_service \$collector_dir \$(service_pid \"\$collector_service\")\"" 2>/dev/null)
  if [ "$got" = "$want" ]; then pass=$((pass+1)); echo "PASS $name"; else fail=$((fail+1)); echo "FAIL $name (got '$got', want '$want')"; fi
}

run_case aix         AIX   "dbdot-otel-collector=/opt/dbdot/dynatrace-bindplane-otel-collector 123" -- "" \
  "dbdot-otel-collector /opt/dbdot 123"
run_case aix-stopped AIX   "dbdot-otel-collector=/opt/dbdot/dynatrace-bindplane-otel-collector" -- "" \
  "dbdot-otel-collector /opt/dbdot "
run_case linux       Linux "dynatrace-bindplane-otel-collector=/opt/dbdot/dynatrace-bindplane-otel-collector 789" -- "" \
  "dynatrace-bindplane-otel-collector.service /opt/dbdot 789"
run_case not-found   Linux -- "/opt/entered" \
  "dynatrace-bindplane-otel-collector.service /opt/entered "

rm -rf "$WORK"
echo "pass=$pass fail=$fail"; [ $fail -eq 0 ]
