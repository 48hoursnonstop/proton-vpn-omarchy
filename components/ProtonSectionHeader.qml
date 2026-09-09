import QtQuick
import qs.Commons
import qs.Ui as Ui

Ui.PanelSectionHeader {
  width: parent ? parent.width : implicitWidth
  color: ProtonUi.secondaryText(foreground)
  topPadding: Style.space(8)
  bottomPadding: Style.space(4)
  wrapMode: Text.Wrap
  lineHeight: 1.2
  Accessible.role: Accessible.Heading
}
