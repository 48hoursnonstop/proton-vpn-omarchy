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
  property int categoryIndex: -1
  property var fieldValues: ({})
  property bool includeLogs: false
  property bool confirmingOfficialReport: false

  readonly property var category: vpnState && categoryIndex >= 0 &&
    categoryIndex < vpnState.reportCategories.length
      ? vpnState.reportCategories[categoryIndex] : null
  implicitHeight: content.implicitHeight

  function label(key) { return strings ? strings.text(key) : key }

  function chooseCategory(index) {
    categoryIndex = index
    fieldValues = ({})
    confirmingOfficialReport = false
    if (vpnState) vpnState.reportSubmitted = false
  }

  function setField(key, value) {
    var next = {}
    var keys = Object.keys(fieldValues)
    for (var index = 0; index < keys.length; ++index)
      next[keys[index]] = fieldValues[keys[index]]
    next[String(key || '')] = String(value || '')
    fieldValues = next
    confirmingOfficialReport = false
  }

  function fieldsValid() {
    if (!category || emailField.text.trim().length < 3) return false
    var fields = category.input_fields || []
    for (var index = 0; index < fields.length; ++index) {
      var field = fields[index]
      if (field.is_mandatory &&
          String(fieldValues[field.submit_label] || '').trim().length === 0)
        return false
    }
    return true
  }

  function submit() {
    if (!fieldsValid() || !confirmingOfficialReport) return
    vpnState.submitReport(
      String(category.submit_label || category.label || ''),
      emailField.text.trim(), fieldValues, includeLogs
    )
  }

  function loadSupportData() {
    if (!vpnState) return
    if (vpnState.reportIssueSupported) vpnState.loadReportCategories()
    vpnState.loadDiagnostics()
  }

  onVisibleChanged: if (visible) loadSupportData()
  Component.onCompleted: if (visible) loadSupportData()

  Column {
    id: content
    width: parent.width
    spacing: Style.space(8)

    Text {
      width: parent.width
      text: root.label('support')
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.heading
      font.weight: Font.DemiBold
    }

    PanelSectionHeader {
      text: root.label('community_support').toUpperCase()
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'bug'
      title: root.label('report_community_issue')
      subtitle: root.label('report_community_issue_description')
      detailIconName: 'arrow_out_square'
      onActivated: if (root.vpnState) root.vpnState.openCommunityIssue()
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'code'
      title: root.vpnState && root.vpnState.diagnosticsCopied
        ? root.label('diagnostics_copied') : root.label('copy_diagnostics')
      subtitle: root.label('copy_diagnostics_description')
      enabled: root.vpnState && root.vpnState.diagnosticsSummary.length > 0
      onActivated: root.vpnState.copyDiagnostics()
    }

    PanelActionRow {
      width: parent.width
      rowForeground: root.foreground
      rowFontFamily: root.fontFamily
      iconName: 'life_ring'
      title: root.label('support_center')
      subtitle: root.label('support_center_description')
      detailIconName: 'arrow_out_square'
      onActivated: if (root.vpnState)
        root.vpnState.openTrustedUrl('https://protonvpn.com/support')
    }

    PanelSeparator {
      visible: root.vpnState && root.vpnState.reportIssueSupported
      foreground: root.foreground
    }

    Text {
      visible: root.vpnState && root.vpnState.reportIssueSupported
      width: parent.width
      text: root.label('official_proton_report')
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      font.weight: Font.DemiBold
    }

    Text {
      visible: root.vpnState && root.vpnState.reportIssueSupported
      width: parent.width
      text: root.label('official_proton_report_disclosure')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    ListView {
      visible: root.vpnState && root.vpnState.reportIssueSupported && root.category === null
      width: parent.width
      height: Math.min(contentHeight, Style.space(360))
      implicitHeight: height
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      model: root.vpnState ? root.vpnState.reportCategories : []
      spacing: Style.space(2)

      delegate: PanelActionRow {
        required property int index
        required property var modelData
        width: ListView.view.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconName: 'exclamation_triangle_filled'
        title: String(modelData.label || '')
        detailIconName: 'chevron_right'
        onActivated: root.chooseCategory(index)
      }
    }

    Column {
      visible: root.vpnState && root.vpnState.reportIssueSupported &&
        root.category !== null && !root.vpnState.reportSubmitted
      width: parent.width
      spacing: Style.space(7)

      ProtonIconButton {
        iconName: 'chevron_left'
        label: root.label('categories')
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: {
          root.categoryIndex = -1
          root.confirmingOfficialReport = false
        }
      }

      Text {
        width: parent.width
        text: root.category ? String(root.category.label || '') : ''
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.weight: Font.DemiBold
        wrapMode: Text.WordWrap
      }

      Repeater {
        model: root.category ? (root.category.suggestions || []) : []

        delegate: PanelActionRow {
          required property var modelData
          width: root.width
          rowForeground: root.foreground
          rowFontFamily: root.fontFamily
          iconName: 'checkmark_circle'
          title: String(modelData.text || '')
          detailIconName: modelData.link ? 'arrow_out_square' : ''
          enabled: !!modelData.link
          onActivated: if (modelData.link && root.vpnState)
            root.vpnState.openTrustedUrl(String(modelData.link))
        }
      }

      TextField {
        id: emailField
        width: parent.width
        placeholderText: root.label('email')
        foreground: root.foreground
        accent: Color.accent
        font.family: root.fontFamily
        inputMethodHints: Qt.ImhEmailCharactersOnly
        onTextChanged: root.confirmingOfficialReport = false
      }

      Repeater {
        model: root.category ? (root.category.input_fields || []) : []

        delegate: Column {
          required property var modelData
          width: root.width
          spacing: Style.space(3)

          Text {
            width: parent.width
            text: String(modelData.label || '') + (modelData.is_mandatory ? ' *' : '')
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          TextField {
            width: parent.width
            placeholderText: String(modelData.placeholder || '')
            foreground: root.foreground
            accent: Color.accent
            font.family: root.fontFamily
            onTextChanged: root.setField(modelData.submit_label, text)
          }
        }
      }

      PanelActionRow {
        width: parent.width
        rowForeground: root.foreground
        rowFontFamily: root.fontFamily
        iconName: 'code'
        title: root.label('include_logs')
        subtitle: root.label('include_logs_description')
        toggleVisible: true
        checked: root.includeLogs
        onActivated: {
          root.includeLogs = !root.includeLogs
          root.confirmingOfficialReport = false
        }
      }

      Button {
        visible: !root.confirmingOfficialReport
        width: parent.width
        text: root.label('review_official_report')
        foreground: root.foreground
        fontFamily: root.fontFamily
        bordered: true
        active: true
        enabled: root.fieldsValid() &&
          !(root.vpnState && root.vpnState.operationBusy)
        onClicked: root.confirmingOfficialReport = true
      }

      Column {
        visible: root.confirmingOfficialReport
        width: parent.width
        spacing: Style.space(5)

        Text {
          width: parent.width
          text: root.label('confirm_official_report')
          color: root.urgent
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
          horizontalAlignment: Text.AlignHCenter
        }

        Row {
          width: parent.width
          spacing: Style.space(4)

          Button {
            width: (parent.width - parent.spacing) / 2
            text: root.label('cancel')
            foreground: root.foreground
            fontFamily: root.fontFamily
            bordered: true
            onClicked: root.confirmingOfficialReport = false
          }

          Button {
            width: (parent.width - parent.spacing) / 2
            text: root.label('send_to_proton')
            foreground: root.foreground
            fontFamily: root.fontFamily
            bordered: true
            active: true
            enabled: root.fieldsValid() &&
              !(root.vpnState && root.vpnState.operationBusy)
            onClicked: root.submit()
          }
        }
      }
    }

    Text {
      visible: root.vpnState && root.vpnState.reportIssueSupported &&
        root.vpnState.reportSubmitted
      width: parent.width
      text: root.label('official_report_sent')
      color: Color.accent
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
    }

    Text {
      visible: root.vpnState && root.vpnState.reportIssueSupported &&
        root.vpnState.reportCategoriesLoading
      width: parent.width
      text: root.label('loading_support')
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      horizontalAlignment: Text.AlignHCenter
    }
  }
}
