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
  property string selectedLocale: vpnState ? vpnState.locale : 'es-MX'
  property bool startAtLogin: vpnState ? vpnState.startWithOmarchy : true
  property bool connectAtLogin: vpnState ? vpnState.autoConnect : false

  readonly property bool storeBusy: vpnState && vpnState.operationBusy &&
    vpnState.operationKind.indexOf('onboarding.') === 0
  readonly property bool canSave: vpnState && vpnState.agentAvailable &&
    vpnState.storeReady && !storeBusy

  implicitHeight: content.implicitHeight

  function label(key) {
    return strings ? strings.text(key) : key
  }

  function focusInitial() {
    continueButton.forceActiveFocus()
  }

  function finish() {
    if (!canSave) return
    vpnState.completeOnboarding(selectedLocale, startAtLogin, connectAtLogin)
  }

  Column {
    id: content
    width: parent.width
    spacing: Style.space(12)

    PanelHero {
      width: parent.width
      title: root.label('welcome_title')
      meta: root.label('welcome_description')
      foreground: root.foreground
      fontFamily: root.fontFamily

      iconComponent: Component {
        ProtonVpnMark {
          iconSize: Style.font.display
          statusColor: Color.accent
          state: root.storeBusy ? 'connecting' : 'information'
        }
      }
    }

    Column {
      width: parent.width
      spacing: Style.space(6)

      PanelSectionHeader {
        text: root.label('language').toUpperCase()
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      RowLayout {
        width: parent.width
        spacing: Style.space(8)

        ProtonIconButton {
          Layout.fillWidth: true
          iconName: 'language'
          label: 'Español'
          foreground: root.foreground
          fontFamily: root.fontFamily
          bordered: true
          active: root.selectedLocale === 'es-MX'
          enabled: !root.storeBusy
          onClicked: root.selectedLocale = 'es-MX'
        }

        ProtonIconButton {
          Layout.fillWidth: true
          iconName: 'language'
          label: 'English'
          foreground: root.foreground
          fontFamily: root.fontFamily
          bordered: true
          active: root.selectedLocale === 'en'
          enabled: !root.storeBusy
          onClicked: root.selectedLocale = 'en'
        }
      }
    }

    PanelSeparator { foreground: root.foreground }

    Column {
      width: parent.width
      spacing: Style.space(5)

      PanelActionRow {
        width: parent.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconName: 'arrows_rotate'
        title: root.label('start_with_omarchy')
        subtitle: root.label('start_with_omarchy_description')
        toggleVisible: true
        checked: root.startAtLogin
        onActivated: {
          root.startAtLogin = !root.startAtLogin
          if (!root.startAtLogin) root.connectAtLogin = false
        }
      }

      PanelActionRow {
        width: parent.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconName: 'bolt'
        title: root.label('auto_connect')
        subtitle: root.label('auto_connect_description')
        toggleVisible: true
        checked: root.connectAtLogin
        onActivated: {
          root.connectAtLogin = !root.connectAtLogin
          if (root.connectAtLogin) root.startAtLogin = true
        }
      }
    }

    Text {
      visible: root.vpnState && root.vpnState.legacyMigrationAvailable
      width: parent.width
      text: root.label('migration_found')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }

    Button {
      id: continueButton
      width: parent.width
      text: root.label('continue')
      foreground: root.foreground
      fontFamily: root.fontFamily
      fontSize: Style.font.body
      bordered: true
      active: true
      enabled: root.canSave
      horizontalPadding: Style.spacing.controlPaddingX
      verticalPadding: Style.spacing.controlPaddingY
      onClicked: root.finish()
    }

    Text {
      visible: text.length > 0
      width: parent.width
      text: {
        if (!root.vpnState) return root.label('agent_unavailable')
        if (root.storeBusy)
          return root.strings.operationStage(root.vpnState.operationStage)
        if (root.vpnState.lastError !== '')
          return root.strings.error(root.vpnState.lastErrorCode, root.vpnState.lastError)
        if (root.vpnState.agentConnecting) return root.label('agent_reconnecting')
        if (!root.vpnState.storeReady) return root.label('store_unavailable')
        return ''
      }
      color: root.storeBusy ? root.dim : root.urgent
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
    }
  }
}
