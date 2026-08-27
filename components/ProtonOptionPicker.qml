import QtQuick
import qs.Commons

// Inline mobile-style single-choice list. Callers provide exact choices;
// opening a row never mutates state and choosing one value takes one action.
Item {
  id: root

  property var options: []
  property var currentValue: null
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  property bool busy: false

  signal selected(var value)

  implicitHeight: choices.implicitHeight

  Column {
    id: choices
    width: parent.width
    spacing: Style.space(2)

    Repeater {
      model: root.options

      delegate: PanelActionRow {
        required property var modelData

        width: choices.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconName: String(modelData.iconName || modelData.icon || '')
        title: String(modelData.label || modelData.value || '')
        subtitle: String(modelData.subtitle || '')
        detailIconName: root.currentValue === modelData.value ? 'checkmark' : ''
        checked: root.currentValue === modelData.value
        busy: root.busy
        onActivated: root.selected(modelData.value)
      }
    }
  }
}
