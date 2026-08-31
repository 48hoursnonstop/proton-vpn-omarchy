import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons

// Renders Proton's official country flags and the Fastest/Random/Latest/Gateway
// destination marks. Country flags are 24:16; special destinations are 30:20.
Item {
  id: root

  property string countryCode: ''
  property string specialName: ''
  property color backgroundColor: Color.popups.background

  readonly property string normalizedCountryCode: {
    var code = String(countryCode || '').trim().toUpperCase()
    if (code === 'GB') code = 'UK'
    return /^[A-Z]{2}$/.test(code) ? code : ''
  }
  readonly property string normalizedSpecialName: {
    var value = String(specialName || '').trim().toLowerCase()
    switch (value) {
    case 'fastest': return 'Fastest'
    case 'random': return 'Random'
    case 'latest': return 'Latest'
    case 'gateway': return 'Gateway'
    default: return ''
    }
  }
  readonly property bool special: normalizedSpecialName !== ''
  readonly property bool darkBackground: {
    var luminance = 0.2126 * backgroundColor.r +
      0.7152 * backgroundColor.g + 0.0722 * backgroundColor.b
    return luminance < 0.5
  }
  readonly property real countryScale: Math.min(width / 24, height / 16)
  readonly property real outlineThickness: countryScale
  readonly property color outlineColor: darkBackground
    ? '#0DFFFFFF' : '#200C0C14'
  readonly property url requestedSource: special
    ? Qt.resolvedUrl('../assets/windows/flags/special/' +
        (darkBackground ? 'dark/' : 'light/') + normalizedSpecialName + '.svg')
    : normalizedCountryCode !== ''
      ? Qt.resolvedUrl('../assets/windows/flags/countries/' +
          normalizedCountryCode + '.svg')
      : ''
  readonly property bool countryReady: normalizedCountryCode !== '' &&
    countryImage.status === Image.Ready

  implicitWidth: Style.space(special ? 30 : 24)
  implicitHeight: Style.space(special ? 20 : 16)

  Image {
    id: genericFlag
    z: 0
    anchors.fill: parent
    visible: root.special || !root.countryReady
    source: root.special ? root.requestedSource
      : Qt.resolvedUrl('../assets/windows/flags/Placeholder.svg')
    fillMode: Image.Stretch
    asynchronous: false
    cache: true
    smooth: true
    sourceSize.width: Math.round(root.width * Screen.devicePixelRatio)
    sourceSize.height: Math.round(root.height * Screen.devicePixelRatio)
  }

  Rectangle {
    id: countryMask
    anchors.fill: parent
    radius: 3 * root.countryScale
    antialiasing: true
    visible: false
    layer.enabled: true
  }

  Item {
    id: countryLayer
    z: 2
    anchors.fill: parent
    visible: root.countryReady
    layer.enabled: visible
    layer.smooth: true
    layer.effect: MultiEffect {
      maskEnabled: true
      maskSource: countryMask
      maskThresholdMin: 0.5
      maskSpreadAtMin: 0.02
    }

    Image {
      id: countryImage
      anchors.fill: parent
      source: !root.special && root.normalizedCountryCode !== ''
        ? root.requestedSource : ''
      fillMode: Image.Stretch
      asynchronous: false
      cache: true
      smooth: true
      sourceSize.width: Math.round(root.width * Screen.devicePixelRatio)
      sourceSize.height: Math.round(root.height * Screen.devicePixelRatio)
    }
  }

  // The Windows control adds a one-unit rounded outline outside country
  // artwork (Margin=-1, Padding=1, CornerRadius=4). The SVG's own clip keeps
  // the inner flag at radius 3/4 while this surface supplies theme contrast.
  Rectangle {
    z: 1
    visible: root.countryReady
    anchors.fill: countryLayer
    anchors.margins: -root.outlineThickness
    color: root.outlineColor
    radius: 4 * root.countryScale
  }
}
