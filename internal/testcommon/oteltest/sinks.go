// Copyright Dynatrace LLC
// SPDX-License-Identifier: Apache-2.0

package oteltest

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"regexp"
	"slices"
	"strconv"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.opentelemetry.io/collector/component"
	"go.opentelemetry.io/collector/component/componenttest"
	"go.opentelemetry.io/collector/config/configoptional"
	"go.opentelemetry.io/collector/confmap"
	"go.opentelemetry.io/collector/consumer"
	"go.opentelemetry.io/collector/consumer/consumertest"
	"go.opentelemetry.io/collector/pdata/pcommon"
	"go.opentelemetry.io/collector/pdata/pmetric"
	"go.opentelemetry.io/collector/receiver/otlpreceiver"
	"go.opentelemetry.io/collector/receiver/receivertest"
)

// ExpectedValueMode selects how an attribute value is compared with an ExpectedValue.
type ExpectedValueMode int

const (
	// AttributeMatchTypeEqual requires the attribute value to equal the expected value.
	AttributeMatchTypeEqual ExpectedValueMode = iota
	// AttributeMatchTypeRegex requires the attribute value to match the expected value as a regular expression.
	AttributeMatchTypeRegex
	// AttributeMatchTypeExist only requires the attribute to be present.
	AttributeMatchTypeExist
	// UIDRe matches a UUID.
	UIDRe = "[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}"
	// IPRe matches an IPv4 address.
	IPRe = "((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?){4}"

	// ServiceNameAttribute is the resource attribute that holds the service name.
	ServiceNameAttribute = "service.name"
)

// ExpectedValue is an expected attribute value and how to match it.
type ExpectedValue struct {
	Mode  ExpectedValueMode
	Value string
}

// NewExpectedValue returns an ExpectedValue with the given mode and value.
func NewExpectedValue(mode ExpectedValueMode, value string) ExpectedValue {
	return ExpectedValue{
		Mode:  mode,
		Value: value,
	}
}

// ReceiverSinks lists the OTLP sinks that StartUpSinks starts for each signal.
type ReceiverSinks struct {
	Metrics []*MetricSinkConfig
	Traces  []*TraceSinkConfig
	Logs    []*LogSinkConfig
}

// MetricSinkConfig is a metrics sink and the ports its OTLP receiver listens on.
type MetricSinkConfig struct {
	Ports    *ReceiverPorts
	Consumer *consumertest.MetricsSink
}

// TraceSinkConfig is a traces sink and the ports its OTLP receiver listens on.
type TraceSinkConfig struct {
	Ports    *ReceiverPorts
	Consumer *consumertest.TracesSink
}

// LogSinkConfig is a logs sink and the ports its OTLP receiver listens on.
type LogSinkConfig struct {
	Ports    *ReceiverPorts
	Consumer *consumertest.LogsSink
}

// ReceiverPorts are the OTLP gRPC and HTTP ports a sink listens on. A nil *ReceiverPorts means the default ports 4317 and 4318.
type ReceiverPorts struct {
	Grpc int
	HTTP int
}

// StartUpSinks starts an OTLP receiver for every sink in sinks and returns a function that shuts them all down.
func StartUpSinks(t *testing.T, sinks ReceiverSinks) func() {
	shutDownFuncs := []func(){}

	if sinks.Metrics != nil {
		for _, sink := range sinks.Metrics {
			fMetric := otlpreceiver.NewFactory()
			cfg := fMetric.CreateDefaultConfig().(*otlpreceiver.Config)
			setupReceiverPorts(cfg, sink.Ports)
			metricsRcvr, err := fMetric.CreateMetrics(context.Background(), receivertest.NewNopSettings(component.MustNewType("otlp")), cfg, sink.Consumer)
			require.NoError(t, err, "failed creating metrics receiver")
			require.NoError(t, metricsRcvr.Start(context.Background(), componenttest.NewNopHost()))
			shutDownFuncs = append(shutDownFuncs, func() {
				assert.NoError(t, metricsRcvr.Shutdown(context.Background()))
			})
		}
	}
	if sinks.Traces != nil {
		for _, sink := range sinks.Traces {
			fTrace := otlpreceiver.NewFactory()
			cfg := fTrace.CreateDefaultConfig().(*otlpreceiver.Config)
			setupReceiverPorts(cfg, sink.Ports)
			tracesRcvr, err := fTrace.CreateTraces(context.Background(), receivertest.NewNopSettings(component.MustNewType("otlp")), cfg, sink.Consumer)
			require.NoError(t, err, "failed creating traces receiver")
			require.NoError(t, tracesRcvr.Start(context.Background(), componenttest.NewNopHost()))
			shutDownFuncs = append(shutDownFuncs, func() {
				assert.NoError(t, tracesRcvr.Shutdown(context.Background()))
			})
		}
	}
	if sinks.Logs != nil {
		for _, sink := range sinks.Logs {
			fLog := otlpreceiver.NewFactory()
			cfg := fLog.CreateDefaultConfig().(*otlpreceiver.Config)
			setupReceiverPorts(cfg, sink.Ports)
			logsRcvr, err := fLog.CreateLogs(context.Background(), receivertest.NewNopSettings(component.MustNewType("otlp")), cfg, sink.Consumer)
			require.NoError(t, err, "failed creating logs receiver")
			require.NoError(t, logsRcvr.Start(context.Background(), componenttest.NewNopHost()))
			shutDownFuncs = append(shutDownFuncs, func() {
				assert.NoError(t, logsRcvr.Shutdown(context.Background()))
			})
		}
	}

	return func() {
		for _, f := range shutDownFuncs {
			f()
		}
	}
}

// availablePort asks the OS for a free port. testutil.GetAvailablePort can't be used because
// packages of this module can't import each other: the module is named testcommon but is
// imported under its full path.
func availablePort(t *testing.T) int {
	l, err := net.Listen("tcp", "localhost:0")
	require.NoError(t, err)
	defer l.Close()
	return l.Addr().(*net.TCPAddr).Port
}

func availablePorts(t *testing.T) *ReceiverPorts {
	return &ReceiverPorts{Grpc: availablePort(t), HTTP: availablePort(t)}
}

// StartTracesSink starts a traces sink on free ports until the test ends.
func StartTracesSink(t *testing.T) (*consumertest.TracesSink, ReceiverPorts) {
	sink := new(consumertest.TracesSink)
	return sink, StartReceiver(t, Consumers{Traces: sink})
}

// StartMetricsSink starts a metrics sink on free ports until the test ends.
func StartMetricsSink(t *testing.T) (*consumertest.MetricsSink, ReceiverPorts) {
	sink := new(consumertest.MetricsSink)
	return sink, StartReceiver(t, Consumers{Metrics: sink})
}

// StartLogsSink starts a logs sink on free ports until the test ends.
func StartLogsSink(t *testing.T) (*consumertest.LogsSink, ReceiverPorts) {
	sink := new(consumertest.LogsSink)
	return sink, StartReceiver(t, Consumers{Logs: sink})
}

// Consumers are the consumers served by StartReceiver. A nil consumer means the signal isn't served.
type Consumers struct {
	Traces  consumer.Traces
	Metrics consumer.Metrics
	Logs    consumer.Logs
}

// StartReceiver starts a single OTLP receiver on free ports that serves all given consumers, until
// the test ends. The receivers of all signals share one config, so they share one port pair.
func StartReceiver(t *testing.T, c Consumers) ReceiverPorts {
	ports := availablePorts(t)
	f := otlpreceiver.NewFactory()
	cfg := f.CreateDefaultConfig().(*otlpreceiver.Config)
	setupReceiverPorts(cfg, ports)
	set := receivertest.NewNopSettings(component.MustNewType("otlp"))

	var receivers []component.Component
	if c.Traces != nil {
		r, err := f.CreateTraces(context.Background(), set, cfg, c.Traces)
		require.NoError(t, err, "failed creating traces receiver")
		receivers = append(receivers, r)
	}
	if c.Metrics != nil {
		r, err := f.CreateMetrics(context.Background(), set, cfg, c.Metrics)
		require.NoError(t, err, "failed creating metrics receiver")
		receivers = append(receivers, r)
	}
	if c.Logs != nil {
		r, err := f.CreateLogs(context.Background(), set, cfg, c.Logs)
		require.NoError(t, err, "failed creating logs receiver")
		receivers = append(receivers, r)
	}
	for _, r := range receivers {
		require.NoError(t, r.Start(context.Background(), componenttest.NewNopHost()))
		t.Cleanup(func() { assert.NoError(t, r.Shutdown(context.Background())) })
	}
	return *ports
}

// Sinks holds one sink per signal, all served by the same OTLP receiver.
type Sinks struct {
	Traces  *consumertest.TracesSink
	Metrics *consumertest.MetricsSink
	Logs    *consumertest.LogsSink
}

// StartSinks starts a single OTLP receiver on free ports that accepts all three signals, until the test ends.
func StartSinks(t *testing.T) (Sinks, ReceiverPorts) {
	sinks := Sinks{Traces: new(consumertest.TracesSink), Metrics: new(consumertest.MetricsSink), Logs: new(consumertest.LogsSink)}
	ports := StartReceiver(t, Consumers{Traces: sinks.Traces, Metrics: sinks.Metrics, Logs: sinks.Logs})
	return sinks, ports
}

// InsertDefault is a helper function to insert a default value for a configoptional.Optional type.
func InsertDefault[T any](opt *configoptional.Optional[T]) error {
	if opt.HasValue() {
		return nil
	}

	empty := confmap.NewFromStringMap(map[string]any{})
	return empty.Unmarshal(opt)
}

func setupReceiverPorts(cfg *otlpreceiver.Config, ports *ReceiverPorts) {
	if err := InsertDefault(&cfg.Protocols.GRPC); err != nil {
		panic(fmt.Sprintf("failed to insert default for gRPC config: %v", err))
	}

	if err := InsertDefault(&cfg.Protocols.HTTP); err != nil {
		panic(fmt.Sprintf("failed to insert default for gRPC config: %v", err))
	}

	if ports != nil {
		cfg.Protocols.GRPC.Get().NetAddr.Endpoint = "0.0.0.0:" + strconv.Itoa(ports.Grpc)
		cfg.Protocols.HTTP.Get().ServerConfig.NetAddr.Endpoint = "0.0.0.0:" + strconv.Itoa(ports.HTTP)
	} else {
		cfg.Protocols.GRPC.Get().NetAddr.Endpoint = "0.0.0.0:4317"
		cfg.Protocols.HTTP.Get().ServerConfig.NetAddr.Endpoint = "0.0.0.0:4318"
	}
}

// WaitForMetrics fails the test unless the sink receives at least entriesNum metric batches within 5 minutes.
func WaitForMetrics(t *testing.T, entriesNum int, mc *consumertest.MetricsSink) {
	timeoutMinutes := 5
	require.Eventuallyf(t, func() bool {
		return len(mc.AllMetrics()) >= entriesNum
	}, time.Duration(timeoutMinutes)*time.Minute, 1*time.Second,
		"failed to receive %d entries,  received %d metrics in %d minutes", entriesNum,
		len(mc.AllMetrics()), timeoutMinutes)
}

// WaitForTraces fails the test unless the sink receives at least entriesNum trace batches within 5 minutes.
func WaitForTraces(t *testing.T, entriesNum int, tc *consumertest.TracesSink) {
	timeoutMinutes := 5
	require.Eventuallyf(t, func() bool {
		return len(tc.AllTraces()) >= entriesNum
	}, time.Duration(timeoutMinutes)*time.Minute, 1*time.Second,
		"failed to receive %d entries,  received %d traces in %d minutes", entriesNum,
		len(tc.AllTraces()), timeoutMinutes)
}

// WaitForLogs fails the test unless the sink receives at least entriesNum log batches within 5 minutes.
func WaitForLogs(t *testing.T, entriesNum int, tc *consumertest.LogsSink) {
	timeoutMinutes := 5
	require.Eventuallyf(t, func() bool {
		return len(tc.AllLogs()) >= entriesNum
	}, time.Duration(timeoutMinutes)*time.Minute, 1*time.Second,
		"failed to receive %d entries,  received %d logs in %d minutes", entriesNum,
		len(tc.AllLogs()), timeoutMinutes)
}

// ScanTracesForAttributes finds the first trace whose resource has service.name expectedService and asserts that the
// resource matches kvs and that, for each entry of scopeSpanAttrs, a span of its first scope matches it. It fails the
// test if no such trace exists.
func ScanTracesForAttributes(t *testing.T, ts *consumertest.TracesSink, expectedService string, kvs map[string]ExpectedValue, scopeSpanAttrs []map[string]ExpectedValue) {
	for i := 0; i < len(ts.AllTraces()); i++ {
		traces := ts.AllTraces()[i]
		for i := 0; i < traces.ResourceSpans().Len(); i++ {
			resource := traces.ResourceSpans().At(i).Resource()
			service, exist := resource.Attributes().Get(ServiceNameAttribute)
			require.True(t, exist, "Resource does not have the 'service.name' attribute")
			if service.AsString() != expectedService {
				continue
			}
			assert.NoError(t, AssertExpectedAttributes(resource.Attributes(), kvs))

			if len(scopeSpanAttrs) == 0 {
				return
			}

			require.NotZero(t, traces.ResourceSpans().At(i).ScopeSpans().Len())
			require.NotZero(t, traces.ResourceSpans().At(i).ScopeSpans().At(0).Spans().Len())

			scopeSpan := traces.ResourceSpans().At(i).ScopeSpans().At(0)

			// look for matching spans containing the desired attributes
			for _, spanAttrs := range scopeSpanAttrs {
				var err error
				for j := 0; j < scopeSpan.Spans().Len(); j++ {
					err = AssertExpectedAttributes(scopeSpan.Spans().At(j).Attributes(), spanAttrs)
					if err == nil {
						break
					}
				}
				assert.NoError(t, err)
			}

			return
		}
	}
	t.Fatalf("no spans found for service %s", expectedService)
}

// AssertExpectedAttributes returns an error listing the entries of kvs that attrs does not match.
func AssertExpectedAttributes(attrs pcommon.Map, kvs map[string]ExpectedValue) error {
	foundAttrs := make(map[string]bool)
	for k := range kvs {
		foundAttrs[k] = false
	}

	attrs.Range(
		func(k string, v pcommon.Value) bool {
			if val, ok := kvs[k]; ok {
				switch val.Mode {
				case AttributeMatchTypeEqual:
					if val.Value == v.AsString() {
						foundAttrs[k] = true
					}
				case AttributeMatchTypeRegex:
					matched, _ := regexp.MatchString(val.Value, v.AsString())
					if matched {
						foundAttrs[k] = true
					}
				case AttributeMatchTypeExist:
					foundAttrs[k] = true
				}
			}
			return true
		},
	)

	var err error
	for k, v := range foundAttrs {
		if !v {
			err = errors.Join(err, fmt.Errorf("attribute '%v' not found", k))
		}
	}
	if err != nil {
		// if something is missing, add a summary with an overview of the expected and actual attributes for easier troubleshooting
		expectedJSON, _ := json.MarshalIndent(kvs, "", "  ")
		actualJSON, _ := json.MarshalIndent(attrs.AsRaw(), "", "  ")
		err = errors.Join(err, fmt.Errorf("one or more attributes were not found.\nExpected attributes:\n %s \nActual attributes: \n%s", expectedJSON, actualJSON))
	}
	return err
}

// ScanForServiceMetrics asserts that the metrics sink provided in the arguments
// contains the given metrics for a service
func ScanForServiceMetrics(t *testing.T, ms *consumertest.MetricsSink, expectedService string, expectedMetrics []string) {
	for _, r := range ms.AllMetrics() {
		for i := 0; i < r.ResourceMetrics().Len(); i++ {
			resource := r.ResourceMetrics().At(i).Resource()
			service, exist := resource.Attributes().Get(ServiceNameAttribute)
			require.True(t, exist, "resource does not have the 'service.name' attribute")
			if service.AsString() != expectedService {
				t.Logf("skipping resource with service.name %s", service.AsString())
				continue
			}

			require.Positive(t, r.ResourceMetrics().At(i).ScopeMetrics().Len(), "resource has no scope metrics")
			sm := r.ResourceMetrics().At(i).ScopeMetrics().At(0).Metrics()
			assert.NoError(t, assertExpectedMetrics(expectedMetrics, sm))
			return
		}
	}
	t.Fatalf("no metric found for service %s", expectedService)
}

func assertExpectedMetrics(expectedMetrics []string, sm pmetric.MetricSlice) error {
	var actualMetrics []string
	for i := 0; i < sm.Len(); i++ {
		actualMetrics = append(actualMetrics, sm.At(i).Name())
	}

	for _, m := range expectedMetrics {
		if !slices.Contains(actualMetrics, m) {
			return fmt.Errorf("metric: %s not found", m)
		}
	}
	return nil
}
