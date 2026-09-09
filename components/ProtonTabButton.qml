import QtQuick
import qs.Commons

// Keep the native selected fill and underline. Hover/focus must not replace
// that fill or add a second frame around the selected destination.
ProtonButton {
  id: root
  borderSpec: Border.none()
  color: keyboardPressed ? Style.pressedFillFor(foreground, accent)
    : selected ? Style.selectedFillFor(foreground, accent)
    : hot ? Style.hoverFillFor(foreground, accent)
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
