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

  Connections {
    target: agentState
    function onActionRequested(action) {
      if (action === 'split-tunneling-settings') root.openRoute('split-tunneling')
      else if (action === 'login') root.openRoute('home')
    }
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

    function connect(): void { agentState.quickConnect() }
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
      if (buttonCode === Qt.RightButton) agentState.toggleConnection()
      else if (buttonCode === Qt.MiddleButton) root.openRoute('details')
      else root.toggle()
    }
  }
}
