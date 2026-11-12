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

# Tests for resolve_unprivileged and check_leftover_files in the package
# scripts, which pick the user the collector runs as.
# Usage: test_package_runtime_user.sh [path-to-install_unix.sh]
# The package scripts are found next to install_unix.sh, in ../package. The
# functions are extracted from preinstall.sh, checked to be the same in
# postinstall.sh, and run with the unit, drop-in and install paths moved into
# a temporary directory, on a PATH without systemctl unless the case has
# systemd. stat is stubbed to fake the updater's owner, and find runs with
# "-user 0" meaning the user running the test, so the test runs unprivileged
# and can fake files that root owns.
SCRIPT=${1:-$(dirname "$0")/../install_unix.sh}
PKG=$(dirname "$SCRIPT")/../package
WORK=$(mktemp -d)
pass=0; fail=0

# extract prints the definition of function $2 in script $1.
extract() {
  sed -n "/^$2() {\$/,/^}\$/p" "$1"
}

for f in resolve_unprivileged check_leftover_files check_runtime_user_change; do
  extract "$PKG/preinstall.sh" "$f" > "$WORK/pre.$f"
  extract "$PKG/postinstall.sh" "$f" > "$WORK/post.$f"
  if [ -s "$WORK/pre.$f" ] && cmp -s "$WORK/pre.$f" "$WORK/post.$f"; then
    pass=$((pass+1)); echo "PASS same-$f"
  else
    fail=$((fail+1)); echo "FAIL same-$f (missing or different in preinstall.sh and postinstall.sh)"
  fi
done

# Both scripts must decide before they check or install anything.
for s in preinstall postinstall; do
  first=$(grep -E '^(resolve_unprivileged|check_user_name|check_runtime_user_change|check_leftover_files|install)( |$)' "$PKG/$s.sh" | head -n 1)
  if [ "$first" = "resolve_unprivileged" ]; then
    pass=$((pass+1)); echo "PASS order-$s"
  else
    fail=$((fail+1)); echo "FAIL order-$s (first call is '$first', want resolve_unprivileged)"
  fi
done

# The functions, with the system paths moved under $ROOT.
cat "$WORK/pre.resolve_unprivileged" "$WORK/pre.check_leftover_files" |
  sed -e 's#"/usr/lib/systemd/system/#"$ROOT/lib/#' \
      -e 's#"/etc/systemd/system/#"$ROOT/etc/#' \
      -e 's#"/run/systemd/system/#"$ROOT/run/#' > "$WORK/lib.sh"

# A PATH like the caller's without systemctl, stat and find, and stubs for
# them. stat prints $UPDATER_UID as the owner.
bin="$WORK/bin"; mkdir -p "$bin" "$WORK/stub" "$WORK/stub-systemd"
for p in $(IFS=:; for d in $PATH; do printf '%s\n' "$d"/*; done); do
  [ -e "$p" ] && [ ! -e "$bin/${p##*/}" ] || continue   # first match on PATH wins, like the shell
  case "${p##*/}" in systemctl|stat|find) continue ;; esac
  ln -s "$p" "$bin/${p##*/}"
done
printf '#!/bin/sh\necho "$UPDATER_UID"\n' > "$WORK/stub/stat"
cat > "$WORK/stub/find" << EOF
#!/bin/sh
uid=\$(id -u); prev=""
for a; do
  shift
  if [ "\$prev" = "-user" ] && [ "\$a" = 0 ]; then a=\$uid; fi
  set -- "\$@" "\$a"; prev=\$a
done
exec $(command -v find) "\$@"
EOF
printf '#!/bin/sh\n' > "$WORK/stub-systemd/systemctl"
chmod +x "$WORK/stub/stat" "$WORK/stub/find" "$WORK/stub-systemd/systemctl"

# run_case <name> <systemd: yes|no> <unit: yes|no> <package drop-in user or -> <other User= or -> <binary: yes|no> <updater: root|user|link|none> <DBDOT_UNPRIVILEGED, unset or empty> <home: empty|file|lostfound|link> <expect>
# other User= is written to an admin drop-in, or with "unit:" to /etc's unit
# file. home "file" holds a file that root owns, "lostfound" holds only a
# lost+found that root owns, and "link" is a link to a directory holding a
# file that root owns. expect is "exit" for a refused install, or
# "<DBDOT_UNPRIVILEGED> <kept_root> <ignored_value or ->".
run_case() {
  name=$1 systemd=$2 unit=$3 dropin=$4 other=$5 binary=$6 updater=$7 value=$8 home_kind=$9; shift 9; want=$*
  ROOT="$WORK/$name"
  dir="dynatrace-bindplane-otel-collector.service.d"
  mkdir -p "$ROOT/lib" "$ROOT/etc/$dir" "$ROOT/run"
  home="$ROOT/home"
  case "$home_kind" in
    link) mkdir -p "$ROOT/real-home/storage" && : > "$ROOT/real-home/storage/marker" && ln -s "$ROOT/real-home" "$home" ;;
    file) mkdir -p "$home/storage" && : > "$home/storage/marker" ;;
    lostfound) mkdir -p "$home/lost+found" ;;
    *) mkdir -p "$home" ;;
  esac
  [ "$unit" = yes ] && : > "$ROOT/lib/dynatrace-bindplane-otel-collector.service"
  [ "$dropin" != - ] && printf '[Service]\nUser=%s\n' "$dropin" > "$ROOT/etc/$dir/10-package-customizations-username.conf"
  case "$other" in
    -) ;;
    unit:*) printf '[Service]\nUser=%s\n' "${other#unit:}" > "$ROOT/etc/dynatrace-bindplane-otel-collector.service" ;;
    *) printf '[Service]\nUser=%s\n' "$other" > "$ROOT/etc/$dir/override.conf" ;;
  esac
  [ "$binary" = yes ] && : > "$home/dynatrace-bindplane-otel-collector"
  uid=0
  case "$updater" in
    root) : > "$home/updater" ;;
    user) : > "$home/updater"; uid=1000 ;;
    link) ln -s /nonexistent "$home/updater" ;;
  esac
  path="$WORK/stub:$bin"
  [ "$systemd" = yes ] && path="$WORK/stub-systemd:$path"
  case "$value" in
    unset) set_value="unset DBDOT_UNPRIVILEGED" ;;
    empty) set_value="DBDOT_UNPRIVILEGED=''" ;;
    *) set_value="DBDOT_UNPRIVILEGED='$value'" ;;
  esac
  got=$(ROOT="$ROOT" UPDATER_UID=$uid PATH="$path" "$bin/sh" -c "
    $set_value
    DBDOT_USER=dbdot
    DBDOT_CONFIG_HOME='$home'
    . '$WORK/lib.sh'
    resolve_unprivileged
    check_leftover_files
    echo \"\$DBDOT_UNPRIVILEGED \$kept_root \${ignored_value:--}\"
  " 2> "$ROOT/stderr") || got="exit"
  if [ "$got" = "$want" ]; then
    pass=$((pass+1)); echo "PASS $name"
  else
    fail=$((fail+1)); echo "FAIL $name (got '$got', want '$want')"; tail -3 "$ROOT/stderr"
  fi
}

#        name                   systemd unit dropin other      binary updater value home      expect
run_case new-default            yes     no   -      -          no     none    unset  empty     true false -
run_case new-empty-value        yes     no   -      -          no     none    empty  empty     true false -
run_case new-true               yes     no   -      -          no     none    true   empty     true false -
run_case new-false              yes     no   -      -          no     none    false  empty     false false -
run_case new-other-value        yes     no   -      -          no     none    yes    empty     false false yes
run_case root-default           yes     yes  -      -          yes    root    unset  empty     false true -
run_case root-true              yes     yes  -      -          yes    root    true   empty     true false -
run_case root-false             yes     yes  -      -          yes    root    false  empty     false false -
run_case root-other-root        yes     yes  -      root       yes    root    unset  empty     false true -
run_case root-no-unit           yes     no   -      -          yes    root    unset  empty     false true -
run_case user-default           yes     yes  dbdot  -          yes    user    unset  empty     true false -
run_case user-false             yes     yes  dbdot  -          yes    user    false  empty     false false -
run_case no-dropin-user-updater yes     yes  -      -          yes    user    unset  empty     exit
run_case no-dropin-user-false   yes     yes  -      -          yes    user    false  empty     exit
run_case no-dropin-no-updater   yes     yes  -      -          yes    none    unset  empty     exit
run_case no-dropin-link-updater yes     yes  -      -          yes    link    unset  empty     exit
run_case no-unit-user-updater   yes     no   -      -          yes    user    unset  empty     exit
run_case other-user-dropin      yes     yes  -      dbdot      yes    root    unset  empty     exit
run_case other-user-false       yes     yes  -      dbdot      yes    root    false  empty     exit
run_case other-user-unit        yes     yes  -      unit:dbdot yes    root    unset  empty     exit
run_case sysv-default           no      no   -      -          no     none    unset  empty     false false -
run_case sysv-true              no      no   -      -          no     none    true   empty     false false true
run_case leftovers-default      yes     no   -      -          no     none    unset  file      exit
run_case leftovers-true         yes     no   -      -          no     none    true   file      exit
run_case leftovers-false        yes     no   -      -          no     none    false  file      false false -
run_case leftovers-linked-home  yes     no   -      -          no     none    unset  link      exit
run_case leftovers-lost-found   yes     no   -      -          no     none    unset  lostfound true false -
run_case leftovers-upgrade      yes     yes  dbdot  -          yes    user    unset  file      true false -

[ -n "$KEEP" ] || rm -rf "$WORK"
echo "pass=$pass fail=$fail"; [ $fail -eq 0 ]
