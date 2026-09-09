import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import 'components' as ProtonComponents

ShellRoot {
  id: showcaseShell
  readonly property string route: Quickshell.env('PROTON_SHOWCASE_ROUTE') || 'home'
  readonly property string outputPath: Quickshell.env('PROTON_SHOWCASE_OUTPUT')
  property bool captureWarmed: false
  ShowcaseState {
    id: showcaseState
    secureCore: showcaseShell.route !== 'home-standard'
    onboardingComplete: showcaseShell.route !== 'onboarding'
    signedIn: showcaseShell.route !== 'authentication'
    locale: Quickshell.env('PROTON_SHOWCASE_LOCALE') || 'en'
  }
  ProtonStrings { id: stringTable; localeName: showcaseState.locale }
  QtObject {
    id: showcaseInstaller
    property bool shouldShow: showcaseShell.route === 'installer'
    property bool packageCurrent: false
    property bool packagePresent: false
    property bool running: false
    property string state: 'ready'
    property real progress: 0
    property string errorCode: ''
    property string diagnostic: ''
    property bool agentReady: false
    property bool installRequested: false
    property bool canStart: true
    function start() {}
  }
  FileView { id: palette; path: Quickshell.env('PROTON_SHOWCASE_THEME_PATH') + '/colors.toml' }
  FileView { id: surface; path: Quickshell.env('PROTON_SHOWCASE_THEME_PATH') + '/shell.toml' }
  // The script enforces offscreen rendering. No layer surface, agent or keyring.
  FloatingWindow {
    id: window
    title: 'Proton VPN Showcase - ' + route
    visible: true
    implicitWidth: Number(Quickshell.env('PROTON_SHOWCASE_WIDTH')) || 420
    implicitHeight: Number(Quickshell.env('PROTON_SHOWCASE_HEIGHT')) || 640
    minimumSize: Qt.size(implicitWidth, implicitHeight)
    maximumSize: minimumSize
    color: 'transparent'
    BorderSurface {
      id: captureRoot
      anchors.fill: parent
      color: Color.popups.background
      borderSpec: Border.surfaceSpec('popups', 'border', Color.popups.border, Math.max(1, Style.space(2)))
      padding: Style.spacing.popupPadding
      radius: Style.cornerRadius
      ProtonWorkspace {
        id: workspace
        anchors.fill: parent
        anchors.topMargin: captureRoot.contentTopInset
        anchors.rightMargin: captureRoot.contentRightInset
        anchors.bottomMargin: captureRoot.contentBottomInset
        anchors.leftMargin: captureRoot.contentLeftInset
        vpnState: showcaseState
        installerState: showcaseInstaller
        strings: stringTable
        Component.onCompleted: setRoute(showcaseShell.route)
      }
    }
  }
  Timer {
    interval: 300
    running: true
    onTriggered: {
      Color.loadColors(palette.text())
      Color.loadUserShell('')
      Color.loadShell(surface.text())
      Style.applyShellValues(Color.shellValues)
      if (showcaseState.connected) showcaseState.seedTrafficHistory()
      var fontSize = Number(Quickshell.env('PROTON_SHOWCASE_FONT_SIZE'))
      if (fontSize > 0) Style.fontBaseSize = fontSize
      var scenario = Quickshell.env('PROTON_SHOWCASE_SCENARIO')
      if (scenario === 'empty' || scenario === 'loading' || scenario === 'error') {
        showcaseState.connected = false
        showcaseState.status = 'disconnected'
        showcaseState.recents = []
        if (scenario === 'loading') {
          showcaseState.connecting = true
          showcaseState.operationBusy = true
          showcaseState.tunnelOperationBusy = true
          showcaseState.operationStage = 'tunnel.connecting'
        } else if (scenario === 'error') {
          showcaseState.lastError = 'Synthetic connection failure'
          showcaseState.lastErrorCode = 'connection_failed'
          showcaseState.lastErrorRetryable = true
        }
      } else if (scenario === 'application') workspace.currentPage.settingsSection = 'application'
      else if (scenario === 'advanced') workspace.currentPage.advancedExpanded = true
      else if (scenario === 'protocols') workspace.currentPage.openPicker = 'protocol'
      else if (scenario === 'edit-profile') {
        workspace.currentPage.newProfile()
        workspace.currentPage.iconPickerVisible = true
      }
      console.log('SHOWCASE_CONTRAST', ProtonComponents.ProtonUi.contrast(
        workspace.dim, Color.popups.background))
    }
  }
  Timer {
    id: captureTimer
    interval: route === 'home' || route === 'details' ? 3400 : 1800
    running: true
    onTriggered: {
      if (!captureWarmed) {
        // Prime every text/icon texture and the chart layer before the image
        // that is persisted. Some Wayland renderers complete those uploads
        // only after the first off-screen grab.
        captureRoot.grabToImage(function(_result) {
          captureWarmed = true
          captureTimer.interval = 500
          captureTimer.restart()
        })
        return
      }
      captureRoot.grabToImage(function(result) {
        var saved = outputPath.length > 0 && result.saveToFile(outputPath)
        console.log('SHOWCASE_CAPTURE', route, saved, outputPath)
        Qt.quit()
      })
    }
  }
}
