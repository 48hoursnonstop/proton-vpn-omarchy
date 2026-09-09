import QtQuick
import QtQuick.Controls as Controls
import qs.Commons

Controls.ScrollBar {
  id: root
  minimumSize: 0.08
  padding: Style.space(3)
  contentItem: Rectangle {
    implicitWidth: Style.space(4)
    implicitHeight: Style.space(4)
    radius: Style.cornerRadius
    color: Color.popups.text
    opacity: root.pressed ? 1 : 0.7
  }
  background: Rectangle {
    implicitWidth: Style.space(10)
    implicitHeight: Style.space(10)
    color: Style.normalFillFor(Color.popups.text, Color.accent)
  }
}
