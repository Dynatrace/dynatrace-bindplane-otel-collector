// Copyright The OpenTelemetry Authors
// Copyright Dynatrace LLC
// SPDX-License-Identifier: Apache-2.0

// Package k8stest provides helpers for the Kubernetes e2e tests: collector config
// rendering, object creation and metrics-server queries.
package k8stest // import "github.com/open-telemetry/opentelemetry-collector-contrib/internal/k8stest"

import (
	"bufio"
	"fmt"
	"os"
	"strings"
	"testing"

	"github.com/open-telemetry/opentelemetry-collector-contrib/pkg/xk8stest"
	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
)

// ConfigTemplate holds the values substituted into a Collector config by GetCollectorConfig.
type ConfigTemplate struct {
	Host      string
	Namespace string
	// Overlays are YAML strings applied in order; later ones win.
	Templates []string
}

// GetCollectorConfig reads the config at path, substitutes the ${env:...} placeholders from template, and deep-merges
// template.Templates over it. It returns "" if path is empty.
func GetCollectorConfig(path string, template ConfigTemplate) (string, error) {
	if path == "" {
		return "", nil
	}

	//#nosec G304 -- path is chosen by the test
	baseBytes, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}

	replacer := strings.NewReplacer(
		"${env:DT_ENDPOINT}", fmt.Sprintf("http://%s:4318", template.Host),
		"${env:DT_PLATFORM_TOKEN}", "",
		"${env:NAMESPACE}", template.Namespace,
	)

	// Replace BEFORE parsing so ${env:...} in flow sequences doesn't break yaml
	baseStr := replacer.Replace(string(baseBytes))

	// 1) Parse base into yaml.Node tree
	var baseDoc yaml.Node
	if err := yaml.Unmarshal([]byte(baseStr), &baseDoc); err != nil {
		return "", fmt.Errorf("unmarshal base config %q: %w", path, err)
	}

	// 2) Apply overlays via deep node merge
	for i, ov := range template.Templates {
		if strings.TrimSpace(ov) == "" {
			continue
		}
		ov = replacer.Replace(ov)
		var overlayDoc yaml.Node
		if err := yaml.Unmarshal([]byte(ov), &overlayDoc); err != nil {
			return "", fmt.Errorf("unmarshal overlay %d: %w", i, err)
		}
		mergeNodes(baseDoc.Content[0], overlayDoc.Content[0])
	}

	// 3) Encode back — use yaml.Encoder with explicit settings to avoid
	// mangling key names or adding document separators
	var buf strings.Builder
	enc := yaml.NewEncoder(&buf)
	enc.SetIndent(2)
	if err := enc.Encode(baseDoc.Content[0]); err != nil {
		return "", fmt.Errorf("marshal merged config: %w", err)
	}
	if err := enc.Close(); err != nil {
		return "", fmt.Errorf("close merged config encoder: %w", err)
	}

	// 4) Indent for ConfigMap
	var b strings.Builder
	sc := bufio.NewScanner(strings.NewReader(buf.String()))
	for sc.Scan() {
		b.WriteString("    ")
		b.WriteString(sc.Text())
		b.WriteByte('\n')
	}
	if err := sc.Err(); err != nil {
		return "", fmt.Errorf("building indented config: %w", err)
	}

	return b.String(), nil
}

// mergeNodes deep-merges src into dst at the yaml.Node level.
func mergeNodes(base, overlay *yaml.Node) *yaml.Node {
	if base.Kind == yaml.MappingNode && overlay.Kind == yaml.MappingNode {
		for oi := 0; oi < len(overlay.Content)-1; oi += 2 {
			overlayKey := overlay.Content[oi].Value
			found := false
			for bi := 0; bi < len(base.Content)-1; bi += 2 {
				if base.Content[bi].Value == overlayKey {
					//  Key exists in base — recurse, don't replace
					base.Content[bi+1] = mergeNodes(base.Content[bi+1], overlay.Content[oi+1])
					found = true
					break
				}
			}
			if !found {
				//  New key — append cloned nodes
				base.Content = append(base.Content,
					cloneNode(overlay.Content[oi]),
					cloneNode(overlay.Content[oi+1]),
				)
			}
		}
		return base
	}
	// Scalar or sequence — overlay wins, return a clone
	return cloneNode(overlay)
}

// cloneNode returns a deep copy of a yaml.Node so no two nodes
// in the tree share the same pointer — prevents yaml.v3 from
// emitting anchors/aliases which corrupt key names on marshal.
func cloneNode(n *yaml.Node) *yaml.Node {
	if n == nil {
		return nil
	}
	clone := *n // copy all scalar fields (Kind, Tag, Value, Style, etc.)
	if len(n.Content) > 0 {
		clone.Content = make([]*yaml.Node, len(n.Content))
		for i, child := range n.Content {
			clone.Content[i] = cloneNode(child)
		}
	}
	// Clear anchor/alias fields so yaml.v3 doesn't reuse them
	clone.Anchor = ""
	return &clone
}

// KubeconfigFromEnvOrDefault returns the kubeconfig path from KubeConfigEnvVar, or TestKubeConfig if unset.
func KubeconfigFromEnvOrDefault() string {
	if fromEnv := os.Getenv(KubeConfigEnvVar); fromEnv != "" {
		return fromEnv
	}
	return TestKubeConfig
}

// CreateObjectFromFile creates the object in file and deletes it when the test ends.
func CreateObjectFromFile(t *testing.T, client *xk8stest.K8sClient, file string) *unstructured.Unstructured {
	//#nosec G304 -- path is chosen by the test
	buf, err := os.ReadFile(file)
	require.NoErrorf(t, err, "failed to read object file %s", file)

	obj, err := xk8stest.CreateObject(client, buf)
	require.NoErrorf(t, err, "failed to create k8s object from file %s", file)

	t.Cleanup(func() {
		require.NoErrorf(t, xk8stest.DeleteObject(client, obj), "failed to delete object %s", obj.GetName())
	})
	return obj
}

// CreateCollectorObjects creates the Collector objects from manifestsDir and deletes them when the test ends.
func CreateCollectorObjects(t *testing.T, client *xk8stest.K8sClient, testID string, manifestsDir string, values map[string]string, host string) []*unstructured.Unstructured {
	objs := xk8stest.CreateCollectorObjects(t, client, testID, manifestsDir, values, host)
	t.Cleanup(func() {
		for _, obj := range objs {
			require.NoErrorf(t, xk8stest.DeleteObject(client, obj), "failed to delete object %s", obj.GetName())
		}
	})
	return objs
}

// MustRead returns the content of the file p as a string.
func MustRead(t *testing.T, p string) string {
	//#nosec G304 -- path is chosen by the test
	b, err := os.ReadFile(p)
	require.NoErrorf(t, err, "read file %s", p)
	return string(b)
}
