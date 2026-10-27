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

// Package main is the entry point for the ocb-built DBDOT Collector. The
// `agent` Make target copies this file over ocb's generated main.go after
// `builder --skip-compilation` runs; `go build` then compiles it together
// with ocb's components.go inside ./build/.
//
// In its source location this file compiles against the stub `components()`
// in components_stub.go (`go test ./...` inside the extension module is
// fine). When it lands in ./build/, the stub is not copied — ocb's
// generated components.go is the only definition of `components()` and
// returns the manifest's full factory set.
//
// Everything else — flag parsing, managed/standalone dispatch, OpAMP
// wiring, collector lifecycle — lives behind
// opampconnectionextension/runtime.Run.
package main

import (
	"crypto/sha256"
	"fmt"
	"log"
	"os"
	"strings"
	_ "time/tzdata"

	"github.com/dynatrace/dynatrace-bindplane-otel-collector/extension/opampconnectionextension/runtime"
	"github.com/dynatrace/dynatrace-bindplane-otel-contrib/pkg/version"
	"github.com/open-telemetry/opamp-go/protobufs"
	"github.com/spf13/pflag"
)

// Env-var fallbacks for paths (matches legacy cmd/collector behavior).
const (
	configPathENV   = "CONFIG_YAML_PATH"
	managerPathENV  = "MANAGER_YAML_PATH"
	loggingPathENV  = "LOGGING_YAML_PATH"
	featureGatesENV = "COLLECTOR_FEATURE_GATES"
)

func main() {
	collectorConfigPaths := pflag.StringSlice("config", defaultCollectorPaths(), "the collector config path")
	managerConfigPath := pflag.String("manager", defaultManagerPath(), "The configuration for remote management")
	loggingConfigPath := pflag.String("logging", defaultLoggingPath(), "the collector logging config path")
	featureGates := pflag.StringSlice("feature-gates", defaultFeatureGates(), "the collector feature gates")

	_ = pflag.String("log-level", "", "not implemented") // TEMP(jsirianni): Required for OTEL k8s operator
	var showVersion = pflag.BoolP("version", "v", false, "prints the version of the collector")
	pflag.Parse()

	if *showVersion {
		fmt.Println("dynatrace-bindplane-otel-collector version", version.Version())
		fmt.Println("commit:", version.GitHash())
		fmt.Println("built at:", version.Date())
		return
	}

	factories, err := components()
	if err != nil {
		log.Fatalf("Failed to build factories from manifest: %v", err)
	}

	runtime.Run(runtime.Options{
		Factories:                  factories,
		Version:                    version.Version(),
		CollectorConfigPaths:       *collectorConfigPaths,
		ManagerConfigPath:          *managerConfigPath,
		LoggingConfigPath:          *loggingConfigPath,
		FeatureGates:               *featureGates,
		AvailableComponentsMutator: reportLegacyOpAMPConnectionNamespace,
	})
}

// legacyOpAMPConnectionModule is where the opamp_connection extension lived
// before it moved out of internal/ (#59). Bindplane v1.104.x identifies the
// extension by that path, so keep reporting it next to the current one.
const legacyOpAMPConnectionModule = "github.com/dynatrace/dynatrace-bindplane-otel-collector/internal/extension/opampconnectionextension"

// reportLegacyOpAMPConnectionNamespace adds a second code.namespace entry to
// the opamp_connection extension naming legacyOpAMPConnectionModule at the
// version the current module reports, and folds that entry into the report
// hash: the server caches reports by hash, so the mutated report must not
// share the factory-set hash with the unmutated one. ponytail: delete once
// no supported Bindplane release requires the internal/ path.
func reportLegacyOpAMPConnectionNamespace(ac *protobufs.AvailableComponents) {
	ext := ac.GetComponents()["extensions"].GetSubComponentMap()["opamp_connection"]
	for _, kv := range ext.GetMetadata() {
		if kv.GetKey() != "code.namespace" {
			continue
		}
		_, version, ok := strings.Cut(kv.GetValue().GetStringValue(), " ")
		if !ok {
			return
		}
		legacy := legacyOpAMPConnectionModule + " " + version
		ext.Metadata = append(ext.Metadata, &protobufs.KeyValue{
			Key:   "code.namespace",
			Value: &protobufs.AnyValue{Value: &protobufs.AnyValue_StringValue{StringValue: legacy}},
		})
		h := sha256.New()
		h.Write(ac.GetHash())
		h.Write([]byte(legacy))
		ac.Hash = h.Sum(nil)
		return
	}
}

func defaultCollectorPaths() []string {
	if cp, ok := os.LookupEnv(configPathENV); ok {
		return []string{cp}
	}
	return []string{"./config.yaml"}
}

func defaultManagerPath() string {
	if mp, ok := os.LookupEnv(managerPathENV); ok {
		return mp
	}
	return "./manager.yaml"
}

func defaultLoggingPath() string {
	if lp, ok := os.LookupEnv(loggingPathENV); ok {
		return lp
	}
	return runtime.DefaultLoggingPath
}

func defaultFeatureGates() []string {
	if fg, ok := os.LookupEnv(featureGatesENV); ok {
		return strings.Split(fg, ",")
	}
	return nil
}
