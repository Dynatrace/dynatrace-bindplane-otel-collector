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

// Package distro holds the identity of the collector distribution the updater
// is built for. Every value is stamped at link time with
// -X github.com/dynatrace/dynatrace-bindplane-otel-collector/updater/internal/distro.<var>=<value>
// (see UPDATER_LDFLAGS in the Makefile). The defaults are generic placeholders
// so an unstamped build is obviously unstamped. The values must match the
// distro's packaging, or the updater cannot find the install it is updating:
//
//   - name: product slug. Install dir (/opt/<name>), binary name, systemd unit,
//     init.d script, /etc/default and /etc/sysconfig files, Windows service
//     name and the AIX env file (/etc/<name>.env).
//   - displayName: systemd/init.d description, and the Windows MSI product
//     name (the "product" field in windows/wix.json, which names the
//     registry key holding the install dir).
//   - launchdLabel: macOS launchd label; the plist is <launchdLabel>.plist.
//   - configHomeEnv: key in the /etc/default or /etc/sysconfig file that
//     overrides the Linux install dir.
//   - aixSubsystem, aixGroup: AIX SRC subsystem and group names.
package distro

var (
	name          = "otelcol"
	displayName   = "OpenTelemetry Collector"
	launchdLabel  = "otelcol"
	configHomeEnv = "OTELCOL_CONFIG_HOME"
	aixSubsystem  = "otelcol"
	aixGroup      = "otelcol"
)

// Name returns the product slug.
func Name() string { return name }

// DisplayName returns the human readable product name.
func DisplayName() string { return displayName }

// LaunchdLabel returns the macOS launchd label.
func LaunchdLabel() string { return launchdLabel }

// ConfigHomeEnv returns the key that overrides the Linux install dir.
func ConfigHomeEnv() string { return configHomeEnv }

// AIXSubsystem returns the AIX SRC subsystem name.
func AIXSubsystem() string { return aixSubsystem }

// AIXGroup returns the AIX SRC group name.
func AIXGroup() string { return aixGroup }
