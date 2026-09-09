import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

BorderSurface {
  id: root
  property string message: ''
  property string hint: ''
  property bool error: false
  property color foreground: Color.popups.text
  property string fontFamily: Style.font.family
  width: parent ? parent.width : implicitWidth
  implicitHeight: contents.implicitHeight + Style.space(20)
  color: Style.normalFillFor(foreground, Color.accent)
  radius: Style.cornerRadius
  Accessible.role: Accessible.StaticText
  Accessible.name: message + (hint ? '. ' + hint : '')
  RowLayout {
    id: contents
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Style.space(10)
    spacing: Style.space(8)
    ProtonMobileIcon {
      Layout.alignment: Qt.AlignTop
      iconName: root.error ? 'exclamation_triangle_filled' : 'info_circle'
      iconColor: root.error ? Color.urgent : root.foreground
      iconSize: Style.font.icon
    }
    Column {
      Layout.fillWidth: true
      spacing: Style.space(4)
      Text {
        width: parent.width
        text: root.message
        textFormat: Text.PlainText
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        wrapMode: Text.Wrap
        lineHeight: 1.4
      }
      Text {
        width: parent.width
        visible: text !== ''
        text: root.hint
        textFormat: Text.PlainText
        color: ProtonUi.secondaryText(root.foreground)
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.Wrap
        lineHeight: 1.4
      }
    }
  }
}
