import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons

// Official Proton Android navigation glyphs, recolored by Quattro at runtime.
// The 24dp source canvas is decoded at the current device scale so fractional
// display scaling stays sharp without forcing a fixed desktop pixel size.
Item {
  id: root

  property string iconName: ''
  property bool selected: false
  property color iconColor: Color.foreground
  property real iconSize: Style.font.iconLarge

  readonly property string variantSuffix: selected ? '_filled' : ''
  // Qt SVG currently drops the two Android clip-path outline assets. Their
  // checked-in PNGs are lossless 192px renders of the same pinned vectors;
  // display geometry still comes from iconSize and devicePixelRatio below.
  readonly property bool rasterizedOutline: !selected &&
    (iconName === 'house' || iconName === 'window_terminal')
  readonly property string assetName:
    'ic_proton_' + iconName + (selected ? '_filled' : '') +
      ((!selected && (iconName === 'house' || iconName === 'window_terminal'))
        ? '.png' : '.svg')

  implicitWidth: iconSize
  implicitHeight: iconSize

  Image {
    id: sourceIcon
    anchors.fill: parent
    source: Qt.resolvedUrl('../assets/navigation/' + root.assetName)
    fillMode: Image.PreserveAspectFit
    asynchronous: false
    cache: true
    sourceSize.width: Math.round(root.iconSize * Screen.devicePixelRatio)
    sourceSize.height: Math.round(root.iconSize * Screen.devicePixelRatio)
    visible: false
    layer.enabled: true
  }

  MultiEffect {
    anchors.fill: sourceIcon
    source: sourceIcon
    colorization: 1.0
    colorizationColor: root.iconColor
  }
}
