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

# Tests install_unix.sh --build: the names and download URL each build gets, and
# the builds set_build rejects.
# Usage: test_build.sh [path-to-install_unix.sh]
SCRIPT=${1:-$(dirname "$0")/../install_unix.sh}
WORK=$(mktemp -d)
sed '$d' "$SCRIPT" > "$WORK/lib.sh"   # drop trailing main "$@"
pass=0; fail=0

# run_case <name> <build> <os> <expected>; an empty <expected> means set_build must fail
run_case() {
  # An empty DBDOT_CONFIG_HOME gets the build's default, whatever the caller's environment holds
  got=$(DBDOT_CONFIG_HOME='' sh -c ". '$WORK/lib.sh'; OS_TYPE=$3; build=$2; set_build
    version=1.2.3; os_arch=amd64; package_type=deb; set_download_urls
    echo \"\$PACKAGE_NAME \$DBDOT_CONFIG_HOME \$MANAGEMENT_YML_PATH \$collector_download_url\"" 2>/dev/null)
  rc=$?
  if { [ -z "$4" ] && [ $rc -ne 0 ]; } || { [ -n "$4" ] && [ $rc -eq 0 ] && [ "$got" = "$4" ]; }; then
    pass=$((pass+1)); echo "PASS $1"
  else
    fail=$((fail+1)); echo "FAIL $1 (rc=$rc, got '$got', want '$4')"
  fi
}

full=dynatrace-bindplane-otel-collector
slim=dynatrace-bindplane-otel-collector-slim
run_case full-linux full Linux "$full /opt/$full /opt/$full/manager.yaml https://dbdot.bindplane.com/v1.2.3/${full}_v1.2.3_linux_amd64.deb"
run_case slim-linux slim Linux "$slim /opt/$slim /opt/$slim/manager.yaml https://dbdot.bindplane.com/v1.2.3/${slim}_v1.2.3_linux_amd64.deb"
run_case full-aix   full AIX   "$full /opt/$full /opt/$full/manager.yaml https://dbdot.bindplane.com/v1.2.3/${full}-v1.2.3-aix-ppc64.tar.gz"
run_case slim-aix   slim AIX   ""
run_case unknown    bogus Linux ""

rm -rf "$WORK"
echo "pass=$pass fail=$fail"; [ $fail -eq 0 ]
