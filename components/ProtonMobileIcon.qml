import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons

// Shared renderer for Proton's pinned Android/Core iconography. Vector assets
// keep their original geometry; the few Android clip-path icons use 192px PNG
// compatibility renders and still size from Quattro's logical scale tokens.
Item {
  id: root

  property string iconName: ''
  property url sourceOverride: ''
  property color iconColor: Color.foreground
  property real iconSize: Style.font.iconLarge
  property bool tint: true

  readonly property var rasterIcons: [
    'arrow_out_square', 'bookmark', 'cross_circle', 'exclamation_circle',
    'folder', 'mobile', 'paper_plane', 'pencil', 'question_circle', 'shield',
    'star', 'window_terminal'
  ]
  readonly property string extension:
    rasterIcons.indexOf(iconName) >= 0 ? '.png' : '.svg'
  readonly property url resolvedSource: String(sourceOverride).length > 0
    ? sourceOverride
    : iconName !== ''
      ? Qt.resolvedUrl('../assets/mobile/icons/ic_proton_' + iconName + extension)
      : ''

  implicitWidth: iconSize
  implicitHeight: iconSize
  visible: iconName !== '' || String(sourceOverride).length > 0

  Image {
    id: sourceIcon
    anchors.fill: parent
    source: root.resolvedSource
    fillMode: Image.PreserveAspectFit
    asynchronous: false
    cache: true
    smooth: true
    sourceSize.width: Math.round(root.iconSize * Screen.devicePixelRatio)
    sourceSize.height: Math.round(root.iconSize * Screen.devicePixelRatio)
    visible: !root.tint
    layer.enabled: root.tint
  }

  MultiEffect {
    anchors.fill: sourceIcon
    visible: root.tint
    source: sourceIcon
    colorization: 1.0
    colorizationColor: root.iconColor
  }
}
