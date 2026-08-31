import QtQuick
import qs.Commons
import '.' as ProtonComponents

// Chooses Proton's simple or Secure Core two-flag representation.
Item {
  id: root

  property string exitCountryCode: ''
  property string entryCountryCode: ''
  property color backgroundColor: Color.popups.background

  readonly property bool secureCore: entryCountryCode !== ''

  implicitWidth: Style.space(secureCore ? 30 : 24)
  implicitHeight: Style.space(secureCore ? 24 : 16)

  ProtonComponents.ProtonFlag {
    visible: !root.secureCore
    anchors.fill: parent
    countryCode: root.exitCountryCode
    backgroundColor: root.backgroundColor
  }

  ProtonComponents.ProtonComplexFlag {
    visible: root.secureCore
    anchors.fill: parent
    exitCountryCode: root.exitCountryCode
    entryCountryCode: root.entryCountryCode
    backgroundColor: root.backgroundColor
  }
}
