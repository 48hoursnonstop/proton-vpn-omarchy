import QtQuick
import QtQuick.Controls
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

  implicitHeight: content.implicitHeight

  function label(key) { return strings ? strings.text(key) : key }

  function bytesLabel(value) {
    var bytes = Math.max(0, Number(value || 0))
    if (bytes < 1024) return Math.round(bytes) + ' B'
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KiB'
    return (bytes / (1024 * 1024)).toFixed(1) + ' MiB'
  }

  function refresh() {
    if (vpnState && !vpnState.diagnosticsLoading) vpnState.loadDiagnostics()
  }

  onVisibleChanged: if (visible) refresh()
  Component.onCompleted: if (visible) refresh()

  Column {
    id: content
    width: parent.width
    spacing: Style.space(8)

    Text {
      width: parent.width
      text: root.label('diagnostics')
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.heading
      font.weight: Font.DemiBold
    }

    Text {
      width: parent.width
      text: root.label('diagnostics_description')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'brand_proton_vpn'
      title: root.label('agent_status')
      subtitle: root.vpnState && root.vpnState.agentAvailable
        ? root.label('available') : root.label('unavailable')
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'brand_linux'
      title: root.label('proton_linux_core')
      subtitle: root.vpnState && root.vpnState.backendCoreVersion
        ? root.vpnState.backendCoreVersion : root.label('not_reported')
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'folder'
      title: root.label('canonical_store')
      subtitle: root.vpnState && root.vpnState.storeReady
        ? root.label('available') : root.label('unavailable')
    }

    PanelSectionHeader {
      text: root.label('diagnostic_sources').toUpperCase()
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    ListView {
      width: parent.width
      height: Math.min(contentHeight, Style.space(220))
      implicitHeight: height
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      model: root.vpnState ? root.vpnState.diagnosticsSources : []
      spacing: Style.space(2)

      delegate: PanelActionRow {
        required property var modelData
        width: ListView.view.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconName: modelData.available ? 'checkmark_circle' : 'exclamation_circle'
        title: root.label('diagnostic_' + String(modelData.source || 'unknown'))
        subtitle: modelData.available
          ? root.bytesLabel(modelData.bytes) : root.label('unavailable')
      }
    }

    Text {
      visible: root.vpnState && root.vpnState.diagnosticsFailures.length > 0
      width: parent.width
      text: root.label('diagnostic_sources_partial') + ' (' +
        root.vpnState.diagnosticsFailures.length + ')'
      color: root.urgent
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
    }

    Text {
      width: parent.width
      text: root.label('diagnostics_privacy')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
    }

    Button {
      width: parent.width
      text: root.vpnState && root.vpnState.diagnosticsLoading
        ? root.label('checking_diagnostics') : root.label('refresh')
      foreground: root.foreground
      fontFamily: root.fontFamily
      bordered: true
      enabled: root.vpnState && !root.vpnState.diagnosticsLoading
      onClicked: root.refresh()
    }
  }
}
