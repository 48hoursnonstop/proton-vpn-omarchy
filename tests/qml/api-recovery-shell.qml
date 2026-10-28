import QtQuick
import QtTest
import Quickshell

ShellRoot {
  id: suite
  property int phase: 0
  property int refreshes: 0
  property int cancellations: 0
  property bool finished: false
  ShowcaseState {
    id: state
    connected: false
    status: 'disconnected'
    property bool accountRefreshSupported: true
    property bool guestHoleActive: false
    property bool refreshPending: false
    property bool cancelPending: false
    function requestPending(method) {
      return method === 'account.refresh' ? refreshPending
        : method === 'guest_hole.cancel' && cancelPending
    }
    function refreshAccount() { suite.refreshes++; refreshPending = true; authBusy = true }
    function cancelGuestHole() { suite.cancellations++; cancelPending = true }
  }
  FloatingWindow {
    visible: true
    implicitWidth: 420
    implicitHeight: 720
    Item {
      anchors.fill: parent
      TestEvent { id: keyboard }
      ProtonWorkspace { id: workspace; anchors.fill: parent; vpnState: state }
    }
  }
  function check(ok, message) {
    if (!ok) { finished = true; Qt.callLater(Qt.quit); throw new Error('API_RECOVERY: ' + message) }
  }
  function find(item, name) {
    if (item.objectName === name && item.visible) return item
    for (var i = 0; i < item.children.length; ++i) {
      var match = find(item.children[i], name)
      if (match) return match
    }
    return null
  }
  function press(item) {
    check(item && item.enabled, 'action is available')
    item.forceActiveFocus()
    keyboard.keyClick(Qt.Key_Return, Qt.NoModifier, -1)
  }
  Timer {
    id: phaseTimer
    interval: 160
    repeat: true
    running: !suite.finished
    onTriggered: {
      phaseTimer.stop()
      try {
        switch (suite.phase++) {
        case 0: workspace.setRoute('account'); break
        case 1:
          press(find(workspace, 'account-refresh'))
          check(refreshes === 1, 'refresh reaches the agent')
          check(!find(workspace, 'account-refresh').enabled, 'pending refresh cannot repeat')
          state.guestHoleActive = true
          state.operationBusy = true
          state.operationCancelable = true
          state.operationStage = 'guest_hole.connecting'
          break
        case 2:
          press(find(workspace, 'guest-hole-cancel'))
          check(cancellations === 1, 'signed-in recovery can be cancelled')
          check(!find(workspace, 'guest-hole-cancel').enabled, 'pending cancel cannot repeat')
          state.cancelPending = false
          state.signedIn = false
          state.accountStatus = 'signed_out'
          state.locale = 'es'
          break
        case 3:
          check(workspace.authVisible, 'signed-out recovery uses the auth page')
          press(find(workspace, 'guest-hole-cancel'))
          check(cancellations === 2, 'auth recovery can be cancelled')
          state.guestHoleActive = false
          state.operationBusy = false
          state.authBusy = false
          state.signedIn = true
          state.accountRefreshSupported = false
          break
        case 4: workspace.setRoute('account'); break
        case 5:
          check(!find(workspace, 'account-refresh'), 'older agents hide unsupported refresh')
          check(!find(workspace, 'guest-hole-cancel'), 'cancel disappears after recovery')
          finished = true
          console.log('API_RECOVERY_QML', true)
          Qt.quit()
        }
      } finally {
        if (!suite.finished) phaseTimer.start()
      }
    }
  }
}
