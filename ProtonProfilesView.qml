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
  property bool editing: false
  property bool pickerVisible: false
  property bool protocolPickerVisible: false
  property bool netShieldLevelPickerVisible: false
  property bool iconPickerVisible: false
  property bool connectAndGoPickerVisible: false
  property bool connectAndGoAppPickerVisible: false
  property string editingId: ''
  property string targetKind: 'fastest'
  property string countryCode: ''
  property string countryName: ''
  property string entryCountryCode: ''
  property string entryCountryName: ''
  property string serverName: ''
  property string gatewayName: ''
  property string pickerSection: 'countries'
  property string pickerFeature: 'standard'
  property string profileProtocol: 'smart'
  property bool netShieldEnabled: true
  property int netShieldLevel: 2
  property bool moderateNat: false
  property bool portForwardingEnabled: false
  property string profileIconName: 'Speed'
  property string profileColor: '#C857E7'
  property string connectAndGoMode: 'off'
  property string connectAndGoUrl: ''
  property bool connectAndGoPrivate: false
  property string connectAndGoAppId: ''
  property string connectAndGoAppPath: ''
  property string connectAndGoAppName: ''
  property string deleteCandidateId: ''
  property string saveRequestId: ''
  property string deleteRequestId: ''
  readonly property bool subpageActive: editing || pickerVisible

  readonly property var profileColors: [
    '#0E7AD2', '#C857E7', '#4DC73D', '#C93333', '#F08C00', '#E2CC19'
  ]
  readonly property var profileCategories: [
    'Speed', 'Streaming', 'Protection', 'Privacy', 'Anonymous', 'Terminal',
    'Gaming', 'Download', 'Business', 'Shopping', 'Security', 'Browsing'
  ]

  implicitHeight: content.implicitHeight

  function label(key) { return strings ? strings.text(key) : key }

  function refresh() {
    if (vpnState && vpnState.signedIn) vpnState.loadProfiles(0)
  }

  function navigateBack() {
    if (pickerVisible) {
      pickerVisible = false
      return true
    }
    if (!editing) return false
    editing = false
    deleteCandidateId = ''
    return true
  }

  function newProfile() {
    editing = true
    pickerVisible = false
    protocolPickerVisible = false
    netShieldLevelPickerVisible = false
    iconPickerVisible = false
    connectAndGoPickerVisible = false
    connectAndGoAppPickerVisible = false
    editingId = ''
    nameField.text = ''
    targetKind = 'fastest'
    countryCode = ''
    countryName = ''
    entryCountryCode = ''
    entryCountryName = ''
    serverName = ''
    gatewayName = ''
    profileProtocol = 'smart'
    netShieldEnabled = true
    netShieldLevel = 2
    moderateNat = false
    portForwardingEnabled = false
    profileIconName = 'Speed'
    profileColor = '#C857E7'
    connectAndGoMode = 'off'
    connectAndGoUrl = ''
    connectAndGoPrivate = false
    connectAndGoAppId = ''
    connectAndGoAppPath = ''
    connectAndGoAppName = ''
    Qt.callLater(nameField.forceActiveFocus)
  }

  function editProfile(profile) {
    editing = true
    pickerVisible = false
    protocolPickerVisible = false
    netShieldLevelPickerVisible = false
    iconPickerVisible = false
    connectAndGoPickerVisible = false
    connectAndGoAppPickerVisible = false
    editingId = String(profile.id || '')
    nameField.text = String(profile.name || '')
    targetKind = String(profile.targetKind || 'fastest')
    countryCode = String(profile.countryCode || '')
    countryName = String(profile.countryName || '')
    entryCountryCode = String(profile.entryCountryCode || '')
    entryCountryName = String(profile.entryCountryName || '')
    serverName = String(profile.serverName || '')
    gatewayName = String(profile.gatewayName || '')
    profileProtocol = profileProtocolValue(profile.profileProtocol || 'smart')
    netShieldEnabled = profile.profileNetShieldEnabled !== false
    netShieldLevel = Number(profile.profileNetShieldLevel === undefined
      ? 2 : profile.profileNetShieldLevel)
    moderateNat = String(profile.profileNatType || '') === 'moderate'
    portForwardingEnabled = !!profile.profilePortForwardingEnabled
    profileIconName = String(profile.iconName || 'Speed')
    profileColor = String(profile.color || '#C857E7')
    connectAndGoMode = profile.connectAndGoEnabled
      ? String(profile.connectAndGoMode || 'website') : 'off'
    connectAndGoUrl = String(profile.connectAndGoUrl || '')
    connectAndGoPrivate = !!profile.connectAndGoUsePrivateBrowsingMode
    connectAndGoAppId = String(profile.connectAndGoAppId || '')
    connectAndGoAppPath = String(profile.connectAndGoAppPath || '')
    connectAndGoAppName = String(profile.connectAndGoAppName || '')
    Qt.callLater(nameField.forceActiveFocus)
  }

  function openLocationPicker() {
    protocolPickerVisible = false
    pickerSection = ['gateway', 'gatewayServer'].indexOf(targetKind) >= 0
      ? 'gateways' : 'countries'
    pickerFeature = targetKind === 'secureCore' ? 'secure_core'
      : targetKind === 'p2p' ? 'p2p'
      : targetKind === 'tor' ? 'tor' : 'standard'
    pickerVisible = true
    Qt.callLater(function() {
      locationPicker.selectSection(root.pickerSection)
      locationPicker.selectFeature(root.pickerFeature)
      locationPicker.refresh()
    })
  }

  function applyLocation(selection) {
    if (!selection) return
    targetKind = String(selection.targetKind || 'fastest')
    countryCode = String(selection.countryCode || '')
    countryName = String(selection.countryName || '')
    entryCountryCode = String(selection.entryCountryCode || '')
    entryCountryName = String(selection.entryCountryName || '')
    serverName = String(selection.serverName || '')
    gatewayName = String(selection.gatewayName || '')
    pickerVisible = false
  }

  function targetSummary(profile) {
    var item = profile || {
      targetKind: targetKind,
      countryCode: countryCode,
      countryName: countryName,
      entryCountryCode: entryCountryCode,
      entryCountryName: entryCountryName,
      serverName: serverName,
      gatewayName: gatewayName
    }
    var kind = String(item.targetKind || 'fastest')
    var country = String(item.countryName || item.countryCode || '')
    var entry = String(item.entryCountryName || item.entryCountryCode || '')
    var server = String(item.serverName || '')
    var gateway = String(item.gatewayName || '')
    if (kind === 'gateway' || kind === 'gatewayServer')
      return gateway + (server ? ' · ' + server : '')
    if (kind === 'secureCore' && entry)
      return entry + ' → ' + (country || server)
    if (server) return (country ? country + ' · ' : '') + server
    if (country) return country
    return label('target_' + kind)
  }

  function profileProtocolValue(value) {
    switch (String(value || '').toLowerCase()) {
    case 'wireguard': return 'wireguard-udp'
    case 'protun-smart': return 'smart'
    default: return String(value || 'smart').toLowerCase()
    }
  }

  function profileProtocolOptions() {
    var advertised = vpnState && Array.isArray(vpnState.availableProfileProtocols)
      ? vpnState.availableProfileProtocols : []
    // This Omarchy target ships the validated ProTun TLS backend. Keep its
    // profile-facing Stealth choice visible even before the lazy bridge has
    // published its connector inventory.
    var supported = ['smart', 'protun-tls']
    for (var index = 0; index < advertised.length; ++index) {
      var value = profileProtocolValue(advertised[index])
      if (value !== 'smart' && supported.indexOf(value) < 0)
        supported.push(value)
    }

    // Keep the mobile-style choices predictable, with Stealth next to
    // WireGuard instead of buried at the end of a backend-defined list.
    var preferred = [
      'smart', 'wireguard-udp', 'protun-tls', 'protun-udp',
      'protun-tcp', 'openvpn-udp', 'openvpn-tcp'
    ]
    var output = []
    for (index = 0; index < preferred.length; ++index) {
      if (supported.indexOf(preferred[index]) >= 0)
        output.push(preferred[index])
    }
    return output
  }

  function protocolIcon(value) {
    switch (String(value || '')) {
    case 'smart': return 'sliders'
    case 'protun-tls': return 'shield'
    case 'openvpn-udp':
    case 'openvpn-tcp': return 'globe'
    default: return 'brand_wireguard'
    }
  }

  function profileIconSource(value) {
    var asset = 'bolt'
    switch (String(value || 'Speed')) {
    case 'Streaming': asset = 'streaming'; break
    case 'Protection': asset = 'shield'; break
    case 'Privacy': asset = 'eye'; break
    case 'Anonymous': asset = 'anonymous'; break
    case 'Terminal': asset = 'terminal'; break
    case 'Gaming': asset = 'gaming'; break
    case 'Download': asset = 'download'; break
    case 'Business': asset = 'business'; break
    case 'Shopping': asset = 'shopping'; break
    case 'Security': asset = 'security'; break
    case 'Browsing': asset = 'browsing'; break
    }
    return Qt.resolvedUrl('assets/mobile/profiles/profile_' + asset + '_icon.webp')
  }

  function connectAndGoValid() {
    if (connectAndGoMode === 'off') return true
    if (connectAndGoMode === 'website')
      return connectAndGoUrl.trim().length > 0
    if (connectAndGoMode === 'application')
      return connectAndGoAppId.length > 0
    return false
  }

  function selectConnectAndGoApp(app) {
    if (!app) return
    connectAndGoAppId = String(app.id || '')
    connectAndGoAppPath = String(app.executable || '')
    connectAndGoAppName = String(app.name || app.id || '')
    connectAndGoAppPickerVisible = false
  }

  function targetValid() {
    if (['fastest', 'p2p', 'secureCore', 'tor'].indexOf(targetKind) >= 0)
      return true
    if (targetKind === 'country') return countryCode.length > 0
    if (targetKind === 'server') return countryCode.length > 0 && serverName.length > 0
    if (targetKind === 'gateway') return gatewayName.length > 0
    if (targetKind === 'gatewayServer') return gatewayName.length > 0 &&
      serverName.length > 0
    return false
  }

  function save() {
    if (!vpnState || nameField.text.trim().length === 0 || !targetValid()) return
    saveRequestId = vpnState.saveProfile({
      id: editingId,
      name: nameField.text.trim(),
      iconName: profileIconName,
      color: profileColor,
      targetKind: targetKind,
      countryCode: countryCode,
      countryName: countryName,
      entryCountryCode: entryCountryCode,
      entryCountryName: entryCountryName,
      serverName: serverName,
      gatewayName: gatewayName,
      profileProtocol: profileProtocol,
      profileNetShieldEnabled: netShieldEnabled,
      profileNetShieldLevel: netShieldLevel,
      profileNatType: moderateNat ? 'moderate' : 'strict',
      profilePortForwardingEnabled: portForwardingEnabled,
      connectAndGoEnabled: connectAndGoMode !== 'off',
      connectAndGoMode: connectAndGoMode === 'off' ? 'website' : connectAndGoMode,
      connectAndGoUrl: connectAndGoUrl.trim(),
      connectAndGoUsePrivateBrowsingMode: connectAndGoPrivate,
      connectAndGoAppId: connectAndGoAppId,
      connectAndGoAppPath: connectAndGoAppPath,
      connectAndGoAppName: connectAndGoAppName
    })
  }

  Connections {
    target: root.vpnState

    function onRequestFinished(requestId, method, ok, errorCode) {
      if (requestId === root.saveRequestId) {
        root.saveRequestId = ''
        if (ok) root.editing = false
      }
      if (requestId === root.deleteRequestId) {
        root.deleteRequestId = ''
        if (ok) {
          root.deleteCandidateId = ''
          root.editing = false
        }
      }
    }
  }

  onVisibleChanged: if (visible) refresh()
  Component.onCompleted: if (visible) refresh()

  Column {
    id: content
    width: parent.width
    spacing: Style.space(9)

    RowLayout {
      width: parent.width

      Text {
        Layout.fillWidth: true
        text: root.pickerVisible ? root.label('choose_location')
          : root.editing ? root.label('edit_profile') : root.label('profiles')
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.heading
        font.weight: Font.DemiBold
      }

      Button {
        visible: root.editing
        text: root.label('cancel')
        foreground: root.foreground
        fontFamily: root.fontFamily
        bordered: false
        onClicked: {
          if (root.pickerVisible) root.pickerVisible = false
          else if (root.editing) root.editing = false
          else root.newProfile()
        }
      }

      ProtonIconButton {
        visible: !root.editing
        iconName: 'plus'
        foreground: root.foreground
        fontFamily: root.fontFamily
        tooltipText: root.label('profiles')
        onClicked: root.newProfile()
      }
    }

    Column {
      visible: root.editing && !root.pickerVisible
      width: parent.width
      spacing: Style.space(7)

      TextField {
        id: nameField
        width: parent.width
        placeholderText: root.label('profile_name')
        foreground: root.foreground
        accent: Color.accent
        font.family: root.fontFamily
        maximumLength: 60
      }

      PanelActionRow {
        width: parent.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconSource: root.profileIconSource(root.profileIconName)
        iconTint: false
        title: root.label('profile_icon')
        subtitle: root.profileIconName
        detailIconName: 'chevron_right'
        onActivated: root.iconPickerVisible = !root.iconPickerVisible
      }

      Column {
        visible: root.iconPickerVisible
        width: parent.width
        spacing: Style.space(2)

        Row {
          width: parent.width
          spacing: Style.space(4)

          Repeater {
            model: root.profileColors

            delegate: Button {
              required property string modelData
              width: Math.max(Style.space(34),
                              (parent.width - Style.space(20)) / 6)
              text: root.profileColor.toUpperCase() === modelData.toUpperCase()
                ? '●' : '○'
              foreground: modelData
              fontFamily: root.fontFamily
              bordered: false
              onClicked: root.profileColor = modelData
            }
          }
        }

        Repeater {
          model: root.profileCategories

          delegate: PanelActionRow {
            required property string modelData
            width: root.width
            rowForeground: root.foreground
            rowFontFamily: root.fontFamily
            iconSource: root.profileIconSource(modelData)
            iconTint: false
            title: modelData
            detailIconName: root.profileIconName === modelData ? 'checkmark' : ''
            checked: root.profileIconName === modelData
            onActivated: {
              root.profileIconName = modelData
              root.iconPickerVisible = false
            }
          }
        }
      }

      PanelActionRow {
        width: parent.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconName: 'map_pin'
        title: root.label('profile_target')
        subtitle: root.targetSummary(null)
        detailIconName: 'chevron_right'
        onActivated: root.openLocationPicker()
      }

      PanelActionRow {
        width: parent.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconName: 'servers'
        title: root.label('protocol')
        subtitle: root.vpnState
          ? root.vpnState.protocolName(root.profileProtocol)
          : root.profileProtocol
        detailIconName: 'chevron_right'
        onActivated: root.protocolPickerVisible = !root.protocolPickerVisible
      }

      Column {
        visible: root.protocolPickerVisible
        width: parent.width
        spacing: Style.space(2)

        Repeater {
          model: root.profileProtocolOptions()

          delegate: PanelActionRow {
            required property string modelData
            width: root.width
            rowForeground: root.foreground
            rowFontFamily: root.fontFamily
            iconName: root.protocolIcon(modelData)
            title: root.vpnState
              ? root.vpnState.protocolName(modelData) : modelData
            detailIconName: root.profileProtocol === modelData ? 'checkmark' : ''
            checked: root.profileProtocol === modelData
            onActivated: {
              root.profileProtocol = modelData
              root.protocolPickerVisible = false
            }
          }
        }
      }

      PanelActionRow {
        width: parent.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconName: 'shield_2_bolt'
        title: 'NetShield'
        subtitle: root.netShieldEnabled ? root.label('enabled') : root.label('disabled')
        toggleVisible: true
        checked: root.netShieldEnabled
        onActivated: root.netShieldEnabled = !root.netShieldEnabled
      }

      PanelActionRow {
        visible: root.netShieldEnabled
        width: parent.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconName: 'shield_2_bolt'
        title: root.label('netshield_level')
        subtitle: root.label('netshield_level_' + root.netShieldLevel)
        detailIconName: 'chevron_right'
        onActivated: root.netShieldLevelPickerVisible =
          !root.netShieldLevelPickerVisible
      }

      ProtonOptionPicker {
        visible: root.netShieldEnabled && root.netShieldLevelPickerVisible
        width: parent.width
        options: [0, 1, 2].map(function(value) {
          return {
            value: value,
            label: root.label('netshield_level_' + value),
            iconName: 'shield_2_bolt'
          }
        })
        currentValue: root.netShieldLevel
        foreground: root.foreground
        fontFamily: root.fontFamily
        onSelected: function(value) {
          root.netShieldLevel = value
          root.netShieldLevelPickerVisible = false
        }
      }

      PanelActionRow {
        width: parent.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconName: 'globe'
        title: root.label('moderate_nat')
        toggleVisible: true
        checked: root.moderateNat
        onActivated: {
          root.moderateNat = !root.moderateNat
          if (root.moderateNat) root.portForwardingEnabled = false
        }
      }

      PanelActionRow {
        width: parent.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconName: 'arrow_right_arrow_left'
        title: root.label('port_forwarding')
        toggleVisible: true
        checked: root.portForwardingEnabled
        enabled: !root.moderateNat
        onActivated: root.portForwardingEnabled = !root.portForwardingEnabled
      }

      PanelActionRow {
        width: parent.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconName: 'arrow_out_square'
        title: 'Connect and Go'
        subtitle: root.connectAndGoMode === 'website'
          ? root.label('open_website')
          : root.connectAndGoMode === 'application'
            ? root.label('open_application') : root.label('disabled')
        detailIconName: 'chevron_right'
        onActivated: root.connectAndGoPickerVisible = !root.connectAndGoPickerVisible
      }

      Column {
        visible: root.connectAndGoPickerVisible
        width: parent.width
        spacing: Style.space(3)

        Repeater {
          model: ['off', 'website', 'application']

          delegate: PanelActionRow {
            required property string modelData
            width: root.width
            rowForeground: root.foreground
            rowFontFamily: root.fontFamily
            iconName: modelData === 'website' ? 'globe'
              : modelData === 'application' ? 'squares_in_square' : 'power_off'
            title: modelData === 'website' ? root.label('open_website')
              : modelData === 'application' ? root.label('open_application')
              : root.label('disabled')
            detailIconName: root.connectAndGoMode === modelData ? 'checkmark' : ''
            checked: root.connectAndGoMode === modelData
            onActivated: root.connectAndGoMode = modelData
          }
        }

        TextField {
          visible: root.connectAndGoMode === 'website'
          width: parent.width
          placeholderText: 'https://protonvpn.com'
          text: root.connectAndGoUrl
          foreground: root.foreground
          accent: Color.accent
          font.family: root.fontFamily
          maximumLength: 2048
          onTextChanged: root.connectAndGoUrl = text
        }

        PanelActionRow {
          visible: root.connectAndGoMode === 'website'
          width: parent.width
          rowForeground: root.foreground
          rowFontFamily: root.fontFamily
          iconName: 'eye'
          title: root.label('private_browsing')
          subtitle: root.label('private_browsing_description')
          toggleVisible: true
          checked: root.connectAndGoPrivate
          onActivated: root.connectAndGoPrivate = !root.connectAndGoPrivate
        }

        PanelActionRow {
          visible: root.connectAndGoMode === 'application'
          width: parent.width
          rowForeground: root.foreground
          rowFontFamily: root.fontFamily
          iconName: 'squares_in_square'
          title: root.label('application')
          subtitle: root.connectAndGoAppName || root.label('select_application')
          detailIconName: 'chevron_right'
          onActivated: {
            root.connectAndGoAppPickerVisible = !root.connectAndGoAppPickerVisible
            if (root.connectAndGoAppPickerVisible && root.vpnState)
              root.vpnState.loadApps('')
          }
        }

        ListView {
          visible: root.connectAndGoMode === 'application' &&
            root.connectAndGoAppPickerVisible
          width: parent.width
          height: Math.min(contentHeight, Style.space(220))
          implicitHeight: height
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          model: root.vpnState ? root.vpnState.installedApps : []
          spacing: Style.space(2)

          delegate: PanelActionRow {
            required property var modelData
            width: ListView.view.width
            rowForeground: root.foreground
            rowFontFamily: root.fontFamily
            iconName: 'squares_in_square'
            title: String(modelData.name || modelData.id || '')
            subtitle: String(modelData.executable || '')
            detailIconName: root.connectAndGoAppId === String(modelData.id || '')
              ? 'checkmark' : ''
            checked: root.connectAndGoAppId === String(modelData.id || '')
            onActivated: root.selectConnectAndGoApp(modelData)
          }
        }
      }

      Button {
        width: parent.width
        text: root.label('save_profile')
        foreground: root.foreground
        fontFamily: root.fontFamily
        bordered: true
        active: true
        enabled: nameField.text.trim().length > 0 && root.targetValid() &&
          root.connectAndGoValid() &&
          root.saveRequestId.length === 0 &&
          !(root.vpnState && root.vpnState.operationBusy)
        onClicked: root.save()
      }

      Button {
        visible: root.editingId.length > 0
        width: parent.width
        text: root.vpnState && root.vpnState.defaultConnection.type === 'profile' &&
          root.vpnState.defaultConnection.profileId === root.editingId
          ? root.label('default_profile_active') : root.label('make_default_profile')
        foreground: root.foreground
        fontFamily: root.fontFamily
        bordered: false
        enabled: !(root.vpnState && root.vpnState.defaultConnection.type === 'profile' &&
          root.vpnState.defaultConnection.profileId === root.editingId) &&
          !(root.vpnState && root.vpnState.storeOperationBusy)
        onClicked: root.vpnState.setDefaultConnection({
          type: 'profile', profileId: root.editingId
        })
      }
    }

    ProtonLocationsView {
      id: locationPicker
      visible: root.editing && root.pickerVisible
      width: parent.width
      vpnState: root.vpnState
      strings: root.strings
      foreground: root.foreground
      urgent: root.urgent
      dim: root.dim
      fontFamily: root.fontFamily
      selectionMode: true
      section: root.pickerSection
      feature: root.pickerFeature
      onLocationSelected: function(selection) {
        root.applyLocation(selection)
      }
    }

    ListView {
      visible: !root.editing
      width: parent.width
      height: Math.min(contentHeight, Style.space(410))
      implicitHeight: height
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      model: root.vpnState ? root.vpnState.profiles : []
      spacing: Style.space(2)

      delegate: Item {
        required property var modelData
        width: ListView.view.width
        height: row.implicitHeight

        PanelActionRow {
          id: row
          anchors.left: parent.left
          anchors.right: editButton.left
          rowForeground: root.foreground
          rowFontFamily: root.fontFamily
          iconSource: root.profileIconSource(modelData.iconName)
          iconTint: false
          title: String(modelData.name || '')
          subtitle: root.targetSummary(modelData)
          detailIconName: 'play'
          enabled: root.vpnState && !root.vpnState.tunnelOperationBusy
          busy: root.vpnState && root.vpnState.tunnelOperationBusy
          onActivated: root.vpnState.connectProfile(modelData)
        }

        ProtonIconButton {
          id: editButton
          anchors.right: parent.right
          anchors.verticalCenter: row.verticalCenter
          iconName: 'three_dots_horizontal'
          foreground: root.foreground
          fontFamily: root.fontFamily
          tooltipText: root.label('edit_profile')
          onClicked: root.editProfile(modelData)
        }
      }
    }

    Text {
      visible: !root.editing && root.vpnState && root.vpnState.profiles.length === 0
      width: parent.width
      text: root.label('no_profiles')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
    }

    Column {
      visible: root.deleteCandidateId.length > 0
      width: parent.width
      spacing: Style.space(6)

      Text {
        width: parent.width
        text: root.label('delete_profile_confirm')
        color: root.urgent
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }

      Button {
        width: parent.width
        text: root.label('delete')
        foreground: root.urgent
        fontFamily: root.fontFamily
        bordered: true
        enabled: root.vpnState && !root.vpnState.storeOperationBusy &&
          root.deleteRequestId.length === 0
        onClicked: {
          root.deleteRequestId = root.vpnState.deleteProfile(root.deleteCandidateId)
        }
      }
    }

    Button {
      visible: root.editing && root.editingId.length > 0 &&
        root.deleteCandidateId.length === 0
      width: parent.width
      text: root.label('delete_profile')
      foreground: root.urgent
      fontFamily: root.fontFamily
      bordered: false
      onClicked: root.deleteCandidateId = root.editingId
    }
  }
}
