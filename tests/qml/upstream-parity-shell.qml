import QtQuick
import Quickshell
import 'components'

ShellRoot {
  id: suite
  property int phase: 0
  property int dismissals: 0
  property bool finished: false
  property int pausedAt: 0
  ShowcaseState { id: state; hostCountryCode: 'US'; hostCountryName: 'United States' }
  ProtonStrings { id: strings; localeName: 'en' }
  ProtonFeedbackTimer {
    id: budget
    sessionId: 'first'
    timeoutSeconds: 1
    available: true
    exposed: false
    onDismissed: suite.dismissals++
  }
  FloatingWindow {
    visible: true
    implicitWidth: 420
    implicitHeight: 640
    ProtonConnectionDetailsView { id: details; width: parent.width; vpnState: state; strings: strings }
    ProtonLocationsView { id: locations; visible: false; width: parent.width; vpnState: state; strings: strings }
  }
  function check(ok, message) {
    if (!ok) { finished = true; Qt.callLater(Qt.quit); throw new Error('UPSTREAM: ' + message) }
  }
  function find(item, name) {
    if (item.objectName === name) return item
    for (var i = 0; i < item.children.length; ++i) {
      var result = find(item.children[i], name)
      if (result) return result
    }
    return null
  }
  Timer {
    interval: 120
    repeat: true
    running: !finished
    onTriggered: {
      switch (phase++) {
      case 0:
        check(budget.elapsedMs === 0 && dismissals === 0, 'hidden feedback does not consume time')
        var row = find(details, 'smart-routing-details')
        check(row.visible && row.subtitle.indexOf('United States') >= 0, 'physical host is visible in details')
        check(state.countryCode === 'CH' && state.entryCountryCode === 'IS', 'exit and entry remain distinct')
        var subtitle = locations.serverSubtitle({ city: 'Buenos Aires', load: 20, host_country_code: 'US', host_country_name: 'United States' })
        check(subtitle.indexOf('Physical location: United States') >= 0, 'server lists disclose physical host')
        check(locations.countrySubtitle({ smart_routing_countries: [{code: 'US', name: 'United States'}, {code: 'CL', name: 'Chile'}] }).indexOf('Chile') >= 0,
          'country groups retain all host countries')
        state.hostCountryCode = ''
        budget.exposed = true
        break
      case 3:
        check(!find(details, 'smart-routing-details').visible, 'native servers do not show Smart Routing')
        check(budget.elapsedMs > 0 && budget.elapsedMs < 1000, 'visible budget advances')
        budget.exposed = false
        pausedAt = budget.elapsedMs
        break
      case 7:
        check(budget.elapsedMs === pausedAt && dismissals === 0, 'navigation pauses the same session budget')
        budget.exposed = true
        break
      case 17:
        check(budget.expired && dismissals === 1, 'expires once after accumulated visible time')
        budget.exposed = false
        budget.exposed = true
        break
      case 20:
        check(dismissals === 1, 'reopening cannot repeat dismissal')
        budget.sessionId = 'second'
        budget.available = false
        break
      case 22:
        check(!budget.expired && budget.elapsedMs === 0, 'reconnect resets, unavailable feedback stays idle')
        budget.timeoutSeconds = -2
        check(budget.budgetMs === 10000, 'invalid duration falls back to ten seconds')
        strings.localeName = 'es-MX'
        state.hostCountryCode = 'US'
        break
      case 23:
        check(find(details, 'smart-routing-details').subtitle.indexOf('Ubicación física: Estados Unidos') >= 0,
          'physical host uses Spanish country names')
        finished = true
        console.log('UPSTREAM_QML', true)
        Qt.quit()
      }
    }
  }
}
