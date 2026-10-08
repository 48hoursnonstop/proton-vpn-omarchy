import QtQuick
import Quickshell
import qs.Ui

// Wayland import/lifecycle smoke check. The host remains closed throughout.
ShellRoot {
  id: suite
  property int suppressionCalls: 0
  property bool requestedSuppression: true
  PluginBarApi {
    id: barApi
    pluginId: 'proton.omarchy'
    moduleName: 'proton.omarchy'
    _setCenterHoverRevealSuppressed: function(value) {
      suite.suppressionCalls++
      suite.requestedSuppression = value
    }
  }
  ProtonPanel { id: host; bar: barApi }
  Timer {
    interval: 100
    running: true
    onTriggered: {
      host.setRoute('settings')
      var previousCalls = suite.suppressionCalls
      // Exercise the real read-only facade without opening a desktop surface.
      host.openedChanged()
      if (suite.suppressionCalls !== previousCalls + 1 || suite.requestedSuppression)
        throw new Error('Host must use the bar facade setter when closing')
      console.log('HOST_QML', !host.opened && host.route === 'settings')
      Qt.quit()
    }
  }
}
