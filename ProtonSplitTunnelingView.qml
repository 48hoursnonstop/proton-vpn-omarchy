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
  property string mode: vpnState && vpnState.splitTunnelingMode === 'inverse'
    ? 'inverse' : 'standard'
  property bool enabledValue: vpnState ? vpnState.splitTunneling : false
  property var standardApps: vpnState ? vpnState.splitStandardApps.slice() : []
  property var inverseApps: vpnState ? vpnState.splitInverseApps.slice() : []
  property var standardIpRanges: vpnState ? vpnState.splitStandardIpRanges.slice() : []
  property var inverseIpRanges: vpnState ? vpnState.splitInverseIpRanges.slice() : []

  readonly property var activeApps: mode === 'inverse' ? inverseApps : standardApps
  readonly property var activeIpRanges: mode === 'inverse' ? inverseIpRanges : standardIpRanges
  readonly property bool ipRangesSupported: vpnState && vpnState.splitIpRangesSupported
  implicitHeight: content.implicitHeight

  function label(key) { return strings ? strings.text(key) : key }

  function refresh() {
    if (!vpnState) return
    mode = vpnState.splitTunnelingMode === 'inverse' ? 'inverse' : 'standard'
    enabledValue = vpnState.splitTunneling
    standardApps = vpnState.splitStandardApps.slice()
    inverseApps = vpnState.splitInverseApps.slice()
    standardIpRanges = vpnState.splitStandardIpRanges.slice()
    inverseIpRanges = vpnState.splitInverseIpRanges.slice()
    vpnState.loadApps('')
  }

  function contains(values, executable) {
    return values.indexOf(String(executable || '')) >= 0
  }

  function toggleExecutable(executable) {
    var value = String(executable || '').trim()
    if (value.length === 0) return
    var values = activeApps.slice()
    var index = values.indexOf(value)
    if (index >= 0) values.splice(index, 1)
    else values.push(value)
    if (mode === 'inverse') inverseApps = values
    else standardApps = values
  }

  function addIpRange(value) {
    value = String(value || '').trim()
    if (value.length === 0) return
    var values = activeIpRanges.slice()
    if (values.indexOf(value) < 0) values.push(value)
    if (mode === 'inverse') inverseIpRanges = values
    else standardIpRanges = values
  }

  function removeIpRange(value) {
    var values = activeIpRanges.slice()
    var index = values.indexOf(String(value || ''))
    if (index >= 0) values.splice(index, 1)
    if (mode === 'inverse') inverseIpRanges = values
    else standardIpRanges = values
  }

  function apply() {
    if (!vpnState || (enabledValue && activeApps.length === 0 &&
                      activeIpRanges.length === 0)) return
    vpnState.applySplitTunneling(
      enabledValue, mode, standardApps, inverseApps,
      standardIpRanges, inverseIpRanges
    )
  }

  onVisibleChanged: if (visible) refresh()
  Component.onCompleted: if (visible) refresh()

  Column {
    id: content
    width: parent.width
    spacing: Style.space(8)

    Text {
      width: parent.width
      text: root.label('split_tunneling')
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.heading
      font.weight: Font.DemiBold
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'squares_in_square'
      title: root.label('split_tunneling')
      subtitle: root.enabledValue ? root.label('enabled') : root.label('disabled')
      toggleVisible: true
      checked: root.enabledValue
      onActivated: root.enabledValue = !root.enabledValue
    }

    RowLayout {
      width: parent.width
      spacing: Style.space(8)

      ProtonIconButton {
        Layout.fillWidth: true
        iconName: 'cross_circle'
        label: root.label('exclude_mode')
        foreground: root.foreground
        fontFamily: root.fontFamily
        bordered: true
        active: root.mode === 'standard'
        onClicked: root.mode = 'standard'
      }

      ProtonIconButton {
        Layout.fillWidth: true
        iconName: 'checkmark_circle'
        label: root.label('include_mode')
        foreground: root.foreground
        fontFamily: root.fontFamily
        bordered: true
        active: root.mode === 'inverse'
        onClicked: root.mode = 'inverse'
      }
    }

    Text {
      width: parent.width
      text: root.mode === 'standard'
        ? root.label('exclude_mode_description')
        : root.label('include_mode_description')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    TextField {
      id: searchField
      width: parent.width
      placeholderText: root.label('search_apps')
      foreground: root.foreground
      accent: Color.accent
      font.family: root.fontFamily
      onTextChanged: appSearch.restart()
    }

    Timer {
      id: appSearch
      interval: 250
      repeat: false
      onTriggered: root.vpnState.loadApps(searchField.text)
    }

    ListView {
      width: parent.width
      height: Math.min(contentHeight, Style.space(310))
      implicitHeight: height
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      model: root.vpnState ? root.vpnState.installedApps : []
      spacing: Style.space(2)

      delegate: PanelActionRow {
        required property var modelData
        width: ListView.view.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconName: root.contains(root.activeApps, modelData.executable)
          ? 'checkmark_circle' : 'squares_in_square'
        title: String(modelData.name || '')
        subtitle: String(modelData.executable || '')
        checked: root.contains(root.activeApps, modelData.executable)
        onActivated: root.toggleExecutable(modelData.executable)
      }
    }

    RowLayout {
      width: parent.width
      spacing: Style.space(6)

      TextField {
        id: manualAppField
        Layout.fillWidth: true
        placeholderText: root.label('manual_executable')
        foreground: root.foreground
        accent: Color.accent
        font.family: root.fontFamily
        onAccepted: {
          root.toggleExecutable(text)
          text = ''
        }
      }

      ProtonIconButton {
        iconName: 'plus'
        foreground: root.foreground
        fontFamily: root.fontFamily
        bordered: true
        tooltipText: root.label('manual_executable')
        enabled: manualAppField.text.trim().length > 0
        onClicked: {
          root.toggleExecutable(manualAppField.text)
          manualAppField.text = ''
        }
      }
    }

    Text {
      visible: root.enabledValue && root.activeApps.length === 0 &&
        root.activeIpRanges.length === 0
      width: parent.width
      text: root.label('split_requires_app')
      color: root.urgent
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    Text {
      visible: root.vpnState && root.vpnState.killSwitch && root.enabledValue
      width: parent.width
      text: root.label('split_kill_switch_conflict')
      color: root.urgent
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    PanelSectionHeader {
      visible: root.ipRangesSupported
      text: root.label('ip_ranges').toUpperCase()
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    Repeater {
      model: root.ipRangesSupported ? root.activeIpRanges : []

      PanelActionRow {
        required property string modelData
        required property int index
        width: content.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconName: 'globe'
        title: modelData
        subtitle: root.label('remove_ip_range')
        detailIconName: 'cross_circle'
        onActivated: root.removeIpRange(modelData)
      }
    }

    RowLayout {
      visible: root.ipRangesSupported
      width: parent.width
      spacing: Style.space(6)

      TextField {
        id: ipRangeField
        Layout.fillWidth: true
        placeholderText: root.label('ip_range_placeholder')
        foreground: root.foreground
        accent: Color.accent
        font.family: root.fontFamily
        onAccepted: {
          root.addIpRange(text)
          text = ''
        }
      }

      ProtonIconButton {
        iconName: 'plus'
        foreground: root.foreground
        fontFamily: root.fontFamily
        bordered: true
        tooltipText: root.label('add_ip_range')
        enabled: ipRangeField.text.trim().length > 0
        onClicked: {
          root.addIpRange(ipRangeField.text)
          ipRangeField.text = ''
        }
      }
    }

    Text {
      visible: !root.ipRangesSupported
      width: parent.width
      text: root.label('split_ip_ranges_requires_update')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    Button {
      width: parent.width
      text: root.label('apply')
      foreground: root.foreground
      fontFamily: root.fontFamily
      bordered: true
      active: true
      enabled: (!root.enabledValue || root.activeApps.length > 0 ||
        root.activeIpRanges.length > 0) &&
        !(root.enabledValue && root.vpnState && root.vpnState.killSwitch) &&
        !(root.vpnState && root.vpnState.operationBusy)
      onClicked: root.apply()
    }
  }
}
