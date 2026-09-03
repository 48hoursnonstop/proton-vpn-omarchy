import QtQuick
import Quickshell.Io

// Supervises the unprivileged clean-removal launcher. The actual worker is
// detached into a transient user unit before this plugin removes itself.
QtObject {
  id: root

  property string state: 'idle'
  property string errorCode: ''
  property string diagnostic: ''

  readonly property string scriptPath: localFilePath(
    Qt.resolvedUrl('scripts/uninstall'))
  readonly property bool running: uninstallProcess.running
  readonly property bool canStart: scriptPath.length > 0 && !running

  function localFilePath(url) {
    var value = String(url || '')
    if (value.indexOf('file://') !== 0) return ''
    try {
      return decodeURIComponent(value.substring(7))
    } catch (_error) {
      return ''
    }
  }

  function start() {
    if (!canStart) return
    state = 'launching'
    errorCode = ''
    diagnostic = ''
    uninstallProcess.command = ['/usr/bin/bash', scriptPath, '--launch']
    uninstallProcess.running = true
  }

  property Process uninstallProcess: Process {
    id: uninstallProcess
    running: false
    command: []
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.diagnostic = String(text || '').trim().substring(0, 1000)
    }
    onExited: function(exitCode) {
      if (Number(exitCode) === 0) {
        root.state = 'complete'
      } else {
        root.state = 'error'
        root.errorCode = 'uninstall_failed'
      }
    }
  }
}
