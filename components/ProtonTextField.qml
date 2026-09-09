import QtQuick
import qs.Commons
import qs.Ui as Ui

// Keep the native input API and focus/selection behavior. Its label remains
// visible while typing, including password and verification-code fields.
Ui.TextField {
  id: root
  property string fieldLabel: placeholderText
  Accessible.name: fieldLabel
  topPadding: caption.implicitHeight + Style.space(12) + Border.top(_borderSpec)
  bottomPadding: Math.max(Style.space(8), verticalPadding) + Border.bottom(_borderSpec)
  placeholderTextColor: fieldLabel === placeholderText ? 'transparent' : ProtonUi.secondaryText(foreground)
  Text {
    id: caption
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
