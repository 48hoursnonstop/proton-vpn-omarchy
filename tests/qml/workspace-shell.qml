import QtQuick
import QtTest
import Quickshell
import 'components'

ShellRoot {
  id: suite
  property int phase: 0
  property int closes: 0
  property int rowCalls: 0
  property bool finished: false
  property var savedGateways: []
  property var input: null
  ShowcaseState { id: state }
  FloatingWindow {
    id: window
    visible: true
    implicitWidth: 420
    implicitHeight: 640
    Item {
      anchors.fill: parent
      TestEvent { id: keyboard }
      ProtonWorkspace {
        id: workspace
        anchors.fill: parent
        vpnState: state
        onCloseRequested: suite.closes++
      }
      PanelActionRow {
        id: row
        visible: false
        width: 300
        title: 'Test setting'
        toggleVisible: true
        onActivated: suite.rowCalls++
      }
      ProtonListView {
        id: longList
        visible: false
        width: 250
        height: 100
        model: 100
        delegate: PanelActionRow {
          required property int index
          width: 240
          title: 'Row ' + index
          objectName: 'row-' + index
        }
      }
    }
  }
  function check(condition, message) {
    if (!condition) { finished = true; Qt.callLater(Qt.quit); throw new Error('WORKSPACE: ' + message) }
  }
  function find(item, predicate) {
    if (!item) return null
    if (predicate(item)) return item
    for (var i = 0; i < item.children.length; ++i) {
      var match = find(item.children[i], predicate)
      if (match) return match
    }
    return null
  }
  function named(name) { return find(workspace, function(item) { return item.objectName === name }) }
  function labelled(label) { return find(workspace, function(item) { return item.visible && item.Accessible.name === label }) }
  function press(key, modifiers) { check(keyboard.keyClick(key, modifiers || Qt.NoModifier, -1), 'key event delivered') }
  function focusedName() { return window.contentItem.Window.window.activeFocusItem.Accessible.name }
  Timer {
    interval: 80
    repeat: true
    running: !suite.finished
    onTriggered: {
      switch (suite.phase++) {
      case 0:
        check(workspace.route === 'home' && !workspace.inputViewVisible, 'signed-in home')
        workspace.focusInitial()
        break
      case 1:
        check(focusedName() === 'Home', 'initial selected-tab focus')
        press(Qt.Key_Right)
        break
      case 2:
        check(workspace.route === 'locations' && focusedName() === 'Countries', 'arrow changes destination')
        press(Qt.Key_F, Qt.ControlModifier)
        break
      case 3:
        input = window.contentItem.Window.window.activeFocusItem
        check(input.fieldLabel === 'Search country, city or server', 'search shortcut focuses labelled input')
        input.text = 'Canada'
        check(input.Accessible.name === input.fieldLabel && input.fieldLabel.length > 0, 'label persists while typing')
        workspace.setRoute('details')
        workspace.focusInitial()
        press(Qt.Key_Escape)
        check(workspace.route === 'home' && closes === 0, 'Escape returns from detail')
        press(Qt.Key_Escape)
        check(closes === 1, 'Escape closes root')
        workspace.setRoute('settings')
        break
      case 4:
        labelled('Application').forceActiveFocus()
        press(Qt.Key_Space)
        check(workspace.currentPage.settingsSection === 'application', 'keyboard opens Application settings')
        // Let the section's visibility/bindings settle before finding its
        // controls; reading Accessible.name in the same key event can be stale.
        Qt.callLater(function() { labelled('Sign out').forceActiveFocus() })
        break
      case 5:
        check(named('page-viewport').contentY > 0, 'keyboard reveals offscreen control')
        press(Qt.Key_Return)
        check(workspace.currentPage.confirmingLogout, 'signout asks for confirmation')
        labelled('Cancel').forceActiveFocus()
        press(Qt.Key_Return)
        check(!workspace.currentPage.confirmingLogout, 'signout can be cancelled')
        workspace.setRoute('home')
        state.tunnelOperationBusy = true
        check(!named('connection-action').enabled, 'in-flight connection disables duplicate action')
        state.tunnelOperationBusy = false
        savedGateways = state.gateways
        workspace.setRoute('gateways')
        state.gateways = []
        check(workspace.route === 'locations', 'removed gateway destination reroutes')
        state.gateways = savedGateways
        state.signedIn = false
        break
      case 6:
        check(workspace.authVisible, 'signed-out state gates navigation')
        workspace.focusInitial()
        break
      case 7:
        check(focusedName() === 'Email or username', 'authentication initial focus')
        press(Qt.Key_Tab)
        check(focusedName() === 'Password', 'Tab moves through form')
        state.signedIn = true
        state.onboardingComplete = false
        break
      case 8:
        check(workspace.onboardingVisible, 'onboarding gate preserved')
        state.onboardingComplete = true
        row.visible = true
        row.forceActiveFocus()
        press(Qt.Key_Space)
        check(rowCalls === 1 && row.hasCursor, 'row keyboard activation and visible focus')
        row.busy = true
        press(Qt.Key_Space)
        check(rowCalls === 1, 'busy row rejects repeat activation')
        row.visible = false
        workspace.visible = false
        longList.visible = true
        longList.forceActiveFocus()
        break
      default:
        if (phase < 25) { press(Qt.Key_Down); break }
        check(longList.currentIndex >= 14 && longList.contentY > 0, 'arrows reach virtualized rows')
        check(window.contentItem.Window.window.activeFocusItem.hasCursor, 'virtualized row retains visible focus')
        finished = true
        console.log('WORKSPACE_QML', true)
        Qt.quit()
      }
    }
  }
}
