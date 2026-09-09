import QtQuick
import QtQuick.Layouts
import qs.Commons

ProtonButtonBase {
  id: root
  property string iconName: ''
  property url iconSource: ''
  property string label: ''
  text: ''
  focusable: true
  tooltipText: label
  horizontalPadding: Style.space(8)
  verticalPadding: Style.space(6)
  implicitWidth: Math.max(ProtonUi.controlHeight, content.implicitWidth + horizontalPadding * 2)
  implicitHeight: Math.max(ProtonUi.controlHeight, content.implicitHeight + verticalPadding * 2)
  opacity: enabled ? 1 : 0.5
  Accessible.role: Accessible.Button
  Accessible.name: label || tooltipText
  Accessible.focusable: enabled
  Accessible.onPressAction: if (enabled) clicked()

  RowLayout {
    id: content
    anchors.centerIn: parent
    width: Math.max(0, parent.width - root.horizontalPadding * 2)
    spacing: root.label === '' ? 0 : Style.space(6)
    ProtonMobileIcon {
      Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
      iconName: root.iconName
      sourceOverride: root.iconSource
      iconColor: root.foreground
      iconSize: root.iconSize
      Accessible.ignored: true
    }
    Text {
      visible: root.label !== ''
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      text: root.label
      textFormat: Text.PlainText
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      wrapMode: Text.Wrap
      lineHeight: 1.15
      Accessible.ignored: true
    }
  }
}
