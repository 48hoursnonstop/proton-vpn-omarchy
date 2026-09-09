import QtQuick
import Quickshell
import 'components'

ShellRoot {
  id: suite
  property int phase: 0
  property bool finished: false
  ShowcaseState { id: motionAgent }
  FloatingWindow {
    id: window
    visible: true
    implicitWidth: 420
    implicitHeight: 640
    ProtonWorkspace { id: workspace; anchors.fill: parent; vpnState: motionAgent }
    PanelActionRow { id: row; width: 220; title: 'Disclosure'; detailIconName: 'chevron_right' }
  }
  function check(ok, message) {
    if (!ok) { finished = true; Qt.callLater(Qt.quit); throw new Error('MOTION: ' + message) }
  }
  function find(item, name) {
    if (item.objectName === name) return item
    for (var i = 0; i < item.children.length; ++i) {
      var result = find(item.children[i], name)
      if (result) return result
    }
    return null
  }
  Timer {
    interval: 40
    repeat: true
    running: !finished
    onTriggered: {
      var page = find(workspace, 'page-content')
      var arrow = find(row, 'row-detail-icon')
      switch (phase++) {
      case 0:
        check(page.opacity === 1, 'no initial entrance')
        workspace.setRoute('settings')
        check(page.opacity < 1 && workspace.currentPage !== null, 'content switches immediately with a short fade')
        break
      case 1:
        check(page.opacity > 0.65 && page.opacity < 1, 'intermediate route opacity')
        var previous = page.opacity
        workspace.setRoute('locations')
        check(Math.abs(page.opacity - previous) < 0.01, 'rapid navigation retargets without an opacity jump')
        break
      case 2: case 3: case 4: case 5: case 6: break
      case 7:
        check(page.opacity === 1, 'route transition finishes')
        row.detailIconRotation = 90
        break
      case 8:
        check(arrow.rotation > 0 && arrow.rotation < 90, 'disclosure rotates between states')
        row.detailIconRotation = 0
        break
      case 9: case 10: case 11: case 12: case 13: break
      case 14:
        check(arrow.rotation === 0, 'reversed transitions settle correctly')
        ProtonUi.reducedMotion = true
        row.detailIconRotation = 90
        workspace.setRoute('profiles')
        check(arrow.rotation === 90 && page.opacity === 1, 'reduced motion applies changes immediately')
        window.visible = false
        ProtonUi.reducedMotion = false
        workspace.setRoute('home')
        check(page.opacity === 1, 'hidden route changes skip animation')
        finished = true
        console.log('MOTION_QML', true)
        Qt.quit()
      }
    }
  }
}
