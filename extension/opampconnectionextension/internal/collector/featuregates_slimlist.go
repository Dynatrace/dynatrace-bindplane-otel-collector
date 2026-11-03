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

package collector

// SlimSkippedFeatureGates are gates registered by components the slim build leaves out.
// Each entry is a verbatim copy of a hardcodedFeatureGates line (prefix and all);
// its gate is skipped only while the registry doesn't know it, so adding the
// component back to the slim build puts the gate back in effect. It's exported so
// the slim build check can read it from any build.
var SlimSkippedFeatureGates = []string{
	"exporter.prometheusremotewritexporter.enableSendingRW2", // prometheusremotewriteexporter
	"-exporter.prometheusexporter.DisableAddMetricSuffixes",  // prometheusexporter
	// Added in 1.3.0. Remove in 1.4.0.
	"-pkg.translator.zipkin.DontEmitV0ScopeConventions", // kafkaexporter, kafkareceiver
	"-pkg.translator.zipkin.DontEmitV0HttpConventions",  // kafkaexporter, kafkareceiver
}
