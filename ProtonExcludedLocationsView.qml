import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import 'components'

Item {
  id: root

  property QtObject vpnState: null
  property QtObject strings: null
  property color foreground: Color.foreground
  property color urgent: Color.urgent
  property color dim: Qt.darker(foreground, 1.55)
  property string fontFamily: Style.font.family
  property var selectedCountry: null
  property string selectedState: ''

  implicitHeight: content.implicitHeight

  function label(key) { return strings ? strings.text(key) : key }

  function refresh() {
    if (!vpnState || !vpnState.signedIn) return
    vpnState.loadLocations()
    vpnState.loadExcludedLocations()
  }

  function locationKey(item) {
    return [
      String(item.kind || '').toLowerCase(),
      String(item.country_code || '').toUpperCase(),
      String(item.state || '').toLowerCase(),
      String(item.city || '').toLowerCase()
    ].join(':')
  }

  function addLocation(item) {
    if (!vpnState || !item) return
    var key = locationKey(item)
    var next = []
    for (var index = 0; index < vpnState.excludedLocations.length; ++index) {
      var existing = vpnState.excludedLocations[index]
      if (locationKey(existing) === key) return
      next.push(existing)
    }
    next.push(item)
    vpnState.setExcludedLocations(next)
  }

  function removeLocation(index) {
    if (!vpnState) return
    var next = []
    for (var itemIndex = 0; itemIndex < vpnState.excludedLocations.length; ++itemIndex) {
      if (itemIndex !== index) next.push(vpnState.excludedLocations[itemIndex])
    }
    vpnState.setExcludedLocations(next)
  }

  function excludedLabel(item) {
    var country = String(item.country_code || '')
    if (item.kind === 'state') return country + ' · ' + String(item.state || '')
    if (item.kind === 'city') {
      var state = String(item.state || '')
      return country + ' · ' + (state ? state + ' · ' : '') + String(item.city || '')
    }
    return country
  }

  function selectedStateCities() {
    if (!selectedCountry || !Array.isArray(selectedCountry.states)) return []
    for (var index = 0; index < selectedCountry.states.length; ++index) {
      var state = selectedCountry.states[index]
      if (String(state.name || '') === selectedState)
        return Array.isArray(state.cities) ? state.cities : []
    }
    return []
  }

  onVisibleChanged: if (visible) refresh()
  Component.onCompleted: if (visible) refresh()

  Column {
    id: content
    width: parent.width
    spacing: Style.space(8)

    Text {
      width: parent.width
      text: root.label('excluded_locations')
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.heading
      font.weight: Font.DemiBold
    }

    Text {
      width: parent.width
      text: root.label('excluded_locations_description')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    PanelSectionHeader {
      visible: root.vpnState && root.vpnState.excludedLocations.length > 0
      text: root.label('excluded').toUpperCase()
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    Repeater {
      model: root.vpnState ? root.vpnState.excludedLocations : []

      delegate: Item {
        required property var modelData
        required property int index
        width: root.width
        height: excludedRow.implicitHeight

        PanelActionRow {
          id: excludedRow
          anchors.left: parent.left
          anchors.right: removeButton.left
          rowForeground: root.foreground
          rowFontFamily: root.fontFamily
          iconName: modelData.kind === 'country' ? 'earth' : 'map_pin'
          title: root.excludedLabel(modelData)
          subtitle: root.label('excluded_' + String(modelData.kind || 'country'))
          enabled: false
        }

        ProtonIconButton {
          id: removeButton
          anchors.right: parent.right
          anchors.verticalCenter: excludedRow.verticalCenter
          iconName: 'cross'
          foreground: root.urgent
          fontFamily: root.fontFamily
          tooltipText: root.label('delete')
          enabled: root.vpnState && !root.vpnState.storeOperationBusy
          onClicked: root.removeLocation(index)
        }
      }
    }

    PanelSeparator { foreground: root.foreground }

    PanelSectionHeader {
      text: root.label('add_location').toUpperCase()
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    ProtonIconButton {
      visible: root.selectedCountry !== null
      iconName: 'chevron_left'
      label: (root.selectedState
        ? root.selectedState : String(root.selectedCountry.name || root.selectedCountry.code || ''))
      foreground: root.foreground
      fontFamily: root.fontFamily
      onClicked: {
        if (root.selectedState) root.selectedState = ''
        else root.selectedCountry = null
      }
    }

    Repeater {
      model: root.selectedCountry === null && root.vpnState
        ? root.vpnState.countries : []

      delegate: Item {
        required property var modelData
        width: root.width
        height: countryRow.implicitHeight

        PanelActionRow {
          id: countryRow
          anchors.left: parent.left
          anchors.right: addCountryButton.left
          rowForeground: root.foreground
          rowFontFamily: root.fontFamily
          iconName: 'earth'
          title: String(modelData.name || modelData.code || '')
          subtitle: String(modelData.code || '')
          detailIconName: (modelData.states && modelData.states.length > 0) ||
            (modelData.cities && modelData.cities.length > 0)
              ? 'chevron_right' : ''
          onActivated: {
            root.selectedCountry = modelData
            root.selectedState = ''
          }
        }

        ProtonIconButton {
          id: addCountryButton
          anchors.right: parent.right
          anchors.verticalCenter: countryRow.verticalCenter
          iconName: 'plus'
          foreground: root.foreground
          fontFamily: root.fontFamily
          tooltipText: root.label('add_location')
          enabled: root.vpnState && !root.vpnState.storeOperationBusy
          onClicked: root.addLocation({
            kind: 'country', country_code: String(modelData.code || '')
          })
        }
      }
    }

    Repeater {
      model: root.selectedCountry && !root.selectedState &&
        Array.isArray(root.selectedCountry.states) ? root.selectedCountry.states : []

      delegate: Item {
        required property var modelData
        width: root.width
        height: stateRow.implicitHeight

        PanelActionRow {
          id: stateRow
          anchors.left: parent.left
          anchors.right: addStateButton.left
          rowForeground: root.foreground
          rowFontFamily: root.fontFamily
          iconName: 'map_pin'
          title: String(modelData.name || '')
          subtitle: root.label('excluded_state')
          detailIconName: modelData.cities && modelData.cities.length > 0
            ? 'chevron_right' : ''
          onActivated: root.selectedState = String(modelData.name || '')
        }

        ProtonIconButton {
          id: addStateButton
          anchors.right: parent.right
          anchors.verticalCenter: stateRow.verticalCenter
          iconName: 'plus'
          foreground: root.foreground
          fontFamily: root.fontFamily
          tooltipText: root.label('add_location')
          enabled: root.vpnState && !root.vpnState.storeOperationBusy
          onClicked: root.addLocation({
            kind: 'state',
            country_code: String(root.selectedCountry.code || ''),
            state: String(modelData.name || '')
          })
        }
      }
    }

    Repeater {
      model: root.selectedCountry && !root.selectedState &&
        Array.isArray(root.selectedCountry.cities) ? root.selectedCountry.cities : []

      delegate: PanelActionRow {
        required property string modelData
        width: root.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconName: 'map_pin'
        title: modelData
        detailIconName: 'plus'
        enabled: root.vpnState && !root.vpnState.storeOperationBusy
        onActivated: root.addLocation({
          kind: 'city',
          country_code: String(root.selectedCountry.code || ''),
          city: modelData
        })
      }
    }

    Repeater {
      model: root.selectedCountry && root.selectedState
        ? root.selectedStateCities() : []

      delegate: PanelActionRow {
        required property string modelData
        width: root.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconName: 'map_pin'
        title: modelData
        detailIconName: 'plus'
        enabled: root.vpnState && !root.vpnState.storeOperationBusy
        onActivated: root.addLocation({
          kind: 'city',
          country_code: String(root.selectedCountry.code || ''),
          state: root.selectedState,
          city: modelData
        })
      }
    }
  }
}
