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

# Tests for install_unix.sh unprivileged_check, which warns when the collector
# will run as an unprivileged user but sudo is missing.
# Usage: test_unprivileged_check.sh [path-to-install_unix.sh]
# Sources the script with main stripped, on a PATH of symlinks without sudo and
# visudo, plus stubs for them when the case has sudo.
SCRIPT=${1:-$(dirname "$0")/../install_unix.sh}
WORK=$(mktemp -d)
sed '$d' "$SCRIPT" > "$WORK/lib.sh"   # drop trailing main "$@"
pass=0; fail=0

bin="$WORK/bin"; mkdir -p "$bin" "$WORK/sudo"
for p in $(IFS=:; for d in $PATH; do printf '%s\n' "$d"/*; done); do
  [ -e "$p" ] && [ ! -e "$bin/${p##*/}" ] || continue   # first match on PATH wins, like the shell
  case "${p##*/}" in sudo|visudo) continue ;; esac
  ln -s "$p" "$bin/${p##*/}"
done
for t in sudo visudo; do printf '#!/bin/sh\n' > "$WORK/sudo/$t"; chmod +x "$WORK/sudo/$t"; done

# run_case <name> <SVC_PRE> <DBDOT_UNPRIVILEGED or unset> <unit: yes|no> <drop-in: yes|no> <sudo: yes|no> <expect: warn|check|skip>
# warn: checks for sudo and warns, check: checks for sudo without a warning, skip: no check.
run_case() {
  name=$1 svc=$2 value=$3 unit=$4 dropin=$5 sudo=$6 want=$7
  dir="$WORK/$name"; mkdir -p "$dir"
  [ "$unit" = yes ] && : > "$dir/unit"
  [ "$dropin" = yes ] && : > "$dir/dropin"
  path="$bin"
  [ "$sudo" = yes ] && path="$WORK/sudo:$path"
  set_value="unset DBDOT_UNPRIVILEGED"
  [ "$value" != unset ] && set_value="DBDOT_UNPRIVILEGED='$value'"
  # Set the value after sourcing install_unix.sh, which reads the host's
  # package override files.
  out=$(unset TERM; PATH="$path" "$bin/sh" -c "
    . '$WORK/lib.sh'
    $set_value
    SVC_PRE='$svc'
    SYSTEMD_UNIT_PATH='$dir/unit'
    SYSTEMD_USER_DROPIN_PATH='$dir/dropin'
    unprivileged_check
  " 2>&1); rc=$?
  got=skip
  case "$out" in *"checking for sudo"*) got=check ;; esac
  case "$out" in *"sudo is not installed"*) got=warn ;; esac
  if [ $rc -eq 0 ] && [ "$got" = "$want" ]; then
    pass=$((pass+1)); echo "PASS $name"
  else
    fail=$((fail+1)); echo "FAIL $name (rc=$rc, got $got, want $want)"; printf '%s\n' "$out" | tail -3
  fi
}

#        name                 SVC_PRE   value  unit dropin sudo expect
run_case new-default-no-sudo  systemctl unset  no   no     no   warn
run_case new-default-sudo     systemctl unset  no   no     yes  check
run_case root-install-default systemctl unset  yes  no     no   skip
run_case user-install-default systemctl unset  yes  yes    no   warn
run_case true-no-sudo         systemctl true   yes  no     no   warn
run_case false-no-sudo        systemctl false  no   no     no   skip
run_case sysv-default         service   unset  no   no     no   skip
run_case sysv-true            service   true   no   no     no   skip
[ -n "$KEEP" ] || rm -rf "$WORK"
echo "pass=$pass fail=$fail"; [ $fail -eq 0 ]
