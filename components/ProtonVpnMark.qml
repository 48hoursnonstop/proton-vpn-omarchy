import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons
import qs.Ui

Item {
  id: root
  property color statusColor: Color.foreground
  property bool connected: false
  property bool connecting: false
  property bool information: false
  property string state: ''
  property real iconSize: Style.bar.iconCanvas
  property real connectionPulseOpacity: 1.0
  implicitWidth: iconSize
  implicitHeight: iconSize

  readonly property string effectiveState: {
    var requested = String(state || '')
    if (['information', 'disconnected', 'connecting', 'connected'].indexOf(requested) >= 0)
      return requested
    if (information) return 'information'
    if (connecting) return 'connecting'
    if (connected) return 'connected'
    return 'disconnected'
  }
  readonly property string stateAsset: 'ic_vpn_status_' + effectiveState + '.webp'

  Image {
    id: androidStatusIcon
    anchors.fill: parent
    fillMode: Image.PreserveAspectFit
    asynchronous: false
    cache: true
    source: Qt.resolvedUrl('../assets/status/' + root.stateAsset)
    sourceSize.width: Math.round(root.iconSize * Screen.devicePixelRatio)
    sourceSize.height: Math.round(root.iconSize * Screen.devicePixelRatio)
    visible: false
    layer.enabled: true
  }

  MultiEffect {
    id: tintedStatusIcon
    anchors.fill: androidStatusIcon
    source: androidStatusIcon
    colorization: 1.0
    colorizationColor: root.statusColor
    opacity: root.effectiveState === 'connecting' ? root.connectionPulseOpacity : 1.0
  }

  SequentialAnimation on connectionPulseOpacity {
    running: root.effectiveState === 'connecting'
    loops: Animation.Infinite
    NumberAnimation { from: 0.55; to: 1.0; duration: 420 }
    NumberAnimation { from: 1.0; to: 0.55; duration: 420 }
  }
}
