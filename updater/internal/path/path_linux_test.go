// Copyright Dynatrace LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package path

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
)

func TestInstallDir(t *testing.T) {
	customIni := filepath.Join(t.TempDir(), "custom_install_dir.ini")
	require.NoError(t, os.WriteFile(customIni, []byte(configHomeOverrideKey+"=/opt/custom\n"), 0600))

	tests := []struct {
		name            string
		configOverrides []string
		expectedDir     string
		errorContains   string
	}{
		{
			name:            "default install dir when no config files exist",
			configOverrides: []string{"nonexistent1.conf", "nonexistent2.conf"},
			expectedDir:     DefaultLinuxInstallDir,
		},
		{
			name:            "custom install dir",
			configOverrides: []string{customIni},
			expectedDir:     "/opt/custom",
		},
		{
			name:            "multi config - one missing",
			configOverrides: []string{"nonexist.ini", customIni},
			expectedDir:     "/opt/custom",
		},
		{
			name:            "multi config - two missing",
			configOverrides: []string{customIni, "nonexist.ini"},
			expectedDir:     "/opt/custom",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := InstallDir(zap.NewNop(), tt.configOverrides)

			if tt.errorContains != "" {
				require.Error(t, err, "InstallDir should return an error")
				require.ErrorAs(t, err, &tt.errorContains, "InstallDir should return the expected error")
				return
			}

			require.NoError(t, err, "InstallDir should not return an error")
			require.Equal(t, tt.expectedDir, result, "InstallDir returned unexpected directory")

		})
	}
}
