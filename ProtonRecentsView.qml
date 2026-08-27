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
  property var selectedRecent: null
  property string deleteCandidateId: ''
  property string deleteRequestId: ''

  implicitHeight: content.implicitHeight

  function label(key) { return strings ? strings.text(key) : key }

  function refresh() {
    if (vpnState && vpnState.signedIn) vpnState.loadRecents(0)
  }

  function recentIconName(recent) {
    if (recent && recent.pinned) return 'star_filled'
    switch (String(recent && recent.kind || '')) {
    case 'profile': return 'window_terminal'
    case 'gateway':
    case 'gatewayServer': return 'servers'
    case 'secureCore': return 'locks'
    default: return ''
    }
  }

  function isDefault(recent) {
    return vpnState && recent && vpnState.defaultConnection.type === 'recent' &&
      vpnState.defaultConnection.recentId === recent.id
  }

  Connections {
    target: root.vpnState

    function onRequestFinished(requestId, method, ok, errorCode) {
      if (requestId !== root.deleteRequestId) return
      root.deleteRequestId = ''
      if (ok) {
        root.selectedRecent = null
        root.deleteCandidateId = ''
      }
    }
  }

  onVisibleChanged: if (visible) refresh()
  Component.onCompleted: if (visible) refresh()

  Column {
    id: content
    width: parent.width
    spacing: Style.space(8)

    RowLayout {
      width: parent.width

      Text {
        Layout.fillWidth: true
        text: root.label('recents_and_favorites')
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.heading
        font.weight: Font.DemiBold
      }

      Text {
        text: root.vpnState ? String(root.vpnState.recents.length) : '0'
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }

    Text {
      width: parent.width
      text: root.label('favorites_description')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    ListView {
      id: recentsList
      width: parent.width
      height: Math.min(contentHeight, Style.space(410))
      implicitHeight: height
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      model: root.vpnState ? root.vpnState.recents : []
      spacing: Style.space(2)

      delegate: Item {
        required property var modelData
        width: ListView.view.width
        height: recentRow.implicitHeight

        PanelActionRow {
          id: recentRow
          anchors.left: parent.left
          anchors.right: favoriteButton.left
          rowForeground: root.foreground
          rowFontFamily: root.fontFamily
          iconName: root.recentIconName(modelData)
          iconText: root.recentIconName(modelData) === ''
            ? String(modelData.countryCode || '') : ''
          title: String(modelData.header || modelData.countryName || modelData.serverName || '')
          subtitle: String(modelData.description || modelData.city || root.label('saved_connection'))
          detailIconName: root.isDefault(modelData) ? 'checkmark' : 'play'
          enabled: root.vpnState && !root.vpnState.tunnelOperationBusy
          busy: root.vpnState && root.vpnState.tunnelOperationBusy
          onActivated: root.vpnState.connectRecent(modelData)
        }

        ProtonIconButton {
          id: favoriteButton
          anchors.right: moreButton.left
          anchors.verticalCenter: recentRow.verticalCenter
          iconName: modelData.pinned ? 'star_filled' : 'star'
          foreground: root.foreground
          fontFamily: root.fontFamily
          tooltipText: root.label('favorites_description')
          enabled: root.vpnState && !root.vpnState.storeOperationBusy
          onClicked: root.vpnState.setRecentPinned(
            String(modelData.id || ''), !modelData.pinned
          )
        }

        ProtonIconButton {
          id: moreButton
          anchors.right: parent.right
          anchors.verticalCenter: recentRow.verticalCenter
          iconName: 'three_dots_horizontal'
          foreground: root.foreground
          fontFamily: root.fontFamily
          tooltipText: root.label('recents_and_favorites')
          onClicked: {
            root.selectedRecent = modelData
            root.deleteCandidateId = ''
          }
        }
      }
    }

    Text {
      visible: root.vpnState && root.vpnState.recents.length === 0
      width: parent.width
      text: root.label('no_recents')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
    }

    Column {
      visible: root.selectedRecent !== null
      width: parent.width
      spacing: Style.space(6)

      PanelSeparator { foreground: root.foreground }

      Text {
        width: parent.width
        text: root.selectedRecent
          ? String(root.selectedRecent.header || root.selectedRecent.serverName || '') : ''
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.weight: Font.DemiBold
        elide: Text.ElideRight
      }

      Button {
        width: parent.width
        text: root.isDefault(root.selectedRecent)
          ? root.label('default_connection_active') : root.label('use_as_default')
        foreground: root.foreground
        fontFamily: root.fontFamily
        bordered: true
        enabled: !root.isDefault(root.selectedRecent) && root.vpnState &&
          !root.vpnState.storeOperationBusy
        onClicked: root.vpnState.setDefaultConnection({
          type: 'recent', recentId: String(root.selectedRecent.id || '')
        })
      }

      Button {
        width: parent.width
        text: root.deleteCandidateId.length > 0
          ? root.label('confirm_delete_recent') : root.label('delete_recent')
        foreground: root.urgent
        fontFamily: root.fontFamily
        bordered: root.deleteCandidateId.length > 0
        enabled: root.vpnState && !root.vpnState.storeOperationBusy &&
          root.deleteRequestId.length === 0
        onClicked: {
          if (root.deleteCandidateId.length > 0) {
            root.deleteRequestId = root.vpnState.deleteRecent(root.deleteCandidateId)
          } else {
            root.deleteCandidateId = String(root.selectedRecent.id || '')
          }
        }
      }

      Button {
        width: parent.width
        text: root.label('cancel')
        foreground: root.foreground
        fontFamily: root.fontFamily
        bordered: false
        onClicked: {
          root.selectedRecent = null
          root.deleteCandidateId = ''
        }
      }
    }
  }
}
