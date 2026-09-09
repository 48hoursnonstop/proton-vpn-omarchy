import QtQuick
import QtTest
import Quickshell
import qs.Commons
import 'components'

ShellRoot {
  id: suite
  property int step: 0
  property bool finished: false
  property var target: null
  property var search: null
  property real searchWidth: 0
  property int protocolCalls: 0
  ShowcaseState {
    id: state
    function setProtocol(value) { selectedProtocol = value; suite.protocolCalls++ }
  }
  FloatingWindow {
    visible: true
    implicitWidth: 420
    implicitHeight: 640
    TestEvent { id: events }
    ProtonWorkspace { id: workspace; anchors.fill: parent; anchors.margins: 16; vpnState: state }
  }
  function find(item, name) {
    if (item.visible && item.Accessible.name === name && item.activeFocusOnTab) return item
    for (var i = 0; i < item.children.length; ++i) {
      var result = find(item.children[i], name)
      if (result) return result
    }
    return null
  }
  function click(item) {
    check(!!item, 'control exists')
    events.mouseClick(item, item.width / 2, item.height / 2, Qt.LeftButton, Qt.NoModifier, -1)
    events.mouseMove(workspace, 1, workspace.height - 1, -1, Qt.NoButton, Qt.NoModifier)
  }
  function check(ok, message) {
    if (!ok) { finished = true; Qt.callLater(Qt.quit); throw new Error('CONTROL STATES: ' + message) }
  }
  function noFrame(item) {
    return Border.left(item.borderSpec) === 0 && Border.right(item.borderSpec) === 0 && Border.top(item.borderSpec) === 0
  }
  Timer {
    interval: 180
    repeat: true
    running: !suite.finished
    onTriggered: {
      switch (suite.step++) {
      case 0:
        target = find(workspace, 'Countries')
        click(target)
        break
      case 1:
        check(workspace.route === 'locations', 'pointer changes page')
        check(target.activeFocus && target.pointerFocus && noFrame(target) && target.color.a === 0, 'clicked tab retains focus without frame or dimming: ' + [target.activeFocus, target.pointerFocus, noFrame(target), target.color.a])
        search = find(workspace, 'Search country, city or server')
        check(search.height >= 40 && search.height <= 42, 'search is a single 40px row')
        searchWidth = search.width
        search.text = 'Switzerland'
        check(search.width === searchWidth, 'clear action does not shrink the field')
        break
      case 2:
        click(find(workspace, 'Clear search'))
        check(search.text === '' && search.activeFocus && search.width === searchWidth, 'clear preserves typing focus and geometry')
        click(find(workspace, 'Settings'))
        break
      case 3:
        target = find(workspace, 'Application')
        click(target)
        break
      case 4:
        check(workspace.currentPage.settingsSection === 'application', 'pointer changes settings section')
        check(target.pointerFocus && noFrame(target) && target.color.a === 0, 'settings tabs use the same clean pointer state')
        events.keyClick(Qt.Key_Tab, Qt.NoModifier, -1)
        check(!target.activeFocus, 'Tab can leave a pointer-focused tab')
        click(find(workspace, 'Connection'))
        workspace.currentPage.openPicker = 'protocol'
        break
      case 5:
        target = find(workspace.currentPage, workspace.strings.protocolName('smart'))
        click(target)
        break
      case 6:
        check(workspace.currentPage.openPicker === '' && protocolCalls === 0, 'choosing current protocol closes without mutation')
        click(find(workspace, 'Home'))
        break
      case 7:
        events.keyClick(Qt.Key_Right, Qt.NoModifier, -1)
        break
      case 8:
        target = find(workspace, 'Countries')
        check(workspace.route === 'locations' && target.activeFocus && target.keyboardFocus && noFrame(target), 'arrow navigation has keyboard indication without side frames')
        target = find(workspace, 'P2P')
        click(target)
        break
      case 9:
        check(workspace.currentPage.feature === 'p2p' && target.selected && noFrame(target), 'feature choice selects without a box')
        finished = true
        console.log('CONTROL_STATES_QML', true)
        Qt.quit()
      }
    }
  }
}
