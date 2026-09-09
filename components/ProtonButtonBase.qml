import QtQuick
import qs.Commons
import qs.Ui as Ui

// Native pointer feedback, with the same pressed fill for keyboard operation.
// Holding a key must never advance a confirmation or repeat an agent action.
Ui.Button {
  id: root
  property bool spaceHeld: false
  property bool pointerFocus: false
  property bool keyboardActivation: false
  readonly property bool keyboardFocus: focusable && activeFocus && !pointerFocus
  readonly property bool keyboardPressed: spaceHeld && activeFocus && enabled
  // A pointer click may retain focus for keyboard navigation, without retaining
  // the keyboard outline. Hover uses a fill only, never side borders.
  borderSpec: keyboardFocus ? Border.controlSpec('focus', foreground, accent)
    : bordered ? Border.controlSpec('normal', foreground, accent) : Border.none()
  function activateFromKeyboard() {
    keyboardActivation = true
    clicked()
    keyboardActivation = false
  }
  Connections {
    target: root
    function onClicked() { if (!root.keyboardActivation) root.pointerFocus = true }
  }
  Binding {
    target: root
    property: 'color'
    when: root.pointerFocus && !root.hot && !root.keyboardPressed
    value: root.selected || root.active
      ? Style.selectedFillFor(root.foreground, root.accent) : root.background
    restoreMode: Binding.RestoreBindingOrValue
  }
  Behavior on opacity { NumberAnimation { duration: ProtonUi.transitionMs; easing.type: Easing.OutCubic } }

  Keys.forwardTo: [activationKeys]
  Item {
    id: activationKeys
    // Consume activation before the toolkit's press-only handlers. Other keys
    // continue to the button (tabs/arrows) and then its containing workspace.
    Keys.onPressed: function(event) {
      root.pointerFocus = false
      if (event.key === Qt.Key_Space) {
        if (root.focusable && root.enabled && !event.isAutoRepeat) root.spaceHeld = true
        event.accepted = true
      } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        if (root.focusable && root.enabled && !event.isAutoRepeat) root.activateFromKeyboard()
        event.accepted = true
      }
    }
    Keys.onReleased: function(event) {
      if (event.key !== Qt.Key_Space) return
      event.accepted = true
      if (event.isAutoRepeat) return
      var activate = root.keyboardPressed && root.focusable
      root.spaceHeld = false
      if (activate) root.activateFromKeyboard()
    }
  }
  onActiveFocusChanged: if (!activeFocus) { spaceHeld = false; pointerFocus = false }
  onEnabledChanged: if (!enabled) spaceHeld = false

  Binding {
    target: root
    property: 'color'
    when: root.keyboardPressed
    value: Style.pressedFillFor(root.foreground, root.accent)
    restoreMode: Binding.RestoreBindingOrValue
  }
}
