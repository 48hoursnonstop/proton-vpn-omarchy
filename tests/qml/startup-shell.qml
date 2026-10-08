import QtQuick
import Quickshell

ShellRoot {
  id: suite
  QtObject {
    id: state
    property bool lifecyclePreferenceKnown: false
    property bool cachedStartWithOmarchy: true
    property bool onboardingComplete: true
    property bool autoConnect: true
    property bool backendDemanded: false
    property int activations: 0
    function activateBackend() { activations++; backendDemanded = true }
  }
  ProtonStartup { id: startup; vpnState: state }
  function check(ok, message) {
    if (!ok) { Qt.callLater(Qt.quit); throw new Error('STARTUP: ' + message) }
  }
  Timer {
    interval: 50
    running: true
    onTriggered: {
      check(state.activations === 0, 'unknown lifecycle preference cannot wake the agent')
      state.cachedStartWithOmarchy = false
      state.lifecyclePreferenceKnown = true
      check(state.activations === 0, 'persisted opt-out wins over default startup value')
      state.onboardingComplete = false
      state.cachedStartWithOmarchy = true
      check(state.activations === 0, 'onboarding must be complete')
      state.autoConnect = false
      state.onboardingComplete = true
      check(state.activations === 0, 'no eager connector when auto-connect is disabled')
      state.autoConnect = true
      check(state.activations === 1 && state.backendDemanded, 'late settings trigger startup without opening a panel')
      startup.activateIfRequested()
      state.cachedStartWithOmarchy = false
      state.cachedStartWithOmarchy = true
      check(state.activations === 1, 'no duplicate initialization from later signals')
      console.log('STARTUP_QML true')
      Qt.quit()
    }
  }
}
