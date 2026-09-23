import QtQuick
import QtTest
import Quickshell
import qs.Commons

ShellRoot {
  id: suite
  property int step: 0
  property int cancelCalls: 0
  property bool finished: false
  ShowcaseState {
    id: state
    connected: false
    status: 'disconnected'
    function toggleConnection() {
      suite.cancelCalls++
      operationCancelable = false
      operationStage = 'tunnel.cancelling'
    }
  }
  FloatingWindow {
    visible: true
    implicitWidth: 420
    implicitHeight: 640
    TestEvent { id: events }
    ProtonWorkspace { id: workspace; anchors.fill: parent; vpnState: state }
  }
  function find(item) {
    if (item.objectName === 'connection-action') return item
    for (var i = 0; i < item.children.length; ++i) {
      var found = find(item.children[i])
      if (found) return found
    }
    return null
  }
  function check(ok, message) {
    if (!ok) { finished = true; Qt.callLater(Qt.quit); throw new Error('CONNECTION CANCEL: ' + message) }
  }
  Timer {
    interval: 160
    repeat: true
    running: !finished
    onTriggered: {
      var button = find(workspace)
      switch (step++) {
      case 0:
        state.connecting = true
        state.operationBusy = true
        state.tunnelOperationBusy = true
        state.operationKind = 'connection.connect'
        state.operationStage = 'tunnel.preparing_connection'
        state.operationCancelable = true
        break
      case 1:
        check(button.enabled && button.label === 'Cancel', 'preparation exposes an enabled Cancel action')
        state.operationStage = 'tunnel.securing_session'
        break
      case 2:
        check(button.enabled && button.label === 'Cancel', 'session handshake remains cancellable')
        events.mouseClick(button, button.width / 2, button.height / 2, Qt.LeftButton, Qt.NoModifier, -1)
        break
      case 3:
        check(cancelCalls === 1 && !button.enabled, 'click requests cancel once and disables while cleaning up')
        check(button.label === 'Cancelling connection…', 'cancellation progress remains visible')
        state.connecting = false
        state.operationBusy = false
        state.tunnelOperationBusy = false
        state.operationKind = ''
        state.operationStage = ''
        break
      case 4:
        check(button.enabled && button.label !== 'Cancel', 'normal connect action returns after cleanup')
        finished = true
        console.log('CONNECTION_CANCEL_QML true')
        Qt.quit()
      }
    }
  }
}
