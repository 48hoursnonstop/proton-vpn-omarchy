import QtQuick
import qs.Commons
import qs.Ui as Ui

// Keep the native input API and focus/selection behavior. Its label remains
// visible while typing, including password and verification-code fields.
Ui.TextField {
  id: root
  property string fieldLabel: placeholderText
  property bool compact: false
  implicitHeight: Math.max(compact ? ProtonUi.controlHeight : 0,
    contentHeight + topPadding + bottomPadding)
  Accessible.name: fieldLabel
  topPadding: compact ? Style.space(10) : caption.implicitHeight + Style.space(12) + Border.top(_borderSpec)
  bottomPadding: compact ? Style.space(10) : Math.max(Style.space(8), verticalPadding) + Border.bottom(_borderSpec)
  leftPadding: compact ? Style.space(34) : horizontalPadding + Border.left(_borderSpec)
  placeholderTextColor: !compact && fieldLabel === placeholderText ? 'transparent' : ProtonUi.secondaryText(foreground)
  background: Ui.BorderSurface {
    color: root.compact ? Style.normalFillFor(root.foreground, root.accent)
      : Style.controlFill(root._focused, root._hot, root.foreground, root.accent)
    borderSpec: root.compact ? Border.none() : root._borderSpec
    radius: Style.cornerRadius
    Rectangle {
      visible: root.compact
      anchors.bottom: parent.bottom
      width: parent.width
      height: root.activeFocus ? Math.max(2, Style.space(2)) : 1
      color: root.activeFocus ? root.foreground : ProtonUi.secondaryText(root.foreground)
      opacity: root.activeFocus ? 1 : 0.4
    }
  }
  ProtonMobileIcon {
    visible: root.compact
    iconName: 'magnifier'
    iconColor: ProtonUi.secondaryText(root.foreground)
    iconSize: Style.font.icon
    x: Style.space(10)
    anchors.verticalCenter: parent.verticalCenter
  }
  Text {
    id: caption
    visible: !root.compact
    x: root.leftPadding
    y: Style.space(6) + Border.top(root._borderSpec)
    width: Math.max(0, root.width - root.leftPadding - root.rightPadding)
    text: root.fieldLabel
    textFormat: Text.PlainText
    color: ProtonUi.secondaryText(root.foreground)
    font.family: root.font.family
    font.pixelSize: Style.font.bodySmall
    wrapMode: Text.Wrap
    Accessible.ignored: true
  }
}
