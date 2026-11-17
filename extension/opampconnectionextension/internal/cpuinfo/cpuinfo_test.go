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

package cpuinfo

import (
	"os"
	"os/exec"
	"runtime"
	"strconv"
	"testing"

	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
	"go.uber.org/zap/zaptest/observer"
)

func TestWarnings(t *testing.T) {
	tests := []struct {
		name string
		r    Report
		want []string
	}{
		{"no env", Report{GOMAXPROCS: 2, RuntimeDefault: 2}, nil},
		{"env equal to default", Report{GOMAXPROCS: 2, RuntimeDefault: 2, FromEnv: true}, nil},
		{"env above default", Report{GOMAXPROCS: 8, RuntimeDefault: 2, FromEnv: true}, []string{envWarning}},
		{"env below default", Report{GOMAXPROCS: 2, RuntimeDefault: 4, FromEnv: true}, nil},
		{"limit ignored", Report{GOMAXPROCS: 14, RuntimeDefault: 14, CPULimitIgnored: true}, []string{limitIgnoredWarning}},
		{"both", Report{GOMAXPROCS: 8, RuntimeDefault: 2, FromEnv: true, CPULimitIgnored: true}, []string{envWarning, limitIgnoredWarning}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			require.Equal(t, tt.want, tt.r.warnings())
			require.Equal(t, len(tt.want) > 0, tt.r.ExceedsAvailableCPU())
		})
	}
}

func TestEnvSetsGOMAXPROCS(t *testing.T) {
	tests := map[string]bool{
		"8": true, "+8": true, "1": true, "2147483647": true,
		"": false, "abc": false, "0": false, "-1": false,
		"2147483648": false, "+9999999999": false, "8.5": false, " 8": false,
	}
	for in, want := range tests {
		require.Equal(t, want, envSetsGOMAXPROCS(in), "%q", in)
	}
}

func TestLog(t *testing.T) {
	core, logs := observer.New(zap.InfoLevel)
	Log(zap.New(core), Report{GOMAXPROCS: 8, NumCPU: 14, RuntimeDefault: 2, FromEnv: true})
	Log(zap.New(core), Report{GOMAXPROCS: 14, NumCPU: 14, RuntimeDefault: 14, CPULimitIgnored: true})

	entries := logs.All()
	require.Len(t, entries, 4)

	require.Equal(t, zap.InfoLevel, entries[0].Level)
	require.Equal(t, "Go runtime CPU settings", entries[0].Message)
	require.Equal(t, map[string]any{
		"gomaxprocs":        int64(8),
		"num_cpu":           int64(14),
		"runtime_default":   int64(2),
		"source":            "environment",
		"cpu_limit_ignored": false,
	}, entries[0].ContextMap())

	require.Equal(t, zap.WarnLevel, entries[1].Level)
	require.Equal(t, envWarning, entries[1].Message)
	require.Equal(t, entries[0].ContextMap(), entries[1].ContextMap())

	require.Equal(t, zap.InfoLevel, entries[2].Level)
	require.Equal(t, zap.WarnLevel, entries[3].Level)
	require.Equal(t, limitIgnoredWarning, entries[3].Message)
	require.Equal(t, true, entries[3].ContextMap()["cpu_limit_ignored"])
}

// The runtime reads GOMAXPROCS at process start, so the real Inspect path is
// exercised in a child process started with the variable set.
const helperEnv = "CPUINFO_TEST_HELPER"

func TestInspectHelper(t *testing.T) {
	mode := os.Getenv(helperEnv)
	if mode == "" {
		t.Skip("only runs as a subprocess")
	}
	before := runtime.GOMAXPROCS(0)
	r := Inspect()
	switch mode {
	case "set":
		want, err := strconv.Atoi(os.Getenv("GOMAXPROCS"))
		require.NoError(t, err)
		require.True(t, r.FromEnv)
		require.Equal(t, want, r.GOMAXPROCS)
		require.Equal(t, want, runtime.GOMAXPROCS(0), "env value must survive Inspect")
		require.GreaterOrEqual(t, r.RuntimeDefault, 1)
		require.NotEqual(t, want, r.RuntimeDefault)
	case "ignored":
		require.False(t, r.FromEnv)
		require.Equal(t, before, runtime.GOMAXPROCS(0), "automatic mode must be left untouched")
		require.Equal(t, before, r.GOMAXPROCS)
	}
}

func TestInspectSubprocess(t *testing.T) {
	// A value above NumCPU can never equal the runtime default.
	set := strconv.Itoa(runtime.NumCPU() + 3)
	for _, tt := range []struct{ name, mode, gomaxprocs string }{
		{"valid env", "set", set},
		{"out of range env", "ignored", "2147483648"},
	} {
		t.Run(tt.name, func(t *testing.T) {
			cmd := exec.Command(os.Args[0], "-test.run=^TestInspectHelper$", "-test.v")
			cmd.Env = append(os.Environ(), helperEnv+"="+tt.mode, "GOMAXPROCS="+tt.gomaxprocs)
			out, err := cmd.CombinedOutput()
			require.NoError(t, err, string(out))
			require.NotContains(t, string(out), "SKIP")
		})
	}
}
