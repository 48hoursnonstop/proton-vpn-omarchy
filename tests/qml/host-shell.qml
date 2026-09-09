import QtQuick
import Quickshell

// Wayland import/lifecycle smoke check. The host remains closed throughout.
ShellRoot {
  ProtonPanel { id: host }
  Timer {
    interval: 100
    running: true
    onTriggered: {
      host.setRoute('settings')
      console.log('HOST_QML', !host.opened && host.route === 'settings')
      Qt.quit()
    }
  }
}
