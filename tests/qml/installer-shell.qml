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

  ProtonStrings {
    id: englishStrings
    localeName: 'en-US'
  }

  ProtonStrings {
    id: fallbackStrings
    localeName: 'fr-FR'
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
                  installer.scriptPath.endsWith('/scripts/install-backend'),
                  strings.text('welcome_title') === 'Le damos la bienvenida a Proton VPN',
                  englishStrings.text('welcome_title') === 'Welcome to Proton VPN',
                  strings.localeOptions().length === 2,
                  strings.profileCopyName('Test') === 'Copia de Test',
                  strings.catalogsComplete,
                  fallbackStrings.text('welcome_title') === 'Welcome to Proton VPN',
                  installer.detectedPackageState(false, '0.9.0-1') === 'outdated',
                  strings.installerStage('outdated') ===
                    'El backend instalado necesita actualizarse.')
      Qt.quit()
    }
  }
}
