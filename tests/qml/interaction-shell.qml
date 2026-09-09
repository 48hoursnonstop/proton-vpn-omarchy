import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import qs.Commons
import 'components'

ShellRoot {
  id: suite
  property int step: 0
  property bool finished: false
  property int rowCalls: 0
  property int buttonCalls: 0
  property int serverCalls: 0
  property int lookupCalls: 0
  property int callsBefore: 0
  property real previousScroll: 0
  property var searchInput: null
  ShowcaseState {
    id: state
    function loadServers(query, country, gateway, feature, scope) {
      suite.serverCalls++
      servers = []
      serverTotal = 0
      remoteSearchServer = null
    }
    function lookupServer(query) { suite.lookupCalls++ }
  }
  FloatingWindow {
    id: window
    visible: true
    implicitWidth: 420
    implicitHeight: 640
    Item {
      anchors.fill: parent
      TestEvent { id: events }
      ProtonWorkspace { id: workspace; anchors.fill: parent; vpnState: state }
      PanelActionRow {
        id: row
        visible: false
        width: 220
        title: 'Setting'
        onActivated: suite.rowCalls++
      }
      ProtonButton {
        id: button
        visible: false
        y: 100
        width: 220
        label: 'Action'
        onClicked: suite.buttonCalls++
      }
    }
  }
  function check(ok, message) {
    if (!ok) { finished = true; Qt.callLater(Qt.quit); throw new Error('INTERACTION: ' + message) }
  }
  function find(item, predicate) {
    if (!item) return null
    if (predicate(item)) return item
    for (var i = 0; i < item.children.length; ++i) {
      var result = find(item.children[i], predicate)
      if (result) return result
    }
    return null
  }
  function named(name) { return find(workspace, function(item) { return item.objectName === name }) }
  function labelled(label) { return find(workspace, function(item) { return item.visible && item.Accessible.name === label }) }
  function press(key) { events.keyPress(key, Qt.NoModifier, -1) }
  function release(key) { events.keyRelease(key, Qt.NoModifier, -1) }
  function click(key) { events.keyClick(key, Qt.NoModifier, -1) }
  Timer {
    interval: 170
    repeat: true
    running: !finished
    onTriggered: {
      switch (step++) {
      case 0:
        workspace.setRoute('settings')
        break
      case 1:
        workspace.currentPage.settingsSection = 'application'
        workspace.currentPage.advancedExpanded = true
        break
      case 2:
        labelled('About').forceActiveFocus()
        break
      case 3:
        previousScroll = named('page-viewport').contentY
        check(previousScroll > 0, 'starting navigation from a scrolled settings page')
        click(Qt.Key_Space)
        check(workspace.route === 'about', 'activate nested page')
        break
      case 4:
        click(Qt.Key_Escape)
        break
      case 5:
        check(workspace.route === 'settings' && workspace.currentPage.settingsSection === 'application', 'Back preserves settings section')
        check(workspace.currentPage.advancedExpanded, 'Back preserves disclosure')
        check(Math.abs(named('page-viewport').contentY - previousScroll) < 2, 'Back preserves scroll')
        check(window.contentItem.Window.window.activeFocusItem.Accessible.name === 'About', 'Back restores invoking control')
        workspace.setRoute('locations')
        break
      case 6:
        searchInput = labelled('Search country, city or server')
        searchInput.forceActiveFocus()
        searchInput.text = 'no-such-location-fixture'
        check(workspace.currentPage.searchPending, 'immediate feedback during debounce')
        check(!named('search-empty').visible, 'no premature empty state')
        break
      case 7: break
      case 8: break
      case 9:
        check(!workspace.currentPage.searchPending && named('search-empty').visible, 'empty only after search settles')
        searchInput.text = 'CH#42'
        callsBefore = serverCalls
        click(Qt.Key_Return)
        check(serverCalls === callsBefore + 1 && lookupCalls === 1, 'Enter submits immediately including exact lookup')
        searchInput.text = 'Switzerland'
        workspace.currentPage.selectFeature('p2p')
        workspace.setRoute('settings')
        break
      case 10:
        workspace.setRoute('locations')
        break
      case 11:
        check(workspace.currentPage.searchQuery === 'Switzerland' && workspace.currentPage.feature === 'p2p', 'tab round trip retains search/filter')
        workspace.currentPage.openLocation(state.countries[0], 'country')
        check(workspace.currentPage.showingServers, 'browse into country')
        workspace.goBack()
        check(workspace.currentPage.searchQuery === 'Switzerland', 'country Back restores previous search')
        workspace.currentPage.openLocation(state.countries[0], 'country')
        var back = named('locations-back')
        events.mouseClick(back, back.width / 2, back.height / 2, Qt.LeftButton, Qt.NoModifier, -1)
        check(workspace.currentPage.searchQuery === 'Switzerland', 'pointer Back restores previous search')
        workspace.currentPage.clearSearch()
        callsBefore = serverCalls
        check(window.contentItem.Window.window.activeFocusItem.fieldLabel === 'Search country, city or server', 'clear keeps typing focus')
        break
      case 12: break
      case 13: break
      case 14:
        check(serverCalls === callsBefore && !workspace.currentPage.searchPending, 'clear cancels pending search')
        state.signedIn = false
        check(Object.keys(workspace.navigationMemory).length === 0, 'account gate clears presentation memory')
        workspace.visible = false
        row.visible = true
        button.visible = true
        row.forceActiveFocus()
        press(Qt.Key_Space)
        check(row.pressed && rowCalls === 0, 'Space has held feedback without activation')
        break
      case 15:
        check(row.fill === Style.pressedFillFor(row.rowForeground, Color.accent), 'native pressed color')
        press(Qt.Key_Space)
        check(rowCalls === 0, 'held row does not repeat')
        release(Qt.Key_Space)
        check(!row.pressed && rowCalls === 1, 'row activates once on release')
        button.forceActiveFocus()
        press(Qt.Key_Space)
        check(button.keyboardPressed && buttonCalls === 0, 'button held feedback without activation')
        break
      case 16:
        check(button.color === Style.pressedFillFor(button.foreground, button.accent), 'keyboard uses native button pressed paint')
        release(Qt.Key_Space)
        check(buttonCalls === 1 && !button.keyboardPressed, 'button activates once')
        press(Qt.Key_Space)
        row.forceActiveFocus()
        release(Qt.Key_Space)
        check(buttonCalls === 1 && rowCalls === 1, 'changing focus cancels held action')
        break
      case 17:
        events.mousePress(row, 40, 20, Qt.LeftButton, Qt.NoModifier, -1)
        check(row.pressed, 'pointer press is distinct from hover')
        events.mouseMove(row, 270, 20, -1, Qt.LeftButton, Qt.NoModifier)
        events.mouseRelease(row, 270, 20, Qt.LeftButton, Qt.NoModifier, -1)
        check(rowCalls === 1 && !row.pressed, 'dragging out cancels click')
        row.busy = true
        click(Qt.Key_Space)
        check(rowCalls === 1 && !row.pressed, 'busy rejects action')
        button.forceActiveFocus()
        click(Qt.Key_Return)
        check(buttonCalls === 2, 'Enter activates once')
        finished = true
        console.log('INTERACTION_QML', true)
        Qt.quit()
      }
    }
  }
}
