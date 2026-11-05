// Copyright Dynatrace LLC
// SPDX-License-Identifier: Apache-2.0

// Package smoke checks that the slim Collector binary (`make agent DISTRO=slim`) starts. It
// catches startup failures that unit tests can't, such as a feature gate that the binary
// refuses to start with. Point DBDOT_COLLECTOR_BIN at dist/collector-slim_<os>_<arch>.
package smoke

import (
	"io"
	"net"
	"net/http"
	"strconv"
	"testing"
	"time"

	"github.com/stretchr/testify/require"

	"github.com/dynatrace/dynatrace-bindplane-otel-collector/internal/testcommon/testutil"
)

func TestCollectorStarts(t *testing.T) {
	tests := []struct {
		name       string
		configFile string
	}{
		{
			name:       "Basic test",
			configFile: "config-smoke.yaml",
		},
		// config-allcomponents.yaml declares every component of the slim build. Only the file_log
		// receiver is in a pipeline and no extension is enabled, so the other components are only
		// unmarshalled and validated. When a component is added to the slim manifest, add it there too.
		{
			name:       "All components",
			configFile: "config-allcomponents.yaml",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			metricsPort := testutil.GetAvailablePort(t)
			cfg := testutil.LoadConfig(t, "testdata/"+tt.configFile).
				Replace("internal metrics port", func(s string) string {
					return testutil.SetInternalMetricsPort(s, metricsPort)
				})

			col := testutil.StartCollector(t, testutil.CollectorParams{
				Name:      tt.name,
				Config:    cfg.String(),
				ReadyPort: metricsPort,
				Env: map[string]string{
					"SMOKE_FILE_STORAGE_DIR": t.TempDir(),
				},
			})

			url := "http://" + net.JoinHostPort("127.0.0.1", strconv.Itoa(metricsPort)) + "/metrics"
			var body string
			require.Eventually(t, func() bool {
				resp, err := http.Get(url) //#nosec G107 -- local test URL
				if err != nil {
					return false
				}
				defer func() { _ = resp.Body.Close() }()
				b, err := io.ReadAll(resp.Body)
				body = string(b)
				return err == nil && resp.StatusCode == http.StatusOK
			}, 15*time.Second, time.Second)
			require.Contains(t, body, "otelcol_process_uptime")

			col.Stop(t)
		})
	}
}
