import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

// Quattro button surface with Proton mobile icon content. It replaces Unicode
// glyph buttons whose metrics varied by font and display scale.
Item {
  id: root

  property string iconName: ''
  property url iconSource: ''
  property string label: ''
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  property bool bordered: false
  property bool active: false
  property bool selected: false
  property string tooltipText: label
  property real iconSize: Style.font.iconLarge
  property real horizontalPadding: Style.space(8)
  property real verticalPadding: Style.space(5)

  signal clicked()

  implicitWidth: Math.max(Style.space(32), content.implicitWidth + horizontalPadding * 2)
  implicitHeight: Math.max(Style.space(30), content.implicitHeight + verticalPadding * 2)
  opacity: enabled ? 1.0 : 0.45

  Button {
    anchors.fill: parent
    text: ''
    foreground: root.foreground
    fontFamily: root.fontFamily
    bordered: root.bordered
    active: root.active
    selected: root.selected
    tooltipText: root.tooltipText
    horizontalPadding: 0
    verticalPadding: 0
    enabled: root.enabled
    onClicked: root.clicked()
  }

  RowLayout {
    id: content
    anchors.centerIn: parent
    spacing: root.label === '' ? 0 : Style.space(4)

    ProtonMobileIcon {
      Layout.alignment: Qt.AlignVCenter
      iconName: root.iconName
      sourceOverride: root.iconSource
      iconColor: root.foreground
      iconSize: root.iconSize
    }

    Text {
      visible: root.label !== ''
      Layout.alignment: Qt.AlignVCenter
      text: root.label
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
    }
  }
}
