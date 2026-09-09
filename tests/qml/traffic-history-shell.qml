import QtQuick
import Quickshell

ShellRoot {
  id: suite
  property int phase: 0
  property int calls: 0
  property int before: 0
  property bool finished: false
  ShowcaseState {
    id: trafficAgent
    function refreshTraffic() { suite.calls++; downloadBytes += 1000; trafficUpdated() }
  }
  FloatingWindow {
    id: window
    visible: true
    implicitWidth: 420
    implicitHeight: 640
    Loader { id: first; active: false; width: 400; sourceComponent: card }
    Loader { id: second; active: false; width: 400; y: 280; sourceComponent: card }
  }
  Component { id: card; ProtonTrafficCard { vpnState: trafficAgent } }
  function check(ok, message) {
    if (!ok) { finished = true; Qt.callLater(Qt.quit); throw new Error('TRAFFIC_HISTORY: ' + message) }
  }
  Timer {
    interval: 300
    repeat: true
    running: !finished
    onTriggered: {
      switch (phase++) {
      case 0:
        check(calls > 0, 'samples before a view exists')
        first.active = true; second.active = true
        before = calls
        break
      case 1:
        check(first.item.monitor === second.item.monitor, 'views share the collector')
        check(first.item.renderActive, 'visible view can paint')
        window.visible = false
        break
      case 2:
        check(!first.item.renderActive, 'closed window disables painting')
        break
      case 3: case 4: case 5: break
      case 6:
        check(calls > before && calls <= before + 2, 'one poller with two views, including while closed')
        first.active = false; second.active = false
        before = calls
        break
      case 7: case 8: case 9: case 10: break
      case 11:
        check(calls > before, 'polls with all views destroyed')
        first.active = true; window.visible = true
        check(first.item.samples.length >= 3, 'new view immediately receives prior history')
        break
      case 12:
        trafficAgent.agentAvailable = false
        before = calls
        break
      case 13: case 14: case 15: case 16: break
      case 17:
        check(calls === before, 'no requests while agent unavailable')
        trafficAgent.connected = false
        check(trafficAgent.trafficMonitor.samples.length === 0, 'disconnect discards session history')
        trafficAgent.agentAvailable = true; trafficAgent.connected = true
        var history = trafficAgent.trafficMonitor
        history.poll.stop()
        history.reset()
        var now = Date.now()
        for (var i = 0; i < 620; ++i) history.record(now + i * 1000)
        check(history.samples.length === 300, 'history bounded after a long session')
        history.record(now + 650000)
        check(!history.known && history.samples[history.samples.length - 1].download === null, 'suspension creates a gap, not an averaged spike')
        history.record(now + 651000)
        check(history.known, 'next regular sample recovers')
        trafficAgent.downloadBytes = 0
        history.record(now + 652000)
        check(history.samples.length === 1 && !history.known, 'counter reset starts a new baseline')
        trafficAgent.serverName = 'CH#99'
        check(history.samples.length === 0, 'server change resets history')
        trafficAgent.trafficKnown = false
        history.record(now + 653000)
        check(!history.known, 'unavailable data stays unknown')
        finished = true
        console.log('TRAFFIC_HISTORY_QML', true)
        Qt.quit()
      }
    }
  }
}
