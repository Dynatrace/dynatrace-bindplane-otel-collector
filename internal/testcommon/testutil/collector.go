// Copyright Dynatrace LLC
// SPDX-License-Identifier: Apache-2.0

// Package testutil provides helpers for running the Collector binary in tests and
// for editing and comparing its configs and telemetry.
package testutil

import (
	"net"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/open-telemetry/opentelemetry-collector-contrib/testbed/testbed"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// SubpackageConfigExamplesDir is the path of the config examples, relative to a package directory
// directly below internal/testbed/integration. The directory is populated by `make e2e-config-examples`.
const SubpackageConfigExamplesDir = "../../config_examples"

// CollectorExecPath returns the path of the Collector binary under test. It is $DBDOT_COLLECTOR_BIN
// if set, and otherwise the binary `make agent` writes to dist/ for the current platform.
func CollectorExecPath() string {
	if p := os.Getenv("DBDOT_COLLECTOR_BIN"); p != "" {
		abs, err := filepath.Abs(p)
		if err != nil {
			return p
		}
		return abs
	}
	_, thisFile, _, _ := runtime.Caller(0)
	// thisFile is <repo>/internal/testcommon/testutil/collector.go
	repoRoot := filepath.Join(filepath.Dir(thisFile), "..", "..", "..")
	name := "collector_" + runtime.GOOS + "_" + runtime.GOARCH
	if runtime.GOOS == "windows" {
		name += ".exe"
	}
	return filepath.Join(repoRoot, "dist", name)
}

// StandaloneEnv returns the environment that makes the DBDOT Collector run standalone and log to
// stdout, without touching the working directory. Without it the Collector writes a logging.yaml
// into the current directory and switches to managed mode if a manager.yaml or OPAMP_* variables exist.
func StandaloneEnv(t testing.TB) map[string]string {
	t.Helper()
	dir := t.TempDir()
	loggingPath := filepath.Join(dir, "logging.yaml")
	require.NoError(t, os.WriteFile(loggingPath, []byte("output: stdout\nlevel: info\n"), 0o600))
	return map[string]string{
		"LOGGING_YAML_PATH": loggingPath,
		// Never created, so the Collector doesn't pick up a manager config.
		"MANAGER_YAML_PATH": filepath.Join(dir, "manager.yaml"),
	}
}

// NewChildProcessCollector returns a child process runner for the Collector binary under test,
// configured with StandaloneEnv. Use it instead of testbed.NewChildProcessCollector.
func NewChildProcessCollector(t testing.TB) testbed.OtelcolRunner {
	t.Helper()
	opts := []testbed.ChildProcessOption{testbed.WithAgentExePath(CollectorExecPath())}
	for k, v := range StandaloneEnv(t) {
		opts = append(opts, testbed.WithEnvVar(k, v))
	}
	return testbed.NewChildProcessCollector(opts...)
}

// Config is a Collector config that is adapted for a test. Every edit is required to change
// the config, so that changes to the original can't silently break the test.
type Config struct {
	t   testing.TB
	cfg string
}

// LoadConfig reads the config at path.
func LoadConfig(t testing.TB, path string) *Config {
	//#nosec G304 -- path is chosen by the test
	raw, err := os.ReadFile(path)
	require.NoError(t, err)
	return &Config{t: t, cfg: string(raw)}
}

// LoadConfigExample reads a config from config_examples. It must be called from a package
// directly below internal/testbed/integration.
func LoadConfigExample(t testing.TB, name string) *Config {
	return LoadConfig(t, filepath.Join(SubpackageConfigExamplesDir, name))
}

// Replace applies f to the config. name describes the edit in the failure message.
func (c *Config) Replace(name string, f func(string) string) *Config {
	c.t.Helper()
	out := f(c.cfg)
	require.NotEqual(c.t, c.cfg, out, "config replacement %q had no effect", name)
	c.cfg = out
	return c
}

// ReplaceString replaces the first occurrence of old with replacement.
func (c *Config) ReplaceString(old, replacement string) *Config {
	c.t.Helper()
	return c.Replace(old, func(s string) string { return strings.Replace(s, old, replacement, 1) })
}

func (c *Config) String() string {
	return c.cfg
}

// ReplaceHealthCheckPort changes the health check endpoint port (13133) in cfg to port.
func ReplaceHealthCheckPort(cfg string, port int) string {
	return replaceEndpointPort(cfg, 13133, port)
}

// DisableInternalMetrics turns off the Collector's internal metrics server. It binds the fixed
// port 8888, which would clash with other Collectors on the machine (or a leftover from an aborted run).
func DisableInternalMetrics(cfg string) string {
	return strings.Replace(cfg, "service:\n", "service:\n  telemetry:\n    metrics:\n      level: none\n", 1)
}

// SetInternalMetricsPort moves the Collector's internal metrics server from the fixed port 8888
// to the given port on 127.0.0.1. Use it instead of DisableInternalMetrics when the test scrapes
// the internal metrics. The config must not have a service.telemetry section. The reader keeps the
// defaults of the built-in one, so metric names and scopes are unchanged.
func SetInternalMetricsPort(cfg string, port int) string {
	reader := "service:\n  telemetry:\n    metrics:\n      readers:\n        - pull:\n            exporter:\n" +
		"              prometheus:\n                host: 127.0.0.1\n                port: " + strconv.Itoa(port) + "\n"
	return strings.Replace(cfg, "service:\n", reader, 1)
}

// DisableSendingQueueAndRetry makes the results of the given exporter synchronous, so that
// export failures are returned to the client and show up immediately.
func DisableSendingQueueAndRetry(cfg, exporter string) string {
	header := "\n  " + exporter + ":\n"
	return strings.Replace(cfg, header,
		header+"    retry_on_failure:\n      enabled: false\n    sending_queue:\n      enabled: false\n", 1)
}

// CollectorParams configures a Collector started with StartCollector.
type CollectorParams struct {
	// Name identifies the Collector in the test output.
	Name   string
	Config string
	// ReadyPort is a port the Collector listens on once it has started, e.g. its OTLP receiver.
	ReadyPort int
	// ExecPath defaults to CollectorExecPath().
	ExecPath string
	// Args are additional command line arguments, e.g. feature gates.
	Args []string
	// Env is added to the environment of the Collector process.
	Env map[string]string
}

// Collector is a Collector child process started with StartCollector.
type Collector struct {
	runner  testbed.OtelcolRunner
	name    string
	logPath string
}

// Stop sends SIGTERM and waits for the Collector to exit.
// It fails the test if the Collector didn't exit cleanly. Calling it again is a no-op.
func (c *Collector) Stop(t *testing.T) {
	t.Helper()
	_, err := c.runner.Stop()
	require.NoError(t, err)
}

// StartCollector runs the Collector binary as a child process until the test ends or Stop is
// called. Its log is written to the test output if the test fails.
func StartCollector(t *testing.T, p CollectorParams) *Collector {
	t.Helper()
	execPath := p.ExecPath
	if execPath == "" {
		execPath = CollectorExecPath()
	}
	opts := []testbed.ChildProcessOption{testbed.WithAgentExePath(execPath)}
	for k, v := range StandaloneEnv(t) {
		opts = append(opts, testbed.WithEnvVar(k, v))
	}
	for k, v := range p.Env {
		opts = append(opts, testbed.WithEnvVar(k, v))
	}
	col := testbed.NewChildProcessCollector(opts...)
	cleanupCfg, err := col.PrepareConfig(t, p.Config)
	require.NoError(t, err)
	t.Cleanup(cleanupCfg)

	c := &Collector{
		runner:  col,
		name:    p.Name,
		logPath: filepath.Join(t.TempDir(), "collector.log"),
	}
	require.NoError(t, col.Start(testbed.StartParams{
		Name:        p.Name,
		LogFilePath: c.logPath,
		CmdArgs:     p.Args,
	}))
	t.Cleanup(func() {
		_, err := col.Stop()
		assert.NoError(t, err)
		if t.Failed() {
			if b, err := os.ReadFile(c.logPath); err == nil {
				t.Logf("%s log:\n%s", c.name, b)
			}
		}
	})

	WaitForListener(t, net.JoinHostPort("localhost", strconv.Itoa(p.ReadyPort)))
	waitForStartupComplete(t, c.logPath)
	return c
}

// startupPollGrace is how long to wait after the Collector logs "Everything is ready". That line is
// logged inside svc.Run, but waitForStartup in extension/opampconnectionextension/internal/collector
// (used in standalone and managed mode) only checks for StateRunning every 250ms, and a stop that
// arrives before that check makes the process exit 1. 500ms is twice the poll interval.
const startupPollGrace = 500 * time.Millisecond

// waitForStartupComplete waits until the DBDOT Collector has finished starting, so that stopping it
// right after its port opens doesn't make it exit with an error.
func waitForStartupComplete(t testing.TB, logPath string) {
	t.Helper()
	require.Eventually(t, func() bool {
		//#nosec G304 -- path is chosen by the test
		b, err := os.ReadFile(logPath)
		return err == nil && strings.Contains(string(b), "Everything is ready")
	}, 30*time.Second, 50*time.Millisecond, "the Collector did not finish starting, see %s", logPath)
	time.Sleep(startupPollGrace)
}

// WaitForListener waits until addr accepts TCP connections.
func WaitForListener(t testing.TB, addr string) {
	t.Helper()
	require.Eventually(t, func() bool {
		conn, err := net.DialTimeout("tcp", addr, time.Second)
		if err != nil {
			return false
		}
		_ = conn.Close()
		return true
	}, 30*time.Second, 200*time.Millisecond, "nothing started listening on %s", addr)
}

// WaitForHealthCheck waits until the health_check extension on port reports that the Collector
// is ready, i.e. all pipelines have started.
func WaitForHealthCheck(t testing.TB, port int) {
	t.Helper()
	url := "http://" + net.JoinHostPort("localhost", strconv.Itoa(port)) + "/"
	client := &http.Client{Timeout: time.Second}
	require.Eventually(t, func() bool {
		resp, err := client.Get(url)
		if err != nil {
			return false
		}
		_ = resp.Body.Close()
		return resp.StatusCode == http.StatusOK
	}, 30*time.Second, 200*time.Millisecond, "health check on %s did not become ready", url)
}
