import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import qs.Commons
import qs.Ui
import 'components'

// One production workspace for the bar panel, floating previews and tests.
// Only the active page is instantiated. All account/network mutations remain
// on the existing agent interface supplied by the host.
FocusScope {
  id: root
  property QtObject vpnState: null
  property QtObject installerState: null
  property QtObject uninstallerState: null
  property QtObject strings: stringTable
  property color foreground: Color.popups.text
  property color urgent: Color.urgent
  property color dim: ProtonUi.secondaryText(foreground)
  property string fontFamily: Style.font.family
  property string route: 'home'
  property var routeStack: ['home']
  // Bounded, presentation-only memory. Credentials and view objects never enter it.
  property var navigationMemory: ({})
  property bool restorePageFocus: false
  property bool pagePresented: false
  readonly property alias currentPage: pageLoader.item
  readonly property bool installerVisible: installerState && installerState.shouldShow
  readonly property bool onboardingVisible: !installerVisible &&
    (!vpnState || !vpnState.storeReady || !vpnState.onboardingComplete)
  readonly property bool authVisible: !installerVisible && !onboardingVisible &&
    (!vpnState || !vpnState.signedIn)
  readonly property bool inputViewVisible: installerVisible || onboardingVisible || authVisible
  readonly property bool hasGateways: vpnState && vpnState.gateways && vpnState.gateways.length > 0
  readonly property var rootRoutes: ['home', 'locations', 'gateways', 'profiles', 'settings']
  readonly property var validRoutes: rootRoutes.concat([
    'recents', 'details', 'split-tunneling', 'support', 'about',
    'default-connection', 'excluded-locations', 'account', 'diagnostics'])
  readonly property string selectedRoot: rootRoutes.indexOf(route) >= 0 ? route : String(routeStack[0] || 'home')
  readonly property var navigationDestinations: {
    var items = [
      { route: 'home', label: strings.text('home') },
      { route: 'locations', label: strings.text('countries') }
    ]
    if (hasGateways) items.push({ route: 'gateways', label: strings.text('gateways') })
    items.push({ route: 'profiles', label: strings.text('profiles') })
    items.push({ route: 'settings', label: strings.text('settings') })
    return items
  }
  signal closeRequested()

  ProtonStrings { id: stringTable; localeName: root.vpnState ? root.vpnState.locale : 'en' }

  function routeLabel(value) {
    var names = { locations: 'countries', details: 'connection_details',
      'split-tunneling': 'split_tunneling', 'excluded-locations': 'excluded_locations',
      'default-connection': 'default_connection' }
    return strings.text(names[value] || value)
  }

  function rememberPage() {
    if (inputViewVisible || !pageLoader.item) return
    var item = root.Window.window ? root.Window.window.activeFocusItem : null
    var focusLabel = ''
    for (var node = item; node; node = node.parent) {
      if (node === pageLoader.item) { focusLabel = item.Accessible.name || ''; break }
    }
    var memory = Object.assign({}, navigationMemory)
    memory[route] = {
      scrollY: viewport.contentY, focusLabel: focusLabel,
      page: typeof pageLoader.item.captureViewState === 'function'
        ? pageLoader.item.captureViewState() : null
    }
    navigationMemory = memory
  }

  function findFocus(item, name) {
    if (!item || !item.visible || !item.enabled) return null
    if (item.activeFocusOnTab && item.Accessible.name === name) return item
    for (var i = 0; i < item.children.length; ++i) {
      var match = findFocus(item.children[i], name)
      if (match) return match
    }
    return null
  }

  function pageLoaded() {
    var wasFading = pageFade.running
    pageFade.stop()
    // Short, interruptible settling of the new content; no outgoing live page
    // or delayed input. First render and hidden windows remain instantaneous.
    if (pagePresented && !ProtonUi.reducedMotion && root.QsWindow.window && root.QsWindow.window.visible) {
      if (!wasFading) pageLoader.opacity = 0.65
      pageFade.start()
    } else pageLoader.opacity = 1
    pagePresented = true
    var page = pageLoader.item, loadedRoute = route
    var memory = !inputViewVisible ? navigationMemory[loadedRoute] : null
    var returnFocus = restorePageFocus
    restorePageFocus = false
    if (memory && typeof page.restoreViewState === 'function') page.restoreViewState(memory.page)
    Qt.callLater(function() {
      if (pageLoader.item !== page || route !== loadedRoute) return
      viewport.contentY = memory ? Math.max(0, Math.min(memory.scrollY,
        viewport.contentHeight - viewport.height)) : 0
      if (!root.activeFocus) return
      var target = returnFocus && memory && memory.focusLabel
        ? findFocus(page, memory.focusLabel) : null
      if (target) target.forceActiveFocus(Qt.BacktabFocusReason)
      else root.focusInitial()
    })
  }

  function setRoute(value, returnFocus) {
    var candidate = String(value || 'home')
    if (validRoutes.indexOf(candidate) < 0) candidate = 'home'
    if (candidate === 'gateways' && !hasGateways) candidate = 'locations'
    if (candidate === route) return
    rememberPage()
    restorePageFocus = !!returnFocus
    if (rootRoutes.indexOf(candidate) >= 0) routeStack = [candidate]
    else routeStack = [candidate === 'recents' || candidate === 'details' ? 'home' : 'settings', candidate]
    route = candidate
    viewport.contentY = 0
  }

  function goBack() {
    if (pageLoader.item && typeof pageLoader.item.navigateBack === 'function' &&
        pageLoader.item.navigateBack()) { viewport.contentY = 0; return true }
    if (routeStack.length <= 1) return false
    setRoute(String(routeStack[0]), true)
    return true
  }

  function focusInitial() {
    if (inputViewVisible && pageLoader.item && typeof pageLoader.item.focusInitial === 'function')
      pageLoader.item.focusInitial()
    else navigation.focusCurrent()
  }

  function containsItem(item) {
    for (var node = item; node; node = node.parent) if (node === root) return true
    return false
  }

  function revealFocus() {
    var item = root.Window.window ? root.Window.window.activeFocusItem : null
    if (!item || !containsItem(item)) return
    var node = item
    var inPage = false
    while (node && node !== root) { if (node === pageColumn) inPage = true; node = node.parent }
    if (!inPage) return
    var point = item.mapToItem(viewport.contentItem, 0, 0)
    var margin = Style.space(8)
    if (point.y < viewport.contentY + margin) viewport.contentY = Math.max(0, point.y - margin)
    else if (point.y + item.height > viewport.contentY + viewport.height - margin)
      viewport.contentY = Math.min(Math.max(0, viewport.contentHeight - viewport.height),
        point.y + item.height + margin - viewport.height)
  }

  Connections {
    target: root.Window.window
    function onActiveFocusItemChanged() { focusReveal.restart() }
  }
  Timer {
    id: focusReveal
    // Focus may move in the same event that opens a section. Let Qt polish
    // the layout before measuring it; coalesce rapid focus changes in one frame.
    interval: 16
    onTriggered: root.revealFocus()
  }
  NumberAnimation {
    id: pageFade
    objectName: 'page-transition'
    target: pageLoader
    property: 'opacity'
    to: 1
    duration: ProtonUi.transitionMs
    easing.type: Easing.OutCubic
  }

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_Escape) {
      if (!root.goBack()) root.closeRequested()
      event.accepted = true
    } else if (!inputViewVisible && (event.modifiers & Qt.ControlModifier) &&
        (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)) {
      navigation.move(event.modifiers & Qt.ShiftModifier ? -1 : 1)
      event.accepted = true
    } else if ((event.modifiers & Qt.AltModifier) && event.key === Qt.Key_Left) {
      root.goBack(); event.accepted = true
    } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F && !inputViewVisible) {
      if (route !== 'locations' && route !== 'gateways') setRoute('locations')
      Qt.callLater(function() {
        if (pageLoader.item && typeof pageLoader.item.focusSearch === 'function') pageLoader.item.focusSearch()
      })
      event.accepted = true
    }
  }

  onHasGatewaysChanged: if (!hasGateways && route === 'gateways') setRoute('locations')
  onInputViewVisibleChanged: if (inputViewVisible) navigationMemory = ({})
  onVpnStateChanged: navigationMemory = ({})

  Column {
    id: chrome
    // Use part of the host's top padding for the 40px close-button hit area,
    // instead of stacking that padding above the centered header label.
    y: -Style.space(10)
    width: parent.width
    spacing: Style.space(4)
    RowLayout {
      width: parent.width
      spacing: Style.space(8)
      ProtonVpnMark {
        iconSize: Style.font.iconLarge
        statusColor: root.foreground
        state: root.vpnState && root.vpnState.connected ? 'connected' : 'disconnected'
      }
      Text {
        Layout.fillWidth: true
        text: 'Proton VPN'
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.title
        font.weight: Font.DemiBold
      }
      ProtonIconButton {
        objectName: 'close-panel'
        iconName: 'cross'
        tooltipText: root.strings.text('close')
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.closeRequested()
      }
    }
    ProtonBottomNavigation {
      id: navigation
      objectName: 'root-navigation'
      width: parent.width
      visible: !root.inputViewVisible
      destinations: root.navigationDestinations
      currentRoute: root.selectedRoot
      foreground: root.foreground
      fontFamily: root.fontFamily
      onRouteRequested: function(value) { root.setRoute(value) }
    }
    ProtonIconButton {
      visible: !root.inputViewVisible && root.routeStack.length > 1
      iconName: 'chevron_left'
      label: root.routeLabel(root.selectedRoot)
      foreground: root.foreground
      fontFamily: root.fontFamily
      onClicked: root.goBack()
    }
  }

  Flickable {
    id: viewport
    objectName: 'page-viewport'
    anchors.top: chrome.bottom
    anchors.topMargin: Style.space(8)
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    contentWidth: width
    contentHeight: pageColumn.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick
    ScrollBar.vertical: ProtonScrollBar { policy: viewport.contentHeight > viewport.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff }
    Column {
      id: pageColumn
      width: viewport.width - (viewport.contentHeight > viewport.height ? Style.space(10) : 0)
      spacing: Style.space(12)
      Loader {
        id: pageLoader
        objectName: 'page-content'
        width: parent.width
        height: item ? item.implicitHeight : 0
        sourceComponent: {
          if (root.installerVisible) return installerComponent
          if (root.onboardingVisible) return onboardingComponent
          if (root.authVisible) return authComponent
          switch (root.route) {
          case 'home': return homeComponent
          case 'locations': return locationsComponent
          case 'gateways': return gatewaysComponent
          case 'profiles': return profilesComponent
          case 'recents': return recentsComponent
          case 'details': return detailsComponent
          case 'settings': return settingsComponent
          case 'split-tunneling': return splitTunnelingComponent
          case 'excluded-locations': return excludedLocationsComponent
          case 'default-connection': return defaultConnectionComponent
          case 'account': return accountComponent
          case 'diagnostics': return diagnosticsComponent
          case 'support': return supportComponent
          case 'about': return aboutComponent
          default: return homeComponent
          }
        }
        onLoaded: root.pageLoaded()
      }
      Connections {
        target: pageLoader.item
        ignoreUnknownSignals: true
        function onNavigateRequested(value) { root.setRoute(value) }
        function onDetailsRequested() { root.setRoute('details') }
      }
      ProtonNotice {
        width: parent.width
        visible: !root.inputViewVisible && root.route !== 'home' && root.vpnState &&
          root.vpnState.connecting && root.vpnState.networkConflicts.length > 0
        error: true
        foreground: root.foreground
        message: root.vpnState ? root.strings.networkConflictWarning(root.vpnState.networkConflicts) : ''
      }
      ProtonNotice {
        width: parent.width
        visible: !root.inputViewVisible && root.route !== 'home' && message !== ''
        foreground: root.foreground
        error: root.vpnState && !root.vpnState.operationBusy && root.vpnState.lastError !== ''
        message: !root.vpnState ? '' : root.vpnState.operationBusy
          ? root.strings.operationStage(root.vpnState.operationStage)
          : root.vpnState.lastError ? root.strings.error(root.vpnState.lastErrorCode, root.vpnState.lastError) : ''
        hint: error && root.vpnState.lastErrorRetryable ? root.strings.text('retryable_hint') : ''
      }
    }
  }
  Component {
    id: homeComponent
    ProtonHomeView {
      vpnState: root.vpnState; strings: root.strings
      foreground: root.foreground; urgent: root.urgent; dim: root.dim; fontFamily: root.fontFamily
    }
  }
  Component {
    id: installerComponent
    ProtonInstallerView {
      installerState: root.installerState; strings: root.strings; uninstallerState: root.uninstallerState
      foreground: root.foreground; urgent: root.urgent; dim: root.dim; fontFamily: root.fontFamily
    }
  }
  Component {
    id: onboardingComponent
    ProtonOnboardingView {
      vpnState: root.vpnState; strings: root.strings; uninstallerState: root.uninstallerState
      foreground: root.foreground; urgent: root.urgent; dim: root.dim; fontFamily: root.fontFamily
    }
  }
  Component {
    id: authComponent
    ProtonAuthView {
      vpnState: root.vpnState; strings: root.strings; uninstallerState: root.uninstallerState
      foreground: root.foreground; urgent: root.urgent; dim: root.dim; fontFamily: root.fontFamily
    }
  }
  Component {
    id: recentsComponent
    ProtonRecentsView {
      vpnState: root.vpnState; strings: root.strings
      foreground: root.foreground; urgent: root.urgent
      dim: root.dim; fontFamily: root.fontFamily
    }
  }

  Component {
    id: locationsComponent
    ProtonLocationsView {
      vpnState: root.vpnState; strings: root.strings
      foreground: root.foreground; urgent: root.urgent
      dim: root.dim; fontFamily: root.fontFamily
      section: 'countries'; sectionSwitcherVisible: false
    }
  }

  Component {
    id: gatewaysComponent
    ProtonLocationsView {
      vpnState: root.vpnState; strings: root.strings
      foreground: root.foreground; urgent: root.urgent
      dim: root.dim; fontFamily: root.fontFamily
      section: 'gateways'; sectionSwitcherVisible: false
    }
  }

  Component {
    id: profilesComponent
    ProtonProfilesView {
      vpnState: root.vpnState; strings: root.strings
      foreground: root.foreground; urgent: root.urgent
      dim: root.dim; fontFamily: root.fontFamily
    }
  }

  Component {
    id: detailsComponent
    ProtonConnectionDetailsView {
      vpnState: root.vpnState; strings: root.strings
      foreground: root.foreground; urgent: root.urgent
      dim: root.dim; fontFamily: root.fontFamily
    }
  }

  Component {
    id: splitTunnelingComponent
    ProtonSplitTunnelingView {
      vpnState: root.vpnState; strings: root.strings
      foreground: root.foreground; urgent: root.urgent
      dim: root.dim; fontFamily: root.fontFamily
    }
  }

  Component {
    id: excludedLocationsComponent
    ProtonExcludedLocationsView {
      vpnState: root.vpnState; strings: root.strings
      foreground: root.foreground; urgent: root.urgent
      dim: root.dim; fontFamily: root.fontFamily
    }
  }

  Component {
    id: supportComponent
    ProtonSupportView {
      vpnState: root.vpnState; strings: root.strings
      foreground: root.foreground; urgent: root.urgent
      dim: root.dim; fontFamily: root.fontFamily
    }
  }

  Component {
    id: aboutComponent
    ProtonAboutView {
      vpnState: root.vpnState; strings: root.strings
      foreground: root.foreground; urgent: root.urgent
      dim: root.dim; fontFamily: root.fontFamily
    }
  }

  Component {
    id: defaultConnectionComponent
    ProtonDefaultConnectionView {
      vpnState: root.vpnState; strings: root.strings
      foreground: root.foreground; urgent: root.urgent
      dim: root.dim; fontFamily: root.fontFamily
    }
  }

  Component {
    id: accountComponent
    ProtonAccountView {
      vpnState: root.vpnState; strings: root.strings
      foreground: root.foreground; urgent: root.urgent
      dim: root.dim; fontFamily: root.fontFamily
    }
  }

  Component {
    id: diagnosticsComponent
    ProtonDiagnosticsView {
      vpnState: root.vpnState; strings: root.strings
      foreground: root.foreground; urgent: root.urgent
      dim: root.dim; fontFamily: root.fontFamily
    }
  }

  Component {
    id: settingsComponent
    ProtonSettingsView {
      vpnState: root.vpnState; strings: root.strings
      uninstallerState: root.uninstallerState
      foreground: root.foreground; urgent: root.urgent
      dim: root.dim; fontFamily: root.fontFamily
    }
  }
}
