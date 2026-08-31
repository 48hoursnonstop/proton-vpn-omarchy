import QtQuick
import Quickshell

ShellRoot {
  property var savedProfile: null

  ProtonStrings {
    id: strings
    localeName: 'es-MX'
  }

  QtObject {
    id: mockState
    signal requestFinished(string requestId, string method, bool ok, string errorCode)
    property bool signedIn: true
    property bool operationBusy: false
    property bool storeOperationBusy: false
    property bool tunnelOperationBusy: false
    property bool locationsLoading: false
    property bool serversLoading: false
    property bool serverLookupLoading: false
    property int serverTotal: 1
    property string desiredServerLookupQuery: ''
    property var remoteSearchServer: null
    property var profiles: []
    property var installedApps: []
    property var availableProfileProtocols: ['smart', 'protun-tls']
    property var defaultConnection: ({ type: 'fastest' })
    property var servers: [{
      id: 'mx-one', name: 'MX#1', country_code: 'MX', country_name: 'Mexico',
      city: 'Mexico City', load: 20, enabled: true, maintenance: false,
      p2p: false, tor: false, secure_core: false, gateway_name: ''
    }]
    property var countries: [{
      code: 'MX', name: 'Mexico', standard: true, secure_core: false,
      p2p: true, tor: false, server_count: 20, available_server_count: 19,
      states: [{ name: 'Jalisco', cities: ['Guadalajara'] }],
      cities: ['Mexico City'], p2p_states: [], p2p_cities: [],
      secure_core_entries: []
    }]
    property var gateways: []

    function hasCapability(_capability) { return false }
    function loadProfiles(_offset) {}
    function loadLocations() {}
    function loadServers(_query, _country, _gateway, _feature, _scope) {}
    function loadMoreServers() {}
    function lookupServer(_query) {}
    function loadApps(_query) {}
    function saveProfile(profile) {
      savedProfile = profile
      return 'save-1'
    }
    function duplicateProfile(_id, _name) { return 'duplicate-1' }
    function deleteProfile(_id) { return 'delete-1' }
    function setDefaultConnection(_selection) { return 'default-1' }
    function connectProfile(_profile) {}
  }

  FloatingWindow {
    visible: true
    implicitWidth: 380
    implicitHeight: Math.max(600, profilesView.implicitHeight)
    color: 'black'

    ProtonProfilesView {
      id: profilesView
      anchors.fill: parent
      vpnState: mockState
      strings: strings
    }
  }

  Timer {
    interval: 100
    running: true
    onTriggered: {
      profilesView.editProfile({
        id: 'existing', name: 'Guadalajara', targetKind: 'city',
        selectionStrategy: 'fastest', countryCode: 'MX', countryName: 'México',
        state: 'Jalisco', city: 'Guadalajara'
      })
      profilesView.targetKind = 'random'
      if (!profilesView.targetValid())
        throw new Error('Legacy random profiles must remain editable')
      profilesView.targetKind = 'city'
      profilesView.openLocationPicker()
      Qt.callLater(function() {
        if (!profilesView.pickerVisible)
          throw new Error('Profile destination selector did not open')
        if (!profilesView.navigateBack() || !profilesView.pickerVisible)
          throw new Error('Inner country page did not navigate back independently')
        if (!profilesView.navigateBack() || profilesView.pickerVisible)
          throw new Error('Second back did not close the destination selector')

        profilesView.applyLocation({
          targetKind: 'country', selectionStrategy: 'random',
          excludeMyCountry: false, countryCode: 'MX', countryName: 'México'
        })
        if (profilesView.targetKind !== 'country' ||
            profilesView.selectionStrategy !== 'random' ||
            profilesView.countryCode !== 'MX')
          throw new Error('Scoped random destination was not retained by the editor')

        profilesView.applyLocation({
          targetKind: 'fastest', selectionStrategy: 'fastest',
          excludeMyCountry: true
        })
        if (!profilesView.excludeMyCountry || profilesView.countryCode !== '')
          throw new Error('Fastest-excluding destination retained stale location fields')

        profilesView.applyLocation({
          targetKind: 'fastest', selectionStrategy: 'random',
          excludeMyCountry: false
        })
        if (profilesView.targetSummary(null) !== 'País aleatorio')
          throw new Error('Global random target has the wrong summary')

        console.log('PROFILE_DESTINATION_QML', true, true, true)
        Qt.quit()
      })
    }
  }
}
