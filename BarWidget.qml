import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import 'components'

// Omarchy-native Proton VPN bar widget.
//
// The root follows Quattro's rich bar-widget contract: it is the popout
// identity, owns IPC, and lazily creates the panel only when requested.
BarWidget {
  id: root
  moduleName: 'proton.omarchy'

  property bool panelRequested: false
  property bool pendingOpen: false
  property string pendingRoute: ''
  Binding {
    target: ProtonUi
    property: 'reducedMotion'
    value: !!root.setting('reducedMotion', false)
  }

  // Bar chrome uses barForeground rather than the popup/content foreground.
  // Omarchy changes this value when transparent-bar contrast is active.
  readonly property color statusColor: bar ? bar.barForeground : Color.foreground
  readonly property string statusIconState: {
    if (agentState.connected) return 'connected'
    if (agentState.status === 'connecting' || agentState.tunnelOperationBusy) return 'connecting'
    if (agentState.status === 'disconnected' || agentState.status === 'error' ||
        agentState.accountStatus === 'signed_out' ||
        agentState.accountStatus === 'two_factor_required')
      return 'disconnected'
    return 'information'
  }

  readonly property bool opened: panelLoader.item
    ? panelLoader.item.opened === true
    : false

  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true
    : false

  readonly property real openPanelIndicatorWidth: Style.bar.iconSlot
  readonly property real openPanelIndicatorHeight: Math.max(Style.space(10), Math.round(Style.bar.iconSlot * 0.55))

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ('bar' in target) target.bar = root.bar
    if ('settings' in target) target.settings = root.settings
    if ('anchorItem' in target) target.anchorItem = button
    if ('hostWidget' in target) target.hostWidget = root
    if ('vpnState' in target) target.vpnState = agentState
    if ('installerState' in target) target.installerState = backendInstaller
    if ('uninstallerState' in target) target.uninstallerState = cleanUninstaller
  }

  // Headless boot auto-connect: the panel used to be the only place that
  // called activateBackend(), so auto-connect never fired until the user
  // opened the panel. Initialize the backend at shell startup instead,
  // respecting the lifecycle opt-out (cachedStartWithOmarchy).
  function maybeActivateBackendAtStartup() {
    if (agentState.backendDemanded) return
    if (!agentState.cachedStartWithOmarchy) return
    if (!agentState.onboardingComplete) return
    agentState.activateBackend()
  }

  Component.onCompleted: {
    Qt.callLater(function() {
      root.maybeActivateBackendAtStartup()
      root.fireBootRetry()
      root.maybeScheduleBootRetry()
      root.bootRetryPrimer.restart()
    })
  }

  function open() {
    if (panelLoader.item) {
      panelLoader.item.open()
      return
    }
    pendingOpen = true
    panelRequested = true
  }

  function openRoute(route) {
    pendingRoute = String(route || 'home')
    if (panelLoader.item) {
      panelLoader.item.setRoute(pendingRoute)
      pendingRoute = ''
      panelLoader.item.open()
      return
    }
    pendingOpen = true
    panelRequested = true
  }

  function close() {
    pendingOpen = false
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    if (opened) close()
    else open()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
    else close()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  AgentState {
    id: agentState
  }

  BackendInstaller {
    id: backendInstaller
    vpnState: agentState
  }

  CleanUninstaller {
    id: cleanUninstaller
  }

  Connections {
    target: agentState
    function onActionRequested(action) {
      if (action === 'split-tunneling-settings') root.openRoute('split-tunneling')
      else if (action === 'login') root.openRoute('home')
    }
  }

  Connections {
    target: agentState
    function onOnboardingCompleteChanged() {
      root.maybeActivateBackendAtStartup()
      root.maybeScheduleBootRetry()
    }
    function onLifecyclePreferenceKnownChanged() {
      root.maybeActivateBackendAtStartup()
      root.maybeScheduleBootRetry()
    }
    function onCachedStartWithOmarchyChanged() {
      root.maybeActivateBackendAtStartup()
      root.maybeScheduleBootRetry()
    }
    function onStatusChanged() {
      if (agentState.connected) {
        root.bootRetryAttempts = 0
        // A live connection proves user intent is satisfied; never
        // auto-retry again this session (a later manual disconnect must
        // stick). Fresh shell start re-arms for the next boot.
        root.bootWindowOpen = false
      } else root.maybeScheduleBootRetry()
    }
    function onWifiConnectedChanged() { root.maybeScheduleBootRetry() }
    function onConnectionErrorCodeChanged() { root.maybeScheduleBootRetry() }
  }

  // Boot retry: the agent's headless auto-connect fires once very early and
  // gives up on network_conflict_detected (wifi still coming up, tailscale0
  // confusing the gateway check) with no retry. Re-issue the normal
  // user-equivalent quick-connect a few times once wifi is up.
  //
  // Gating notes: the op-journal error code is not reliably reflected on
  // connection.error_code in the failure snapshot, so the disconnected
  // branch cannot depend on error codes alone. Instead it is scoped to the
  // boot window: until the first successful connection in this shell
  // session, a plain 'disconnected' state means failure, not user intent
  // (there was never a connection to disconnect from). Once connected,
  // bootWindowOpen closes permanently and only explicit error states can
  // still trigger a retry. Attempts are capped in all cases.
  // Timing: failed attempts fail instantly while offline, so a tight 5s
  // cadence converges within ~5s of readiness at negligible cost.
  property int bootRetryAttempts: 0
  property int bootRetryMaxAttempts: 8
  property bool bootWindowOpen: true
  readonly property bool bootRetryEligible: agentState.autoConnect
    && agentState.signedIn
    && !agentState.connecting && !agentState.tunnelOperationBusy
    && agentState.wifiConnected
    && root.bootRetryAttempts < root.bootRetryMaxAttempts
    && ((agentState.status === 'error' && agentState.lastErrorRetryable)
      || (agentState.status === 'disconnected'
        && (root.bootWindowOpen
          || agentState.connectionErrorCode.indexOf('network_conflict') === 0
          || agentState.connectionErrorCode.indexOf('kill_switch') === 0
          || agentState.lastErrorCode.indexOf('network_conflict') === 0
          || agentState.lastErrorCode.indexOf('kill_switch') === 0))))

  property Timer bootRetryTimer: Timer {
    interval: 5000
    repeat: false
    onTriggered: root.fireBootRetry()
  }

  // Immediate attempt (no timer wait) for the case where wifi is already
  // up when the shell starts. Same gates and cap as the timer path.
  function fireBootRetry() {
    if (!root.bootRetryEligible) return
    root.bootRetryAttempts += 1
    console.log('proton.omarchy: boot auto-connect retry '
      + root.bootRetryAttempts + '/' + root.bootRetryMaxAttempts)
    agentState.quickConnect()
    if (root.bootRetryAttempts < root.bootRetryMaxAttempts)
      root.bootRetryTimer.restart()
  }

  // Fixed boot-delayed safety net: signal-driven scheduling above can miss
  // the window if the failure snapshot arrives before wifi/status signals
  // settle, so also check once shortly after shell startup.
  property Timer bootRetryPrimer: Timer {
    interval: 10000
    repeat: false
    onTriggered: root.maybeScheduleBootRetry()
  }

  function maybeScheduleBootRetry() {
    if (root.bootRetryEligible && !root.bootRetryTimer.running)
      root.bootRetryTimer.restart()
  }

  Loader {
    id: panelLoader
    active: root.panelRequested
    source: Qt.resolvedUrl('ProtonPanel.qml')
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(function() {
        root.injectPanel()
        if (root.pendingOpen && panelLoader.item) {
          root.pendingOpen = false
          if (root.pendingRoute) {
            panelLoader.item.setRoute(root.pendingRoute)
            root.pendingRoute = ''
          }
          panelLoader.item.open()
        }
      })
    }
  }

  IpcHandler {
    target: 'proton.omarchy'

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function home(): void { root.openRoute('home') }
    function recents(): void { root.openRoute('recents') }
    function locations(): void { root.openRoute('locations') }
    function gateways(): void { root.openRoute('gateways') }
    function profiles(): void { root.openRoute('profiles') }
    function details(): void { root.openRoute('details') }
    function settings(): void { root.openRoute('settings') }
    function splitTunneling(): void { root.openRoute('split-tunneling') }
    function support(): void { root.openRoute('support') }
    function about(): void { root.openRoute('about') }
    function defaultConnection(): void { root.openRoute('default-connection') }
    function account(): void { root.openRoute('account') }
    function diagnostics(): void { root.openRoute('diagnostics') }

    function connect(): void {
      if (backendInstaller.shouldShow) root.open()
      else agentState.quickConnect()
    }
    function disconnect(): void { agentState.disconnect() }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    iconComponent: Component {
      ProtonVpnMark {
        anchors.fill: parent
        statusColor: root.statusColor
        state: root.statusIconState
      }
    }

    // Quattro-style mouse affordances:
    // left = panel, right = quick connect/disconnect, middle = connection details.
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) {
        if (backendInstaller.shouldShow) root.open()
        else agentState.toggleConnection()
      }
      else if (buttonCode === Qt.MiddleButton) root.openRoute('details')
      else root.toggle()
    }
  }
}
