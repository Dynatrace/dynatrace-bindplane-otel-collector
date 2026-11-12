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

import (
	"maps"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// scenario runs the test scenarios for one distro. Each scenario starts a
// fresh container.
type scenario struct {
	env    *suiteEnv
	distro distro
	ops    formatOps
	// pkg is the host path of the package under test.
	pkg string
	// image is the systemd-enabled image for the distro.
	image string
}

// install installs the package on a clean system with the default
// overrides, which run the collector as the runtime user. It starts the
// service the way install_unix.sh does, checks the sudoers grant the updater
// uses, installs the package again, and then removes it.
func (s *scenario) install(t *testing.T) {
	b := startBox(t, s.env, s.image)
	pkg := b.copyPackage(s.pkg)

	out := b.installPackage(s.ops, pkg, false)
	s.assertInstalled(b, pkg, unprivilegedInstall, nil, nil)
	assert.Equal(t, "[Service]\nUser="+runtimeUser, b.mustRun("cat "+userDropIn), "User= drop-in contents")
	b.mustRun("visudo -cf " + sudoersPath)
	// postinstall warns when sudo won't let the runtime user run the
	// commands in the sudoers drop-in.
	assert.NotContains(t, out, "WARNING:", "install output")
	assert.NotContains(t, out, "NOTE:", "install output")
	assert.Contains(t, out, `The collector runs as the "`+runtimeUser+`" user.`, "install output")

	// The package configures the service but does not enable or start it.
	assert.Equal(t, "disabled", b.unitState("is-enabled"), "service should not be enabled by the package")
	assert.Equal(t, "inactive", b.unitState("is-active"), "service should not be started by the package")
	b.assertAbsent(wantsPath)

	b.mustRun("systemctl enable --now " + packageName)
	pid := b.assertServiceRunning(1, runtimeUser)

	// The updater stops and starts the service through sudo as the runtime
	// user. Nothing else is allowed.
	unit := packageName + ".service"
	for _, cmd := range []string{"sudo -n systemctl restart " + unit, "sudo -n true"} {
		assert.NotZero(t, b.run(asRuntimeUser(cmd)).code, "%s should be denied", cmd)
	}
	assert.Equal(t, pid, b.unitProps("MainPID")["MainPID"], "denied commands should not restart the service")

	b.mustRun(asRuntimeUser("sudo -n systemctl stop " + unit))
	assert.Equal(t, "inactive", b.unitState("is-active"), "service should be stopped")
	starts := b.startupCount()
	b.mustRun(asRuntimeUser("sudo -n systemctl start " + unit))
	pid = b.assertServiceRunning(starts+1, runtimeUser)

	// Installing it again with the default overrides keeps the runtime user.
	b.pkgCommand(s.ops.reinstall(pkg))
	// The running collector created its log.
	ranLog := func(p string) bool { return p == "log/collector.log" }
	s.assertInstalled(b, pkg, unprivilegedInstall, nil, ranLog)
	assert.Equal(t, pid, b.unitProps("MainPID")["MainPID"], "the install should not restart the service")

	s.uninstall(t, b)
}

// installRoot installs the package with DBDOT_UNPRIVILEGED=false, starts the
// service, and checks that it runs as root. It checks that making the install
// unprivileged is refused, and that installing it again with the default
// overrides keeps it running as root. Then it removes the package.
func (s *scenario) installRoot(t *testing.T) {
	b := startBox(t, s.env, s.image)
	pkg := b.copyPackage(s.pkg)

	b.writeOverride(s.ops, rootOverride)
	out := b.installPackage(s.ops, pkg, false)
	s.assertInstalled(b, pkg, privilegedInstall, nil, nil)
	assert.NotContains(t, out, "NOTE:", "install output")
	assert.Contains(t, out, `The collector runs as the "root" user.`, "install output")

	b.mustRun("systemctl enable --now " + packageName)
	pid := b.assertServiceRunning(1, "root")

	// Making the existing root install unprivileged is refused. The
	// collector would run as the runtime user against files root created.
	b.writeOverride(s.ops, unprivilegedOverride)
	cmd := s.ops.reinstall(pkg)
	res := b.run(cmd)
	t.Logf("$ %s\n%s", cmd, res)
	require.NotZero(t, res.code, "the install should be refused")
	assert.Contains(t, res.stdout+res.stderr, "set these values in "+s.ops.overridePath, "refusal message names the override file")
	assert.Contains(t, res.stdout+res.stderr, "DBDOT_UNPRIVILEGED=false", "refusal message names the value to restore")
	b.assertAbsent(userDropIn, sudoersPath)
	assert.Equal(t, pid, b.unitProps("MainPID")["MainPID"], "the refused install should not restart the service")
	b.assertPackageVersion(s.ops, pkg)

	// With the default overrides, the existing root install keeps running
	// as root, and the package says so.
	b.writeOverride(s.ops)
	out = b.pkgCommand(s.ops.reinstall(pkg))
	s.assertInstalled(b, pkg, privilegedInstall, nil, nil)
	assert.Contains(t, out, "NOTE: The collector keeps running as root", "install output")
	assert.Equal(t, pid, b.unitProps("MainPID")["MainPID"], "the install should not restart the service")

	s.uninstall(t, b)
}

// refusePrivileged installs the package with the default overrides, which
// run the service as the runtime user, and starts it. Then it installs the
// package again with DBDOT_UNPRIVILEGED=false, which would run the service as
// root. The runtime user owns installDir and can replace any entry in it with
// a symbolic link, which a root install would follow, so the package must
// refuse the install before it changes anything.
func (s *scenario) refusePrivileged(t *testing.T) {
	b := startBox(t, s.env, s.image)
	pkg := b.copyPackage(s.pkg)

	b.installPackage(s.ops, pkg, false)
	b.mustRun("systemctl enable --now " + packageName)
	pid := b.assertServiceRunning(1, runtimeUser)

	// A link the runtime user could plant. A root install would touch and
	// chown the canary through it.
	const canary = "/etc/pkgtest-canary"
	logPath := installDir + "/log/collector.log"
	b.mustRun("install -o root -g root -m 0600 /dev/null " + canary +
		" && ln -sfn " + canary + " " + logPath +
		" && chown -h " + runtimeUser + ":" + runtimeGrp + " " + logPath)
	statCanary := "stat -c '%U:%G %a %y' " + canary
	before := b.mustRun(statCanary)

	b.writeOverride(s.ops, rootOverride)
	cmd := s.ops.reinstall(pkg)
	res := b.run(cmd)
	t.Logf("$ %s\n%s", cmd, res)
	require.NotZero(t, res.code, "the install should be refused")
	assert.Contains(t, res.stdout+res.stderr, "Changing DBDOT_UNPRIVILEGED or DBDOT_USER on an existing install is not supported", "refusal message")
	assert.Contains(t, res.stdout+res.stderr, "set these values in "+s.ops.overridePath, "refusal message names the override file")
	assert.Contains(t, res.stdout+res.stderr, "DBDOT_USER="+runtimeUser, "refusal message names the runtime user")

	assert.Equal(t, before, b.mustRun(statCanary), "the refused install should not change the canary")
	b.assertPresent(userDropIn, sudoersPath)
	assert.Equal(t, "active", b.unitState("is-active"), "service should keep running")
	assert.Equal(t, pid, b.unitProps("MainPID")["MainPID"], "the refused install should not restart the service")
	// dpkg runs the installed package's postinst with abort-upgrade after
	// the refusal. It must not fail too, or the package is left
	// half-installed.
	b.assertPackageVersion(s.ops, pkg)

	// Restoring the overrides recovers the install. An unprivileged install
	// doesn't change files in installDir as root, so it leaves the link and
	// the canary alone.
	b.writeOverride(s.ops)
	b.pkgCommand(s.ops.reinstall(pkg))
	assert.Equal(t, before, b.mustRun(statCanary), "the unprivileged install should not change the canary")
	link := map[string]fileEntry{"log/collector.log": {"l", runtimeUser, runtimeGrp, "777"}}
	s.assertInstalled(b, pkg, unprivilegedInstall, link, nil)

	s.uninstall(t, b)
}

// reinstallUnprivileged installs the package as root and starts it, then
// follows the steps the refusal message gives to make an install
// unprivileged: it removes the package and DBDOT_CONFIG_HOME, writes
// DBDOT_UNPRIVILEGED=true, and installs the package again. The install is new,
// so it must not be refused. dpkg keeps a removed package in the "rc" state
// and passes the old version to postinst "configure", the same as on an
// upgrade.
func (s *scenario) reinstallUnprivileged(t *testing.T) {
	b := startBox(t, s.env, s.image)
	pkg := b.copyPackage(s.pkg)

	b.writeOverride(s.ops, rootOverride)
	b.installPackage(s.ops, pkg, false)
	b.mustRun("systemctl enable --now " + packageName)
	b.assertServiceRunning(1, "root")

	b.removePackage(s.ops)
	b.mustRun("rm -rf " + installDir)

	b.writeOverride(s.ops, unprivilegedOverride)
	b.installPackage(s.ops, pkg, false)
	s.assertInstalled(b, pkg, unprivilegedInstall, nil, nil)

	starts := b.startupCount()
	b.mustRun("systemctl enable --now " + packageName)
	b.assertServiceRunning(starts+1, runtimeUser)

	s.uninstall(t, b)
}

// reinstallLeftovers installs the package as root, starts it, and removes it,
// which leaves files that root owns in installDir. A new install with the
// default overrides would run the collector as the runtime user against those
// files, so the package must refuse it before it changes anything. An install
// as root is allowed. Then it removes the package.
func (s *scenario) reinstallLeftovers(t *testing.T) {
	b := startBox(t, s.env, s.image)
	pkg := b.copyPackage(s.pkg)

	b.writeOverride(s.ops, rootOverride)
	b.installPackage(s.ops, pkg, false)
	b.mustRun("systemctl enable --now " + packageName)
	b.assertServiceRunning(1, "root")
	// A file the collector creates while it runs as root.
	const rootFile = installDir + "/storage/root-owned"
	b.mustRun("install -o root -g root -m 0600 /dev/null " + rootFile)

	b.removePackage(s.ops)
	b.assertPresent(rootFile)

	b.writeOverride(s.ops)
	cmd := s.ops.install(pkg, false)
	res := b.run(cmd)
	t.Logf("$ %s\n%s", cmd, res)
	require.NotZero(t, res.code, "the install should be refused")
	assert.Contains(t, res.stdout+res.stderr, installDir+" holds files that root owns, such as "+rootFile, "refusal message names the file")
	assert.Contains(t, res.stdout+res.stderr, "DBDOT_UNPRIVILEGED=false", "refusal message names the override")
	b.assertAbsent(unitPath, userDropIn, sudoersPath, installDir+"/"+packageName)
	// dpkg marks the removed package to be installed ("ic") but leaves only
	// its config files, and rpm doesn't install it.
	assert.NotContains(t, []string{"ii", "installed"}, b.mustRun(s.ops.packageState), "the refused install should not install the package")

	b.writeOverride(s.ops, rootOverride)
	b.installPackage(s.ops, pkg, false)
	s.assertInstalled(b, pkg, privilegedInstall, map[string]fileEntry{"storage/root-owned": {"f", "root", "root", "600"}}, nil)

	s.uninstall(t, b)
}

// revertDropIn installs the package with the default overrides, starts it,
// and removes the User= drop-in, as `systemctl revert` does. The runtime user
// still owns installDir, so a root install would follow its links as root,
// and the user to run the collector as is unknown. The package must refuse
// the next install. Then it removes the package.
func (s *scenario) revertDropIn(t *testing.T) {
	b := startBox(t, s.env, s.image)
	pkg := b.copyPackage(s.pkg)

	b.installPackage(s.ops, pkg, false)
	b.mustRun("systemctl enable --now " + packageName)
	pid := b.assertServiceRunning(1, runtimeUser)

	b.mustRun("rm " + userDropIn + " && systemctl daemon-reload")

	for _, lines := range [][]string{nil, {rootOverride}} {
		b.writeOverride(s.ops, lines...)
		cmd := s.ops.reinstall(pkg)
		res := b.run(cmd)
		t.Logf("$ %s\n%s", cmd, res)
		require.NotZero(t, res.code, "the install with overrides %q should be refused", lines)
		assert.Contains(t, res.stdout+res.stderr, "The package can't tell which user to run the collector as", "refusal message")
		assert.Equal(t, pid, b.unitProps("MainPID")["MainPID"], "the refused install should not restart the service")
		b.assertPackageVersion(s.ops, pkg)
	}

	s.uninstall(t, b)
}

// upgrade installs a released package, starts it, modifies the files a user
// would, upgrades to the package under test, and then removes the package.
func (s *scenario) upgrade(t *testing.T, from string) {
	oldHostPkg := releasePackage(t, from, s.env.arch, s.distro.Format)
	b := startBox(t, s.env, s.image)
	oldPkg := b.copyPackage(oldHostPkg)
	newPkg := b.copyPackage(s.pkg)

	b.writeOverride(s.ops)
	b.installPackage(s.ops, oldPkg, false)
	b.mustRun("systemctl enable --now " + packageName)
	require.True(t, poll(time.Minute, func() bool { return b.startupCount() >= 1 }), "release %s should start", from)
	oldPID := b.unitProps("MainPID")["MainPID"]

	// User state that the upgrade must preserve.
	b.writeUserFiles(true)
	preserved := []string{
		installDir + "/config.yaml",
		installDir + "/logging.yaml",
		installDir + "/manager.yaml",
		installDir + "/storage/marker",
		s.ops.overridePath,
	}
	before := b.sha256sums(preserved...)

	// Upgrading to a snapshot of the release it is based on is a downgrade
	// as far as the package manager is concerned (1.2.3~SNAPSHOT < 1.2.3).
	oldVersion := b.mustRun(s.ops.fileVersion(oldPkg))
	newVersion := b.mustRun(s.ops.fileVersion(newPkg))
	downgrade := b.run(s.ops.older(newVersion, oldVersion)).code == 0
	if downgrade {
		t.Logf("%s is older than %s, installing it as a downgrade", newVersion, oldVersion)
	}
	out := b.installPackage(s.ops, newPkg, downgrade)

	assert.Equal(t, before, b.sha256sums(preserved...), "the upgrade should not modify user files")
	// Releases up to 1.3 ran the collector as root by default. The upgrade
	// keeps it running as root, and the package says so. Later releases run
	// it as the runtime user, and the upgrade keeps that.
	expect, user := unprivilegedInstall, runtimeUser
	if ranAsRootByDefault(t, from) {
		expect, user = privilegedInstall, "root"
		assert.Contains(t, out, "NOTE: The collector keeps running as root", "upgrade output")
	} else {
		assert.NotContains(t, out, "NOTE:", "upgrade output")
	}
	userFiles := map[string]fileEntry{
		"manager.yaml":   {"f", runtimeUser, runtimeGrp, "640"},
		"storage/marker": {"f", runtimeUser, runtimeGrp, "640"},
	}
	// Plugins removed from the new release are not cleaned up on upgrade.
	oldPlugins := func(p string) bool { return strings.HasPrefix(p, "plugins/") }
	// The collector that ran as the runtime user created its log.
	allowExtra := func(p string) bool { return oldPlugins(p) || (user == runtimeUser && p == "log/collector.log") }
	s.assertInstalled(b, newPkg, expect, userFiles, allowExtra)

	// The package does not restart the service; the old binary keeps
	// running until it is restarted.
	assert.Equal(t, "enabled", b.unitState("is-enabled"), "service should stay enabled")
	assert.Equal(t, "active", b.unitState("is-active"), "service should keep running")
	assert.Equal(t, oldPID, b.unitProps("MainPID")["MainPID"], "the package should not restart the service")

	// Restart like install_unix.sh does after an upgrade. manager.yaml is
	// removed first because it switches the collector to managed mode.
	b.mustRun("rm " + installDir + "/manager.yaml")
	starts := b.startupCount()
	b.mustRun("systemctl restart " + packageName)
	pid := b.assertServiceRunning(starts+1, user)
	assert.NotEqual(t, oldPID, pid, "service should have a new process after restart")

	s.uninstall(t, b)
}

// uninstall removes the installed and running package from b, and checks
// what is removed and what is kept. It runs as the "uninstall" subtest of
// each action.
func (s *scenario) uninstall(t *testing.T, b *box) {
	t.Run("uninstall", func(t *testing.T) {
		b := b.withT(t)

		// User state that removal keeps, or removes where the per-format
		// expectations say so. The package scripts source the override
		// file on removal too.
		b.writeOverride(s.ops)
		b.writeUserFiles(false)

		b.removePackage(s.ops)

		assert.NotEqual(t, "active", b.unitState("is-active"), "service should be stopped")
		assert.NotEqual(t, "enabled", b.unitState("is-enabled"), "service should be disabled")
		// The bracket keeps pgrep from matching the shell running it.
		assert.NotZero(t, b.run("pgrep -f '[/]opt/dynatrace-bindplane-otel-collector/dynatrace-bindplane-otel-collector'").code, "collector process should be stopped")

		b.assertPresent(uninstallShared.present...)
		b.assertAbsent(uninstallShared.absent...)
		b.assertPresent(s.ops.uninstall.present...)
		b.assertAbsent(s.ops.uninstall.absent...)
		assert.Equal(t, s.ops.uninstall.state, b.mustRun(s.ops.packageState), "package state after removal")
		assert.Zero(t, b.run("id "+runtimeUser).code, "user %s should be kept", runtimeUser)
	})
}

// assertInstalled checks the state of a system with pkg installed, using the
// expectations in e for the parts that depend on DBDOT_UNPRIVILEGED.
// extraTree adds expected entries under installDir, and allowExtra permits
// unexpected ones, see assertTree.
func (s *scenario) assertInstalled(b *box, pkg string, e installExpect, extraTree map[string]fileEntry, allowExtra func(string) bool) {
	b.t.Helper()
	want := installTree(b.payloadPlugins(s.ops, pkg))
	maps.Copy(want, e.tree)
	for _, p := range e.omit {
		delete(want, p)
	}
	maps.Copy(want, extraTree)
	b.assertTree(installDir, want, allowExtra)
	b.assertFiles(installSystemFiles)
	b.assertFiles(e.files)
	b.assertAbsent(installAbsent...)
	b.assertAbsent(e.absent...)
	b.assertPackageVersion(s.ops, pkg)
	b.assertVersionFiles(s.env.dist.metadata)
	b.assertRuntimeUser()
	b.assertUnit(e.user)
}

// installPackage installs pkg and returns the output of the package scripts.
func (b *box) installPackage(o formatOps, pkg string, downgrade bool) string {
	b.t.Helper()
	return b.pkgCommand(o.install(pkg, downgrade))
}

func (b *box) removePackage(o formatOps) {
	b.t.Helper()
	b.pkgCommand(o.remove)
}

// pkgCommand runs a package manager command and logs its output, which
// includes the output of the package scripts. It returns stdout and stderr.
func (b *box) pkgCommand(cmd string) string {
	b.t.Helper()
	res := b.run(cmd)
	b.t.Logf("$ %s\n%s", cmd, res)
	require.Zero(b.t, res.code, "%s failed", cmd)
	return res.stdout + res.stderr
}

// asRuntimeUser returns cmd run as runtimeUser in a new session without a
// TTY and with the service's PATH, the way the updater runs inside the
// service. -w makes setsid wait for cmd and return its exit status, also
// when setsid has to fork because the caller already leads a process group.
func asRuntimeUser(cmd string) string {
	return "setsid -w runuser -u " + runtimeUser + " -- env PATH=" + servicePath + " " + cmd
}

// writeOverride writes a package override file holding lines. With no lines
// it keeps the defaults. The install scripts only source it when it is
// written before the install.
func (b *box) writeOverride(o formatOps, lines ...string) {
	b.t.Helper()
	script := "mkdir -p \"$(dirname " + o.overridePath + ")\" && printf '%s\\n' '# written by the packaging test suite'"
	for _, line := range lines {
		script += " " + shellQuote(line)
	}
	b.mustRun(script + " > " + o.overridePath)
}

// writeUserFiles creates files a user or install_unix.sh would create after
// install. When editConfig is set, the config files are modified too.
func (b *box) writeUserFiles(editConfig bool) {
	b.t.Helper()
	script := `set -e
cd ` + installDir + `
install -o ` + runtimeUser + ` -g ` + runtimeGrp + ` -m 0640 /dev/null storage/marker
echo 'written by the packaging test suite' > storage/marker
install -o ` + runtimeUser + ` -g ` + runtimeGrp + ` -m 0640 /dev/null manager.yaml
echo 'endpoint: "ws://127.0.0.1:3001/v1/opamp"' > manager.yaml
`
	if editConfig {
		script += `echo '# edited by the packaging test suite' >> config.yaml
echo '# edited by the packaging test suite' >> logging.yaml
`
	}
	b.mustRun(script)
}

// ranAsRootByDefault reports whether release version (x.y.z) ran the
// collector as root when DBDOT_UNPRIVILEGED was unset. Releases up to 1.3 did.
func ranAsRootByDefault(t *testing.T, version string) bool {
	t.Helper()
	parts := strings.SplitN(version, ".", 3)
	require.Len(t, parts, 3, "release version %q", version)
	major, err := strconv.Atoi(parts[0])
	require.NoError(t, err, "release version %q", version)
	minor, err := strconv.Atoi(parts[1])
	require.NoError(t, err, "release version %q", version)
	return major < 1 || (major == 1 && minor <= 3)
}
