import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import 'components'

// Production Home surface shared by the live panel and sanitized showcases.
// State mutations remain on the agent object supplied by the caller.
Item {
  id: root

  property QtObject vpnState: null
  property QtObject strings: null
  property color foreground: Color.foreground
  property color urgent: Color.urgent
  property color dim: ProtonUi.secondaryText(foreground)
  property string fontFamily: Style.font.family
  property int cursorIndex: 0
  property bool cursorActive: false

  readonly property Item heroItem: connectButton
  readonly property Item detailsItem: detailsRow
  readonly property var activeProfile: root.resolveActiveProfile()

  signal cursorRequested(int index)
  signal detailsRequested()
  signal navigateRequested(string route)

  function label(key) { return strings ? strings.text(key) : key }

  implicitHeight: content.implicitHeight

  function resolveActiveProfile() {
    if (!vpnState || !vpnState.connected ||
        String(vpnState.activeProfileId || '') === '' ||
        !Array.isArray(vpnState.profiles)) return null
    for (var index = 0; index < vpnState.profiles.length; ++index) {
      var profile = vpnState.profiles[index]
      if (String(profile.id || '') === String(vpnState.activeProfileId))
        return profile
    }
    return null
  }

  function connectedCountry() {
    return vpnState
      ? (strings ? strings.countryName(vpnState.countryCode, vpnState.countryName)
          : String(vpnState.countryName || vpnState.countryCode || '')) : ''
  }

  function connectionTitle() {
    var country = connectedCountry()
    var profileName = activeProfile ? String(activeProfile.name || '') : ''
    return profileName && country ? profileName + ' — ' + country
      : profileName || country
  }

  Column {
    id: content
    width: parent.width
    spacing: Style.space(16)

    Column {
      width: parent.width
      spacing: Style.space(12)
      Text {
        width: parent.width
        text: !root.vpnState || !root.vpnState.agentAvailable ? root.label('agent_unavailable')
          : root.vpnState.connecting ? root.label('connecting')
          : root.vpnState.connected ? root.label('connection_protected') : root.label('not_connected')
        textFormat: Text.PlainText
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.heading
        font.weight: Font.DemiBold
        wrapMode: Text.Wrap
        Accessible.role: Accessible.Heading
      }
      RowLayout {
        width: parent.width
        spacing: Style.space(12)
        Item {
          Layout.preferredWidth: Style.space(45)
          Layout.preferredHeight: Style.space(36)
          ProtonConnectionFlag {
            visible: root.vpnState && root.vpnState.connected && root.activeProfile === null
            anchors.centerIn: parent
            width: Style.space(45); height: Style.space(36)
            exitCountryCode: root.vpnState ? root.vpnState.countryCode : ''
            entryCountryCode: root.vpnState && root.vpnState.secureCore ? root.vpnState.entryCountryCode : ''
          }
          ProtonProfileConnectionIcon {
            visible: root.vpnState && root.vpnState.connected && root.activeProfile !== null
            anchors.centerIn: parent
            width: Style.space(45); height: Style.space(36)
            countryCode: root.vpnState ? root.vpnState.countryCode : ''
            profileCategory: root.activeProfile ? String(root.activeProfile.iconName || 'Speed') : 'Speed'
            profileColor: root.activeProfile ? String(root.activeProfile.color || '#C857E7') : '#C857E7'
          }
          ProtonVpnMark {
            visible: !root.vpnState || !root.vpnState.connected
            anchors.centerIn: parent
            iconSize: Style.font.display
            statusColor: root.foreground
            state: root.vpnState && root.vpnState.connecting ? 'connecting' : 'disconnected'
          }
        }
        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.space(3)
          Text {
            Layout.fillWidth: true
            text: root.vpnState && root.vpnState.connected ? root.connectionTitle() : root.label('default_connection')
            textFormat: Text.PlainText
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
            font.weight: Font.DemiBold
            wrapMode: Text.Wrap
          }
          Text {
            Layout.fillWidth: true
            text: root.vpnState && root.vpnState.connected
              ? root.vpnState.serverName + ' · ' + root.strings.protocolName(root.vpnState.protocol)
              : root.label('connect_default_hint')
            textFormat: Text.PlainText
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.Wrap
            lineHeight: 1.4
          }
        }
      }
      ProtonButton {
        id: connectButton
        objectName: 'connection-action'
        width: parent.width
        label: root.vpnState && root.vpnState.tunnelOperationBusy
          ? root.strings.operationStage(root.vpnState.operationStage) : root.vpnState && root.vpnState.connected
          ? root.label('disconnect_proton_vpn') : root.label('quick_connect')
        foreground: root.foreground
        fontFamily: root.fontFamily
        primary: true
        hasCursor: root.cursorActive && root.cursorIndex === 0
        enabled: root.vpnState && root.vpnState.agentAvailable && root.vpnState.backendReady &&
          root.vpnState.signedIn && !root.vpnState.tunnelOperationBusy
        onClicked: root.vpnState.toggleConnection()
      }
    }

    ProtonNotice {
      width: parent.width
      visible: message !== ''
      error: root.vpnState && !root.vpnState.operationBusy && root.vpnState.lastError !== ''
      foreground: root.foreground
      fontFamily: root.fontFamily
      message: !root.vpnState ? '' : root.vpnState.operationBusy
        ? root.strings.operationStage(root.vpnState.operationStage)
        : root.vpnState.lastError ? root.strings.error(root.vpnState.lastErrorCode, root.vpnState.lastError) : ''
      hint: error && root.vpnState.lastErrorRetryable ? root.label('retryable_hint') : ''
    }
    PanelActionRow {
      visible: root.vpnState && root.vpnState.signedIn && root.vpnState.networkSecurityKnown &&
        root.vpnState.wifiConnected && root.vpnState.insecureWifi && !root.vpnState.connected && !root.vpnState.connecting
      width: parent.width
      rowForeground: root.foreground; rowFontFamily: root.fontFamily
      iconName: 'exclamation_triangle_filled'
      title: root.label('insecure_wifi')
      subtitle: root.label('insecure_wifi_description')
      detailIconName: 'play'
      busy: root.vpnState && root.vpnState.tunnelOperationBusy
      onActivated: if (root.vpnState) root.vpnState.quickConnect()
    }
    ProtonNotice {
      width: parent.width
      visible: root.vpnState && root.vpnState.connecting && root.vpnState.networkConflicts.length > 0
      error: true
      foreground: root.foreground
      message: root.vpnState ? root.strings.networkConflictWarning(root.vpnState.networkConflicts) : ''
    }
    ProtonTrafficCard {
      visible: root.vpnState && root.vpnState.connected
      width: parent.width
      vpnState: root.vpnState; strings: root.strings
      foreground: root.foreground; dim: root.dim; fontFamily: root.fontFamily
    }
    PanelActionRow {
      id: detailsRow
      width: parent.width
      rowForeground: root.foreground; rowFontFamily: root.fontFamily
      iconName: 'shield'
      title: root.label('connection_details')
      subtitle: root.label('connection_details_description')
      detailIconName: 'chevron_right'
      hasKeyboardCursor: root.cursorActive && root.cursorIndex === 1
      onActivated: root.detailsRequested()
    }
    ProtonRecentsView {
      width: parent.width
      compact: true
      vpnState: root.vpnState; strings: root.strings
      foreground: root.foreground; urgent: root.urgent; dim: root.dim; fontFamily: root.fontFamily
      onNavigateRequested: function(route) { root.navigateRequested(route) }
    }
  }
}
