import QtQuick
import Quickshell.Io

// First-run bridge between an unprivileged Omarchy plugin checkout and the
// signed Arch backend package. Privileged work remains in the auditable helper;
// this object only supervises it and exposes bounded progress to the panel.
QtObject {
  id: root

  property QtObject vpnState: null
  property bool packageKnown: false
  property bool packageCurrent: false
  property string installedVersion: ''
  property bool installRequested: false
  property bool repairSuggested: false
  property bool frontendDemanded: false
  property string state: 'detecting'
  property int progress: 0
  property string errorCode: ''
  property string diagnostic: ''
  property int pendingExitCode: 0

  readonly property string scriptPath: localFilePath(
    Qt.resolvedUrl('scripts/install-backend'))
  readonly property bool running: installProcess.running
  readonly property bool agentReady: vpnState ? vpnState.agentAvailable : false
  readonly property bool packagePresent: installedVersion.length > 0
  readonly property bool shouldShow:
    !packageKnown || !packageCurrent || running || state === 'error' ||
    repairSuggested || (installRequested && !agentReady)
  readonly property bool canStart: scriptPath.length > 0 && !running

  signal installationFinished()

  function localFilePath(url) {
    var value = String(url || '')
    if (value.indexOf('file://') !== 0) return ''
    try {
      return decodeURIComponent(value.substring(7))
    } catch (_error) {
      return ''
    }
  }

  function demand() {
    frontendDemanded = true
    refreshPackage()
    scheduleRepairSuggestion()
  }

  function releaseDemand() {
    frontendDemanded = false
    repairTimer.stop()
  }

  function scheduleRepairSuggestion() {
    if (frontendDemanded && packageKnown && packageCurrent && !agentReady &&
        !installRequested && !running) {
      repairTimer.restart()
    } else {
      repairTimer.stop()
    }
  }

  function refreshPackage() {
    if (!scriptPath || detectProcess.running) return
    detectedVersion = ''
    detectProcess.command = ['/usr/bin/bash', scriptPath, '--check']
    detectProcess.running = true
  }

  function start() {
    if (!canStart) return
    installRequested = true
    repairSuggested = false
    errorCode = ''
    diagnostic = ''
    progress = 1
    state = 'launching'
    pendingExitCode = 0
    installProcess.command = ['/usr/bin/bash', scriptPath, '--install']
    installProcess.running = true
  }

  function applyStatus(raw) {
    if (!installRequested && !running) return
    var parsed = null
    try {
      parsed = JSON.parse(String(raw || ''))
    } catch (_error) {
      return
    }
    if (!parsed || Number(parsed.version) !== 1) return
    state = String(parsed.state || state)
    progress = Math.max(0, Math.min(100, Number(parsed.progress || 0)))
    errorCode = String(parsed.code || '')
  }

  onAgentReadyChanged: {
    if (agentReady) {
      repairTimer.stop()
      repairSuggested = false
      if (installRequested) {
        state = 'ready'
        progress = 100
        installRequested = false
        installationFinished()
      }
    } else {
      scheduleRepairSuggestion()
    }
  }

  property string detectedVersion: ''

  property Process detectProcess: Process {
    id: detectProcess
    running: false
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.detectedVersion = String(text || '').trim()
    }
    onExited: function(exitCode) {
      root.packageKnown = true
      root.packageCurrent = exitCode === 0
      root.installedVersion = root.detectedVersion
      if (!root.installRequested && root.state !== 'error')
        root.state = root.packageCurrent ? 'installed' : 'missing'
      root.scheduleRepairSuggestion()
    }
  }

  property Process installProcess: Process {
    id: installProcess
    running: false
    command: []
    stdout: SplitParser {
      splitMarker: '\n'
      onRead: data => root.applyStatus(data)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.diagnostic = String(text || '').trim().substring(0, 1000)
    }
    onExited: function(exitCode) {
      root.pendingExitCode = Number(exitCode)
      root.resultTimer.restart()
    }
  }

  property Timer resultTimer: Timer {
    interval: 120
    repeat: false
    onTriggered: {
      if (root.pendingExitCode === 0) {
        root.packageKnown = true
        root.packageCurrent = true
        root.state = root.agentReady ? 'ready' : 'starting_backend'
        root.progress = 100
        root.refreshPackage()
        if (root.vpnState && typeof root.vpnState.retryAgentNow === 'function')
          root.vpnState.retryAgentNow()
        if (root.agentReady) {
          root.installRequested = false
          root.installationFinished()
        }
      } else if (root.state !== 'error') {
        root.state = 'error'
        root.errorCode = 'installer_failed'
      }
    }
  }

  property Timer repairTimer: Timer {
    interval: 5000
    repeat: false
    onTriggered: {
      if (root.frontendDemanded && root.packageCurrent && !root.agentReady &&
          !root.installRequested && !root.running)
        root.repairSuggested = true
    }
  }

  Component.onCompleted: refreshPackage()
}
