import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

// Android's root destination model expressed with Quattro controls and tokens.
// This component owns layout only; colors, type, spacing and interaction paint
// continue to come from the active Omarchy theme.
Item {
  id: root

  property var destinations: []
  property string currentRoute: 'home'
  property color foreground: Color.foreground
  property color dim: Qt.darker(foreground, 1.55)
  property string fontFamily: Style.font.family

  signal routeRequested(string route)

  implicitHeight: content.implicitHeight

  Column {
    id: content
    width: parent.width
    spacing: Style.space(4)

    PanelSeparator {
      foreground: root.foreground
    }

    RowLayout {
      width: parent.width
      spacing: Style.space(2)

      Repeater {
        model: root.destinations

        delegate: Item {
          required property var modelData

          Layout.fillWidth: true
          Layout.minimumWidth: 0
          implicitHeight: Style.space(46)

          readonly property bool selectedRoute:
            root.currentRoute === String(modelData.route || '')

          Button {
            anchors.fill: parent
            selected: parent.selectedRoute
            foreground: root.foreground
            fontFamily: root.fontFamily
            tooltipText: String(parent.modelData.label || '')
            horizontalPadding: 0
            verticalPadding: 0
            onClicked: root.routeRequested(String(parent.modelData.route || 'home'))
          }

          Column {
            anchors.centerIn: parent
            width: parent.width - Style.space(6)
            spacing: Style.space(2)

            ProtonMobileNavIcon {
              anchors.horizontalCenter: parent.horizontalCenter
              iconName: String(parent.parent.modelData.icon || '')
              selected: parent.parent.selectedRoute
              iconColor: parent.parent.selectedRoute
                ? Style.selectedStateColor(root.foreground, Color.accent)
                : root.dim
              iconSize: Style.font.iconLarge
            }

            Text {
              width: parent.width
              text: String(parent.parent.modelData.label || '')
              color: parent.parent.selectedRoute
                ? Style.selectedStateColor(root.foreground, Color.accent)
                : root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.weight: parent.parent.selectedRoute ? Font.DemiBold : Font.Normal
              horizontalAlignment: Text.AlignHCenter
              elide: Text.ElideRight
            }
          }
        }
      }
    }
  }
}
