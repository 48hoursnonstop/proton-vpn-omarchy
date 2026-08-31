import QtQuick
import Quickshell
import 'i18n/Search.js' as Search

ShellRoot {
  property var selected: null

  ProtonStrings {
    id: strings
    localeName: 'es-MX'
  }

  QtObject {
    id: mockState
    property bool signedIn: true
    property bool tunnelOperationBusy: false
    property bool locationsLoading: false
    property bool serversLoading: false
    property bool serverLookupLoading: false
    property int serverTotal: 0
    property string desiredServerLookupQuery: ''
    property var remoteSearchServer: null
    property var servers: [{
      id: 'mx-one', name: 'MX#1', country_code: 'MX', country_name: 'Mexico',
      city: 'Mexico City', load: 20, enabled: true, maintenance: false,
      p2p: false, tor: false, secure_core: false, gateway_name: ''
    }]
    property var countries: [{
      code: 'MX', name: 'Mexico', standard: true, secure_core: true,
      p2p: true, tor: false, server_count: 20, available_server_count: 19,
      states: [{ name: 'Jalisco', cities: ['Guadalajara'] }],
      cities: ['Mexico City'],
      p2p_states: [], p2p_cities: [], secure_core_entries: []
    }]
    property var gateways: [{
      name: 'ACME', server_count: 2, available_server_count: 2
    }]
    property string lastFeature: ''
    property string lastScope: ''

    function loadLocations() {}
    function loadServers(_query, _country, _gateway, feature, scope) {
      lastFeature = feature
      lastScope = scope
    }
    function loadMoreServers() {}
    function lookupServer(_query) {}
    function connectCountry(_country, _feature) {}
    function connectLocation(_country, _selection, _feature) {}
    function connectGateway(_gateway) {}
    function connectServer(_server) {}
  }

  FloatingWindow {
    visible: true
    implicitWidth: 380
    implicitHeight: Math.max(500, locations.implicitHeight)
    color: 'black'

    ProtonLocationsView {
      id: locations
      anchors.fill: parent
      vpnState: mockState
      strings: strings
      selectionMode: true
      onLocationSelected: function(value) { selected = value }
    }
  }

  Timer {
    interval: 80
    running: true
    onTriggered: {
      if (Search.canonicalServerLookup('us-ca-42') !== 'US-CA#42')
        throw new Error('Common server-name separators were not canonicalized')
      locations.setSearchQuery('México')
      Qt.callLater(function() {
        var results = locations.searchResults
        var country = null
        var serverCount = 0
        for (var index = 0; index < results.length; ++index) {
          if (results[index].resultType === 'country') country = results[index]
          if (results[index].resultType === 'server') ++serverCount
        }
        if (!country || country.title !== 'México' || serverCount !== 0)
          throw new Error('Country searches must stay localized logical targets')
        locations.chooseSearchResult(country)
        if (!locations.showingServers || locations.selectedKind !== 'country' || selected)
          throw new Error('Profile country search must drill into the country')
        if (!locations.navigateBack())
          throw new Error('Country drill-down must be independently navigable')

        locations.setSearchQuery('Guadalajara')
        Qt.callLater(function() {
          var city = null
          for (var index = 0; index < locations.searchResults.length; ++index) {
            if (locations.searchResults[index].resultType === 'city')
              city = locations.searchResults[index]
          }
          if (!city) throw new Error('City result missing')
          locations.chooseSearchResult(city)
          if (!selected || selected.targetKind !== 'city' ||
              selected.countryCode !== 'MX' || selected.city !== 'Guadalajara')
            throw new Error('Profile destination lost its logical city target')

          selected = null
          locations.clearSearch()
          locations.chooseBestLocation('fastest', true)
          if (!selected || selected.targetKind !== 'fastest' ||
              !selected.excludeMyCountry)
            throw new Error('Fastest-excluding-my-country target is missing')

          selected = null
          locations.openLocation(mockState.countries[0], 'country')
          locations.chooseBestLocation('random', false)
          if (!selected || selected.targetKind !== 'country' ||
              selected.countryCode !== 'MX' ||
              selected.selectionStrategy !== 'random')
            throw new Error('Random server within a country is not represented')

          locations.selectSection('gateways')
          locations.setSearchQuery('ACME')
          locations.requestServers()
          if (mockState.lastFeature !== 'all' || mockState.lastScope !== 'gateways')
            throw new Error('Gateway search leaked into the consumer catalog')
          console.log('LOCATION_SEARCH_QML', true, true, true)
          Qt.quit()
        })
      })
    }
  }
}
