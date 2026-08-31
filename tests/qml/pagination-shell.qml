import QtQuick
import Quickshell

ShellRoot {
  AgentState {
    id: agentState
  }

  Timer {
    interval: 50
    running: true
    onTriggered: {
      agentState.desiredServerQuery = ''
      agentState.desiredServerCountry = 'US'
      agentState.desiredServerGateway = ''
      agentState.desiredServerFeature = 'standard'
      agentState.pendingRequests = ({ first: { method: 'servers.get' } })
      agentState.handleLine(JSON.stringify({
        v: 1, id: 'first', type: 'response', ok: true,
        result: {
          offset: 0, total: 3, query: '', country_code: 'US',
          gateway_name: '', feature: 'standard', servers: [{ id: 'one' }, { id: 'two' }]
        }
      }))
      agentState.pendingRequests = ({ second: { method: 'servers.get' } })
      agentState.handleLine(JSON.stringify({
        v: 1, id: 'second', type: 'response', ok: true,
        result: {
          offset: 2, total: 3, query: '', country_code: 'US',
          gateway_name: '', feature: 'standard', servers: [{ id: 'three' }]
        }
      }))
      agentState.profiles = [{ id: 'profile-one' }]
      agentState.pendingRequests = ({ profiles: { method: 'profiles.list' } })
      agentState.handleLine(JSON.stringify({
        v: 1, id: 'profiles', type: 'response', ok: true,
        result: {
          offset: 1, total: 2, has_more: false, store_revision: 0,
          items: [{ id: 'profile-two' }]
        }
      }))
      agentState.desiredAppQuery = ''
      agentState.installedApps = [{ id: 'app-one' }]
      agentState.installedAppTotal = 2
      agentState.pendingRequests = ({ apps: { method: 'apps.get' } })
      agentState.handleLine(JSON.stringify({
        v: 1, id: 'apps', type: 'response', ok: true,
        result: {
          offset: 1, total: 2, query: '', apps: [{ id: 'app-two' }]
        }
      }))
      console.log('PAGINATION_QML', agentState.servers.length === 3,
                  agentState.servers[2].id === 'three',
                  agentState.serverTotal === 3,
                  agentState.profiles.length === 2,
                  agentState.installedApps.length === 2)
      Qt.quit()
    }
  }
}
