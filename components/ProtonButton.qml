import QtQuick
import qs.Commons

// Native button paint and behavior, with a wrapping label and one focus stop.
ProtonButtonBase {
  id: root
  property string label: ''
  property bool primary: false
  text: ''
  focusable: enabled
  active: primary
  bordered: primary
  tooltipText: label
  implicitWidth: Math.max(ProtonUi.controlHeight,
    labelText.implicitWidth + horizontalPadding * 2 + Style.space(4))
  implicitHeight: Math.max(ProtonUi.controlHeight,
    labelText.implicitHeight + verticalPadding * 2 + Style.space(4))
  opacity: enabled ? 1 : 0.5
  Accessible.role: Accessible.Button
  Accessible.name: label
  Accessible.focusable: focusable
  Accessible.onPressAction: if (enabled) clicked()

  Text {
    id: labelText
    anchors.centerIn: parent
    width: Math.max(0, parent.width - root.horizontalPadding * 2 - Style.space(4))
    text: root.label
    textFormat: Text.PlainText
    color: root.selected ? Style.selectedStateColor(root.foreground, root.accent) : root.foreground
    font.family: root.fontFamily
    font.pixelSize: root.fontSize
    font.weight: root.primary || root.selected ? Font.DemiBold : Font.Normal
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.Wrap
    lineHeight: 1.15
    Accessible.ignored: true
  }
}
