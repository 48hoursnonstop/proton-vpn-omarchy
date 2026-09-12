import QtQuick
import QtTest
import Quickshell

ShellRoot {
  id: suite
  property int phase: 0
  property int retries: 0
  property bool finished: false
  ShowcaseState {
    id: state
    signedIn: false
    accountStatus: 'restoring'
    property bool pendingRetry: false
    function requestPending(method) { return method === 'account.retry_restore' && pendingRetry }
    function send(method, params) {
      if (method !== 'account.retry_restore') throw new Error('unexpected request')
      suite.retries++
      pendingRetry = true
    }
  }
  FloatingWindow {
    id: window
    visible: true
    implicitWidth: 420
    implicitHeight: 640
    Item {
      anchors.fill: parent
      TestEvent { id: keyboard }
      ProtonWorkspace { id: workspace; anchors.fill: parent; vpnState: state }
    }
  }
  function check(ok, message) {
    if (!ok) { finished = true; Qt.callLater(Qt.quit); throw new Error('KEYRING: ' + message) }
  }
  function find(item, predicate) {
    if (predicate(item)) return item
    for (var i = 0; i < item.children.length; ++i) {
      var match = find(item.children[i], predicate)
      if (match) return match
    }
    return null
  }
  function retry() { return find(workspace, function(item) { return item.objectName === 'keyring-retry' }) }
  function visibleText(value) {
    return find(workspace, function(item) { return item.visible && item.text === value })
  }
  Timer {
    interval: 150
    repeat: true
    running: !suite.finished
    onTriggered: {
      switch (suite.phase++) {
      case 0:
        check(workspace.authVisible, 'recovery gates VPN controls')
        check(visibleText('Waiting for keyring'), 'shows recovery status')
        check(!visibleText('Sign in to Proton VPN'), 'does not ask for credentials during recovery')
        workspace.focusInitial()
        break
      case 1:
        check(retry().activeFocus && retry().enabled, 'retry is keyboard accessible')
        keyboard.keyClick(Qt.Key_Return, Qt.NoModifier, -1)
        check(retries === 1 && !retry().enabled, 'one retry while pending')
        keyboard.keyClick(Qt.Key_Return, Qt.NoModifier, -1)
        check(retries === 1, 'no duplicate retry')
        state.pendingRetry = false
        state.locale = 'es'
        break
      case 2:
        check(visibleText('Esperando al llavero'), 'Spanish recovery message')
        state.locale = 'en'
        state.accountStatus = 'signed_out'
        break
      case 3:
        check(visibleText('Sign in to Proton VPN'), 'empty keyring offers normal login')
        check(!retry().visible, 'retry hidden after restoration')
        state.accountStatus = 'restoring'
        break
      case 4:
        state.accountStatus = 'signed_in'
        state.signedIn = true
        break
      case 5:
        check(!workspace.authVisible && workspace.route === 'home', 'restored session opens home')
        finished = true
        console.log('KEYRING_RECOVERY_QML', true)
        Qt.quit()
      }
    }
  }
}
