import QtQuick
import qs.Commons
import '.' as ProtonComponents

// Profile connections mirror Proton's overlapping destination treatment:
// the country stays readable behind, while the chosen profile identity leads.
Item {
  id: root

  property string countryCode: ''
  property string profileCategory: 'Speed'
  property color profileColor: '#C857E7'
  property color backgroundColor: Color.popups.background

  implicitWidth: Style.space(30)
  implicitHeight: Style.space(24)

  Item {
    width: Style.space(30)
    height: Style.space(24)
    anchors.centerIn: parent
    scale: Math.min(root.width / width, root.height / height)

    ProtonComponents.ProtonFlag {
      width: Style.space(18)
      height: Style.space(12)
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      countryCode: root.countryCode
      backgroundColor: root.backgroundColor
    }

    ProtonComponents.ProtonProfileIcon {
      width: Style.space(24)
      height: Style.space(16)
      anchors.right: parent.right
      anchors.top: parent.top
      category: root.profileCategory
      profileColor: root.profileColor
    }
  }
}
