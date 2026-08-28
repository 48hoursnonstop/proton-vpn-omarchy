import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import 'components' as ProtonComponents

// Shared live-traffic surface for Home and Connection details. The agent owns
// sampling; this component only retains a short, bounded presentation history.
Item {
  id: root

  property QtObject vpnState: null
  property QtObject strings: null
  property color foreground: Color.foreground
  property color dim: Qt.darker(foreground, 1.55)
  property string fontFamily: Style.font.family
  property int historyLimit: 45
  property var downloadHistory: []
  property var uploadHistory: []

  readonly property color downloadColor: Color.accent
  readonly property color uploadColor: foreground
  readonly property bool trafficKnown: vpnState ? vpnState.trafficKnown : false

  implicitHeight: content.implicitHeight

  function label(key) { return strings ? strings.text(key) : key }

  function bytes(value) {
    var amount = Math.max(0, Number(value || 0))
    if (amount >= 1024 * 1024 * 1024)
      return (amount / (1024 * 1024 * 1024)).toFixed(1) + ' GiB'
    if (amount >= 1024 * 1024)
      return (amount / (1024 * 1024)).toFixed(1) + ' MiB'
    if (amount >= 1024)
      return (amount / 1024).toFixed(1) + ' KiB'
    return Math.round(amount) + ' B'
  }

  function rate(value) {
    return trafficKnown ? bytes(value) + '/s' : '—'
  }

  function total(value) {
    return trafficKnown ? bytes(value) : '—'
  }

  function appendSample() {
    if (!visible || !vpnState || !vpnState.connected) return
    var downloads = downloadHistory.slice(0)
    var uploads = uploadHistory.slice(0)
    downloads.push(Math.max(0, Number(vpnState.downloadBytesPerSecond || 0)))
    uploads.push(Math.max(0, Number(vpnState.uploadBytesPerSecond || 0)))
    while (downloads.length > historyLimit) downloads.shift()
    while (uploads.length > historyLimit) uploads.shift()
    downloadHistory = downloads
    uploadHistory = uploads
    chart.requestPaint()
  }

  function resetHistory() {
    downloadHistory = []
    uploadHistory = []
    chart.requestPaint()
  }

  Timer {
    interval: 1000
    repeat: true
    triggeredOnStart: true
    running: root.visible && root.vpnState && root.vpnState.connected
    onTriggered: root.vpnState.refreshTraffic()
  }

  Connections {
    target: root.vpnState
    ignoreUnknownSignals: true
    function onTrafficUpdated() { root.appendSample() }
    function onConnectedChanged() {
      if (!root.vpnState || !root.vpnState.connected) root.resetHistory()
    }
  }

  Column {
    id: content
    width: parent.width
    spacing: Style.space(7)

    PanelSectionHeader {
      text: root.label('traffic').toUpperCase()
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    RowLayout {
      width: parent.width
      spacing: Style.space(12)

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(7)

        ProtonComponents.ProtonMobileIcon {
          iconName: 'arrow_down'
          iconColor: root.downloadColor
          iconSize: Style.font.iconLarge
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 0

          Text {
            Layout.fillWidth: true
            text: root.label('download')
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Text {
            Layout.fillWidth: true
            text: root.rate(root.vpnState
              ? root.vpnState.downloadBytesPerSecond : 0)
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.weight: Font.DemiBold
            elide: Text.ElideRight
          }

          Text {
            Layout.fillWidth: true
            text: root.total(root.vpnState ? root.vpnState.downloadBytes : 0)
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(7)

        ProtonComponents.ProtonMobileIcon {
          iconName: 'arrow_up'
          iconColor: root.uploadColor
          iconSize: Style.font.iconLarge
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 0

          Text {
            Layout.fillWidth: true
            text: root.label('upload')
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Text {
            Layout.fillWidth: true
            text: root.rate(root.vpnState
              ? root.vpnState.uploadBytesPerSecond : 0)
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.weight: Font.DemiBold
            elide: Text.ElideRight
          }

          Text {
            Layout.fillWidth: true
            text: root.total(root.vpnState ? root.vpnState.uploadBytes : 0)
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }
        }
      }
    }

    Rectangle {
      width: parent.width
      height: Style.space(82)
      radius: Style.cornerRadius
      color: Qt.rgba(root.foreground.r, root.foreground.g,
                     root.foreground.b, 0.045)
      clip: true

      Canvas {
        id: chart
        anchors.fill: parent
        anchors.margins: Style.space(7)
        antialiasing: true

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
          var ctx = getContext('2d')
          ctx.reset()
          if (width <= 0 || height <= 0) return

          ctx.lineWidth = 1
          ctx.strokeStyle = Qt.rgba(root.foreground.r, root.foreground.g,
                                    root.foreground.b, 0.10)
          for (var grid = 1; grid < 4; ++grid) {
            var gridY = height * grid / 4
            ctx.beginPath()
            ctx.moveTo(0, gridY)
            ctx.lineTo(width, gridY)
            ctx.stroke()
          }

          var downloads = root.downloadHistory
          var uploads = root.uploadHistory
          var count = Math.max(downloads.length, uploads.length)
          if (count < 2) return
          var maximum = 1024
          for (var i = 0; i < downloads.length; ++i)
            maximum = Math.max(maximum, Number(downloads[i] || 0))
          for (var j = 0; j < uploads.length; ++j)
            maximum = Math.max(maximum, Number(uploads[j] || 0))

          function drawSeries(values, stroke, fill, dashed) {
            if (values.length < 2) return
            var firstX = width * (count - values.length) / (count - 1)
            ctx.beginPath()
            for (var index = 0; index < values.length; ++index) {
              var pointIndex = count - values.length + index
              var x = width * pointIndex / (count - 1)
              var y = height - Math.min(height,
                height * Number(values[index] || 0) / maximum)
              if (index === 0) ctx.moveTo(x, y)
              else ctx.lineTo(x, y)
            }
            ctx.strokeStyle = stroke
            ctx.lineWidth = 2
            ctx.lineJoin = 'round'
            ctx.lineCap = 'round'
            ctx.setLineDash(dashed ? [4, 4] : [])
            ctx.stroke()
            ctx.setLineDash([])

            ctx.lineTo(width, height)
            ctx.lineTo(firstX, height)
            ctx.closePath()
            ctx.fillStyle = fill
            ctx.fill()
          }

          drawSeries(uploads, root.uploadColor,
            Qt.rgba(root.uploadColor.r, root.uploadColor.g,
                    root.uploadColor.b, 0.07), true)
          drawSeries(downloads, root.downloadColor,
            Qt.rgba(root.downloadColor.r, root.downloadColor.g,
                    root.downloadColor.b, 0.14), false)
        }
      }
    }
  }
}
