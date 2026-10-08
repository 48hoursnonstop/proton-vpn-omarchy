import QtQuick

// The agent owns auto-connect and its retry/cancellation policy. The bar only
// requests initialization once the user's persisted startup choice is known.
QtObject {
  id: root
  required property var vpnState

  function activateIfRequested() {
    if (!vpnState.lifecyclePreferenceKnown || !vpnState.cachedStartWithOmarchy ||
        !vpnState.onboardingComplete || !vpnState.autoConnect ||
        vpnState.backendDemanded) return
    vpnState.activateBackend()
  }

  Component.onCompleted: Qt.callLater(activateIfRequested)

  property Connections stateSignals: Connections {
    target: root.vpnState
    function onLifecyclePreferenceKnownChanged() { root.activateIfRequested() }
    function onCachedStartWithOmarchyChanged() { root.activateIfRequested() }
    function onOnboardingCompleteChanged() { root.activateIfRequested() }
    function onAutoConnectChanged() { root.activateIfRequested() }
  }
}
