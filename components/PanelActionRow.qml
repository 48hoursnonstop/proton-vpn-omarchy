import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui

// Small shell-native action row. It intentionally uses Quattro's CursorSurface
// and spacing/font system so keyboard and pointer states look like first-party
// panels rather than desktop-app settings cards.
CursorSurface {
  id: root

  property string iconText: ''
  property string iconName: ''
  property url iconSource: ''
  property bool iconTint: true
  property real iconSize: Style.font.iconLarge
  property string title: ''
  property string subtitle: ''
  property string detail: ''
  property string detailIconName: ''
  property bool toggleVisible: false
  property bool checked: false
  property bool busy: false
  property bool hasKeyboardCursor: false
  property color rowForeground: Color.foreground
  property color dimForeground: Qt.darker(rowForeground, 1.55)
  property color iconForeground: checked ? Color.accent : dimForeground
  property string rowFontFamily: Style.font.family

  signal activated()
  signal hovered()

  hasCursor: hasKeyboardCursor && enabled
  foreground: rowForeground
  fill: Style.hoverFillFor(rowForeground, Color.accent)
  currentFill: Style.selectedFillFor(rowForeground, Color.accent)
  implicitHeight: rowContent.implicitHeight + Style.spacing.rowPaddingX
  opacity: enabled ? 1.0 : 0.45

  Behavior on opacity {
    NumberAnimation { duration: 120 }
  }

  RowLayout {
    id: rowContent
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: Style.space(10)
    anchors.rightMargin: Style.space(10)
    spacing: Style.space(9)

    Item {
      Layout.preferredWidth: Style.space(24)
      Layout.preferredHeight: root.iconSize
      Layout.alignment: Qt.AlignVCenter

      ProtonMobileIcon {
        anchors.centerIn: parent
        iconName: root.iconName
        sourceOverride: root.iconSource
        iconColor: root.iconForeground
        iconSize: root.iconSize
        tint: root.iconTint
      }

      Text {
        visible: root.iconName === '' && String(root.iconSource).length === 0
        anchors.fill: parent
        text: root.iconText
        color: root.iconForeground
        font.family: root.rowFontFamily
        font.pixelSize: Style.font.heading
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.space(1)

      Text {
        Layout.fillWidth: true
        text: root.title
        color: root.rowForeground
        font.family: root.rowFontFamily
        font.pixelSize: Style.font.body
        elide: Text.ElideRight
      }

      Text {
        Layout.fillWidth: true
        visible: root.subtitle !== ''
        text: root.subtitle
        color: root.dimForeground
        font.family: root.rowFontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }
    }

    RowLayout {
      visible: !root.toggleVisible &&
        (root.detail !== '' || root.detailIconName !== '')
      Layout.alignment: Qt.AlignVCenter
      spacing: Style.space(2)

      Text {
        visible: root.detail !== ''
        text: root.detail
        color: root.dimForeground
        font.family: root.rowFontFamily
        font.pixelSize: Style.font.caption
      }

      ProtonMobileIcon {
        iconName: root.detailIconName
        iconColor: root.checked ? Color.accent : root.dimForeground
        iconSize: Style.font.iconSmall
      }
    }

    ToggleSwitch {
      id: rowSwitch
      visible: root.toggleVisible
      Layout.alignment: Qt.AlignVCenter
      checked: root.checked
      busy: root.busy || !root.enabled
      foreground: root.rowForeground
      onHovered: function(on) { if (on) root.hovered() }
      onToggled: root.activated()
    }
  }

  MouseArea {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    anchors.rightMargin: root.toggleVisible
      ? rowSwitch.width + Style.space(10) : 0
    enabled: root.enabled && !root.busy
    hoverEnabled: true
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onEntered: root.hovered()
    onClicked: root.activated()
  }
}
