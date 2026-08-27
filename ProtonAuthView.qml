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
  property bool securityKeyMode: false

  readonly property bool twoFactor: vpnState &&
    vpnState.accountStatus === 'two_factor_required'
  readonly property bool securityKeyActive: vpnState &&
    vpnState.operationKind === 'account.authenticate_fido2' &&
    vpnState.operationBusy
  readonly property bool authBusy: vpnState ? vpnState.authBusy : false
  readonly property bool pinRequestBusy: vpnState &&
    vpnState.requestPending('account.submit_fido2_pin')
  readonly property bool cancelRequestBusy: vpnState &&
    vpnState.requestPending('account.cancel_fido2')
  readonly property bool authAvailable: vpnState && vpnState.agentAvailable &&
    vpnState.backendReady

  implicitHeight: content.implicitHeight

  function label(key) {
    return strings ? strings.text(key) : key
  }

  function focusInitial() {
    if (!twoFactor) usernameField.forceActiveFocus()
    else if (securityKeyMode && vpnState && vpnState.securityKeyPinRequired)
      pinField.forceActiveFocus()
    else if (!securityKeyMode) codeField.forceActiveFocus()
  }

  function feedback() {
    if (!vpnState) return ''
    if (vpnState.operationBusy)
      return strings ? strings.operationStage(vpnState.operationStage) : vpnState.operationStage
    if (vpnState.lastError !== '')
      return strings
        ? strings.error(vpnState.lastErrorCode, vpnState.lastError)
        : vpnState.lastError
    if (vpnState.agentConnecting) return label('agent_reconnecting')
    if (!vpnState.agentAvailable) return label('agent_unavailable')
    if (!vpnState.backendReady) return label('backend_unavailable')
    return ''
  }

  function submitLogin() {
    if (!authAvailable || authBusy || usernameField.text.trim().length === 0 ||
        passwordField.text.length === 0) return
    var password = passwordField.text
    passwordField.text = ''
    vpnState.login(usernameField.text.trim(), password)
    password = ''
  }

  function submitCode() {
    if (!authAvailable || authBusy || codeField.text.length !== 6) return
    var code = codeField.text
    codeField.text = ''
    vpnState.submitTwoFactor(code)
    code = ''
  }

  function submitPin() {
    if (!authAvailable || pinField.text.length === 0) return
    var pin = pinField.text
    pinField.text = ''
    vpnState.submitSecurityKeyPin(pin)
    pin = ''
  }

  onTwoFactorChanged: {
    if (!twoFactor) securityKeyMode = false
    else if (!vpnState.twoFactorCodeSupported &&
             vpnState.twoFactorSecurityKeySupported)
      securityKeyMode = true
    Qt.callLater(focusInitial)
  }

  Column {
    id: content
    width: parent.width
    spacing: Style.space(12)

    PanelHero {
      width: parent.width
      title: root.twoFactor
        ? (root.securityKeyMode
            ? root.label('security_key_title')
            : root.label('two_factor_title'))
        : root.label('sign_in_title')
      meta: root.twoFactor
        ? (root.securityKeyMode
            ? root.label('security_key_description')
            : root.label('two_factor_description'))
        : root.label('sign_in_description')
      foreground: root.foreground
      fontFamily: root.fontFamily

      iconComponent: Component {
        ProtonVpnMark {
          iconSize: Style.font.display
          statusColor: Color.accent
          state: root.authBusy ? 'connecting' : 'information'
        }
      }
    }

    Column {
      visible: root.vpnState && root.vpnState.networkBlockedKnown &&
        root.vpnState.networkBlocked && root.vpnState.killSwitchMode === 'advanced'
      width: parent.width
      spacing: Style.space(6)

      Text {
        width: parent.width
        text: root.label('advanced_kill_switch_blocked')
        color: root.urgent
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }

      Button {
        width: parent.width
        text: root.label('disable_advanced_kill_switch')
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.bodySmall
        bordered: true
        enabled: root.vpnState && root.vpnState.killSwitchWritable &&
          !root.vpnState.configurationOperationBusy
        horizontalPadding: Style.spacing.controlPaddingX
        verticalPadding: Style.spacing.controlPaddingY
        onClicked: root.vpnState.send('feature.set', {
          feature: 'kill_switch', value: 'off'
        })
      }
    }

    Column {
      visible: !root.twoFactor
      width: parent.width
      spacing: Style.space(8)

      TextField {
        id: usernameField
        width: parent.width
        placeholderText: root.label('username')
        foreground: root.foreground
        accent: Color.accent
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        enabled: root.authAvailable && !root.authBusy
        horizontalPadding: Style.spacing.controlGap
        verticalPadding: Style.spacing.controlPaddingY
        onAccepted: passwordField.forceActiveFocus()
      }

      TextField {
        id: passwordField
        width: parent.width
        password: true
        placeholderText: root.label('password')
        foreground: root.foreground
        accent: Color.accent
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        enabled: root.authAvailable && !root.authBusy
        horizontalPadding: Style.spacing.controlGap
        verticalPadding: Style.spacing.controlPaddingY
        onAccepted: root.submitLogin()
      }

      Button {
        width: parent.width
        text: root.label('sign_in')
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.body
        bordered: true
        active: true
        enabled: root.authAvailable && !root.authBusy && usernameField.text.trim().length > 0 &&
          passwordField.text.length > 0
        horizontalPadding: Style.spacing.controlPaddingX
        verticalPadding: Style.spacing.controlPaddingY
        onClicked: root.submitLogin()
      }
    }

    Column {
      visible: root.twoFactor && !root.securityKeyMode
      width: parent.width
      spacing: Style.space(8)

      TextField {
        id: codeField
        width: parent.width
        placeholderText: root.label('two_factor_code')
        foreground: root.foreground
        accent: Color.accent
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        horizontalAlignment: TextInput.AlignHCenter
        inputMethodHints: Qt.ImhDigitsOnly
        maximumLength: 6
        enabled: root.authAvailable && !root.authBusy
        horizontalPadding: Style.spacing.controlGap
        verticalPadding: Style.spacing.controlPaddingY
        validator: RegularExpressionValidator { regularExpression: /^[0-9]{0,6}$/ }
        onAccepted: root.submitCode()
      }

      Button {
        width: parent.width
        text: root.label('authenticate')
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.body
        bordered: true
        active: true
        enabled: root.authAvailable && !root.authBusy && codeField.text.length === 6
        horizontalPadding: Style.spacing.controlPaddingX
        verticalPadding: Style.spacing.controlPaddingY
        onClicked: root.submitCode()
      }

      Button {
        visible: root.vpnState && root.vpnState.twoFactorSecurityKeySupported
        width: parent.width
        text: root.label('use_security_key')
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.bodySmall
        bordered: false
        enabled: root.authAvailable && !root.authBusy
        onClicked: root.securityKeyMode = true
      }
    }

    Column {
      visible: root.twoFactor && root.securityKeyMode
      width: parent.width
      spacing: Style.space(8)

      TextField {
        id: pinField
        visible: root.vpnState && root.vpnState.securityKeyPinRequired
        width: parent.width
        password: true
        placeholderText: root.label('security_key_pin')
        foreground: root.foreground
        accent: Color.accent
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        enabled: root.authAvailable && !root.pinRequestBusy
        horizontalPadding: Style.spacing.controlGap
        verticalPadding: Style.spacing.controlPaddingY
        onAccepted: root.submitPin()
        onVisibleChanged: if (visible) Qt.callLater(forceActiveFocus)
      }

      Button {
        visible: root.vpnState && root.vpnState.securityKeyPinRequired
        width: parent.width
        text: root.label('submit_pin')
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.body
        bordered: true
        active: true
        enabled: root.authAvailable && !root.pinRequestBusy &&
          pinField.text.length > 0
        horizontalPadding: Style.spacing.controlPaddingX
        verticalPadding: Style.spacing.controlPaddingY
        onClicked: root.submitPin()
      }

      Button {
        visible: !root.securityKeyActive
        width: parent.width
        text: root.label('authenticate')
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.body
        bordered: true
        active: true
        enabled: root.authAvailable && root.vpnState.twoFactorSecurityKeySupported
        horizontalPadding: Style.spacing.controlPaddingX
        verticalPadding: Style.spacing.controlPaddingY
        onClicked: root.vpnState.authenticateWithSecurityKey()
      }

      Button {
        visible: root.securityKeyActive && root.vpnState &&
          root.vpnState.operationCancelable
        width: parent.width
        text: root.label('cancel')
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.bodySmall
        bordered: false
        enabled: !root.cancelRequestBusy
        onClicked: root.vpnState.cancelSecurityKey()
      }

      Button {
        visible: root.vpnState && root.vpnState.twoFactorCodeSupported &&
          !root.securityKeyActive
        width: parent.width
        text: root.label('use_authenticator')
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.bodySmall
        bordered: false
        onClicked: {
          root.securityKeyMode = false
          Qt.callLater(codeField.forceActiveFocus)
        }
      }
    }

    Text {
      visible: root.feedback().length > 0
      width: parent.width
      text: root.feedback()
      color: root.vpnState && root.vpnState.operationBusy ? root.dim : root.urgent
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
    }
  }
}
