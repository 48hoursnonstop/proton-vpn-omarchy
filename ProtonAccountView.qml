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

  readonly property string planLabel: !vpnState || vpnState.accountTier < 0
    ? label('plan_unknown')
    : vpnState.accountTier === 0 ? label('plan_free') : label('plan_paid')

  Column {
    id: content
    width: parent.width
    spacing: Style.space(8)

    Text {
      width: parent.width
      text: root.label('account')
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.heading
      font.weight: Font.DemiBold
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'user_circle'
      title: root.vpnState ? String(root.vpnState.accountName || '') : ''
      subtitle: root.planLabel
    }

    Text {
      width: parent.width
      text: root.label('shared_session_description')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'arrow_out_square'
      title: root.label('manage_account')
      subtitle: root.label('opens_secure_browser')
      detailIconName: 'arrow_out_square'
      onActivated: if (root.vpnState) root.vpnState.openAccountManagement()
    }

    PanelActionRow {
      visible: root.vpnState && root.vpnState.accountUpgradeSupported
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'bag_percent'
      title: root.vpnState && root.vpnState.accountTier > 0
        ? root.label('manage_subscription') : root.label('upgrade_plan')
      subtitle: root.label('authenticated_browser_handoff')
      detail: root.vpnState && root.vpnState.requestPending('account.upgrade_url') ? '…' : ''
      detailIconName: root.vpnState && root.vpnState.requestPending('account.upgrade_url')
        ? '' : 'arrow_out_square'
      enabled: root.vpnState && !root.vpnState.requestPending('account.upgrade_url')
      onActivated: root.vpnState.openUpgrade()
    }

    Text {
      width: parent.width
      text: root.label('account_web_boundary')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
    }
  }
}
