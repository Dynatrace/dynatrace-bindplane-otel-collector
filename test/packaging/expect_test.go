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

//go:build packaging

package packaging

// Expected state of a system with the package installed using the default
// package overrides (DBDOT_USER=dbdot, DBDOT_GROUP=dbdot, DBDOT_UNPRIVILEGED=false,
// DBDOT_CONFIG_HOME=/opt/dynatrace-bindplane-otel-collector). The values are derived from
// the nfpm contents in .goreleaser.yml and scripts/package/*.sh.

const (
	installDir  = "/opt/dynatrace-bindplane-otel-collector"
	stageRoot   = "/usr/share/dynatrace-bindplane-otel-collector"
	unitPath    = "/usr/lib/systemd/system/dynatrace-bindplane-otel-collector.service"
	dropInDir   = "/etc/systemd/system/dynatrace-bindplane-otel-collector.service.d"
	wantsPath   = "/etc/systemd/system/multi-user.target.wants/dynatrace-bindplane-otel-collector.service"
	initdPath   = "/etc/init.d/dynatrace-bindplane-otel-collector"
	runtimeUser = "dbdot"
	runtimeGrp  = "dbdot"

	// standaloneLogLine is logged by the collector at startup when no
	// manager.yaml is present.
	standaloneLogLine = "Starting Standalone Mode"
)

// fileEntry is the type and permissions of a path. Type uses find's %y
// letters: f (regular file), d (directory), l (symlink).
type fileEntry struct {
	Type  string
	Owner string
	Group string
	Mode  string // octal permission bits, as printed by find %m / stat %a
}

// installTree returns the expected entries under installDir after a fresh
// install and before the service is started, keyed by path relative to
// installDir ("" is installDir itself). plugins is the list of plugin files
// in the package payload.
func installTree(plugins []string) map[string]fileEntry {
	tree := map[string]fileEntry{
		"":                                   {"d", runtimeUser, runtimeGrp, "755"},
		"dynatrace-bindplane-otel-collector": {"f", runtimeUser, runtimeGrp, "755"},
		"updater":                            {"f", "root", "root", "755"},
		"config.yaml":                        {"f", runtimeUser, runtimeGrp, "640"},
		"logging.yaml":                       {"f", runtimeUser, runtimeGrp, "640"},
		"LICENSE":                            {"f", runtimeUser, runtimeGrp, "644"},
		"VERSION.txt":                        {"f", runtimeUser, runtimeGrp, "644"},
		"plugins":                            {"d", runtimeUser, runtimeGrp, "750"},
		"storage":                            {"d", runtimeUser, runtimeGrp, "750"},
		"log":                                {"d", runtimeUser, runtimeGrp, "750"},
		// Created by postinstall so the service (running as root) does not
		// create it owned by root.
		"log/collector.log": {"f", runtimeUser, runtimeGrp, "644"},
	}
	for _, p := range plugins {
		tree["plugins/"+p] = fileEntry{"f", runtimeUser, runtimeGrp, "640"}
	}
	return tree
}

// installSystemFiles are the expected paths outside installDir after install.
var installSystemFiles = map[string]fileEntry{
	unitPath:  {"f", "root", "root", "640"},
	dropInDir: {"d", "root", "root", "755"},
}

// installAbsent are paths that must not exist after install.
var installAbsent = []string{
	// Only written when DBDOT_UNPRIVILEGED=true.
	dropInDir + "/10-package-customizations-username.conf",
	// The stage directory is removed by postinstall.
	stageRoot,
	// systemd hosts get a unit file, not an init script.
	initdPath,
}

// installUnitProps are the expected `systemctl show` properties of the unit.
// ExecStart and Environment are checked separately because they contain
// more than a single value.
var installUnitProps = map[string]string{
	"User":             "root",
	"Group":            runtimeGrp,
	"WorkingDirectory": installDir,
	"Restart":          "on-failure",
	"LimitNOFILE":      "65000",
	"KillMode":         "process",
	"FragmentPath":     unitPath,
}

// uninstallExpect is the expected state after the package is removed.
type uninstallExpect struct {
	// state is the output of formatOps.packageState.
	state string
	// present and absent are paths that must, or must not, exist.
	present []string
	absent  []string
}

// uninstallShared is the expected state after removal on every format. The
// uninstall scenario creates manager.yaml and storage/marker before removal.
// The package has no %ghost files, so deb and rpm keep and remove the same
// paths. postremove.sh removes the collector's files, the systemd unit, the
// drop-in directory and the init script.
var uninstallShared = uninstallExpect{
	present: []string{
		installDir,
		installDir + "/manager.yaml",
		installDir + "/storage",
		installDir + "/storage/marker",
		installDir + "/config.yaml",
		installDir + "/logging.yaml",
		installDir + "/LICENSE",
	},
	absent: []string{
		dropInDir,
		installDir + "/dynatrace-bindplane-otel-collector",
		installDir + "/updater",
		installDir + "/VERSION.txt",
		installDir + "/plugins",
		installDir + "/log",
		installDir + "/install",
		installDir + "/package_statuses.json",
		stageRoot,
		wantsPath,
		unitPath,
		initdPath,
	},
}

// debUninstall is the expected state after `dpkg -r`, in addition to
// uninstallShared.
var debUninstall = uninstallExpect{
	// dpkg keeps the package in the "rc" (removed, config remains) state
	// until it is purged, because the package has a postrm script.
	state: "rc",
	present: []string{
		// The package override file is not owned by the package.
		debOverridePath,
	},
}

// rpmUninstall is the expected state after `rpm -e`, in addition to
// uninstallShared.
var rpmUninstall = uninstallExpect{
	state: "",
	present: []string{
		// The package override file is not owned by the package.
		rpmOverridePath,
	},
}
