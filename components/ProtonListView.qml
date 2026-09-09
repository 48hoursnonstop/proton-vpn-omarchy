import QtQuick
import QtQuick.Window
import QtQuick.Controls
import qs.Commons

// Keep model virtualization and incremental loading. Arrow keys reach items
// beyond the instantiated delegates; Tab still follows native focus order.
ListView {
  id: root
  activeFocusOnTab: false
  boundsBehavior: Flickable.StopAtBounds
  ScrollBar.vertical: ProtonScrollBar {
    policy: root.contentHeight > root.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
  }

  function focusControl(item) {
    if (!item || !item.visible || !item.enabled) return false
    if (item.activeFocusOnTab) { item.forceActiveFocus(); return true }
    for (var i = 0; i < item.children.length; ++i)
      if (focusControl(item.children[i])) return true
    return false
  }

  function focusIndex(index, direction) {
    if (index < 0 || index >= count) return
    currentIndex = index
    positionViewAtIndex(index, ListView.Contain)
    Qt.callLater(function() {
      if (!focusControl(currentItem) && direction !== 0)
        focusIndex(index + direction, direction)
    })
  }

  onActiveFocusChanged: if (activeFocus) focusIndex(Math.max(0, currentIndex), 1)
  Keys.onPressed: function(event) {
    var direction = event.key === Qt.Key_Down ? 1 : event.key === Qt.Key_Up ? -1 : 0
    if (!direction) return
    var item = root.Window.window ? root.Window.window.activeFocusItem : null
    while (item && item.parent !== contentItem) item = item.parent
    var index = item ? indexAt(1, item.y + 1) : currentIndex
    focusIndex(index + direction, direction)
    event.accepted = true
  }
}
