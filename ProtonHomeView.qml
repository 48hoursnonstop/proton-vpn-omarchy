import QtQuick
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
  property color dim: Qt.darker(foreground, 1.55)
  property string fontFamily: Style.font.family
  property int cursorIndex: 0
  property bool cursorActive: false

  readonly property Item heroItem: heroBlock
  readonly property Item detailsItem: detailsRow
  readonly property var activeProfile: root.resolveActiveProfile()

  signal cursorRequested(int index)
  signal detailsRequested()

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
      ? String(vpnState.countryName || vpnState.countryCode || '') : ''
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
    spacing: Style.space(10)

    Item {
      id: heroBlock
      width: parent.width
      implicitHeight: hero.implicitHeight
      readonly property bool ringVisible:
        root.cursorActive && root.cursorIndex === 0

      ProtonPanelHero {
        id: hero
        width: parent.width
        title: root.vpnState && root.vpnState.connected
          ? root.connectionTitle()
          : 'Proton VPN'
        meta: !root.vpnState || !root.vpnState.agentAvailable
          ? root.strings.text('agent_unavailable')
          : !root.vpnState.backendReady
            ? root.strings.text('backend_unavailable')
            : !root.vpnState.signedIn
              ? root.strings.text('sign_in_title')
              : root.vpnState.connecting
                ? root.strings.text('connecting_to') + ' ' +
                  (root.vpnState.countryName || root.vpnState.countryCode ||
                   root.strings.text('fastest_server').toLowerCase()) + '…'
                : root.vpnState.connected
                  ? root.vpnState.serverName
                  : root.strings.text('vpn_disconnected')
        foreground: root.foreground
        fontFamily: root.fontFamily
        iconOpacity: root.vpnState && root.vpnState.connected ? 1.0 : 0.58

        iconComponent: Component {
          Item {
            implicitWidth: root.vpnState && root.vpnState.connected
              ? Style.space(45) : Style.font.display
            implicitHeight: root.vpnState && root.vpnState.connected &&
              (root.activeProfile !== null ||
               (root.vpnState.secureCore && root.vpnState.entryCountryCode !== ''))
                ? Style.space(36) : Style.font.display

            ProtonConnectionFlag {
              visible: root.vpnState && root.vpnState.connected &&
                root.activeProfile === null
              width: Style.space(45)
              height: root.vpnState && root.vpnState.secureCore &&
                root.vpnState.entryCountryCode !== ''
                ? Style.space(36) : Style.space(30)
              anchors.centerIn: parent
              exitCountryCode: root.vpnState ? root.vpnState.countryCode : ''
              entryCountryCode: root.vpnState && root.vpnState.secureCore
                ? root.vpnState.entryCountryCode : ''
            }

            ProtonProfileConnectionIcon {
              visible: root.vpnState && root.vpnState.connected &&
                root.activeProfile !== null
              width: Style.space(45)
              height: Style.space(36)
              anchors.centerIn: parent
              countryCode: root.vpnState ? root.vpnState.countryCode : ''
              profileCategory: root.activeProfile
                ? String(root.activeProfile.iconName || 'Speed') : 'Speed'
              profileColor: root.activeProfile
                ? String(root.activeProfile.color || '#C857E7') : '#C857E7'
            }

            ProtonVpnMark {
              visible: !root.vpnState || !root.vpnState.connected
              anchors.centerIn: parent
              iconSize: Style.font.display
              statusColor: root.vpnState && root.vpnState.connecting
                ? root.foreground : root.dim
              state: !root.vpnState || root.vpnState.status === 'unknown'
                ? 'information'
                : root.vpnState.connecting ? 'connecting' : 'disconnected'
            }
          }
        }

        trailingControl: Component {
          ToggleSwitch {
            id: connectionSwitch
            checked: root.vpnState ? root.vpnState.connected : false
            busy: root.vpnState ? root.vpnState.tunnelOperationBusy : false
            hasCursor: heroBlock.ringVisible
            foreground: hero.foreground
            onHovered: function(on) {
              if (on) root.cursorRequested(0)
            }
            onToggled: if (root.vpnState) root.vpnState.toggleConnection()

            PanelToolTip {
              visible: connectionSwitch.containsMouse
              text: root.vpnState &&
                (root.vpnState.connected || root.vpnState.connecting)
                  ? root.strings.text('disconnect_proton_vpn')
                  : root.strings.text('quick_connect')
              fontFamily: hero.fontFamily
            }
          }
        }
      }
    }

    Text {
      visible: root.vpnState &&
        (root.vpnState.operationBusy || root.vpnState.lastError !== '')
      width: parent.width
      text: !root.vpnState
        ? ''
        : root.vpnState.operationBusy
          ? root.strings.operationStage(root.vpnState.operationStage)
          : root.strings.error(
              root.vpnState.lastErrorCode,
              root.vpnState.lastError)
      color: root.vpnState && root.vpnState.operationBusy
        ? root.dim : root.urgent
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
    }

    Text {
      visible: root.vpnState && root.vpnState.connected
      width: parent.width
      text: root.vpnState
        ? root.strings.protocolName(root.vpnState.protocol) +
          '  ·  ' + root.vpnState.countryCode : ''
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      horizontalAlignment: Text.AlignHCenter
    }

    PanelActionRow {
      visible: root.vpnState && root.vpnState.signedIn &&
        root.vpnState.networkSecurityKnown && root.vpnState.wifiConnected &&
        root.vpnState.insecureWifi && !root.vpnState.connected &&
        !root.vpnState.connecting
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'exclamation_triangle_filled'
      title: root.strings.text('insecure_wifi')
      subtitle: root.strings.text('insecure_wifi_description')
      detailIconName: 'play'
      enabled: root.vpnState && !root.vpnState.tunnelOperationBusy
      busy: root.vpnState && root.vpnState.tunnelOperationBusy
      onActivated: if (root.vpnState) root.vpnState.quickConnect()
    }

    Text {
      visible: root.vpnState && root.vpnState.connecting &&
        root.vpnState.networkConflicts.length > 0
      width: parent.width
      text: root.strings.networkConflictWarning(root.vpnState.networkConflicts)
      color: root.urgent
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
    }

    Text {
      visible: root.vpnState && !root.vpnState.operationBusy &&
        root.vpnState.lastError !== '' &&
        root.vpnState.lastErrorRetryable
      width: parent.width
      text: root.strings.text('retryable_hint')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      horizontalAlignment: Text.AlignHCenter
    }

    ProtonTrafficCard {
      visible: root.vpnState && root.vpnState.connected
      width: parent.width
      vpnState: root.vpnState
      strings: root.strings
      foreground: root.foreground
      dim: root.dim
      fontFamily: root.fontFamily
    }

    PanelActionRow {
      id: detailsRow
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'arrow_down_arrow_up'
      title: root.strings.text('connection_details')
      subtitle: root.strings.text('connection_details_description')
      detailIconName: 'chevron_right'
      hasKeyboardCursor: root.cursorActive && root.cursorIndex === 1
      onHovered: root.cursorRequested(1)
      onActivated: root.detailsRequested()
    }

    PanelSeparator { foreground: root.foreground }

    ProtonRecentsView {
      width: parent.width
      vpnState: root.vpnState
      strings: root.strings
      foreground: root.foreground
      urgent: root.urgent
      dim: root.dim
      fontFamily: root.fontFamily
    }

    Text {
      width: parent.width
      topPadding: Style.space(4)
      text: root.strings.text('official_core_note')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
    }
  }
}
