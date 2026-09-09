import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui

// Persistent native destination controls, shared by the panel and previews.
Item {
  id: root
  property var destinations: []
  property string currentRoute: 'home'
  property color foreground: Color.popups.text
  property color dim: ProtonUi.secondaryText(foreground)
  property string fontFamily: Style.font.family
  signal routeRequested(string route)
  implicitHeight: tabs.implicitHeight + Style.space(6)
  readonly property real tabHeight: {
    var result = ProtonUi.controlHeight
    for (var i = 0; i < repeater.count; ++i) {
      var tab = repeater.itemAt(i)
      if (tab) result = Math.max(result, tab.implicitHeight)
    }
    return result
  }
  onCurrentRouteChanged: Qt.callLater(revealCurrent)
  onWidthChanged: Qt.callLater(revealCurrent)

  function revealCurrent() {
    for (var i = 0; i < repeater.count; ++i) {
      var button = repeater.itemAt(i)
      if (button.selected) { reveal(button); return }
    }
  }

  function focusCurrent() {
    for (var i = 0; i < repeater.count; ++i) {
      var button = repeater.itemAt(i)
      if (button.selected) { button.forceActiveFocus(); reveal(button); return }
    }
  }

  function reveal(button) {
    if (button.x < viewport.contentX) viewport.contentX = button.x
    else if (button.x + button.width > viewport.contentX + viewport.width)
      viewport.contentX = button.x + button.width - viewport.width
  }

  Flickable {
    id: viewport
    width: parent.width
    height: root.implicitHeight
    contentWidth: tabs.width
    contentHeight: height
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.HorizontalFlick
    ScrollBar.horizontal: ProtonScrollBar {
      policy: viewport.contentWidth > viewport.width ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
    }
    Row {
      id: tabs
      spacing: Style.space(3)
      Repeater {
        id: repeater
        model: root.destinations
        delegate: ProtonTabButton {
          required property var modelData
          width: Math.max(Style.space(48),
            (viewport.width - tabs.spacing * (repeater.count - 1)) / Math.max(1, repeater.count))
          height: root.tabHeight
          onActiveFocusChanged: if (activeFocus) root.reveal(this)
          label: String(modelData.label || '')
          selected: root.currentRoute === String(modelData.route || '')
          foreground: root.foreground
          fontFamily: root.fontFamily
          fontSize: viewport.width < Style.space(330) ? Style.font.caption : Style.font.bodySmall
          horizontalPadding: viewport.width < Style.space(330) ? 0 : Style.space(4)
          Accessible.role: Accessible.PageTab
          Accessible.name: label
          Accessible.selected: selected
          onClicked: root.routeRequested(String(modelData.route || 'home'))
          Keys.onLeftPressed: root.move(-1)
          Keys.onRightPressed: root.move(1)
        }
      }
    }
  }

  function move(direction) {
    for (var i = 0; i < destinations.length; ++i) {
      if (String(destinations[i].route) !== currentRoute) continue
      var index = (i + direction + destinations.length) % destinations.length
      routeRequested(String(destinations[index].route))
      Qt.callLater(focusCurrent)
      return
    }
  }
}
