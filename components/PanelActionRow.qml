import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import '.' as ProtonComponents

// Small shell-native action row. It intentionally uses Quattro's CursorSurface
// and spacing/font system so keyboard and pointer states look like first-party
// panels rather than desktop-app settings cards.
CursorSurface {
  id: root

  property string iconText: ''
  property string iconName: ''
  property url iconSource: ''
  property string flagCode: ''
  property string entryFlagCode: ''
  property string specialFlag: ''
  property string profileIconName: ''
  property color profileIconColor: '#C857E7'
  property color flagBackground: Color.popups.background
  property bool iconTint: true
  property real iconSize: Style.font.iconLarge
  property real iconWidth: iconSize
  property string title: ''
  property string subtitle: ''
  property bool subtitleWrap: false
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
  readonly property bool hasProfileIcon: profileIconName !== ''
  readonly property bool hasFlag: flagCode !== '' || specialFlag !== ''
  readonly property bool hasComplexFlag: flagCode !== '' && entryFlagCode !== ''
  readonly property bool hasGenericIcon: iconName !== '' ||
    String(iconSource).length > 0
  readonly property real resolvedIconWidth: hasProfileIcon ? Style.space(30)
    : hasComplexFlag ? Style.space(30)
    : hasFlag ? Style.space(30) : iconWidth
  readonly property real resolvedIconHeight: hasProfileIcon ? Style.space(20)
    : hasComplexFlag ? Style.space(24)
    : hasFlag ? Style.space(specialFlag !== '' ? 20 : 16) : iconSize

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
      Layout.preferredWidth: Math.max(Style.space(24), root.resolvedIconWidth)
      Layout.preferredHeight: Math.max(Style.space(20), root.resolvedIconHeight)
      Layout.alignment: Qt.AlignVCenter

      ProtonComponents.ProtonProfileIcon {
        visible: root.hasProfileIcon
        anchors.centerIn: parent
        category: root.profileIconName
        profileColor: root.profileIconColor
      }

      ProtonComponents.ProtonFlag {
        visible: !root.hasProfileIcon && root.hasFlag && !root.hasComplexFlag
        width: Style.space(30)
        height: Style.space(20)
        anchors.centerIn: parent
        countryCode: root.flagCode
        specialName: root.specialFlag
        backgroundColor: root.flagBackground
      }

      ProtonComponents.ProtonComplexFlag {
        visible: !root.hasProfileIcon && root.hasComplexFlag
        anchors.centerIn: parent
        exitCountryCode: root.flagCode
        entryCountryCode: root.entryFlagCode
        backgroundColor: root.flagBackground
      }

      ProtonComponents.ProtonMobileIcon {
        visible: !root.hasProfileIcon && !root.hasFlag && root.hasGenericIcon
        anchors.centerIn: parent
        iconName: root.iconName
        sourceOverride: root.iconSource
        iconColor: root.iconForeground
        iconSize: root.iconSize
        iconWidth: root.iconWidth
        tint: root.iconTint
      }

      Text {
        visible: !root.hasProfileIcon && !root.hasFlag && !root.hasGenericIcon
        anchors.fill: parent
        text: root.iconText
        textFormat: Text.PlainText
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
        textFormat: Text.PlainText
        color: root.rowForeground
        font.family: root.rowFontFamily
        font.pixelSize: Style.font.body
        elide: Text.ElideRight
      }

      Text {
        Layout.fillWidth: true
        visible: root.subtitle !== ''
        text: root.subtitle
        textFormat: Text.PlainText
        color: root.dimForeground
        font.family: root.rowFontFamily
        font.pixelSize: Style.font.caption
        wrapMode: root.subtitleWrap ? Text.WordWrap : Text.NoWrap
        elide: root.subtitleWrap ? Text.ElideNone : Text.ElideRight
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
        textFormat: Text.PlainText
        color: root.dimForeground
        font.family: root.rowFontFamily
        font.pixelSize: Style.font.caption
      }

      ProtonComponents.ProtonMobileIcon {
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
