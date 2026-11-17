// Copyright  Dynatrace LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Package cpuinfo reports how the Go scheduler's parallelism (GOMAXPROCS) was
// chosen for this process.
package cpuinfo

import (
	"os"
	"runtime"
	"runtime/metrics"
	"strconv"
	"sync"

	"go.uber.org/zap"
)

// Report describes the CPU settings of the Go runtime at startup.
type Report struct {
	// GOMAXPROCS is the value in effect when the report was taken.
	GOMAXPROCS int
	// NumCPU is the number of logical CPUs usable by the process.
	NumCPU int
	// RuntimeDefault is the value the runtime would choose without the
	// GOMAXPROCS environment variable.
	RuntimeDefault int
	// FromEnv is true when the GOMAXPROCS environment variable set the value.
	FromEnv bool
	// CPULimitIgnored is true when the runtime was told not to follow the
	// container CPU limit (GODEBUG containermaxprocs=0) and that limit would
	// have lowered GOMAXPROCS.
	CPULimitIgnored bool
}

const (
	envWarning          = "GOMAXPROCS is set higher than the CPU available to the collector, which can cause CPU throttling or oversubscription. Unset GOMAXPROCS or set it no higher than runtime_default."
	limitIgnoredWarning = "The container CPU limit is being ignored because GODEBUG containermaxprocs=0 is in effect, and GOMAXPROCS may be higher than that limit. This can cause CPU throttling. Remove containermaxprocs=0 or set GOMAXPROCS no higher than the CPU limit."
)

func (r Report) source() string {
	if r.FromEnv {
		return "environment"
	}
	return "runtime default"
}

// warnings returns the problems worth telling the operator about. Values below
// the runtime default are not reported: operators set them to the CPU request
// on purpose.
func (r Report) warnings() []string {
	var w []string
	if r.FromEnv && r.GOMAXPROCS > r.RuntimeDefault {
		w = append(w, envWarning)
	}
	if r.CPULimitIgnored {
		w = append(w, limitIgnoredWarning)
	}
	return w
}

// ExceedsAvailableCPU is true exactly when Log emits a warning.
func (r Report) ExceedsAvailableCPU() bool {
	return len(r.warnings()) > 0
}

// Log writes the report: always an info line, plus one warning per problem.
func Log(logger *zap.Logger, r Report) {
	fields := []zap.Field{
		zap.Int("gomaxprocs", r.GOMAXPROCS),
		zap.Int("num_cpu", r.NumCPU),
		zap.Int("runtime_default", r.RuntimeDefault),
		zap.String("source", r.source()),
		zap.Bool("cpu_limit_ignored", r.CPULimitIgnored),
	}
	logger.Info("Go runtime CPU settings", fields...)
	for _, w := range r.warnings() {
		logger.Warn(w, fields...)
	}
}

// envSetsGOMAXPROCS mirrors the runtime's own check: the value must parse as a
// positive 32-bit decimal integer, anything else is ignored.
func envSetsGOMAXPROCS(v string) bool {
	n, err := strconv.ParseInt(v, 10, 32)
	return err == nil && n > 0
}

// cpuLimitIgnored reads the runtime's counter that is non-zero only when
// container awareness is disabled and the CPU limit would have lowered
// GOMAXPROCS. Platforms without the counter report KindBad.
func cpuLimitIgnored() bool {
	s := []metrics.Sample{{Name: "/godebug/non-default-behavior/containermaxprocs:events"}}
	metrics.Read(s)
	return s[0].Value.Kind() == metrics.KindUint64 && s[0].Value.Uint64() > 0
}

// Inspect returns the Report for the running process, computed once.
//
// It must run before anything in this process changes GOMAXPROCS or the
// GOMAXPROCS environment variable. It reflects startup only: later changes,
// such as a component adjusting GOMAXPROCS when it starts, appear in neither
// the log nor the OpAMP attributes.
//
// When the environment overrides GOMAXPROCS, the runtime default is read by
// briefly resetting to it and then restoring the previous value.
func Inspect() Report {
	return inspect()
}

var inspect = sync.OnceValue(func() Report {
	env := os.Getenv("GOMAXPROCS")
	cur := runtime.GOMAXPROCS(0)
	def := cur
	fromEnv := envSetsGOMAXPROCS(env)
	if fromEnv {
		runtime.SetDefaultGOMAXPROCS()
		def = runtime.GOMAXPROCS(0)
		runtime.GOMAXPROCS(cur)
	}
	return Report{
		GOMAXPROCS:      cur,
		NumCPU:          runtime.NumCPU(),
		RuntimeDefault:  def,
		FromEnv:         fromEnv,
		CPULimitIgnored: cpuLimitIgnored(),
	}
})
