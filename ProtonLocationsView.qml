import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import 'components'
import 'i18n/Search.js' as Search

Item {
  id: root

  property QtObject vpnState: null
  property QtObject strings: null
  property color foreground: Color.foreground
  property color urgent: Color.urgent
  property color dim: Qt.darker(foreground, 1.55)
  property string fontFamily: Style.font.family
  property string section: 'countries'
  property string feature: 'standard'
  property bool sectionSwitcherVisible: true
  property bool selectionMode: false
  property var selectedLocation: null
  property string selectedKind: ''
  property var currentSelection: null
  property bool restoreSelectionPending: false

  signal locationSelected(var selection)

  readonly property string searchQuery: searchField.text.trim()
  readonly property bool searching: selectedLocation === null && searchQuery.length > 0
  readonly property bool showingServers: selectedLocation !== null
  readonly property bool subpageActive: selectedLocation !== null
  readonly property var baseLocations: section === 'gateways'
    ? (vpnState ? vpnState.gateways : [])
    : (vpnState ? vpnState.countries : [])
  readonly property var filteredLocations: filterLocations()
  readonly property var logicalTargets: buildLogicalTargets()
  readonly property var searchResults: buildSearchResults()

  implicitHeight: content.implicitHeight

  function label(key) {
    return strings ? strings.text(key) : key
  }

  function countryDisplayName(country) {
    if (!country) return ''
    var code = String(country.code || country.country_code || '')
    var fallback = String(country.name || country.country_name || code)
    return strings && strings.countryName
      ? strings.countryName(code, fallback) : fallback
  }

  function countryAliases(country) {
    if (!country) return []
    var code = String(country.code || country.country_code || '')
    var fallback = String(country.name || country.country_name || code)
    return strings && strings.countrySearchNames
      ? strings.countrySearchNames(code, fallback)
      : [fallback, code]
  }

  function supportsFeature(country) {
    if (!country) return false
    if (feature === 'standard') return country.standard !== false
    return !!country[feature]
  }

  function targetKindForFeature(locationKind) {
    if (feature === 'secure_core') return 'secureCore'
    if (feature === 'p2p') return 'p2p'
    if (feature === 'tor') return 'tor'
    return String(locationKind || 'fastest')
  }

  function currentStrategy() {
    if (!currentSelection) return 'fastest'
    if (String(currentSelection.targetKind || '') === 'random') return 'random'
    return String(currentSelection.selectionStrategy || 'fastest')
  }

  function currentGlobalMatches(strategy, excludingMine) {
    if (!currentSelection) return false
    var expectedKind = targetKindForFeature('fastest')
    var actualKind = String(currentSelection.targetKind || 'fastest')
    if (strategy === 'random' && feature === 'standard' && actualKind === 'random')
      actualKind = 'fastest'
    return actualKind === expectedKind &&
      String(currentSelection.countryCode || '') === '' &&
      String(currentSelection.gatewayName || '') === '' &&
      currentStrategy() === strategy &&
      !!currentSelection.excludeMyCountry === !!excludingMine
  }

  function currentLocationMatches(strategy) {
    if (!currentSelection || !selectedLocation) return false
    if (selectedKind === 'gateway') {
      return String(currentSelection.gatewayName || '') ===
          String(selectedLocation.name || '') &&
        String(currentSelection.serverName || '') === '' &&
        currentStrategy() === strategy
    }
    return String(currentSelection.countryCode || '').toUpperCase() ===
        String(selectedLocation.code || '').toUpperCase() &&
      String(currentSelection.state || '') === '' &&
      String(currentSelection.city || '') === '' &&
      String(currentSelection.serverName || '') === '' &&
      currentStrategy() === strategy
  }

  function currentServerMatches(server) {
    return !!currentSelection && !!server &&
      String(currentSelection.serverName || '').toLowerCase() ===
        String(server.name || '').toLowerCase()
  }

  function sortSearchEntries(left, right) {
    var rankDifference = Number(left.rank || 0) - Number(right.rank || 0)
    if (rankDifference !== 0) return rankDifference
    var leftTitle = Search.normalize(left.title)
    var rightTitle = Search.normalize(right.title)
    return leftTitle < rightTitle ? -1 : leftTitle > rightTitle ? 1 : 0
  }

  function sectionedSearchResults(sectionKey, items, output) {
    if (items.length === 0) return
    output.push({ resultType: 'header', title: label(sectionKey) })
    for (var index = 0; index < items.length; ++index) output.push(items[index])
  }

  function searchableServers() {
    var output = []
    var source = vpnState && Array.isArray(vpnState.servers) ? vpnState.servers : []
    for (var index = 0; index < source.length; ++index) {
      var server = source[index]
      if (serverMatchesCurrentSearch(server) &&
          Search.matchRank(searchQuery, [server.name]) >= 0) output.push(server)
    }
    var remote = vpnState ? vpnState.remoteSearchServer : null
    if (remote && serverMatchesCurrentSearch(remote) &&
        Search.matchRank(searchQuery, [remote.name]) >= 0) {
      var duplicate = output.some(function(item) {
        return String(item.id || item.name) === String(remote.id || remote.name)
      })
      if (!duplicate) output.push(remote)
    }
    return output
  }

  function serverMatchesCurrentSearch(server) {
    if (!server) return false
    var gateway = String(server.gateway_name || '')
    if (section === 'gateways') return gateway.length > 0
    if (gateway.length > 0) return false
    if (feature === 'secure_core') return !!server.secure_core
    if (feature === 'p2p') return !!server.p2p
    if (feature === 'tor') return !!server.tor
    return !server.secure_core && !server.restricted && !server.partner
  }

  function buildSearchResults() {
    if (!searching) return []
    var countries = []
    var states = []
    var cities = []
    var gateways = []
    var servers = []
    var output = []

    if (section === 'gateways') {
      var gatewaySource = vpnState && Array.isArray(vpnState.gateways)
        ? vpnState.gateways : []
      for (var gatewayIndex = 0; gatewayIndex < gatewaySource.length; ++gatewayIndex) {
        var gateway = gatewaySource[gatewayIndex]
        var gatewayRank = Search.matchRank(searchQuery, [gateway.name])
        if (gatewayRank >= 0) gateways.push({
          resultType: 'gateway', rank: gatewayRank, gateway: gateway,
          title: String(gateway.name || ''),
          subtitle: String(gateway.available_server_count || 0) + ' / ' +
            String(gateway.server_count || 0) + ' ' + label('servers').toLowerCase()
        })
      }
    } else {
      var countrySource = vpnState && Array.isArray(vpnState.countries)
        ? vpnState.countries : []
      for (var countryIndex = 0; countryIndex < countrySource.length; ++countryIndex) {
        var country = countrySource[countryIndex]
        if (!supportsFeature(country)) continue
        var displayName = countryDisplayName(country)
        var countryRank = Search.matchRank(searchQuery, countryAliases(country))
        if (countryRank >= 0) countries.push({
          resultType: 'country', rank: countryRank, country: country,
          title: displayName,
          subtitle: String(country.available_server_count || 0) + ' / ' +
            String(country.server_count || 0) + ' ' + label('servers').toLowerCase()
        })

        if (feature !== 'standard' && feature !== 'p2p') continue
        var stateKey = feature === 'p2p' ? 'p2p_states' : 'states'
        var cityKey = feature === 'p2p' ? 'p2p_cities' : 'cities'
        var stateSource = Array.isArray(country[stateKey]) ? country[stateKey] : []
        for (var stateIndex = 0; stateIndex < stateSource.length; ++stateIndex) {
          var stateItem = stateSource[stateIndex]
          var stateName = String(stateItem.name || '')
          var stateRank = Search.matchRank(searchQuery, [stateName])
          if (stateRank >= 0) states.push({
            resultType: 'state', rank: stateRank, country: country,
            state: stateName, title: stateName,
            subtitle: displayName + ' · ' + label('fastest_in_state')
          })
          var stateCities = Array.isArray(stateItem.cities) ? stateItem.cities : []
          for (var nestedIndex = 0; nestedIndex < stateCities.length; ++nestedIndex) {
            var nestedCity = String(stateCities[nestedIndex] || '')
            var nestedRank = Search.matchRank(searchQuery, [nestedCity, nestedCity + ' ' + stateName])
            if (nestedRank >= 0) cities.push({
              resultType: 'city', rank: nestedRank, country: country,
              state: stateName, city: nestedCity, title: nestedCity,
              subtitle: stateName + ' · ' + displayName
            })
          }
        }
        var citySource = Array.isArray(country[cityKey]) ? country[cityKey] : []
        for (var cityIndex = 0; cityIndex < citySource.length; ++cityIndex) {
          var cityName = String(citySource[cityIndex] || '')
          var cityRank = Search.matchRank(searchQuery, [cityName])
          if (cityRank >= 0) cities.push({
            resultType: 'city', rank: cityRank, country: country,
            state: '', city: cityName, title: cityName,
            subtitle: displayName + ' · ' + label('fastest_in_city')
          })
        }
      }
    }

    var serverSource = searchableServers()
    for (var serverIndex = 0; serverIndex < serverSource.length; ++serverIndex) {
      var server = serverSource[serverIndex]
      servers.push({
        resultType: 'server', rank: Search.matchRank(searchQuery, [server.name]),
        server: server, title: String(server.name || ''),
        subtitle: server.secure_core
          ? countryDisplayName({ code: server.entry_country_code,
              name: server.entry_country_name }) + ' → ' +
            countryDisplayName({ code: server.country_code, name: server.country_name })
          : (server.city ? String(server.city) + ' · ' : '') +
            String(server.load || 0) + '%'
      })
    }

    countries.sort(sortSearchEntries)
    states.sort(sortSearchEntries)
    cities.sort(sortSearchEntries)
    gateways.sort(sortSearchEntries)
    servers.sort(sortSearchEntries)
    sectionedSearchResults('countries', countries, output)
    sectionedSearchResults('states', states, output)
    sectionedSearchResults('cities', cities, output)
    sectionedSearchResults('gateways', gateways, output)
    sectionedSearchResults('servers', servers, output)
    return output
  }

  function filterLocations() {
    var output = []
    for (var index = 0; index < baseLocations.length; ++index) {
      var item = baseLocations[index]
      if (section === 'countries' && !supportsFeature(item))
        continue
      output.push(item)
    }
    output.sort(function(left, right) {
      var leftName = section === 'countries' ? countryDisplayName(left) : String(left.name || '')
      var rightName = section === 'countries' ? countryDisplayName(right) : String(right.name || '')
      var leftNormalized = Search.normalize(leftName)
      var rightNormalized = Search.normalize(rightName)
      return leftNormalized < rightNormalized ? -1
        : leftNormalized > rightNormalized ? 1 : 0
    })
    return output
  }

  function buildLogicalTargets() {
    if (!selectedLocation || selectedKind !== 'country') return []
    var output = []
    var needle = Search.normalize(searchQuery)
    if (feature === 'secure_core') {
      var entries = Array.isArray(selectedLocation.secure_core_entries)
        ? selectedLocation.secure_core_entries : []
      for (var entryIndex = 0; entryIndex < entries.length; ++entryIndex) {
        var entry = entries[entryIndex]
        var entryName = countryDisplayName(entry)
        if (needle.length === 0 || Search.matchRank(needle, [entryName]) >= 0)
          output.push({
            kind: 'secureCore',
            entryCountryCode: String(entry.code || ''),
            entryCountryName: entryName,
            title: label('via') + ' ' + entryName,
            subtitle: label('fastest_secure_core')
          })
      }
      return output
    }
    // Windows exposes State/City for Standard and P2P. The catalog keeps the
    // two hierarchies separate so a location is never offered without an
    // eligible server. Tor stays country/server only.
    if (feature !== 'standard' && feature !== 'p2p') return output
    var stateKey = feature === 'p2p' ? 'p2p_states' : 'states'
    var cityKey = feature === 'p2p' ? 'p2p_cities' : 'cities'
    var states = Array.isArray(selectedLocation[stateKey])
      ? selectedLocation[stateKey] : []
    for (var stateIndex = 0; stateIndex < states.length; ++stateIndex) {
      var stateItem = states[stateIndex]
      var stateName = String(stateItem.name || '')
      if (needle.length === 0 || Search.matchRank(needle, [stateName]) >= 0)
        output.push({
          kind: 'state', state: stateName, city: '',
          title: stateName, subtitle: label('fastest_in_state')
        })
      var stateCities = Array.isArray(stateItem.cities) ? stateItem.cities : []
      for (var cityIndex = 0; cityIndex < stateCities.length; ++cityIndex) {
        var stateCity = String(stateCities[cityIndex] || '')
        if (needle.length === 0 || Search.matchRank(needle, [stateCity, stateCity + ' ' + stateName]) >= 0)
          output.push({
            kind: 'city', state: stateName, city: stateCity,
            title: stateCity, subtitle: stateName
          })
      }
    }
    var cities = Array.isArray(selectedLocation[cityKey])
      ? selectedLocation[cityKey] : []
    for (var index = 0; index < cities.length; ++index) {
      var cityName = String(cities[index] || '')
      if (needle.length === 0 || Search.matchRank(needle, [cityName]) >= 0)
        output.push({
          kind: 'city', state: '', city: cityName,
          title: cityName, subtitle: label('fastest_in_city')
        })
    }
    return output
  }

  function refresh() {
    if (!vpnState || !vpnState.signedIn) return
    vpnState.loadLocations()
    if (showingServers) requestServers()
  }

  function beginSelection(selection, nextSection, nextFeature) {
    currentSelection = selection || null
    restoreSelectionPending = true
    section = String(nextSection || 'countries')
    feature = String(nextFeature || 'standard')
    resetSelection()
    clearSearch()
    refresh()
    restoreSelectionPath()
  }

  function restoreSelectionPath() {
    if (!restoreSelectionPending || !currentSelection) return
    var source = section === 'gateways'
      ? (vpnState ? vpnState.gateways : [])
      : (vpnState ? vpnState.countries : [])
    var wanted = section === 'gateways'
      ? String(currentSelection.gatewayName || '')
      : String(currentSelection.countryCode || '').toUpperCase()
    if (wanted.length === 0) {
      restoreSelectionPending = false
      return
    }
    for (var index = 0; index < source.length; ++index) {
      var candidate = source[index]
      var value = section === 'gateways'
        ? String(candidate.name || '')
        : String(candidate.code || '').toUpperCase()
      if (value === wanted) {
        restoreSelectionPending = false
        openLocation(candidate, section === 'gateways' ? 'gateway' : 'country')
        return
      }
    }
  }

  function requestServers() {
    if (!vpnState) return
    var query = searchQuery
    if (!selectedLocation && query.length === 0) {
      vpnState.servers = []
      vpnState.serverTotal = 0
      vpnState.remoteSearchServer = null
      vpnState.desiredServerLookupQuery = ''
      return
    }
    var country = selectedKind === 'country' && selectedLocation
      ? String(selectedLocation.code || '') : ''
    var gateway = selectedKind === 'gateway' && selectedLocation
      ? String(selectedLocation.name || '') : ''
    vpnState.loadServers(
      query,
      country,
      gateway,
      selectedKind === 'gateway' || section === 'gateways' ? 'all' : feature,
      selectedKind === 'gateway' || section === 'gateways' ? 'gateways' : 'consumer'
    )
  }

  function clearSearch() {
    searchDebounce.stop()
    remoteLookupTimer.stop()
    searchField.text = ''
    requestServers()
  }

  function setSearchQuery(value) {
    searchField.text = String(value || '')
  }

  function resetSelection() {
    selectedLocation = null
    selectedKind = ''
    if (vpnState) vpnState.servers = []
  }

  function navigateBack() {
    if (selectedLocation === null) return false
    resetSelection()
    return true
  }

  function selectSection(value) {
    restoreSelectionPending = false
    section = value
    resetSelection()
    if (searchQuery.length > 0) Qt.callLater(requestServers)
  }

  function selectFeature(value) {
    restoreSelectionPending = false
    feature = value
    resetSelection()
    if (searchQuery.length > 0) Qt.callLater(requestServers)
  }

  function openLocation(item, kind) {
    restoreSelectionPending = false
    selectedLocation = item
    selectedKind = kind
    searchField.text = ''
    requestServers()
  }

  function chooseBestLocation(strategy, excludingMine) {
    var resolvedStrategy = String(strategy || 'fastest')
    var resolvedExclusion = !!excludingMine
    if (!selectedLocation) {
      if (!selectionMode || section !== 'countries') return
      locationSelected({
        targetKind: targetKindForFeature('fastest'),
        selectionStrategy: resolvedStrategy,
        excludeMyCountry: resolvedExclusion
      })
      return
    }
    if (!selectionMode) {
      if (selectedKind === 'gateway') vpnState.connectGateway(selectedLocation)
      else vpnState.connectCountry(selectedLocation, feature)
      return
    }
    if (selectedKind === 'gateway') {
      locationSelected({
        targetKind: 'gateway',
        selectionStrategy: resolvedStrategy,
        excludeMyCountry: false,
        gatewayName: String(selectedLocation.name || '')
      })
      return
    }
    locationSelected({
      targetKind: targetKindForFeature('country'),
      selectionStrategy: resolvedStrategy,
      excludeMyCountry: false,
      countryCode: String(selectedLocation.code || ''),
      countryName: countryDisplayName(selectedLocation)
    })
  }

  function chooseServer(server) {
    if (!selectionMode) {
      vpnState.connectServer(server)
      return
    }
    var gateway = String(server.gateway_name || '')
    locationSelected({
      targetKind: gateway ? 'gatewayServer'
        : server.secure_core ? 'secureCore'
        : feature === 'p2p' ? 'p2p'
        : feature === 'tor' ? 'tor' : 'server',
      selectionStrategy: 'fastest',
      excludeMyCountry: false,
      countryCode: String(server.country_code || ''),
      countryName: countryDisplayName({
        code: server.country_code, name: server.country_name
      }),
      entryCountryCode: String(server.entry_country_code || ''),
      entryCountryName: String(server.entry_country_name || ''),
      serverName: String(server.name || ''),
      gatewayName: gateway
    })
  }

  function chooseSearchResult(item) {
    if (!item) return
    if (item.resultType === 'server') {
      chooseServer(item.server)
      return
    }
    if (item.resultType === 'gateway') {
      if (selectionMode) {
        openLocation(item.gateway, 'gateway')
      } else {
        vpnState.connectGateway(item.gateway)
      }
      return
    }
    var country = item.country
    if (!country) return
    if (selectionMode && item.resultType === 'country') {
      openLocation(country, 'country')
      return
    }
    var targetKind = item.resultType
    if (item.resultType === 'country') {
      targetKind = feature === 'secure_core' ? 'secureCore'
        : feature === 'p2p' ? 'p2p'
        : feature === 'tor' ? 'tor' : 'country'
    } else if (selectionMode && feature === 'p2p') {
      targetKind = 'p2p'
    }
    var selection = {
      targetKind: targetKind,
      selectionStrategy: 'fastest',
      excludeMyCountry: false,
      countryCode: String(country.code || ''),
      countryName: countryDisplayName(country),
      state: String(item.state || ''),
      city: String(item.city || '')
    }
    if (selectionMode) {
      locationSelected(selection)
    } else if (item.resultType === 'country') {
      vpnState.connectCountry(country, feature)
    } else {
      vpnState.connectLocation(country, selection, feature)
    }
  }

  function chooseLogicalTarget(item) {
    if (!item || !selectedLocation) return
    var selection = {
      // Profiles encode the feature in their target kind. Direct connections
      // keep the hierarchy kind and record the feature in the recent entry.
      targetKind: selectionMode && feature === 'p2p'
        ? 'p2p' : String(item.kind || 'country'),
      selectionStrategy: 'fastest',
      excludeMyCountry: false,
      countryCode: String(selectedLocation.code || ''),
      countryName: countryDisplayName(selectedLocation),
      entryCountryCode: String(item.entryCountryCode || ''),
      entryCountryName: String(item.entryCountryName || ''),
      state: String(item.state || ''),
      city: String(item.city || '')
    }
    if (selectionMode) {
      locationSelected(selection)
      return
    }
    vpnState.connectLocation(selectedLocation, selection, feature)
  }

  onVisibleChanged: if (visible) refresh()
  onBaseLocationsChanged: if (visible && restoreSelectionPending)
    Qt.callLater(restoreSelectionPath)
  Component.onCompleted: if (visible) refresh()

  Column {
    id: content
    width: parent.width
    spacing: Style.space(9)

    RowLayout {
      width: parent.width
      spacing: Style.space(8)

      ProtonIconButton {
        visible: root.selectedLocation !== null
        iconName: 'chevron_left'
        foreground: root.foreground
        fontFamily: root.fontFamily
        tooltipText: root.label('locations')
        onClicked: {
          root.resetSelection()
        }
      }

      Text {
        Layout.fillWidth: true
        text: root.selectedLocation
          ? (root.selectedKind === 'country'
              ? root.countryDisplayName(root.selectedLocation)
              : String(root.selectedLocation.name || ''))
          : root.sectionSwitcherVisible
            ? root.label('locations')
            : root.section === 'gateways'
              ? root.label('gateways') : root.label('countries')
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.heading
        font.weight: Font.DemiBold
        elide: Text.ElideRight
      }

      Text {
        text: root.vpnState && root.vpnState.locationsLoading ? '…' : ''
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
      }
    }

    RowLayout {
      width: parent.width
      spacing: Style.space(5)

      TextField {
        id: searchField
        Layout.fillWidth: true
        placeholderText: root.label('search_locations')
        foreground: root.foreground
        accent: Color.accent
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        horizontalPadding: Style.spacing.controlGap
        verticalPadding: Style.spacing.controlPaddingY
        onTextChanged: {
          searchDebounce.restart()
          if (Search.canonicalServerLookup(text)) {
            remoteLookupTimer.interval = 2500
            remoteLookupTimer.restart()
          }
          else remoteLookupTimer.stop()
        }
      }

      ProtonIconButton {
        visible: root.searchQuery.length > 0
        iconName: 'cross'
        foreground: root.foreground
        fontFamily: root.fontFamily
        tooltipText: root.label('clear_search')
        onClicked: root.clearSearch()
      }
    }

    Timer {
      id: searchDebounce
      interval: 250
      repeat: false
      onTriggered: root.requestServers()
    }

    Timer {
      id: remoteLookupTimer
      interval: 2500
      repeat: false
      onTriggered: {
        if (!root.vpnState || root.searchQuery.length === 0) return
        if (root.vpnState.serversLoading) {
          // A slow local catalog response must not permanently suppress the
          // exact remote lookup. Retry briefly, but preserve the initial
          // delay for each new query so normal searches stay local-first.
          interval = 500
          restart()
          return
        }
        interval = 2500
        if (root.vpnState.serverTotal === 0)
          root.vpnState.lookupServer(root.searchQuery)
      }
    }

    RowLayout {
      visible: root.sectionSwitcherVisible && root.selectedLocation === null
      width: parent.width
      spacing: Style.space(8)

      Button {
        Layout.fillWidth: true
        text: root.label('countries')
        foreground: root.foreground
        fontFamily: root.fontFamily
        bordered: true
        active: root.section === 'countries'
        onClicked: root.selectSection('countries')
      }

      Button {
        visible: root.vpnState && root.vpnState.gateways.length > 0
        Layout.fillWidth: true
        text: root.label('gateways')
        foreground: root.foreground
        fontFamily: root.fontFamily
        bordered: true
        active: root.section === 'gateways'
        onClicked: root.selectSection('gateways')
      }
    }

    RowLayout {
      visible: root.selectedLocation === null && root.section === 'countries'
      width: parent.width
      spacing: Style.space(5)

      Repeater {
        model: [
          { value: 'standard', label: root.label('standard'), icon: 'earth' },
          { value: 'secure_core', label: 'Secure Core', icon: 'locks' },
          { value: 'p2p', label: 'P2P', icon: 'arrow_right_arrow_left' },
          { value: 'tor', label: 'Tor', icon: 'brand_tor' }
        ]

        delegate: ProtonIconButton {
          required property var modelData
          Layout.fillWidth: true
          iconName: String(modelData.icon)
          label: String(modelData.label)
          foreground: root.foreground
          fontFamily: root.fontFamily
          bordered: true
          active: root.feature === String(modelData.value)
          onClicked: root.selectFeature(String(modelData.value))
        }
      }
    }

    PanelActionRow {
      visible: root.selectionMode && root.selectedLocation === null &&
        root.section === 'countries' && !root.searching
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      specialFlag: 'Fastest'
      title: root.feature === 'secure_core' ? root.label('fastest_secure_core')
        : root.feature === 'p2p' ? root.label('fastest_p2p')
        : root.feature === 'tor' ? root.label('fastest_tor')
        : root.label('fastest_country')
      subtitle: root.label('best_available_profile_target')
      detailIconName: root.currentGlobalMatches('fastest', false)
        ? 'checkmark' : 'chevron_right'
      checked: root.currentGlobalMatches('fastest', false)
      onActivated: root.chooseBestLocation('fastest', false)
    }

    PanelActionRow {
      visible: root.selectionMode && root.selectedLocation === null &&
        root.section === 'countries' && root.feature !== 'tor' &&
        !root.searching
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      specialFlag: 'Fastest'
      title: root.label('fastest_country_excluding_my_country')
      subtitle: root.label('exclude_current_country_description')
      detailIconName: root.currentGlobalMatches('fastest', true)
        ? 'checkmark' : 'chevron_right'
      checked: root.currentGlobalMatches('fastest', true)
      onActivated: root.chooseBestLocation('fastest', true)
    }

    PanelActionRow {
      visible: root.selectionMode && root.selectedLocation === null &&
        root.section === 'countries' && root.feature !== 'tor' &&
        !root.searching
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      specialFlag: 'Random'
      title: root.label('random_country')
      subtitle: root.label('random_profile_description')
      detailIconName: root.currentGlobalMatches('random', false)
        ? 'checkmark' : 'chevron_right'
      checked: root.currentGlobalMatches('random', false)
      onActivated: root.chooseBestLocation('random', false)
    }

    PanelActionRow {
      visible: root.selectedLocation !== null
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      flagCode: root.selectedKind === 'country' && root.selectedLocation
        ? String(root.selectedLocation.code || '') : ''
      specialFlag: root.selectedKind === 'gateway' ? 'Gateway' : ''
      title: root.selectedKind === 'gateway'
        ? root.label('fastest_gateway')
        : root.feature === 'secure_core' ? root.label('fastest_secure_core')
        : root.feature === 'p2p' ? root.label('fastest_p2p')
        : root.feature === 'tor' ? root.label('fastest_tor')
        : root.label('fastest_server')
      subtitle: root.label('connect_best_available')
      detailIconName: root.currentLocationMatches('fastest')
        ? 'checkmark' : 'chevron_right'
      checked: root.currentLocationMatches('fastest')
      busy: !root.selectionMode && root.vpnState &&
        root.vpnState.tunnelOperationBusy
      enabled: root.selectionMode || !(root.vpnState &&
        root.vpnState.tunnelOperationBusy)
      onActivated: {
        root.chooseBestLocation('fastest', false)
      }
    }

    PanelActionRow {
      visible: root.selectionMode && root.selectedLocation !== null
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      flagCode: root.selectedKind === 'country' && root.selectedLocation
        ? String(root.selectedLocation.code || '') : ''
      specialFlag: root.selectedKind === 'gateway' ? 'Gateway' : ''
      title: root.label('random_server')
      subtitle: root.label('random_server_in_location_description')
      detailIconName: root.currentLocationMatches('random')
        ? 'checkmark' : 'chevron_right'
      checked: root.currentLocationMatches('random')
      onActivated: root.chooseBestLocation('random', false)
    }

    ListView {
      id: locationsList
      visible: !root.showingServers && !root.searching
      width: parent.width
      height: Math.min(contentHeight, Style.space(410))
      implicitHeight: height
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      model: root.filteredLocations
      spacing: Style.space(2)

      delegate: PanelActionRow {
        required property var modelData
        width: ListView.view.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        flagCode: root.section === 'countries' ? String(modelData.code || '') : ''
        specialFlag: root.section === 'gateways' ? 'Gateway' : ''
        title: root.section === 'countries'
          ? root.countryDisplayName(modelData)
          : String(modelData.name || '')
        subtitle: String(modelData.available_server_count || 0) + ' / ' +
          String(modelData.server_count || 0) + ' ' + root.label('servers').toLowerCase()
        detailIconName: 'chevron_right'
        onActivated: root.openLocation(
          modelData,
          root.section === 'countries' ? 'country' : 'gateway'
        )
      }
    }

    ListView {
      id: searchResultsList
      visible: root.searching
      width: parent.width
      height: Math.min(contentHeight, Style.space(410))
      implicitHeight: height
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      model: root.searchResults
      spacing: Style.space(2)
      onContentYChanged: {
        if (root.vpnState && contentY + height >= contentHeight - Style.space(80))
          root.vpnState.loadMoreServers()
      }

      delegate: Item {
        id: searchResultDelegate
        required property var modelData
        width: ListView.view.width
        height: modelData.resultType === 'header'
          ? Style.space(28) : searchResultRow.implicitHeight

        Text {
          visible: searchResultDelegate.modelData.resultType === 'header'
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.bottomMargin: Style.space(3)
          text: String(searchResultDelegate.modelData.title || '').toUpperCase()
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.weight: Font.DemiBold
          elide: Text.ElideRight
        }

        PanelActionRow {
          id: searchResultRow
          visible: searchResultDelegate.modelData.resultType !== 'header'
          width: parent.width
          rowForeground: root.foreground
          rowFontFamily: root.fontFamily
          flagCode: searchResultDelegate.modelData.resultType === 'gateway'
            ? '' : searchResultDelegate.modelData.resultType === 'server'
              ? String((searchResultDelegate.modelData.server || {}).country_code || '')
              : String((searchResultDelegate.modelData.country || {}).code || '')
          entryFlagCode: searchResultDelegate.modelData.resultType === 'server' &&
            !!(searchResultDelegate.modelData.server || {}).secure_core
              ? String((searchResultDelegate.modelData.server || {}).entry_country_code || '') : ''
          specialFlag: searchResultDelegate.modelData.resultType === 'gateway' ? 'Gateway' : ''
          title: String(searchResultDelegate.modelData.title || '')
          subtitle: String(searchResultDelegate.modelData.subtitle || '')
          detailIconName: {
            var server = searchResultDelegate.modelData.server || {}
            return searchResultDelegate.modelData.resultType === 'server' &&
              (server.maintenance || !server.enabled)
                ? 'minus_circle_filled' : root.selectionMode ? 'chevron_right' : 'play'
          }
          enabled: {
            if (searchResultDelegate.modelData.resultType === 'server') {
              var server = searchResultDelegate.modelData.server || {}
              if (!server.enabled || server.maintenance) return false
            }
            return root.selectionMode || !(root.vpnState && root.vpnState.tunnelOperationBusy)
          }
          busy: !root.selectionMode && root.vpnState && root.vpnState.tunnelOperationBusy
          onActivated: root.chooseSearchResult(searchResultDelegate.modelData)
        }
      }
    }

    ListView {
      id: logicalTargetsList
      visible: root.selectedLocation !== null && root.logicalTargets.length > 0
      width: parent.width
      height: Math.min(contentHeight, Style.space(250))
      implicitHeight: height
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      model: root.logicalTargets
      spacing: Style.space(2)

      delegate: PanelActionRow {
        required property var modelData
        width: ListView.view.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        flagCode: root.selectedLocation
          ? String(root.selectedLocation.code || '') : ''
        entryFlagCode: String(modelData.kind || '') === 'secureCore'
          ? String(modelData.entryCountryCode || '') : ''
        title: String(modelData.title || '')
        subtitle: String(modelData.subtitle || '')
        detailIconName: 'play'
        enabled: root.selectionMode || !(root.vpnState &&
          root.vpnState.tunnelOperationBusy)
        busy: !root.selectionMode && root.vpnState &&
          root.vpnState.tunnelOperationBusy
        onActivated: root.chooseLogicalTarget(modelData)
      }
    }

    ListView {
      id: serversList
      visible: root.showingServers
      width: parent.width
      height: Math.min(contentHeight, Style.space(410))
      implicitHeight: height
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      model: root.vpnState ? root.vpnState.servers : []
      spacing: Style.space(2)
      onContentYChanged: {
        if (root.vpnState && contentY + height >= contentHeight - Style.space(80))
          root.vpnState.loadMoreServers()
      }

      delegate: PanelActionRow {
        required property var modelData
        width: ListView.view.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        flagCode: String(modelData.country_code || '')
        entryFlagCode: modelData.secure_core
          ? String(modelData.entry_country_code || '') : ''
        title: String(modelData.name || '')
        subtitle: (modelData.secure_core
          ? String(modelData.entry_country_name || modelData.entry_country_code || '') + ' → '
          : modelData.city ? String(modelData.city) + ' · ' : '') +
          String(modelData.load || 0) + '%'
        detailIconName: modelData.maintenance || !modelData.enabled
          ? 'minus_circle_filled'
          : root.currentServerMatches(modelData) ? 'checkmark' : 'play'
        checked: root.currentServerMatches(modelData)
        enabled: !!modelData.enabled && !modelData.maintenance &&
          (root.selectionMode || !(root.vpnState &&
            root.vpnState.tunnelOperationBusy))
        busy: !root.selectionMode && root.vpnState &&
          root.vpnState.tunnelOperationBusy
        onActivated: root.chooseServer(modelData)
      }
    }

    Text {
      visible: (root.showingServers || root.searching) && root.vpnState &&
        !root.vpnState.locationsLoading && !root.vpnState.serversLoading &&
        !root.vpnState.serverLookupLoading && root.vpnState.servers.length === 0
        && (!root.searching || root.searchResults.length === 0)
      width: parent.width
      text: root.searching ? root.label('no_locations_found') : root.label('no_servers_found')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
    }

    Text {
      visible: root.vpnState &&
        (root.vpnState.serversLoading || root.vpnState.serverLookupLoading)
      width: parent.width
      text: root.label('loading_servers')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      horizontalAlignment: Text.AlignHCenter
    }
  }
}
