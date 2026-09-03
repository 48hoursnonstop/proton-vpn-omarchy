import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui

Item {
  id: root

  property QtObject uninstallerState: null
  property QtObject strings: null
  property color foreground: Color.foreground
  property color urgent: Color.urgent
  property string fontFamily: Style.font.family
  property bool confirming: false

  implicitHeight: content.implicitHeight

  function label(key) { return strings ? strings.text(key) : key }
  function reset() { confirming = false }

  Column {
    id: content
    width: parent.width
    spacing: Style.space(8)

    PanelSeparator { foreground: root.foreground }

    Button {
      width: parent.width
      text: root.uninstallerState && root.uninstallerState.running
        ? root.label('uninstalling')
        : root.confirming
          ? root.label('confirm_clean_uninstall')
          : root.label('clean_uninstall')
      foreground: root.urgent
      fontFamily: root.fontFamily
      bordered: root.confirming
      enabled: root.uninstallerState && root.uninstallerState.canStart
      onClicked: {
        if (root.confirming) root.uninstallerState.start()
        else root.confirming = true
      }
    }

    Text {
      visible: root.confirming ||
        (root.uninstallerState && root.uninstallerState.running)
      width: parent.width
      text: root.label('clean_uninstall_warning') + '\n' +
        root.label('clean_uninstall_audit_notice')
      textFormat: Text.PlainText
      color: root.urgent
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
    }

    Text {
      visible: root.uninstallerState && root.uninstallerState.state === 'error'
      width: parent.width
      text: root.label('clean_uninstall_failed') +
        (root.uninstallerState && root.uninstallerState.diagnostic.length > 0
          ? '\n' + root.uninstallerState.diagnostic : '')
      textFormat: Text.PlainText
      color: root.urgent
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
    }

    Button {
      visible: root.confirming &&
        !(root.uninstallerState && root.uninstallerState.running)
      width: parent.width
      text: root.label('cancel')
      foreground: root.foreground
      fontFamily: root.fontFamily
      bordered: false
      onClicked: root.confirming = false
    }
  }
}
