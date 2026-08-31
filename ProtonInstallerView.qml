import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import 'components' as ProtonComponents

Item {
  id: root

  property QtObject installerState: null
  property QtObject strings: null
  property color foreground: Color.foreground
  property color urgent: Color.urgent
  property color dim: Qt.darker(foreground, 1.55)
  property string fontFamily: Style.font.family

  readonly property bool busy: installerState ? installerState.running : false
  readonly property bool repairing: installerState && installerState.packageCurrent
  readonly property bool updating: installerState && installerState.packagePresent &&
    !installerState.packageCurrent
  readonly property bool failed: installerState && installerState.state === 'error'

  implicitHeight: content.implicitHeight

  function label(key) {
    return strings ? strings.text(key) : key
  }

  function focusInitial() {
    installButton.forceActiveFocus()
  }

  Column {
    id: content
    width: parent.width
    spacing: Style.space(12)

    ProtonComponents.ProtonPanelHero {
      width: parent.width
      title: root.repairing
        ? root.label('repair_backend_title')
        : root.updating ? root.label('update_backend_title')
          : root.label('install_backend_title')
      meta: root.repairing
        ? root.label('repair_backend_description')
        : root.updating ? root.label('update_backend_description')
          : root.label('install_backend_description')
      foreground: root.foreground
      fontFamily: root.fontFamily

      iconComponent: Component {
        ProtonComponents.ProtonVpnMark {
          iconSize: Style.font.display
          statusColor: root.failed ? root.urgent
            : root.busy ? root.foreground : Color.accent
          state: root.failed ? 'disconnected'
            : root.busy ? 'connecting' : 'information'
        }
      }
    }

    Column {
      width: parent.width
      spacing: Style.space(6)

      Text {
        width: parent.width
        text: !root.installerState ? root.label('installer_detecting')
          : root.failed
            ? root.strings.installerError(root.installerState.errorCode)
            : root.strings.installerStage(root.installerState.state)
        color: root.failed ? root.urgent : root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
      }

      Rectangle {
        visible: root.installerState &&
          (root.installerState.installRequested || root.busy)
        width: parent.width
        height: Math.max(2, Style.space(2))
        radius: height / 2
        color: Qt.rgba(root.foreground.r, root.foreground.g,
                       root.foreground.b, 0.14)

        Rectangle {
          width: parent.width * Math.max(0, Math.min(
            1, root.installerState ? root.installerState.progress / 100 : 0))
          height: parent.height
          radius: parent.radius
          color: root.failed ? root.urgent : Color.accent

          Behavior on width { NumberAnimation { duration: 180 } }
        }
      }
    }

    PanelSeparator { foreground: root.foreground }

    ProtonComponents.PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'shield_2_bolt'
      title: root.label('signed_release')
      subtitle: root.label('signed_release_description')
      enabled: false
    }

    Text {
      width: parent.width
      text: root.label('signing_fingerprint')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WrapAnywhere
      horizontalAlignment: Text.AlignHCenter
    }

    Button {
      id: installButton
      visible: !root.busy && (!root.installerState || !root.installerState.agentReady)
      width: parent.width
      text: root.failed ? root.label('try_again')
        : root.repairing ? root.label('repair_backend')
          : root.updating ? root.label('update_backend') : root.label('install_backend')
      foreground: root.foreground
      fontFamily: root.fontFamily
      fontSize: Style.font.body
      bordered: true
      active: true
      enabled: root.installerState && root.installerState.canStart
      horizontalPadding: Style.spacing.controlPaddingX
      verticalPadding: Style.spacing.controlPaddingY
      onClicked: root.installerState.start()
    }

    Text {
      visible: !root.busy && !root.repairing
      width: parent.width
      text: root.label('administrator_authorization_notice')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
    }

    Text {
      visible: root.failed && root.installerState &&
        root.installerState.diagnostic.length > 0
      width: parent.width
      text: root.installerState ? root.installerState.diagnostic : ''
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WrapAnywhere
      horizontalAlignment: Text.AlignHCenter
    }
  }
}
