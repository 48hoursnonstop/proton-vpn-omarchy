import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import 'components'

Item {
  id: root

  property QtObject vpnState: null
  property QtObject strings: null
  property color foreground: Color.foreground
  property color urgent: Color.urgent
  property color dim: Qt.darker(foreground, 1.55)
  property string fontFamily: Style.font.family
  property string section: 'countries'
  property string feature: 'standard'
  property bool sectionSwitcherVisible: true
  property bool selectionMode: false
  property var selectedLocation: null
  property string selectedKind: ''

  signal locationSelected(var selection)

  readonly property bool showingServers: selectedLocation !== null ||
    searchField.text.trim().length >= 2
  readonly property bool subpageActive: selectedLocation !== null
  readonly property var baseLocations: section === 'gateways'
    ? (vpnState ? vpnState.gateways : [])
    : (vpnState ? vpnState.countries : [])
  readonly property var filteredLocations: filterLocations()

  implicitHeight: content.implicitHeight

  function label(key) {
    return strings ? strings.text(key) : key
  }

  function filterLocations() {
    var needle = searchField.text.trim().toLowerCase()
    var output = []
    for (var index = 0; index < baseLocations.length; ++index) {
      var item = baseLocations[index]
      if (section === 'countries' && feature !== 'standard' && !item[feature])
        continue
      var haystack = String(item.name || item.code || '').toLowerCase()
      if (needle.length === 0 || haystack.indexOf(needle) >= 0)
        output.push(item)
    }
    return output
  }

  function refresh() {
    if (!vpnState || !vpnState.signedIn) return
    vpnState.loadLocations()
    if (showingServers) requestServers()
  }

  function requestServers() {
    if (!vpnState) return
    var query = searchField.text.trim().length >= 2
      ? searchField.text.trim() : ''
    if (!selectedLocation && query.length === 0) {
      vpnState.servers = []
      return
    }
    var country = selectedKind === 'country' && selectedLocation
      ? String(selectedLocation.code || '') : ''
    var gateway = selectedKind === 'gateway' && selectedLocation
      ? String(selectedLocation.name || '') : ''
    vpnState.loadServers(
      query,
      country,
      gateway,
      selectedKind === 'gateway' ? 'all' : feature
    )
  }

  function resetSelection() {
    selectedLocation = null
    selectedKind = ''
    if (vpnState) vpnState.servers = []
  }

  function navigateBack() {
    if (selectedLocation === null) return false
    resetSelection()
    return true
  }

  function selectSection(value) {
    section = value
    resetSelection()
  }

  function selectFeature(value) {
    feature = value
    resetSelection()
  }

  function openLocation(item, kind) {
    selectedLocation = item
    selectedKind = kind
    searchField.text = ''
    requestServers()
  }

  function chooseBestLocation() {
    if (!selectedLocation) {
      if (!selectionMode || section !== 'countries') return
      locationSelected({
        targetKind: feature === 'secure_core' ? 'secureCore'
          : feature === 'p2p' ? 'p2p'
          : feature === 'tor' ? 'tor' : 'fastest'
      })
      return
    }
    if (!selectionMode) {
      if (selectedKind === 'gateway') vpnState.connectGateway(selectedLocation)
      else vpnState.connectCountry(selectedLocation, feature)
      return
    }
    if (selectedKind === 'gateway') {
      locationSelected({
        targetKind: 'gateway',
        gatewayName: String(selectedLocation.name || '')
      })
      return
    }
    locationSelected({
      targetKind: feature === 'secure_core' ? 'secureCore'
        : feature === 'p2p' ? 'p2p'
        : feature === 'tor' ? 'tor' : 'country',
      countryCode: String(selectedLocation.code || ''),
      countryName: String(selectedLocation.name || '')
    })
  }

  function chooseServer(server) {
    if (!selectionMode) {
      vpnState.connectServer(server)
      return
    }
    var gateway = String(server.gateway_name || '')
    locationSelected({
      targetKind: gateway ? 'gatewayServer'
        : server.secure_core ? 'secureCore'
        : feature === 'p2p' ? 'p2p'
        : feature === 'tor' ? 'tor' : 'server',
      countryCode: String(server.country_code || ''),
      countryName: String(server.country_name || ''),
      entryCountryCode: String(server.entry_country_code || ''),
      entryCountryName: String(server.entry_country_name || ''),
      serverName: String(server.name || ''),
      gatewayName: gateway
    })
  }

  onVisibleChanged: if (visible) refresh()
  Component.onCompleted: if (visible) refresh()

  Column {
    id: content
    width: parent.width
    spacing: Style.space(9)

    RowLayout {
      width: parent.width
      spacing: Style.space(8)

      ProtonIconButton {
        visible: root.selectedLocation !== null
        iconName: 'chevron_left'
        foreground: root.foreground
        fontFamily: root.fontFamily
        tooltipText: root.label('locations')
        onClicked: {
          root.resetSelection()
        }
      }

      Text {
        Layout.fillWidth: true
        text: root.selectedLocation
          ? String(root.selectedLocation.name || root.selectedLocation.code || '')
          : root.sectionSwitcherVisible
            ? root.label('locations')
            : root.section === 'gateways'
              ? root.label('gateways') : root.label('countries')
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.heading
        font.weight: Font.DemiBold
        elide: Text.ElideRight
      }

      Text {
        text: root.vpnState && root.vpnState.locationsLoading ? '…' : ''
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
      }
    }

    TextField {
      id: searchField
      width: parent.width
      placeholderText: root.label('search_locations')
      foreground: root.foreground
      accent: Color.accent
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      horizontalPadding: Style.spacing.controlGap
      verticalPadding: Style.spacing.controlPaddingY
      onTextChanged: searchDebounce.restart()
    }

    Timer {
      id: searchDebounce
      interval: 250
      repeat: false
      onTriggered: {
        if (searchField.text.trim().length === 0 ||
            searchField.text.trim().length >= 2)
          root.requestServers()
      }
    }

    RowLayout {
      visible: root.sectionSwitcherVisible && root.selectedLocation === null &&
        searchField.text.trim().length < 2
      width: parent.width
      spacing: Style.space(8)

      Button {
        Layout.fillWidth: true
        text: root.label('countries')
        foreground: root.foreground
        fontFamily: root.fontFamily
        bordered: true
        active: root.section === 'countries'
        onClicked: root.selectSection('countries')
      }

      Button {
        visible: root.vpnState && root.vpnState.gateways.length > 0
        Layout.fillWidth: true
        text: root.label('gateways')
        foreground: root.foreground
        fontFamily: root.fontFamily
        bordered: true
        active: root.section === 'gateways'
        onClicked: root.selectSection('gateways')
      }
    }

    RowLayout {
      visible: root.selectedLocation === null && root.section === 'countries' &&
        searchField.text.trim().length < 2
      width: parent.width
      spacing: Style.space(5)

      Repeater {
        model: [
          { value: 'standard', label: root.label('standard'), icon: 'earth' },
          { value: 'secure_core', label: 'Secure Core', icon: 'locks' },
          { value: 'p2p', label: 'P2P', icon: 'arrow_right_arrow_left' },
          { value: 'tor', label: 'Tor', icon: 'brand_tor' }
        ]

        delegate: ProtonIconButton {
          required property var modelData
          Layout.fillWidth: true
          iconName: String(modelData.icon)
          label: String(modelData.label)
          foreground: root.foreground
          fontFamily: root.fontFamily
          bordered: true
          active: root.feature === String(modelData.value)
          onClicked: root.selectFeature(String(modelData.value))
        }
      }
    }

    PanelActionRow {
      visible: root.selectionMode && root.selectedLocation === null &&
        root.section === 'countries' && searchField.text.trim().length < 2
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'bolt'
      title: root.feature === 'secure_core' ? root.label('fastest_secure_core')
        : root.feature === 'p2p' ? root.label('fastest_p2p')
        : root.feature === 'tor' ? root.label('fastest_tor')
        : root.label('fastest_server')
      subtitle: root.label('best_available_profile_target')
      detailIconName: 'chevron_right'
      onActivated: root.chooseBestLocation()
    }

    PanelActionRow {
      visible: root.selectedLocation !== null
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'bolt'
      title: root.selectedKind === 'gateway'
        ? root.label('fastest_gateway')
        : root.feature === 'secure_core' ? root.label('fastest_secure_core')
        : root.feature === 'p2p' ? root.label('fastest_p2p')
        : root.feature === 'tor' ? root.label('fastest_tor')
        : root.label('fastest_server')
      subtitle: root.label('connect_best_available')
      detailIconName: 'chevron_right'
      busy: !root.selectionMode && root.vpnState &&
        root.vpnState.tunnelOperationBusy
      enabled: root.selectionMode || !(root.vpnState &&
        root.vpnState.tunnelOperationBusy)
      onActivated: {
        root.chooseBestLocation()
      }
    }

    ListView {
      id: locationsList
      visible: !root.showingServers
      width: parent.width
      height: Math.min(contentHeight, Style.space(410))
      implicitHeight: height
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      model: root.filteredLocations
      spacing: Style.space(2)

      delegate: PanelActionRow {
        required property var modelData
        width: ListView.view.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconText: root.section === 'countries' ? String(modelData.code || '') : ''
        iconName: root.section === 'gateways' ? 'servers' : ''
        title: String(modelData.name || modelData.code || '')
        subtitle: String(modelData.available_server_count || 0) + ' / ' +
          String(modelData.server_count || 0) + ' ' + root.label('servers').toLowerCase()
        detailIconName: 'chevron_right'
        onActivated: root.openLocation(
          modelData,
          root.section === 'countries' ? 'country' : 'gateway'
        )
      }
    }

    ListView {
      id: serversList
      visible: root.showingServers
      width: parent.width
      height: Math.min(contentHeight, Style.space(410))
      implicitHeight: height
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      model: root.vpnState ? root.vpnState.servers : []
      spacing: Style.space(2)

      delegate: PanelActionRow {
        required property var modelData
        width: ListView.view.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconText: String(modelData.country_code || '')
        title: String(modelData.name || '')
        subtitle: (modelData.secure_core
          ? String(modelData.entry_country_name || modelData.entry_country_code || '') + ' → '
          : modelData.city ? String(modelData.city) + ' · ' : '') +
          String(modelData.load || 0) + '%'
        detailIconName: modelData.maintenance || !modelData.enabled
          ? 'minus_circle_filled' : 'play'
        enabled: !!modelData.enabled && !modelData.maintenance &&
          (root.selectionMode || !(root.vpnState &&
            root.vpnState.tunnelOperationBusy))
        busy: !root.selectionMode && root.vpnState &&
          root.vpnState.tunnelOperationBusy
        onActivated: root.chooseServer(modelData)
      }
    }

    Text {
      visible: root.showingServers && root.vpnState &&
        !root.vpnState.serversLoading && root.vpnState.servers.length === 0
      width: parent.width
      text: root.label('no_servers_found')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
    }

    Text {
      visible: root.vpnState && root.vpnState.serversLoading
      width: parent.width
      text: root.label('loading_servers')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      horizontalAlignment: Text.AlignHCenter
    }
  }
}
