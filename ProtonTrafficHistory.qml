import QtQuick

// One collector per agent adapter, independent of panel and page lifetimes.
// Only counters/rates live here: a bounded RAM window, never a disk log.
QtObject {
  id: root
  property QtObject vpnState: null
  readonly property int windowMs: 300000
  readonly property int sampleLimit: 300
  readonly property bool active: vpnState && vpnState.connected && vpnState.agentAvailable
  property var samples: []
  property double clockMs: Date.now()
  property double lastAt: 0
  property double lastDownload: 0
  property double lastUpload: 0
  readonly property bool known: active && samples.length > 0 &&
    samples[samples.length - 1].download !== null &&
    clockMs - samples[samples.length - 1].time <= 2500

  function reset() {
    samples = []
    lastAt = 0
  }

  function prune(now) {
    return samples.filter(function(point) { return point.time > now - windowMs && point.time <= now })
      .slice(-sampleLimit)
  }

  function record(now) {
    if (!active) return
    clockMs = now
    var down = Number(vpnState.downloadBytes), up = Number(vpnState.uploadBytes)
    var elapsed = now - lastAt
    if (elapsed < 0 || (lastAt && (down < lastDownload || up < lastUpload))) reset()
    var valid = vpnState.trafficKnown && lastAt > 0 && elapsed >= 500 && elapsed <= 2500 &&
      isFinite(down) && isFinite(up) &&
      isFinite(vpnState.downloadBytesPerSecond) && isFinite(vpnState.uploadBytesPerSecond)
    var next = prune(now)
    next.push({ time: now,
      download: valid ? Math.max(0, vpnState.downloadBytesPerSecond) : null,
      upload: valid ? Math.max(0, vpnState.uploadBytesPerSecond) : null })
    samples = next.slice(-sampleLimit)
    lastAt = vpnState.trafficKnown ? now : 0
    lastDownload = down
    lastUpload = up
  }

  onVpnStateChanged: reset()
  property Connections updates: Connections {
    target: root.vpnState
    function onTrafficUpdated() { root.record(Date.now()) }
    function onConnectedChanged() { root.reset() }
    function onServerNameChanged() { root.reset() }
    function onProtocolChanged() { root.reset() }
  }
  property Timer poll: Timer {
    interval: 1000
    repeat: true
    triggeredOnStart: true
    running: root.active
    onTriggered: {
      root.clockMs = Date.now()
      root.samples = root.prune(root.clockMs)
      // The adapter suppresses a request while traffic.get is already pending.
      root.vpnState.refreshTraffic()
    }
  }
}
