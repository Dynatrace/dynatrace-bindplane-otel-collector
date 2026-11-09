// Copyright Dynatrace LLC
// SPDX-License-Identifier: Apache-2.0

package integration

import (
	"os"
	"path"
	"testing"
	"time"

	"github.com/dynatrace/dynatrace-bindplane-otel-collector/internal/testcommon/testutil"
	"github.com/open-telemetry/opentelemetry-collector-contrib/testbed/testbed"
	"github.com/stretchr/testify/require"
)

// ConfigExamplesDir is the config_examples directory, relative to a test package.
const ConfigExamplesDir = "../../../config_examples"

// SenderFunc creates the data sender for a scenario.
type SenderFunc func(host string, port int) testbed.DataSender

// ReceiverFunc creates the data receiver for a scenario.
type ReceiverFunc func(port int) *testbed.BaseOTLPDataReceiver

// FilteringScenario runs the Collector with the config configName from ConfigExamplesDir, sends it the
// data provider's data and validates the data that reaches the receiver.
func FilteringScenario(
	t *testing.T,
	dataProvider testbed.DataProvider,
	senderFunc SenderFunc,
	receiverFunc ReceiverFunc,
	validator testbed.TestCaseValidator,
	configName string,
) {
	agentProc := testbed.NewChildProcessCollector(testbed.WithAgentExePath(testutil.CollectorTestsExecPath))

	//#nosec G304 -- path is built from a config name chosen by the test
	cfg, err := os.ReadFile(path.Join(ConfigExamplesDir, configName))
	require.NoError(t, err)

	receiverPort := testutil.GetAvailablePort(t)
	exporterPort := testutil.GetAvailablePort(t)

	parsedConfig := string(cfg)
	parsedConfig = testutil.ReplaceOtlpGrpcReceiverPort(parsedConfig, receiverPort)
	parsedConfig = testutil.ReplaceDynatraceExporterEndpoint(parsedConfig, exporterPort)

	configCleanup, err := agentProc.PrepareConfig(t, parsedConfig)
	require.NoError(t, err)
	t.Cleanup(configCleanup)

	tc := testbed.NewTestCase(
		t,
		dataProvider,
		senderFunc(testbed.DefaultHost, receiverPort),
		receiverFunc(exporterPort),
		agentProc,
		validator,
		&testbed.CorrectnessResults{},
	)
	t.Cleanup(tc.Stop)

	tc.EnableRecording()
	tc.StartBackend()
	tc.StartAgent()

	tc.StartLoad(testbed.LoadOptions{
		DataItemsPerSecond: 3,
		ItemsPerBatch:      3,
	})
	tc.Sleep(2 * time.Second)
	tc.StopLoad()

	tc.WaitForN(func() bool { return tc.LoadGenerator.DataItemsSent() == tc.MockBackend.DataItemsReceived() },
		time.Second*30,
		"all data items received")

	tc.ValidateData()
}

// NewOTLPTraceDataSenderWrapper is a SenderFunc for OTLP traces.
func NewOTLPTraceDataSenderWrapper(host string, port int) testbed.DataSender {
	return testbed.NewOTLPTraceDataSender(host, port)
}

// NewOTLPMetricDataSenderWrapper is a SenderFunc for OTLP metrics.
func NewOTLPMetricDataSenderWrapper(host string, port int) testbed.DataSender {
	return testbed.NewOTLPMetricDataSender(host, port)
}

// NewOTLPLogsDataSenderWrapper is a SenderFunc for OTLP logs.
func NewOTLPLogsDataSenderWrapper(host string, port int) testbed.DataSender {
	return testbed.NewOTLPLogsDataSender(host, port)
}
