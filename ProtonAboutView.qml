import QtQuick
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

  Column {
    id: content
    width: parent.width
    spacing: Style.space(8)

    PanelHero {
      width: parent.width
      title: 'Proton VPN for Omarchy'
      meta: root.label('about_description')
      foreground: root.foreground
      fontFamily: root.fontFamily

      iconComponent: Component {
        ProtonVpnMark {
          iconSize: Style.font.display
          statusColor: Color.accent
          state: 'information'
        }
      }
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'brand_proton_vpn'
      title: root.label('version')
      subtitle: '0.8.0'
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'brand_linux'
      title: root.label('proton_linux_core')
      subtitle: root.vpnState && root.vpnState.backendCoreVersion
        ? root.vpnState.backendCoreVersion : root.label('not_reported')
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'file_lines'
      title: root.label('license')
      subtitle: 'GPL-3.0-or-later'
      detailIconName: 'arrow_out_square'
      onActivated: if (root.vpnState)
        root.vpnState.openTrustedUrl('https://www.gnu.org/licenses/gpl-3.0.html')
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'code'
      title: root.label('source_code')
      detailIconName: 'arrow_out_square'
      onActivated: if (root.vpnState)
        root.vpnState.openTrustedUrl('https://github.com/ProtonVPN')
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'shield'
      title: root.label('privacy_policy')
      detailIconName: 'arrow_out_square'
      onActivated: if (root.vpnState)
        root.vpnState.openTrustedUrl('https://protonvpn.com/privacy-policy')
    }

    Text {
      width: parent.width
      text: root.label('about_core_authority')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
    }
  }
}
