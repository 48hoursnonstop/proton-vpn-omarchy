import QtQuick
import qs.Commons
import '.' as ProtonComponents

// Central mapping for the category artwork used by Proton's Windows profiles.
Item {
  id: root

  property string category: 'Speed'
  property color profileColor: '#C857E7'

  readonly property string assetName: {
    switch (String(category || 'Speed')) {
    case 'Streaming': return 'streaming'
    case 'Protection': return 'shield'
    case 'Privacy': return 'eye'
    case 'Anonymous': return 'anonymous'
    case 'Terminal': return 'terminal'
    case 'Gaming': return 'gaming'
    case 'Download': return 'download'
    case 'Business': return 'business'
    case 'Shopping': return 'shopping'
    case 'Security': return 'security'
    case 'Browsing': return 'browsing'
    default: return 'bolt'
    }
  }

  // Windows gives profile and destination marks the same 30x20 row footprint.
  implicitWidth: Style.space(30)
  implicitHeight: Style.space(20)

  ProtonComponents.ProtonMobileIcon {
    anchors.fill: parent
    sourceOverride: Qt.resolvedUrl('../assets/windows/profiles/profile_' +
      root.assetName + '_icon.webp')
    iconColor: root.profileColor
    iconSize: parent.height
    iconWidth: parent.width
    tint: true
  }
}
