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

  implicitHeight: content.implicitHeight

  function label(key) { return strings ? strings.text(key) : key }

  function markFeedbackViewed() {
    if (visible && vpnState && vpnState.connected &&
        vpnState.connectionFeedbackAvailable && !vpnState.connectionFeedbackViewed)
      vpnState.setConnectionFeedback('viewed')
  }

  onVisibleChanged: Qt.callLater(root.markFeedbackViewed)
  Component.onCompleted: Qt.callLater(root.markFeedbackViewed)

  Connections {
    target: root.vpnState
    function onConnectionFeedbackAvailableChanged() {
      Qt.callLater(root.markFeedbackViewed)
    }
    function onConnectedChanged() { Qt.callLater(root.markFeedbackViewed) }
  }

  function bytes(value) {
    var amount = Number(value || 0)
    if (amount >= 1024 * 1024 * 1024)
      return (amount / (1024 * 1024 * 1024)).toFixed(1) + ' GiB'
    if (amount >= 1024 * 1024)
      return (amount / (1024 * 1024)).toFixed(1) + ' MiB'
    if (amount >= 1024)
      return (amount / 1024).toFixed(1) + ' KiB'
    return Math.round(amount) + ' B'
  }

  Timer {
    interval: 1000
    repeat: true
    triggeredOnStart: true
    running: root.visible && root.vpnState && root.vpnState.connected
    onTriggered: root.vpnState.refreshTraffic()
  }

  Timer {
    interval: 20000
    repeat: true
    triggeredOnStart: true
    running: root.visible && root.vpnState && root.vpnState.connected &&
      root.vpnState.netShieldLevel > 0
    onTriggered: root.vpnState.refreshNetShieldStatistics()
  }

  Column {
    id: content
    width: parent.width
    spacing: Style.space(8)

    Text {
      width: parent.width
      text: root.label('connection_details')
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.heading
      font.weight: Font.DemiBold
    }

    PanelHero {
      width: parent.width
      title: root.vpnState && root.vpnState.connected
        ? String(root.vpnState.serverName || root.vpnState.countryName || root.vpnState.countryCode)
        : root.label('not_connected')
      meta: root.vpnState && root.vpnState.connected
        ? String(root.vpnState.city || root.vpnState.countryName || '')
        : root.label('public_connection_details')
      foreground: root.foreground
      fontFamily: root.fontFamily

      iconComponent: Component {
        ProtonVpnMark {
          iconSize: Style.font.display
          statusColor: root.vpnState && root.vpnState.connected ? Color.accent : root.dim
          state: !root.vpnState || root.vpnState.status === 'unknown'
            ? 'information'
            : root.vpnState.connected
              ? 'connected'
              : root.vpnState.connecting
                ? 'connecting' : 'disconnected'
        }
      }
    }

    PanelSectionHeader {
      text: root.label('network').toUpperCase()
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'globe'
      title: root.label('ip_address')
      subtitle: root.vpnState && root.vpnState.connected
        ? root.vpnState.serverIp
        : root.vpnState ? root.vpnState.deviceIpAddress : ''
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'servers'
      title: root.label('protocol')
      subtitle: root.vpnState && root.vpnState.connected
        ? root.vpnState.protocol : '—'
    }

    PanelActionRow {
      visible: root.vpnState && !root.vpnState.connected && root.vpnState.deviceLocationKnown
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'map_pin'
      title: root.label('provider')
      subtitle: root.vpnState ? root.vpnState.deviceIsp : ''
    }

    Column {
      visible: root.vpnState && root.vpnState.connected
      width: parent.width
      spacing: Style.space(5)

      PanelSeparator { foreground: root.foreground }

      PanelSectionHeader {
        text: root.label('traffic').toUpperCase()
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      PanelActionRow {
        width: parent.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconName: 'arrow_down'
        title: root.label('download')
        subtitle: root.bytes(root.vpnState.downloadBytes) + ' · ' +
          root.bytes(root.vpnState.downloadBytesPerSecond) + '/s'
      }

      PanelActionRow {
        width: parent.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconName: 'arrow_up'
        title: root.label('upload')
        subtitle: root.bytes(root.vpnState.uploadBytes) + ' · ' +
          root.bytes(root.vpnState.uploadBytesPerSecond) + '/s'
      }

      PanelActionRow {
        visible: root.vpnState && root.vpnState.netShieldLevel > 0
        width: parent.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconName: 'shield_2_bolt'
        title: root.label('netshield_statistics')
        subtitle: root.vpnState && root.vpnState.netShieldStatisticsKnown
          ? root.label('malware') + ' ' + root.vpnState.netShieldMalwareBlocked +
            ' · ' + root.label('ads') + ' ' + root.vpnState.netShieldAdsBlocked +
            ' · ' + root.label('trackers') + ' ' + root.vpnState.netShieldTrackersBlocked
          : '…'
      }
    }

    RowLayout {
      visible: root.vpnState && root.vpnState.connected &&
        root.vpnState.connectionFeedbackAvailable &&
        !root.vpnState.connectionFeedbackSent
      width: parent.width
      spacing: Style.space(6)

      Text {
        Layout.fillWidth: true
        text: root.label('connection_feedback_question')
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }

      Button {
        text: ''
        foreground: root.foreground
        fontFamily: root.fontFamily
        bordered: false
        enabled: root.vpnState && !root.vpnState.requestPending('connection.feedback')
        onClicked: root.vpnState.setConnectionFeedback('negative')
      }

      Button {
        text: ''
        foreground: root.foreground
        fontFamily: root.fontFamily
        bordered: false
        enabled: root.vpnState && !root.vpnState.requestPending('connection.feedback')
        onClicked: root.vpnState.setConnectionFeedback('positive')
      }
    }
  }
}
