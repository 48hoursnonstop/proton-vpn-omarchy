import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui
import 'components' as ProtonComponents

// Read-only view of the agent adapter's shared rolling traffic history.
// Sampling continues independently; painting is limited to a visible window.
Item {
  id: root

  property QtObject vpnState: null
  property QtObject strings: null
  property color foreground: Color.foreground
  property color dim: ProtonComponents.ProtonUi.secondaryText(foreground)
  property string fontFamily: Style.font.family
  readonly property QtObject monitor: vpnState ? vpnState.trafficMonitor : null
  readonly property var samples: monitor ? monitor.samples : []
  readonly property var downloadHistory: samples.map(function(p) { return p.download })
  readonly property var uploadHistory: samples.map(function(p) { return p.upload })
  readonly property bool renderActive: visible && QsWindow.window && QsWindow.window.visible
  readonly property real maximum: {
    var peak = samples.reduce(function(value, point) {
      return Math.max(value, point.download || 0, point.upload || 0)
    }, 1024)
    // Stable, labeled powers of two avoid rescaling for every small new peak.
    return Math.pow(2, Math.ceil(Math.log(peak) / Math.LN2))
  }
  onSamplesChanged: if (renderActive) chart.requestPaint()
  onRenderActiveChanged: if (renderActive) chart.requestPaint()
  onForegroundChanged: if (renderActive) chart.requestPaint()
  onDownloadColorChanged: if (renderActive) chart.requestPaint()

  readonly property color downloadColor: Color.accent
  readonly property color uploadColor: foreground
  readonly property bool trafficKnown: monitor ? monitor.known : false

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

  Column {
    id: content
    width: parent.width
    spacing: Style.space(7)

    ProtonComponents.ProtonSectionHeader {
      text: root.label('traffic')
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
            font.features: ({ "tnum": 1 })
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
            font.features: ({ "tnum": 1 })
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
      height: Style.space(60)
      radius: Style.cornerRadius
      color: Qt.rgba(root.foreground.r, root.foreground.g,
                     root.foreground.b, 0.045)
      clip: true

      Canvas {
        id: chart
        anchors.fill: parent
        anchors.margins: Style.space(7)
        antialiasing: true

        onWidthChanged: if (root.renderActive) requestPaint()
        onHeightChanged: if (root.renderActive) requestPaint()

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

          var points = root.samples
          if (points.length < 2 || !root.monitor) return
          var end = root.monitor.clockMs
          var start = end - root.monitor.windowMs
          function drawSeries(key, stroke, dashed) {
            ctx.beginPath()
            var previous = null
            for (var i = 0; i < points.length; ++i) {
              var point = points[i]
              if (point[key] === null || point.time < start) { previous = null; continue }
              var x = width * (point.time - start) / root.monitor.windowMs
              var y = height - height * point[key] / root.maximum
              // Missing samples are gaps, never fabricated zero traffic.
              if (!previous || point.time - previous.time > 2500) ctx.moveTo(x, y)
              else ctx.lineTo(x, y)
              previous = point
            }
            ctx.strokeStyle = stroke
            ctx.lineWidth = 2
            ctx.lineJoin = 'round'
            ctx.lineCap = 'round'
            ctx.setLineDash(dashed ? [4, 4] : [])
            ctx.stroke()
            ctx.setLineDash([])
          }
          drawSeries('upload', root.uploadColor, true)
          drawSeries('download', root.downloadColor, false)
        }
      }
    }
    Text {
      width: parent.width
      text: root.strings ? root.strings.text('traffic_window', { scale: root.bytes(root.maximum) }) : ''
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.features: ({ "tnum": 1 })
      wrapMode: Text.Wrap
    }
  }
}
