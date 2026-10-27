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

package main

import (
	"testing"

	"github.com/open-telemetry/opamp-go/protobufs"
	"github.com/stretchr/testify/require"
)

func codeNamespace(v string) *protobufs.KeyValue {
	return &protobufs.KeyValue{Key: "code.namespace", Value: &protobufs.AnyValue{Value: &protobufs.AnyValue_StringValue{StringValue: v}}}
}

func TestReportLegacyOpAMPConnectionNamespace(t *testing.T) {
	ac := &protobufs.AvailableComponents{
		Components: map[string]*protobufs.ComponentDetails{
			"extensions": {SubComponentMap: map[string]*protobufs.ComponentDetails{
				"opamp_connection": {Metadata: []*protobufs.KeyValue{codeNamespace("github.com/dynatrace/dynatrace-bindplane-otel-collector/extension/opampconnectionextension v1.1.0")}},
				"zpages":           {Metadata: []*protobufs.KeyValue{codeNamespace("go.opentelemetry.io/collector/extension/zpagesextension v0.162.0")}},
			}},
		},
	}

	reportLegacyOpAMPConnectionNamespace(ac)

	ext := ac.Components["extensions"].SubComponentMap["opamp_connection"]
	require.Len(t, ext.Metadata, 2)
	require.Equal(t, "code.namespace", ext.Metadata[1].Key)
	require.Equal(t, legacyOpAMPConnectionModule+" v1.1.0", ext.Metadata[1].Value.GetStringValue())
	require.Len(t, ac.Components["extensions"].SubComponentMap["zpages"].Metadata, 1, "other components are untouched")
}

func TestReportLegacyOpAMPConnectionNamespace_NoExtension(t *testing.T) {
	require.NotPanics(t, func() { reportLegacyOpAMPConnectionNamespace(&protobufs.AvailableComponents{}) })
}
