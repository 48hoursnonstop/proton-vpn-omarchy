import QtQuick
import qs.Commons
import qs.Ui
import 'components'

// Native Omarchy host. The same workspace is exercised by floating previews.
Panel {
  id: root
  moduleName: 'proton.omarchy'
  ipcTarget: 'proton.omarchy'
  manageIpc: false
  property var anchorItem: null
  property var hostWidget: null
  property QtObject vpnState: null
  property QtObject installerState: null
  property QtObject uninstallerState: null
  property alias route: workspace.route
  property alias routeStack: workspace.routeStack
  readonly property var barIdentity: hostWidget || root

  function setRoute(value) { workspace.setRoute(value) }
  function open() {
    if (installerState) installerState.demand()
    if (vpnState) {
      vpnState.demandAgent(true)
      if (vpnState.onboardingComplete) vpnState.activateBackend()
    }
    ensureLocations()
    Qt.callLater(ensureLocations)
    controller.show()
    Qt.callLater(workspace.focusInitial)
  }
  function close() { controller.hide() }
  function toggle() { if (opened) close(); else open() }
  function switchPanel(direction) {
    return root.bar && typeof root.bar.switchPanelFrom === 'function'
      ? root.bar.switchPanelFrom(root.barIdentity, direction) : false
  }
  function ensureLocations() {
    if (vpnState && vpnState.signedIn && !vpnState.locationsLoading &&
        vpnState.countries.length === 0 && vpnState.gateways.length === 0) vpnState.loadLocations()
  }
  onOpenedChanged: {
    if (bar && 'centerHoverRevealSuppressed' in bar) bar.centerHoverRevealSuppressed = opened
    if (!opened) {
      if (installerState) installerState.releaseDemand()
      if (vpnState) vpnState.demandAgent(false)
    } else Qt.callLater(workspace.focusInitial)
  }
  Connections {
    target: root.vpnState
    ignoreUnknownSignals: true
    function onSignedInChanged() { root.ensureLocations() }
  }
  Connections {
    target: workspace
    function onOnboardingVisibleChanged() {
      if (root.opened && !workspace.onboardingVisible && root.vpnState)
        root.vpnState.activateBackend()
    }
  }
  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: workspace
    contentWidth: fittedContentWidth(ProtonUi.panelWidth)
    contentHeight: fittedContentHeight(ProtonUi.panelHeight, ProtonUi.panelHeight)
    ProtonWorkspace {
      id: workspace
      anchors.fill: parent
      vpnState: root.vpnState
      installerState: root.installerState
      uninstallerState: root.uninstallerState
      onCloseRequested: root.close()

    }
  }
}
