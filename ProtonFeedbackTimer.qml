import QtQuick

// Lives with AgentState so navigating away pauses, rather than resets, the budget.
QtObject {
  id: root
  property bool exposed: false
  property bool available: false
  property string sessionId: ''
  property int timeoutSeconds: 10
  property int elapsedMs: 0
  property bool expired: false
  readonly property int budgetMs: (timeoutSeconds >= 1 && timeoutSeconds <= 300
    ? timeoutSeconds : 10) * 1000
  signal dismissed()

  onSessionIdChanged: { elapsedMs = 0; expired = false }
  readonly property Timer clock: Timer {
    interval: 100
    repeat: true
    running: root.exposed && root.available && !root.expired && root.sessionId !== ''
    onTriggered: {
      root.elapsedMs += interval
      if (root.elapsedMs >= root.budgetMs) {
        root.expired = true
        root.dismissed()
      }
    }
  }
}
