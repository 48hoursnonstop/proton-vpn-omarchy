import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import 'components'

// Android's compact information architecture adapted to a Quattro panel.
// Navigation and feedback stay in QML; state and networking stay in the agent.
Panel {
  id: panelRoot
  moduleName: 'proton.omarchy'
  ipcTarget: 'proton.omarchy'
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property QtObject vpnState: null
  property int cursorIndex: 0
  property bool cursorActive: false
  property string route: 'home'
  property var routeStack: ['home']

  readonly property var barIdentity: hostWidget || panelRoot
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool onboardingVisible: !vpnState || !vpnState.storeReady ||
    !vpnState.onboardingComplete
  readonly property bool authVisible: !onboardingVisible &&
    (!vpnState || !vpnState.signedIn)
  readonly property bool inputViewVisible: onboardingVisible || authVisible
  readonly property QtObject stringTable: strings
  readonly property var validRoutes: [
    'home', 'recents', 'locations', 'gateways', 'profiles', 'details',
    'settings', 'split-tunneling', 'support', 'about',
    'default-connection', 'excluded-locations', 'account', 'diagnostics'
  ]
  readonly property var rootRoutes: [
    'home', 'locations', 'gateways', 'profiles', 'settings'
  ]
  readonly property bool rootRoute: isRoot(route)
  readonly property bool rootSubpageActive: {
    if (!rootRoute || !routeLoader.item) return false
    if (route === 'profiles' || route === 'locations' || route === 'gateways')
      return !!routeLoader.item.subpageActive
    return false
  }
  readonly property bool hasGateways: vpnState && vpnState.gateways &&
    vpnState.gateways.length > 0
  readonly property var navigationDestinations: {
    var items = [
      { route: 'home', icon: 'house', label: strings.text('home') },
      { route: 'locations', icon: 'earth', label: strings.text('countries') }
    ]
    if (panelRoot.hasGateways)
      items.push({ route: 'gateways', icon: 'servers', label: strings.text('gateways') })
    items.push({ route: 'profiles', icon: 'window_terminal', label: strings.text('profiles') })
    items.push({ route: 'settings', icon: 'cog_wheel', label: strings.text('settings') })
    return items
  }
  readonly property int cursorCount: 2

  ProtonStrings {
    id: strings
    localeName: panelRoot.vpnState ? panelRoot.vpnState.locale : 'es-MX'
  }

  function isRoot(candidate) {
    return rootRoutes.indexOf(String(candidate || '')) >= 0
  }

  function normalizeRoute(candidate) {
    var value = String(candidate || 'home')
    return validRoutes.indexOf(value) >= 0 ? value : 'home'
  }

  function defaultParentFor(candidate) {
    var value = String(candidate || '')
    if (value === 'recents' || value === 'details') return 'home'
    return 'settings'
  }

  function routeLabel(candidate) {
    switch (String(candidate || '')) {
    case 'home': return strings.text('home')
    case 'locations': return strings.text('countries')
    case 'gateways': return strings.text('gateways')
    case 'profiles': return strings.text('profiles')
    case 'settings': return strings.text('settings')
    case 'recents': return strings.text('recents')
    case 'details': return strings.text('connection_details')
    case 'split-tunneling': return strings.text('split_tunneling')
    case 'excluded-locations': return strings.text('excluded_locations')
    case 'support': return strings.text('support')
    case 'about': return strings.text('about')
    case 'default-connection': return strings.text('default_connection')
    case 'account': return strings.text('account')
    case 'diagnostics': return strings.text('diagnostics')
    default: return strings.text('home')
    }
  }

  function resetPagePosition() {
    cursorActive = false
    if (panelFlick) panelFlick.contentY = 0
  }

  function selectRootRoute(nextRoute) {
    var candidate = normalizeRoute(nextRoute)
    if (!isRoot(candidate) || (candidate === 'gateways' && !hasGateways))
      candidate = candidate === 'gateways' ? 'locations' : 'home'
    routeStack = [candidate]
    route = candidate
    resetPagePosition()
  }

  function pushRoute(nextRoute) {
    var candidate = normalizeRoute(nextRoute)
    if (isRoot(candidate)) {
      selectRootRoute(candidate)
      return
    }
    var parentRoute = defaultParentFor(candidate)
    var stack = routeStack && routeStack.length > 0
      ? routeStack.slice(0) : [parentRoute]
    if (!isRoot(stack[0]) || stack[0] !== parentRoute) stack = [parentRoute]
    if (stack[stack.length - 1] !== candidate) stack.push(candidate)
    routeStack = stack
    route = candidate
    resetPagePosition()
  }

  // Public bar/IPC entry point. Secondary routes receive a deterministic root.
  function setRoute(nextRoute) {
    var candidate = normalizeRoute(nextRoute)
    if (isRoot(candidate)) {
      selectRootRoute(candidate)
      return
    }
    routeStack = [defaultParentFor(candidate), candidate]
    route = candidate
    resetPagePosition()
  }

  function goBack() {
    if (rootRoute && rootSubpageActive && routeLoader.item &&
        typeof routeLoader.item.navigateBack === 'function' &&
        routeLoader.item.navigateBack()) {
      resetPagePosition()
      return true
    }
    if (!routeStack || routeStack.length <= 1) return false
    var stack = routeStack.slice(0)
    stack.pop()
    routeStack = stack
    route = String(stack[stack.length - 1] || 'home')
    resetPagePosition()
    return true
  }

  function moveRootRoute(direction) {
    var items = navigationDestinations
    if (!items || items.length === 0) return
    var current = isRoot(route) ? route : String(routeStack[0] || 'home')
    var index = 0
    for (var i = 0; i < items.length; ++i) {
      if (String(items[i].route) === current) {
        index = i
        break
      }
    }
    index = (index + (direction > 0 ? 1 : -1) + items.length) % items.length
    selectRootRoute(String(items[index].route))
  }

  function ensureRootDestinations() {
    if (!vpnState || !vpnState.signedIn || vpnState.locationsLoading) return
    if (vpnState.countries.length === 0 && vpnState.gateways.length === 0)
      vpnState.loadLocations()
  }

  function open() {
    if (panelRoot.vpnState) panelRoot.vpnState.demandAgent(true)
    if (panelRoot.vpnState && panelRoot.vpnState.onboardingComplete)
      panelRoot.vpnState.activateBackend()
    ensureRootDestinations()
    Qt.callLater(panelRoot.ensureRootDestinations)
    panelRoot.controller.show()
    Qt.callLater(function() {
      if (!panelRoot.opened) return
      panelRoot.cursorActive = false
      if (panelRoot.onboardingVisible) onboardingView.focusInitial()
      else if (panelRoot.authVisible) authView.focusInitial()
      else keyCatcher.forceActiveFocus()
    })
  }

  function close() {
    panelRoot.controller.hide()
    if (panelRoot.vpnState) panelRoot.vpnState.demandAgent(false)
  }

  function toggle() {
    if (panelRoot.opened) panelRoot.close()
    else panelRoot.open()
  }

  function switchPanel(direction) {
    if (panelRoot.bar && typeof panelRoot.bar.switchPanelFrom === 'function')
      return panelRoot.bar.switchPanelFrom(panelRoot.barIdentity, direction)
    return false
  }

  function setCenterHoverRevealSuppressed(value) {
    if (panelRoot.bar && 'centerHoverRevealSuppressed' in panelRoot.bar)
      panelRoot.bar.centerHoverRevealSuppressed = value
  }

  function setCursor(index) {
    cursorActive = true
    cursorIndex = Math.max(0, Math.min(cursorCount - 1, index))
  }

  function moveCursor(dy) {
    cursorActive = true
    if (dy === 0) return
    cursorIndex = (cursorIndex + (dy > 0 ? 1 : -1) + cursorCount) % cursorCount
    scrollCursorIntoView()
  }

  function cursorItem(index) {
    return index === 0 ? heroBlock : detailsRow
  }

  function scrollCursorIntoView() {
    Qt.callLater(function() {
      var item = cursorItem(cursorIndex)
      if (!item || !panelFlick) return
      var point = item.mapToItem(panelFlick.contentItem, 0, 0)
      var margin = Style.space(8)
      var top = point.y
      var bottom = top + item.height
      if (top < panelFlick.contentY + margin)
        panelFlick.contentY = Math.max(0, top - margin)
      else if (bottom > panelFlick.contentY + panelFlick.height - margin)
        panelFlick.contentY = Math.min(
          Math.max(0, panelFlick.contentHeight - panelFlick.height),
          bottom + margin - panelFlick.height)
    })
  }

  function activateCursor() {
    if (!vpnState) return
    if (cursorIndex === 0) {
      if (!vpnState.tunnelOperationBusy) vpnState.toggleConnection()
    } else {
      pushRoute('details')
    }
  }

  onOpenedChanged: {
    setCenterHoverRevealSuppressed(opened)
    if (opened) {
      cursorActive = false
      resetPagePosition()
      Qt.callLater(function() {
        if (panelRoot.onboardingVisible) onboardingView.focusInitial()
        else if (panelRoot.authVisible) authView.focusInitial()
        else keyCatcher.forceActiveFocus()
      })
    }
  }

  onOnboardingVisibleChanged: {
    if (!onboardingVisible && vpnState) vpnState.activateBackend()
  }

  onHasGatewaysChanged: {
    if (!hasGateways && route === 'gateways') selectRootRoute('locations')
  }

  Connections {
    target: panelRoot.vpnState
    ignoreUnknownSignals: true
    function onSignedInChanged() {
      if (panelRoot.vpnState && panelRoot.vpnState.signedIn)
        panelRoot.ensureRootDestinations()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: panelRoot.anchorItem
    owner: panelRoot.barIdentity
    bar: panelRoot.bar
    open: panelRoot.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panelRoot.inputViewVisible
      ? panel.fittedContentHeight(
          panelRoot.onboardingVisible
            ? onboardingView.implicitHeight : authView.implicitHeight,
          Style.space(590))
      : panel.fittedContentHeight(Style.space(590), Style.space(590))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      onMoveRequested: function(dx, dy) {
        if (panelRoot.inputViewVisible) return
        if (dx !== 0 && panelRoot.rootRoute) {
          panelRoot.moveRootRoute(dx)
          return
        }
        if (panelRoot.route !== 'home') return
        if (!panelRoot.cursorActive) {
          panelRoot.cursorActive = true
          panelRoot.cursorIndex = 0
          return
        }
        panelRoot.moveCursor(dy)
      }
      onActivateRequested: {
        if (!panelRoot.inputViewVisible && panelRoot.route === 'home' &&
            panelRoot.cursorActive)
          panelRoot.activateCursor()
      }
      onCloseRequested: {
        if (!panelRoot.inputViewVisible && panelRoot.goBack()) return
        panelRoot.close()
      }
      onTabRequested: function(direction) { panelRoot.switchPanel(direction) }
      onTextKey: function(t) {
        if (!panelRoot.vpnState || panelRoot.inputViewVisible) return
        if (t === 'c' || t === 'C') panelRoot.vpnState.toggleConnection()
        else if (t === 'o' || t === 'O') panelRoot.pushRoute('details')
        else if ((t === 'k' || t === 'K') &&
                 panelRoot.vpnState.killSwitchWritable &&
                 !panelRoot.vpnState.operationBusy)
          panelRoot.vpnState.toggleKillSwitch()
        else if ((t === 'n' || t === 'N') &&
                 panelRoot.vpnState.netShieldWritable &&
                 !panelRoot.vpnState.operationBusy)
          panelRoot.vpnState.toggleNetShield()
        else if ((t === 's' || t === 'S') &&
                 panelRoot.vpnState.splitTunnelingWritable &&
                 !panelRoot.vpnState.operationBusy)
          panelRoot.vpnState.toggleSplitTunneling()
      }

      Flickable {
        id: panelFlick
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: rootNavigation.visible ? rootNavigation.top : parent.bottom
        contentWidth: width
        contentHeight: panelRoot.onboardingVisible
          ? onboardingView.implicitHeight
          : panelRoot.authVisible
            ? authView.implicitHeight
            : panelRoot.route === 'home'
              ? homeColumn.implicitHeight : routeColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ProtonOnboardingView {
          id: onboardingView
          visible: panelRoot.onboardingVisible
          width: panelFlick.width
          vpnState: panelRoot.vpnState
          strings: panelRoot.stringTable
          foreground: panelRoot.foreground
          urgent: panelRoot.urgent
          dim: panelRoot.dim
          fontFamily: panelRoot.fontFamily
        }

        ProtonAuthView {
          id: authView
          visible: panelRoot.authVisible
          width: panelFlick.width
          vpnState: panelRoot.vpnState
          strings: panelRoot.stringTable
          foreground: panelRoot.foreground
          urgent: panelRoot.urgent
          dim: panelRoot.dim
          fontFamily: panelRoot.fontFamily
        }

        Column {
          id: homeColumn
          visible: !panelRoot.inputViewVisible && panelRoot.route === 'home'
          enabled: visible
          width: panelFlick.width
          spacing: Style.space(10)

          Item {
            id: heroBlock
            width: parent.width
            implicitHeight: hero.implicitHeight
            readonly property bool ringVisible:
              panelRoot.cursorActive && panelRoot.cursorIndex === 0

            PanelHero {
              id: hero
              width: parent.width
              title: panelRoot.vpnState && panelRoot.vpnState.connected
                ? (panelRoot.vpnState.countryName || panelRoot.vpnState.countryCode)
                : 'Proton VPN'
              meta: !panelRoot.vpnState || !panelRoot.vpnState.agentAvailable
                ? strings.text('agent_unavailable')
                : !panelRoot.vpnState.backendReady
                  ? strings.text('backend_unavailable')
                  : !panelRoot.vpnState.signedIn
                    ? strings.text('sign_in_title')
                    : panelRoot.vpnState.connecting
                      ? strings.text('connecting_to') + ' ' +
                        (panelRoot.vpnState.countryName || panelRoot.vpnState.countryCode ||
                         strings.text('fastest_server').toLowerCase()) + '…'
                      : panelRoot.vpnState.connected
                        ? panelRoot.vpnState.serverName
                        : strings.text('vpn_disconnected')
              foreground: panelRoot.foreground
              fontFamily: panelRoot.fontFamily
              iconOpacity: panelRoot.vpnState && panelRoot.vpnState.connected ? 1.0 : 0.58

              iconComponent: Component {
                ProtonVpnMark {
                  iconSize: Style.font.display
                  statusColor: panelRoot.vpnState && panelRoot.vpnState.connected
                    ? Color.accent
                    : panelRoot.vpnState && panelRoot.vpnState.connecting
                      ? panelRoot.foreground : panelRoot.dim
                  state: !panelRoot.vpnState || panelRoot.vpnState.status === 'unknown'
                    ? 'information'
                    : panelRoot.vpnState.connected
                      ? 'connected'
                      : panelRoot.vpnState.connecting
                        ? 'connecting' : 'disconnected'
                }
              }

              trailingControl: Component {
                ToggleSwitch {
                  id: connectionSwitch
                  checked: panelRoot.vpnState ? panelRoot.vpnState.connected : false
                  busy: panelRoot.vpnState ? panelRoot.vpnState.tunnelOperationBusy : false
                  hasCursor: heroBlock.ringVisible
                  foreground: hero.foreground
                  onHovered: function(on) { if (on) panelRoot.setCursor(0) }
                  onToggled: if (panelRoot.vpnState) panelRoot.vpnState.toggleConnection()

                  PanelToolTip {
                    visible: connectionSwitch.containsMouse
                    text: panelRoot.vpnState &&
                      (panelRoot.vpnState.connected || panelRoot.vpnState.connecting)
                        ? strings.text('disconnect_proton_vpn')
                        : strings.text('quick_connect')
                    fontFamily: hero.fontFamily
                  }
                }
              }
            }
          }

          Text {
            visible: panelRoot.vpnState &&
              (panelRoot.vpnState.operationBusy || panelRoot.vpnState.lastError !== '')
            width: parent.width
            text: !panelRoot.vpnState
              ? ''
              : panelRoot.vpnState.operationBusy
                ? strings.operationStage(panelRoot.vpnState.operationStage)
                : strings.error(
                    panelRoot.vpnState.lastErrorCode,
                    panelRoot.vpnState.lastError)
            color: panelRoot.vpnState && panelRoot.vpnState.operationBusy
              ? panelRoot.dim : panelRoot.urgent
            font.family: panelRoot.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
          }

          Text {
            visible: panelRoot.vpnState && panelRoot.vpnState.connected
            width: parent.width
            text: panelRoot.vpnState
              ? panelRoot.vpnState.protocolName(panelRoot.vpnState.protocol) +
                '  ·  ' + panelRoot.vpnState.countryCode : ''
            color: panelRoot.dim
            font.family: panelRoot.fontFamily
            font.pixelSize: Style.font.bodySmall
            horizontalAlignment: Text.AlignHCenter
          }

          Text {
            visible: panelRoot.vpnState && !panelRoot.vpnState.operationBusy &&
              panelRoot.vpnState.lastError !== '' &&
              panelRoot.vpnState.lastErrorRetryable
            width: parent.width
            text: strings.text('retryable_hint')
            color: panelRoot.dim
            font.family: panelRoot.fontFamily
            font.pixelSize: Style.font.caption
            horizontalAlignment: Text.AlignHCenter
          }

          PanelActionRow {
            id: detailsRow
            width: parent.width
            rowForeground: panelRoot.foreground
            rowFontFamily: panelRoot.fontFamily
            iconName: 'arrow_down_arrow_up'
            title: strings.text('connection_details')
            subtitle: strings.text('connection_details_description')
            detailIconName: 'chevron_right'
            hasKeyboardCursor: panelRoot.cursorActive && panelRoot.cursorIndex === 1
            onHovered: panelRoot.setCursor(1)
            onActivated: panelRoot.pushRoute('details')
          }

          PanelSeparator { foreground: panelRoot.foreground }

          ProtonRecentsView {
            id: homeRecents
            width: parent.width
            vpnState: panelRoot.vpnState
            strings: panelRoot.stringTable
            foreground: panelRoot.foreground
            urgent: panelRoot.urgent
            dim: panelRoot.dim
            fontFamily: panelRoot.fontFamily
          }

          Text {
            width: parent.width
            topPadding: Style.space(4)
            text: strings.text('official_core_note')
            color: panelRoot.dim
            font.family: panelRoot.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
          }
        }

        Column {
          id: routeColumn
          visible: !panelRoot.inputViewVisible && panelRoot.route !== 'home'
          enabled: visible
          width: panelFlick.width
          spacing: Style.space(8)

          ProtonIconButton {
            visible: !panelRoot.rootRoute
            iconName: 'chevron_left'
            label: panelRoot.routeLabel(
              panelRoot.routeStack && panelRoot.routeStack.length > 1
                ? panelRoot.routeStack[panelRoot.routeStack.length - 2] : 'home')
            foreground: panelRoot.foreground
            fontFamily: panelRoot.fontFamily
            onClicked: panelRoot.goBack()
          }

          Loader {
            id: routeLoader
            width: parent.width
            height: item ? item.implicitHeight : 0
            active: routeColumn.visible
            sourceComponent: {
              switch (panelRoot.route) {
              case 'recents': return recentsComponent
              case 'locations': return locationsComponent
              case 'gateways': return gatewaysComponent
              case 'profiles': return profilesComponent
              case 'details': return detailsComponent
              case 'settings': return settingsComponent
              case 'split-tunneling': return splitTunnelingComponent
              case 'excluded-locations': return excludedLocationsComponent
              case 'support': return supportComponent
              case 'about': return aboutComponent
              case 'default-connection': return defaultConnectionComponent
              case 'account': return accountComponent
              case 'diagnostics': return diagnosticsComponent
              default: return null
              }
            }
          }

          Connections {
            target: routeLoader.item
            ignoreUnknownSignals: true
            function onNavigateRequested(nextRoute) {
              panelRoot.pushRoute(nextRoute)
            }
          }

          Text {
            visible: panelRoot.vpnState &&
              (panelRoot.vpnState.operationBusy || panelRoot.vpnState.lastError !== '')
            width: parent.width
            text: !panelRoot.vpnState
              ? ''
              : panelRoot.vpnState.operationBusy
                ? strings.operationStage(panelRoot.vpnState.operationStage)
                : strings.error(
                    panelRoot.vpnState.lastErrorCode,
                    panelRoot.vpnState.lastError)
            color: panelRoot.vpnState && panelRoot.vpnState.operationBusy
              ? panelRoot.dim : panelRoot.urgent
            font.family: panelRoot.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
          }

          Text {
            visible: panelRoot.vpnState && !panelRoot.vpnState.operationBusy &&
              panelRoot.vpnState.lastError !== '' &&
              panelRoot.vpnState.lastErrorRetryable
            width: parent.width
            text: strings.text('retryable_hint')
            color: panelRoot.dim
            font.family: panelRoot.fontFamily
            font.pixelSize: Style.font.caption
            horizontalAlignment: Text.AlignHCenter
          }
        }
      }

      ProtonBottomNavigation {
        id: rootNavigation
        visible: !panelRoot.inputViewVisible && panelRoot.rootRoute &&
          !panelRoot.rootSubpageActive
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        destinations: panelRoot.navigationDestinations
        currentRoute: panelRoot.route
        foreground: panelRoot.foreground
        dim: panelRoot.dim
        fontFamily: panelRoot.fontFamily
        onRouteRequested: function(nextRoute) {
          panelRoot.selectRootRoute(nextRoute)
        }
      }
    }
  }

  Component {
    id: recentsComponent
    ProtonRecentsView {
      vpnState: panelRoot.vpnState; strings: panelRoot.stringTable
      foreground: panelRoot.foreground; urgent: panelRoot.urgent
      dim: panelRoot.dim; fontFamily: panelRoot.fontFamily
    }
  }

  Component {
    id: locationsComponent
    ProtonLocationsView {
      vpnState: panelRoot.vpnState; strings: panelRoot.stringTable
      foreground: panelRoot.foreground; urgent: panelRoot.urgent
      dim: panelRoot.dim; fontFamily: panelRoot.fontFamily
      section: 'countries'; sectionSwitcherVisible: false
    }
  }

  Component {
    id: gatewaysComponent
    ProtonLocationsView {
      vpnState: panelRoot.vpnState; strings: panelRoot.stringTable
      foreground: panelRoot.foreground; urgent: panelRoot.urgent
      dim: panelRoot.dim; fontFamily: panelRoot.fontFamily
      section: 'gateways'; sectionSwitcherVisible: false
    }
  }

  Component {
    id: profilesComponent
    ProtonProfilesView {
      vpnState: panelRoot.vpnState; strings: panelRoot.stringTable
      foreground: panelRoot.foreground; urgent: panelRoot.urgent
      dim: panelRoot.dim; fontFamily: panelRoot.fontFamily
    }
  }

  Component {
    id: detailsComponent
    ProtonConnectionDetailsView {
      vpnState: panelRoot.vpnState; strings: panelRoot.stringTable
      foreground: panelRoot.foreground; urgent: panelRoot.urgent
      dim: panelRoot.dim; fontFamily: panelRoot.fontFamily
    }
  }

  Component {
    id: splitTunnelingComponent
    ProtonSplitTunnelingView {
      vpnState: panelRoot.vpnState; strings: panelRoot.stringTable
      foreground: panelRoot.foreground; urgent: panelRoot.urgent
      dim: panelRoot.dim; fontFamily: panelRoot.fontFamily
    }
  }

  Component {
    id: excludedLocationsComponent
    ProtonExcludedLocationsView {
      vpnState: panelRoot.vpnState; strings: panelRoot.stringTable
      foreground: panelRoot.foreground; urgent: panelRoot.urgent
      dim: panelRoot.dim; fontFamily: panelRoot.fontFamily
    }
  }

  Component {
    id: supportComponent
    ProtonSupportView {
      vpnState: panelRoot.vpnState; strings: panelRoot.stringTable
      foreground: panelRoot.foreground; urgent: panelRoot.urgent
      dim: panelRoot.dim; fontFamily: panelRoot.fontFamily
    }
  }

  Component {
    id: aboutComponent
    ProtonAboutView {
      vpnState: panelRoot.vpnState; strings: panelRoot.stringTable
      foreground: panelRoot.foreground; urgent: panelRoot.urgent
      dim: panelRoot.dim; fontFamily: panelRoot.fontFamily
    }
  }

  Component {
    id: defaultConnectionComponent
    ProtonDefaultConnectionView {
      vpnState: panelRoot.vpnState; strings: panelRoot.stringTable
      foreground: panelRoot.foreground; urgent: panelRoot.urgent
      dim: panelRoot.dim; fontFamily: panelRoot.fontFamily
    }
  }

  Component {
    id: accountComponent
    ProtonAccountView {
      vpnState: panelRoot.vpnState; strings: panelRoot.stringTable
      foreground: panelRoot.foreground; urgent: panelRoot.urgent
      dim: panelRoot.dim; fontFamily: panelRoot.fontFamily
    }
  }

  Component {
    id: diagnosticsComponent
    ProtonDiagnosticsView {
      vpnState: panelRoot.vpnState; strings: panelRoot.stringTable
      foreground: panelRoot.foreground; urgent: panelRoot.urgent
      dim: panelRoot.dim; fontFamily: panelRoot.fontFamily
    }
  }

  Component {
    id: settingsComponent
    ProtonSettingsView {
      vpnState: panelRoot.vpnState; strings: panelRoot.stringTable
      foreground: panelRoot.foreground; urgent: panelRoot.urgent
      dim: panelRoot.dim; fontFamily: panelRoot.fontFamily
    }
  }
}
