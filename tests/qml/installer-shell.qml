import QtQuick
import Quickshell

ShellRoot {
  QtObject {
    id: mockAgent
    property bool agentAvailable: false
    function retryAgentNow() {}
  }

  BackendInstaller {
    id: installer
    vpnState: mockAgent
  }

  ProtonStrings {
    id: strings
    localeName: 'es-MX'
  }

  FloatingWindow {
    visible: true
    implicitWidth: 380
    implicitHeight: Math.max(300, installerView.implicitHeight)
    color: 'black'

    ProtonInstallerView {
      id: installerView
      anchors.fill: parent
      installerState: installer
      strings: strings
      foreground: 'white'
      urgent: 'red'
      dim: '#999999'
      fontFamily: 'monospace'
    }
  }

  Timer {
    interval: 500
    running: true
    onTriggered: {
      console.log('INSTALLER_QML', installer.packageKnown,
                  installer.canStart, installerView.implicitHeight > 0,
                  installer.scriptPath.endsWith('/scripts/install-backend'))
      Qt.quit()
    }
  }
}
