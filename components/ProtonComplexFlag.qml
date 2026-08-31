import QtQuick
import qs.Commons
import '.' as ProtonComponents

// Secure Core uses Proton's two-flag composition: entry behind, exit in front.
Item {
  id: root

  property string exitCountryCode: ''
  property string entryCountryCode: ''
  property color backgroundColor: Color.popups.background

  implicitWidth: Style.space(30)
  implicitHeight: Style.space(24)

  Item {
    id: canvas
    width: Style.space(30)
    height: Style.space(24)
    anchors.centerIn: parent
    scale: Math.min(root.width / width, root.height / height)

    ProtonComponents.ProtonFlag {
      width: Style.space(18)
      height: Style.space(12)
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      countryCode: root.entryCountryCode
      backgroundColor: root.backgroundColor
    }

    Rectangle {
      x: Style.space(4)
      y: Style.space(12)
      width: Style.space(14)
      height: Style.space(6)
      color: '#660C0C14'
      radius: Style.space(3)
    }

    ProtonComponents.ProtonFlag {
      width: Style.space(24)
      height: Style.space(16)
      anchors.right: parent.right
      anchors.top: parent.top
      countryCode: root.exitCountryCode
      backgroundColor: root.backgroundColor
    }
  }
}
