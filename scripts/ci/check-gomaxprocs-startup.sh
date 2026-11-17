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

# Checks the GOMAXPROCS startup log of a built collector image under different
# CPU limits and environments. Run it after a Go version change, since the
# expected values follow the Go runtime's container-aware defaults.
#
# Usage: scripts/ci/check-gomaxprocs-startup.sh <image>
#
# The image must run standalone when /etc/otelcol/config.yaml is mounted, like
# the one built from internal/testbed/docker/Dockerfile. The Docker host needs
# at least 4 CPUs. Nothing is built; exits non-zero on any mismatch.
set -u

IMAGE=${1:?usage: $0 <image>}

NCPU=$(docker info --format '{{.NCPU}}')
if [ "${NCPU}" -lt 4 ]; then
  echo "need a Docker host with at least 4 CPUs, have ${NCPU}" >&2
  exit 2
fi

WORKDIR=$(mktemp -d)
trap 'rm -rf "${WORKDIR}"' EXIT
cat > "${WORKDIR}/config.yaml" <<'YAML'
receivers:
  otlp:
    protocols:
      http:
        endpoint: localhost:4318
exporters:
  debug:
service:
  telemetry:
    metrics:
      level: none
  pipelines:
    metrics:
      receivers: [otlp]
      exporters: [debug]
YAML
chmod -R a+rX "${WORKDIR}"

FAILED=0

# field <logline> <name> prints the value of a JSON field of a zap log line.
field() {
  sed -n "s/.*\"$2\":\"\{0,1\}\([^\",}]*\)\"\{0,1\}.*/\1/p" <<<"$1" | head -n1
}

# run_case <name> <expectations> <warn-count> [docker run args...]
# expectations is a space separated list of field=value pairs checked against
# the "Go runtime CPU settings" line.
run_case() {
  local name=$1 expect=$2 warns=$3
  shift 3
  local id logs info got_warns kv ok=1
  id=$(docker run -d -v "${WORKDIR}/config.yaml:/etc/otelcol/config.yaml:ro" "$@" "${IMAGE}") || {
    echo "FAIL ${name}: container did not start"
    FAILED=1
    return
  }
  for _ in $(seq 1 30); do
    logs=$(docker logs "${id}" 2>&1)
    grep -q 'Starting Standalone Mode' <<<"${logs}" && sleep 1 && break
    sleep 1
  done
  logs=$(docker logs "${id}" 2>&1)
  docker rm -f "${id}" > /dev/null
  info=$(grep -F 'Go runtime CPU settings' <<<"${logs}" | head -n1)
  got_warns=$(grep -c '"level":"warn".*"gomaxprocs":' <<<"${logs}")
  for kv in ${expect}; do
    [ "$(field "${info}" "${kv%%=*}")" = "${kv#*=}" ] || ok=0
  done
  [ "${got_warns}" = "${warns}" ] || ok=0
  local summary
  summary="gomaxprocs=$(field "${info}" gomaxprocs) runtime_default=$(field "${info}" runtime_default) source=$(field "${info}" source) cpu_limit_ignored=$(field "${info}" cpu_limit_ignored) warnings=${got_warns}"
  if [ "${ok}" = 1 ]; then
    echo "PASS ${name}: ${summary}"
  else
    echo "FAIL ${name}: ${summary} (want ${expect} warnings=${warns})"
    FAILED=1
  fi
}

run_case "a cpus=2" "gomaxprocs=2 runtime_default=2 cpu_limit_ignored=false" 0 --cpus=2
run_case "b cpus=2 GOMAXPROCS=8" "gomaxprocs=8 runtime_default=2 source=environment" 1 --cpus=2 -e GOMAXPROCS=8
run_case "c no limit" "gomaxprocs=${NCPU} runtime_default=${NCPU} cpu_limit_ignored=false" 0
run_case "d cpus=4 GOMAXPROCS=2" "gomaxprocs=2 runtime_default=4 source=environment" 0 --cpus=4 -e GOMAXPROCS=2
run_case "e cpus=0.5" "gomaxprocs=2 runtime_default=2" 0 --cpus=0.5
run_case "f cpus=2 containermaxprocs=0" "gomaxprocs=${NCPU} cpu_limit_ignored=true" 1 --cpus=2 -e GODEBUG=containermaxprocs=0
run_case "g cpus=2 GOMAXPROCS=abc" "gomaxprocs=2 runtime_default=2 cpu_limit_ignored=false" 0 --cpus=2 -e GOMAXPROCS=abc
run_case "h cpus=3 containermaxprocs=0" "gomaxprocs=${NCPU} cpu_limit_ignored=true" 1 --cpus=3 -e GODEBUG=containermaxprocs=0
# With cgroup awareness off the runtime default is the host CPU count, so these two cases derive GOMAXPROCS from it.
run_case "i cpus=3 containermaxprocs=0 GOMAXPROCS=${NCPU}" "gomaxprocs=${NCPU} runtime_default=${NCPU} source=environment cpu_limit_ignored=true" 1 --cpus=3 -e GODEBUG=containermaxprocs=0 -e "GOMAXPROCS=${NCPU}"
run_case "j no limit containermaxprocs=0" "gomaxprocs=${NCPU} cpu_limit_ignored=false" 0 -e GODEBUG=containermaxprocs=0
run_case "k cpus=3 containermaxprocs=0 GOMAXPROCS=$((NCPU * 2))" "gomaxprocs=$((NCPU * 2)) runtime_default=${NCPU} source=environment cpu_limit_ignored=true" 2 --cpus=3 -e GODEBUG=containermaxprocs=0 -e "GOMAXPROCS=$((NCPU * 2))"

exit "${FAILED}"
