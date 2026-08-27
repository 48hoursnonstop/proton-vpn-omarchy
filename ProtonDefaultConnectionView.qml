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

  implicitHeight: content.implicitHeight

  function label(key) { return strings ? strings.text(key) : key }

  function selected(type, idName, id) {
    if (!vpnState || vpnState.defaultConnection.type !== type) return false
    return !idName || String(vpnState.defaultConnection[idName] || '') === String(id || '')
  }

  function refresh() {
    if (!vpnState || !vpnState.signedIn) return
    vpnState.loadProfiles(0)
    vpnState.loadRecents(0)
  }

  onVisibleChanged: if (visible) refresh()
  Component.onCompleted: if (visible) refresh()

  Column {
    id: content
    width: parent.width
    spacing: Style.space(8)

    Text {
      width: parent.width
      text: root.label('default_connection')
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.heading
      font.weight: Font.DemiBold
    }

    Text {
      width: parent.width
      text: root.label('default_connection_description')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    Repeater {
      model: [
        { type: 'fastest', icon: 'bolt', title: root.label('fastest_server') },
        { type: 'random', icon: 'arrows_rotate', title: root.label('random_server') },
        { type: 'last', icon: 'clock_rotate_left', title: root.label('last_connection') }
      ]

      delegate: PanelActionRow {
        required property var modelData
        width: root.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconName: String(modelData.icon)
        title: String(modelData.title)
        subtitle: root.selected(String(modelData.type), '', '')
          ? root.label('default_connection_active') : ''
        detailIconName: root.selected(String(modelData.type), '', '')
          ? 'checkmark' : 'chevron_right'
        busy: root.vpnState && root.vpnState.storeOperationBusy
        enabled: root.vpnState && !root.vpnState.storeOperationBusy
        onActivated: root.vpnState.setDefaultConnection({ type: modelData.type })
      }
    }

    PanelSectionHeader {
      visible: root.vpnState && root.vpnState.profiles.length > 0
      text: root.label('profiles').toUpperCase()
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    ListView {
      visible: root.vpnState && root.vpnState.profiles.length > 0
      width: parent.width
      height: Math.min(contentHeight, Style.space(190))
      implicitHeight: height
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      model: root.vpnState ? root.vpnState.profiles : []
      spacing: Style.space(2)

      delegate: PanelActionRow {
        required property var modelData
        width: ListView.view.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconName: 'window_terminal'
        title: String(modelData.name || '')
        subtitle: root.label('target_' + String(modelData.targetKind || 'fastest'))
        detailIconName: root.selected('profile', 'profileId', modelData.id)
          ? 'checkmark' : 'chevron_right'
        busy: root.vpnState && root.vpnState.storeOperationBusy
        enabled: root.vpnState && !root.vpnState.storeOperationBusy
        onActivated: root.vpnState.setDefaultConnection({
          type: 'profile', profileId: String(modelData.id || '')
        })
      }
    }

    PanelSectionHeader {
      visible: root.vpnState && root.vpnState.recents.length > 0
      text: root.label('recents').toUpperCase()
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    ListView {
      visible: root.vpnState && root.vpnState.recents.length > 0
      width: parent.width
      height: Math.min(contentHeight, Style.space(190))
      implicitHeight: height
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      model: root.vpnState ? root.vpnState.recents : []
      spacing: Style.space(2)

      delegate: PanelActionRow {
        required property var modelData
        width: ListView.view.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconName: modelData.pinned ? 'star_filled' : 'clock_rotate_left'
        title: String(modelData.header || modelData.serverName || '')
        subtitle: String(modelData.description || modelData.city || '')
        detailIconName: root.selected('recent', 'recentId', modelData.id)
          ? 'checkmark' : 'chevron_right'
        busy: root.vpnState && root.vpnState.storeOperationBusy
        enabled: root.vpnState && !root.vpnState.storeOperationBusy
        onActivated: root.vpnState.setDefaultConnection({
          type: 'recent', recentId: String(modelData.id || '')
        })
      }
    }

    Text {
      visible: root.vpnState && !root.vpnState.autoConnect
      width: parent.width
      text: root.label('default_used_by_quick_connect')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
    }
  }
}
