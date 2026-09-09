import QtQuick
import qs.Commons

// Selection belongs to the underline. Keyboard focus strengthens that same
// indicator instead of adding a second frame around the destination.
ProtonButton {
  id: root
  filledSelection: false
  borderSpec: Border.none()
  color: keyboardPressed ? Style.pressedFillFor(foreground, accent)
    : 'transparent'
  Accessible.role: Accessible.PageTab
  Accessible.selected: selected
  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: root.keyboardFocus ? Style.space(4) : root.selected ? Math.max(2, Style.space(2)) : 1
    visible: root.selected || root.keyboardFocus || root.hot
    opacity: root.selected || root.keyboardFocus ? 1 : 0.5
    color: root.foreground
  }
}
