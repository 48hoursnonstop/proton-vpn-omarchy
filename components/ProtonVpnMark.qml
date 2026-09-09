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
    // Image is already a texture provider; an extra hidden layer can go stale
    // when the surrounding workspace has opacity animations.
  }

  MultiEffect {
    id: tintedStatusIcon
    anchors.fill: androidStatusIcon
    source: androidStatusIcon
    colorization: 1.0
    colorizationColor: root.statusColor
  }

}
