import QtQuick
import Quickshell

ShellRoot {
  AgentState {
    id: agentState
  }

  QtObject {
    id: mockAgent
    property bool connected: true
    property bool trafficKnown: true
    property double downloadBytes: 73400320
    property double uploadBytes: 12582912
    property double downloadBytesPerSecond: 3145728
    property double uploadBytesPerSecond: 524288
    signal trafficUpdated()
    function refreshTraffic() {
      downloadBytes += downloadBytesPerSecond
      uploadBytes += uploadBytesPerSecond
      downloadBytesPerSecond = downloadBytesPerSecond === 3145728
        ? 1572864 : 3145728
      uploadBytesPerSecond = uploadBytesPerSecond === 524288
        ? 786432 : 524288
      trafficUpdated()
    }
  }

  ProtonStrings {
    id: strings
    localeName: 'es-MX'
  }

  FloatingWindow {
    visible: true
    implicitWidth: 380
    implicitHeight: Math.max(240, traffic.implicitHeight)
    color: 'black'

    ProtonTrafficCard {
      id: traffic
      anchors.fill: parent
      vpnState: mockAgent
      strings: strings
      foreground: 'white'
      dim: '#999999'
      fontFamily: 'monospace'
    }
  }

  Timer {
    interval: 2200
    running: true
    onTriggered: {
      agentState.pendingRequests = ({ passive: { method: 'traffic.get' } })
      var passivePendingHidden = !agentState.operationBusy &&
        agentState.requestPending('traffic.get')
      agentState.pendingRequests = ({ passive: { method: 'netshield.stats.get' } })
      var passiveNetShieldHidden = !agentState.operationBusy
      agentState.pendingRequests = ({ action: { method: 'connection.connect' } })
      var foregroundPendingShown = agentState.operationBusy &&
        agentState.operationKind === 'connection.connect'
      agentState.pendingRequests = ({})
      agentState.activeOperations = [
        { kind: 'traffic.get', stage: 'traffic.reading' }
      ]
      var passiveActiveHidden = !agentState.operationBusy
      agentState.activeOperations = [
        { kind: 'profiles.save', stage: 'profiles.saving' }
      ]
      var foregroundActiveShown = agentState.operationBusy &&
        agentState.operationKind === 'profiles.save'
      agentState.pendingRequests = ({ passiveError: { method: 'traffic.get' } })
      agentState.lastError = 'Keep user feedback'
      agentState.lastErrorCode = 'connection_failed'
      agentState.handleLine(JSON.stringify({
        v: 1, id: 'passiveError', type: 'response', ok: false,
        error: { code: 'poll_failed', message: 'Passive poll failed' }
      }))
      var passiveErrorPreserved = agentState.lastError === 'Keep user feedback' &&
        agentState.lastErrorCode === 'connection_failed'
      agentState.pendingRequests = ({ actionError: { method: 'connection.connect' } })
      agentState.handleLine(JSON.stringify({
        v: 1, id: 'actionError', type: 'response', ok: false,
        error: { code: 'connection_failed', message: 'Foreground action failed' }
      }))
      var foregroundErrorShown = agentState.lastError === 'Foreground action failed' &&
        agentState.lastErrorCode === 'connection_failed'
      var missingDefaultIsFastest =
        agentState.normalizedDefaultConnection({}).type === 'fastest'
      var malformedProfileIsFastest =
        agentState.normalizedDefaultConnection({ type: 'profile' }).type === 'fastest'
      console.log('TRAFFIC_QML', traffic.downloadHistory.length >= 2,
                  traffic.uploadHistory.length >= 2,
                  traffic.implicitHeight > 0,
                  passivePendingHidden,
                  passiveNetShieldHidden,
                  foregroundPendingShown,
                  passiveActiveHidden,
                  foregroundActiveShown,
                  passiveErrorPreserved,
                  foregroundErrorShown,
                  missingDefaultIsFastest,
                  malformedProfileIsFastest)
      Qt.quit()
    }
  }
}
