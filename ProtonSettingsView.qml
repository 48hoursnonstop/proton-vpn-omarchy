import QtQuick
import QtQuick.Controls
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
  property bool confirmingLogout: false
  property bool editingDns: false
  property string openPicker: ''
  property string dnsRequestId: ''
  readonly property bool configurationBusy: vpnState &&
    vpnState.tunnelConfigurationBusy
  readonly property bool storeBusy: vpnState && vpnState.storeOperationBusy

  signal navigateRequested(string route)

  implicitHeight: content.implicitHeight

  function label(key) { return strings ? strings.text(key) : key }

  function togglePicker(name) {
    openPicker = openPicker === name ? '' : name
  }

  function protocolOptions() {
    var output = []
    var values = vpnState && vpnState.availableProtocols
      ? vpnState.availableProtocols : []
    for (var index = 0; index < values.length; ++index) {
      var value = String(values[index])
      output.push({
        value: value,
        label: vpnState.protocolName(value),
        iconName: value.indexOf('openvpn') === 0 ? 'globe'
          : value === 'protun-tls' || value === 'wireguard-tls' ? 'shield'
          : value === 'smart' || value === 'protun-smart' ? 'sliders'
          : 'brand_wireguard'
      })
    }
    return output
  }

  function killSwitchOptions() {
    return ['off', 'standard', 'advanced'].map(function(value) {
      return { value: value, label: label('kill_switch_' + value), iconName: 'kill_switch' }
    })
  }

  function netShieldOptions() {
    return [0, 1, 2].map(function(value) {
      return { value: value, label: label('netshield_level_' + value), iconName: 'shield_2_bolt' }
    })
  }

  function languageOptions() {
    return [
      { value: 'es-MX', label: 'Español', iconName: 'language' },
      { value: 'en', label: 'English', iconName: 'language' }
    ]
  }

  function saveDns() {
    if (!vpnState) return
    var output = []
    var values = dnsField.text.split(',')
    for (var index = 0; index < values.length; ++index) {
      var value = values[index].trim()
      if (value.length > 0) output.push(value)
    }
    dnsRequestId = vpnState.setCustomDns(output.length > 0, output)
  }

  Connections {
    target: root.vpnState

    function onRequestFinished(requestId, method, ok, errorCode) {
      if (requestId !== root.dnsRequestId) return
      root.dnsRequestId = ''
      if (ok) root.editingDns = false
    }
  }

  Column {
    id: content
    width: parent.width
    spacing: Style.space(8)

    Text {
      width: parent.width
      text: root.label('settings')
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.heading
      font.weight: Font.DemiBold
    }

    PanelSectionHeader {
      text: root.label('connection').toUpperCase()
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'servers'
      title: root.label('protocol')
      subtitle: root.vpnState
        ? root.vpnState.protocolName(root.vpnState.selectedProtocol) : ''
      detailIconName: root.vpnState && root.vpnState.protocolWritable
        ? 'chevron_right' : 'minus_circle_filled'
      enabled: root.vpnState && root.vpnState.protocolWritable
      busy: root.configurationBusy
      onActivated: root.togglePicker('protocol')
    }

    ProtonOptionPicker {
      visible: root.openPicker === 'protocol'
      width: parent.width
      options: root.protocolOptions()
      currentValue: root.vpnState ? root.vpnState.selectedProtocol : ''
      foreground: root.foreground
      fontFamily: root.fontFamily
      busy: root.configurationBusy
      onSelected: function(value) {
        root.openPicker = ''
        if (root.vpnState && value !== root.vpnState.selectedProtocol)
          root.vpnState.setProtocol(value)
      }
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'kill_switch'
      title: 'Kill Switch'
      subtitle: root.vpnState ? root.label('kill_switch_' + root.vpnState.killSwitchMode) : ''
      detailIconName: root.vpnState && root.vpnState.killSwitchWritable
        ? 'chevron_right' : 'minus_circle_filled'
      enabled: root.vpnState && root.vpnState.killSwitchWritable
      busy: root.configurationBusy
      onActivated: root.togglePicker('kill-switch')
    }

    ProtonOptionPicker {
      visible: root.openPicker === 'kill-switch'
      width: parent.width
      options: root.killSwitchOptions()
      currentValue: root.vpnState ? root.vpnState.killSwitchMode : 'off'
      foreground: root.foreground
      fontFamily: root.fontFamily
      busy: root.configurationBusy
      onSelected: function(value) {
        root.openPicker = ''
        if (root.vpnState && value !== root.vpnState.killSwitchMode)
          root.vpnState.setFeature('kill_switch', value)
      }
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'shield_2_bolt'
      title: 'NetShield'
      subtitle: root.vpnState ? root.label('netshield_level_' + root.vpnState.netShieldLevel) : ''
      detailIconName: root.vpnState && root.vpnState.netShieldWritable
        ? 'chevron_right' : 'minus_circle_filled'
      enabled: root.vpnState && root.vpnState.netShieldWritable
      busy: root.configurationBusy
      onActivated: root.togglePicker('netshield')
    }

    ProtonOptionPicker {
      visible: root.openPicker === 'netshield'
      width: parent.width
      options: root.netShieldOptions()
      currentValue: root.vpnState ? root.vpnState.netShieldLevel : 0
      foreground: root.foreground
      fontFamily: root.fontFamily
      busy: root.configurationBusy
      onSelected: function(value) {
        root.openPicker = ''
        if (root.vpnState && value !== root.vpnState.netShieldLevel)
          root.vpnState.setFeature('netshield', value)
      }
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'rocket'
      title: 'VPN Accelerator'
      subtitle: root.vpnState && root.vpnState.vpnAccelerator
        ? root.label('enabled') : root.label('disabled')
      toggleVisible: true
      checked: root.vpnState ? root.vpnState.vpnAccelerator : false
      enabled: root.vpnState && root.vpnState.vpnAcceleratorWritable
      busy: root.configurationBusy
      onActivated: root.vpnState.setFeature(
        'vpn_accelerator', !root.vpnState.vpnAccelerator
      )
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'arrow_right_arrow_left'
      title: root.label('port_forwarding')
      subtitle: root.vpnState && root.vpnState.activePort > 0
        ? root.label('active_port') + ': ' + root.vpnState.activePort
        : root.vpnState && root.vpnState.portForwarding
          ? root.label('enabled') : root.label('disabled')
      toggleVisible: true
      checked: root.vpnState ? root.vpnState.portForwarding : false
      enabled: root.vpnState && root.vpnState.portForwardingWritable
      busy: root.configurationBusy
      onActivated: root.vpnState.setFeature(
        'port_forwarding', !root.vpnState.portForwarding
      )
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'globe'
      title: root.label('moderate_nat')
      subtitle: root.vpnState && root.vpnState.moderateNat
        ? root.label('enabled') : root.label('disabled')
      toggleVisible: true
      checked: root.vpnState ? root.vpnState.moderateNat : false
      enabled: root.vpnState && root.vpnState.moderateNatWritable
      busy: root.configurationBusy
      onActivated: root.vpnState.setFeature(
        'moderate_nat', !root.vpnState.moderateNat
      )
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'globe'
      title: root.label('custom_dns')
      subtitle: root.vpnState && root.vpnState.customDnsServers.length > 0
        ? root.vpnState.customDnsServers.join(', ') : root.label('disabled')
      detailIconName: root.vpnState && root.vpnState.customDnsWritable
        ? 'chevron_right' : 'minus_circle_filled'
      enabled: root.vpnState && root.vpnState.customDnsWritable
      busy: root.configurationBusy
      onActivated: {
        root.editingDns = true
        dnsField.text = root.vpnState.customDnsServers.join(', ')
        Qt.callLater(dnsField.forceActiveFocus)
      }
    }

    Column {
      visible: root.editingDns
      width: parent.width
      spacing: Style.space(6)

      TextField {
        id: dnsField
        width: parent.width
        placeholderText: '1.1.1.1, 9.9.9.9'
        foreground: root.foreground
        accent: Color.accent
        font.family: root.fontFamily
        onAccepted: root.saveDns()
      }

      Button {
        width: parent.width
        text: root.label('apply')
        foreground: root.foreground
        fontFamily: root.fontFamily
        bordered: true
        active: true
        enabled: root.dnsRequestId.length === 0 &&
          !root.configurationBusy
        onClicked: root.saveDns()
      }
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'arrows_rotate'
      title: root.label('alternative_routing')
      subtitle: root.label('alternative_routing_description')
      toggleVisible: true
      checked: root.vpnState ? root.vpnState.alternativeRouting : true
      enabled: root.vpnState && root.vpnState.alternativeRoutingWritable
      busy: root.configurationBusy
      onActivated: root.vpnState.setFeature(
        'alternative_routing', !root.vpnState.alternativeRouting
      )
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'globe'
      title: root.label('ipv6')
      subtitle: root.label('ipv6_description')
      toggleVisible: true
      checked: root.vpnState ? root.vpnState.ipv6 : true
      enabled: root.vpnState && root.vpnState.ipv6Writable
      busy: root.configurationBusy
      onActivated: root.vpnState.setFeature('ipv6', !root.vpnState.ipv6)
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'shield'
      title: root.label('ipv6_leak_protection')
      subtitle: root.label('ipv6_leak_protection_description')
      toggleVisible: true
      checked: root.vpnState ? root.vpnState.ipv6LeakProtection : true
      enabled: root.vpnState && root.vpnState.ipv6LeakProtectionWritable
      busy: root.configurationBusy
      onActivated: root.vpnState.setFeature(
        'ipv6_leak_protection', !root.vpnState.ipv6LeakProtection
      )
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'squares_in_square'
      title: root.label('local_area_network_access')
      subtitle: root.label('local_area_network_access_description')
      toggleVisible: true
      checked: root.vpnState ? root.vpnState.allowLanConnections : false
      enabled: root.vpnState && root.vpnState.allowLanConnectionsWritable
      busy: root.configurationBusy
      onActivated: root.vpnState.setFeature(
        'allow_lan_connections', !root.vpnState.allowLanConnections
      )
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'map_pin'
      title: root.label('local_dns_access')
      subtitle: root.label('local_dns_access_description')
      toggleVisible: true
      checked: root.vpnState ? root.vpnState.allowLocalDns : false
      enabled: root.vpnState && root.vpnState.allowLocalDnsWritable
      busy: root.configurationBusy
      onActivated: root.vpnState.setFeature(
        'allow_local_dns', !root.vpnState.allowLocalDns
      )
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'squares_in_square'
      title: root.label('split_tunneling')
      subtitle: root.vpnState && root.vpnState.splitTunneling
        ? root.label('enabled') : root.label('disabled')
      detailIconName: 'chevron_right'
      enabled: root.vpnState && root.vpnState.splitTunnelingWritable
      onActivated: root.navigateRequested('split-tunneling')
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'map_pin'
      title: root.label('excluded_locations')
      subtitle: root.label('excluded_locations_short_description')
      detailIconName: 'chevron_right'
      enabled: root.vpnState && root.vpnState.accountTier > 0
      onActivated: root.navigateRequested('excluded-locations')
    }

    PanelSeparator { foreground: root.foreground }

    PanelSectionHeader {
      text: root.label('application').toUpperCase()
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'user_circle'
      title: root.label('account')
      subtitle: root.vpnState ? String(root.vpnState.accountName || '') : ''
      detailIconName: 'chevron_right'
      onActivated: root.navigateRequested('account')
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'arrows_rotate'
      title: root.label('start_with_omarchy')
      toggleVisible: true
      checked: root.vpnState ? root.vpnState.startWithOmarchy : true
      busy: root.storeBusy
      onActivated: root.vpnState.setPreferences(
        root.vpnState.locale,
        !root.vpnState.startWithOmarchy,
        root.vpnState.autoConnect && !root.vpnState.startWithOmarchy
      )
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'bolt'
      title: root.label('auto_connect')
      toggleVisible: true
      checked: root.vpnState ? root.vpnState.autoConnect : false
      busy: root.storeBusy
      onActivated: root.vpnState.setPreferences(
        root.vpnState.locale,
        root.vpnState.startWithOmarchy || !root.vpnState.autoConnect,
        !root.vpnState.autoConnect
      )
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'bookmark'
      title: root.label('default_connection')
      subtitle: root.vpnState
        ? root.label('default_' + String(root.vpnState.defaultConnection.type || 'fastest'))
        : ''
      detailIconName: 'chevron_right'
      busy: root.storeBusy
      enabled: !root.storeBusy
      onActivated: root.navigateRequested('default-connection')
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'language'
      title: root.label('language')
      subtitle: root.vpnState && root.vpnState.locale === 'es-MX' ? 'Español' : 'English'
      detailIconName: 'chevron_right'
      busy: root.storeBusy
      onActivated: root.togglePicker('language')
    }

    ProtonOptionPicker {
      visible: root.openPicker === 'language'
      width: parent.width
      options: root.languageOptions()
      currentValue: root.vpnState ? root.vpnState.locale : 'es-MX'
      foreground: root.foreground
      fontFamily: root.fontFamily
      busy: root.storeBusy
      onSelected: function(value) {
        root.openPicker = ''
        if (root.vpnState && value !== root.vpnState.locale)
          root.vpnState.setPreferences(
            value,
            root.vpnState.startWithOmarchy,
            root.vpnState.autoConnect
          )
      }
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'bell'
      title: root.label('notifications')
      subtitle: root.label('notifications_description')
      toggleVisible: true
      checked: root.vpnState ? root.vpnState.notificationsEnabled : true
      busy: root.storeBusy
      onActivated: root.vpnState.setNotifications(!root.vpnState.notificationsEnabled)
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'bell'
      title: root.label('port_forwarding_notifications')
      subtitle: root.label('port_forwarding_notifications_description')
      toggleVisible: true
      checked: root.vpnState ? root.vpnState.portForwardingNotificationsEnabled : true
      enabled: root.vpnState && root.vpnState.notificationsEnabled
      busy: root.storeBusy
      onActivated: root.vpnState.setPortForwardingNotifications(
        !root.vpnState.portForwardingNotificationsEnabled
      )
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'bug'
      title: root.label('anonymous_crash_reports')
      toggleVisible: true
      checked: root.vpnState ? root.vpnState.anonymousCrashReports : false
      enabled: root.vpnState && root.vpnState.anonymousCrashReportsWritable
      busy: root.configurationBusy
      onActivated: root.vpnState.setFeature(
        'anonymous_crash_reports', !root.vpnState.anonymousCrashReports
      )
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'users'
      title: root.label('anonymous_usage_statistics')
      subtitle: root.label('anonymous_usage_statistics_description')
      toggleVisible: true
      checked: root.vpnState ? root.vpnState.anonymousUsageStatistics : false
      enabled: root.vpnState && root.vpnState.anonymousUsageStatisticsWritable
      busy: root.configurationBusy
      onActivated: root.vpnState.setFeature(
        'anonymous_usage_statistics', !root.vpnState.anonymousUsageStatistics
      )
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'life_ring'
      title: root.label('support')
      detailIconName: 'chevron_right'
      onActivated: root.navigateRequested('support')
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'code'
      title: root.label('diagnostics')
      subtitle: root.label('diagnostics_short_description')
      detailIconName: 'chevron_right'
      onActivated: root.navigateRequested('diagnostics')
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'info_circle'
      title: root.label('about')
      detailIconName: 'chevron_right'
      onActivated: root.navigateRequested('about')
    }

    PanelSeparator { foreground: root.foreground }

    Text {
      width: parent.width
      text: root.vpnState ? String(root.vpnState.accountName || '') : ''
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideMiddle
    }

    Button {
      width: parent.width
      text: root.confirmingLogout ? root.label('confirm_sign_out') : root.label('sign_out')
      foreground: root.urgent
      fontFamily: root.fontFamily
      bordered: root.confirmingLogout
      enabled: !(root.vpnState && root.vpnState.authBusy)
      onClicked: {
        if (root.confirmingLogout) root.vpnState.logout()
        else root.confirmingLogout = true
      }
    }

    Text {
      visible: root.confirmingLogout
      width: parent.width
      text: root.label('sign_out_shared_warning')
      color: root.urgent
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
    }

    Button {
      visible: root.confirmingLogout
      width: parent.width
      text: root.label('cancel')
      foreground: root.foreground
      fontFamily: root.fontFamily
      bordered: false
      onClicked: root.confirmingLogout = false
    }
  }
}
