import QtQuick
import Quickshell
import Quickshell.Io

// Per-user Rust agent adapter. The Rust agent owns shared state while the
// official Proton Linux core owns every VPN and protection mutation.
QtObject {
  id: root

  readonly property string socketPath: {
    var runtimeDir = Quickshell.env('XDG_RUNTIME_DIR')
    return runtimeDir && runtimeDir.length > 0
      ? runtimeDir + '/proton-omarchy.sock'
      : ''
  }
  readonly property string lifecyclePath: {
    var configHome = Quickshell.env('XDG_CONFIG_HOME')
    if (!configHome || configHome.length === 0)
      configHome = Quickshell.env('HOME') + '/.config'
    return configHome + '/proton-vpn-omarchy/lifecycle.json'
  }

  property bool agentAvailable: false
  property bool lifecyclePreferenceKnown: false
  property bool cachedStartWithOmarchy: true
  property bool frontendDemanded: false
  property bool socketWanted: false
  onSocketWantedChanged: {
    if (agentSocket.connected !== socketWanted)
      agentSocket.connected = socketWanted
  }
  property int socketRetryAttempt: 0
  readonly property bool agentConnecting:
    socketPath.length > 0 && !agentSocket.connected
  property bool coreAvailable: false
  readonly property bool backendReady: coreAvailable // pre-audit compatibility alias
  property bool settingsKnown: false
  property bool connectorInitialized: false
  property bool backendDemanded: false
  property bool backendActivationRequested: false
  property bool connectionObservationRequested: false
  property string queuedAgentAction: ''
  property bool connectionAvailable: false
  property bool connectionAvailabilityKnown: false
  property bool connectionObservationKnown: false
  property string backendCoreVersion: ''
  property bool networkBlockedKnown: false
  property bool networkBlocked: false
  property string accountStatus: 'unknown'
  property string accountName: ''
  property int accountTier: -1
  property bool twoFactorCodeSupported: false
  property bool twoFactorSecurityKeySupported: false
  property bool ssoSupported: false
  property string backendKind: ''
  property var requestMethods: []
  property var capabilities: []
  readonly property bool reportIssueSupported:
    supportsMethod('report_issue.categories.get') && supportsMethod('report_issue.submit')
  readonly property bool accountUpgradeSupported: supportsMethod('account.upgrade_url')

  property bool storeReady: false
  property int storeRevision: 0
  property bool onboardingComplete: false
  property string locale: 'es-MX'
  property bool startWithOmarchy: true
  property bool autoConnect: false
  property bool notificationsEnabled: true
  property bool portForwardingNotificationsEnabled: true
  property bool accountScopeKnown: false
  property int profileCount: 0
  property int recentCount: 0
  property var defaultConnection: ({ type: 'fastest' })
  property bool defaultConnectCancelRequested: false
  property bool legacyMigrationAvailable: false
  property var profiles: []
  property var excludedLocations: []
  property var recents: []
  property var countries: []
  property var gateways: []
  property var servers: []
  property var installedApps: []
  property int installedAppTotal: 0
  property string desiredAppQuery: ''
  readonly property bool appsLoading: requestPending('apps.get')
  property var reportCategories: []
  property bool reportSubmitted: false
  property var diagnosticsSources: []
  property var diagnosticsFailures: []
  property bool diagnosticsRawContentsExposed: false
  readonly property bool reportCategoriesLoading: requestPending('report_issue.categories.get')
  readonly property bool diagnosticsLoading: requestPending('diagnostics.get')
  property int serverTotal: 0
  property string desiredServerQuery: ''
  property string desiredServerCountry: ''
  property string desiredServerGateway: ''
  property string desiredServerFeature: ''
  readonly property bool locationsLoading: requestPending('locations.get')
  readonly property bool serversLoading: requestPending('servers.get')

  property int revision: 0
  property string status: 'unknown'
  property string countryCode: ''
  property string countryName: ''
  property string city: ''
  property string serverName: ''
  property string serverIp: ''
  property string protocol: ''
  property string connectionErrorCode: ''
  property int restrictionReasonCode: 0
  property int latencyMs: 0
  property bool trafficKnown: false
  property double downloadBytes: 0
  property double uploadBytes: 0
  property double downloadBytesPerSecond: 0
  property double uploadBytesPerSecond: 0
  property bool deviceLocationKnown: false
  property string deviceIpAddress: ''
  property string deviceCountryCode: ''
  property string deviceIsp: ''

  property string killSwitchMode: 'off'
  property int netShieldLevel: 0
  property bool netShieldStatisticsKnown: false
  property int netShieldMalwareBlocked: 0
  property int netShieldAdsBlocked: 0
  property int netShieldTrackersBlocked: 0
  property bool moderateNat: false
  property bool moderateNatWritable: false
  property bool ipv6: true
  property bool ipv6Writable: false
  property bool ipv6LeakProtection: true
  property bool ipv6LeakProtectionWritable: false
  property bool alternativeRouting: true
  property bool alternativeRoutingWritable: false
  property bool allowLanConnections: false
  property bool allowLanConnectionsWritable: false
  property bool allowLocalDns: false
  property bool allowLocalDnsWritable: false
  property string splitTunnelingMode: 'off'
  property bool splitTunnelingAvailabilityKnown: false
  property bool splitTunnelingAvailable: false
  property bool splitAppPathsSupported: false
  property bool splitIpRangesSupported: false
  property var splitStandardApps: []
  property var splitInverseApps: []
  property var splitStandardIpRanges: []
  property var splitInverseIpRanges: []
  property bool secureCore: false
  property bool portForwarding: false
  property int activePort: 0
  property string selectedProtocol: ''
  property var availableProtocols: []
  property var availableProfileProtocols: []
  property bool protocolWritable: false
  property bool vpnAccelerator: false
  property bool vpnAcceleratorWritable: false
  property bool anonymousCrashReports: false
  property bool anonymousCrashReportsWritable: false
  property bool anonymousUsageStatistics: false
  property bool anonymousUsageStatisticsWritable: false
  property bool connectionFeedbackAvailable: false
  property bool connectionFeedbackViewed: false
  property bool connectionFeedbackSent: false
  property bool customDns: false
  property var customDnsServers: []
  property bool featuresKnown: false
  property bool featuresWritable: false
  property bool killSwitchWritable: false
  property bool netShieldWritable: false
  property bool customDnsWritable: false
  property bool secureCoreWritable: false
  property bool splitTunnelingWritable: false
  property bool portForwardingWritable: false

  property string lastError: ''
  property string lastErrorCode: ''
  property var lastErrorDetails: null
  property bool lastErrorRetryable: false
  property string lastRequestedAction: ''
  property int nextRequestId: 1
  readonly property string clientInstanceId: 'plugin-' + Date.now() + '-' +
    Math.floor(Math.random() * 0x100000000).toString(16)
  property string serverClientInstanceId: ''
  property var pendingRequests: ({})
  property var pendingConnectionRecents: ({})
  property var pendingPostConnectActions: ({})
  property var queuedPostConnectAction: null
  property int pendingCount: 0
  property string localPendingMethod: ''
  property string lastResponseMethod: ''
  property var activeOperations: []
  property var recentOperations: []
  property string lastHandledOperationId: ''

  readonly property var ownActiveOperation: operationForClient()
  readonly property var foregroundOperation: ownActiveOperation ||
    (activeOperations.length > 0 ? activeOperations[0] : null)
  readonly property bool operationBusy: foregroundOperation !== null ||
    localPendingMethod.length > 0
  readonly property string operationStage: foregroundOperation && foregroundOperation.stage
    ? String(foregroundOperation.stage) : localStageForMethod(localPendingMethod)
  readonly property string operationKind: foregroundOperation && foregroundOperation.kind
    ? String(foregroundOperation.kind) : localPendingMethod
  readonly property bool operationCancelable: foregroundOperation
    ? !!foregroundOperation.cancelable
    : operationKind === 'connection.connect' || operationKind === 'connection.resolve'
  readonly property bool authBusy: operationBusy && (
    (foregroundOperation && foregroundOperation.domain === 'auth_session') ||
    operationKind.indexOf('account.') === 0
  )
  readonly property bool securityKeyPinRequired:
    operationKind === 'account.authenticate_fido2' &&
    (operationStage === 'auth.security_key_pin_required' ||
     operationStage === 'auth.security_key_pin_failed')

  readonly property bool signedIn: accountStatus === 'signed_in'
  readonly property bool connected: status === 'connected'
  readonly property bool tunnelOperationBusy: methodsBusy([
    'connection.resolve', 'connection.connect', 'connection.cancel',
    'connection.disconnect'
  ])
  readonly property bool configurationOperationBusy: methodsBusy([
    'feature.set', 'protocol.set', 'dns.set', 'split_tunneling.set'
  ])
  readonly property bool tunnelConfigurationBusy: tunnelOperationBusy ||
    configurationOperationBusy
  readonly property bool storeOperationBusy: methodsBusy([
    'onboarding.complete', 'preferences.set', 'profiles.save',
    'profiles.delete', 'excluded_locations.set', 'recents.record', 'recents.pin', 'recents.delete',
    'default_connection.set'
  ])
  readonly property bool supportOperationBusy: methodsBusy([
    'report_issue.submit'
  ])
  readonly property bool connecting: status === 'connecting' ||
    ((operationKind === 'connection.connect' || operationKind === 'connection.resolve') &&
     operationBusy) || queuedAgentAction === 'quick-connect'
  readonly property bool disconnected: status === 'disconnected'
  readonly property bool killSwitch: killSwitchMode !== 'off'
  readonly property bool netShield: netShieldLevel > 0
  readonly property bool splitTunneling: splitTunnelingMode !== 'off'

  signal stateChangedByUser()
  signal actionRequested(string action)
  signal requestStarted(string requestId, string method)
  signal requestFinished(string requestId, string method, bool ok, string errorCode)

  function applyLifecycleCache(raw) {
    var parsed = null
    try {
      parsed = JSON.parse(String(raw || ''))
    } catch (_error) {
      parsed = null
    }
    cachedStartWithOmarchy = parsed && parsed.version === 1
      ? parsed.start_with_omarchy !== false : true
    lifecyclePreferenceKnown = true
    syncSocketDemand()
  }

  function demandAgent(demanded) {
    frontendDemanded = !!demanded
    syncSocketDemand()
  }

  function socketDemandActive() {
    return socketPath.length > 0 && lifecyclePreferenceKnown && (
      cachedStartWithOmarchy || frontendDemanded || connected || connecting || operationBusy
    )
  }

  function syncSocketDemand() {
    var shouldConnect = socketDemandActive()
    if (!shouldConnect) {
      socketRetryTimer.stop()
      socketWanted = false
    } else if (!socketRetryTimer.running) {
      socketWanted = true
    }
  }

  function markAgentUnavailable() {
    agentAvailable = false
    backendKind = ''
    requestMethods = []
    capabilities = []
    coreAvailable = false
    settingsKnown = false
    connectorInitialized = false
    connectionAvailabilityKnown = false
    connectionObservationKnown = false
    connectionObservationRequested = false
  }

  function supportsMethod(method) {
    return requestMethods.indexOf(String(method || '')) >= 0
  }

  function hasCapability(capability) {
    return capabilities.indexOf(String(capability || '')) >= 0
  }

  function scheduleSocketRetry() {
    if (!socketDemandActive() || socketRetryTimer.running)
      return

    socketWanted = false
    socketRetryTimer.interval = Math.min(
      30000,
      250 * Math.pow(2, Math.min(socketRetryAttempt, 7))
    )
    socketRetryAttempt += 1
    socketRetryTimer.restart()
  }

  function operationForClient() {
    var instanceId = serverClientInstanceId || clientInstanceId
    for (var index = 0; index < activeOperations.length; ++index) {
      var operation = activeOperations[index]
      if (operation && operation.initiator_client_instance_id === instanceId)
        return operation
    }
    return null
  }

  function requestPending(method) {
    var keys = Object.keys(pendingRequests)
    for (var index = 0; index < keys.length; ++index) {
      if (pendingRequests[keys[index]] &&
          pendingRequests[keys[index]].method === method)
        return true
    }
    return false
  }

  function methodsBusy(methods) {
    var allowed = methods || []
    var pendingKeys = Object.keys(pendingRequests)
    for (var pendingIndex = 0; pendingIndex < pendingKeys.length; ++pendingIndex) {
      var pending = pendingRequests[pendingKeys[pendingIndex]] || {}
      if (allowed.indexOf(String(pending.method || '')) >= 0)
        return true
    }
    for (var operationIndex = 0; operationIndex < activeOperations.length;
         ++operationIndex) {
      var operation = activeOperations[operationIndex] || {}
      if (operation.state === 'running' &&
          allowed.indexOf(String(operation.kind || '')) >= 0)
        return true
    }
    return false
  }

  function protocolName(value) {
    switch (String(value || '').toLowerCase()) {
    case 'smart':
    case 'protun-smart': return 'Smart'
    case 'wireguard':
    case 'wireguard-udp': return 'WireGuard'
    case 'wireguard-tcp': return 'WireGuard TCP'
    case 'wireguard-tls': return 'Stealth'
    case 'protun-udp': return 'WireGuard UDP'
    case 'protun-tcp': return 'WireGuard TCP'
    case 'protun-tls': return 'Stealth'
    case 'openvpn': return 'OpenVPN'
    case 'openvpn-udp': return 'OpenVPN UDP'
    case 'openvpn-tcp': return 'OpenVPN TCP'
    default: return String(value || '')
    }
  }

  function localStageForMethod(method) {
    switch (String(method || '')) {
    case 'account.login': return 'auth.submitting_credentials'
    case 'account.submit_2fa': return 'auth.submitting_two_factor'
    case 'account.authenticate_fido2': return 'auth.scanning_security_keys'
    case 'account.submit_fido2_pin': return 'auth.submitting_security_key_pin'
    case 'account.cancel_fido2': return 'auth.cancelling_security_key'
    case 'account.logout': return 'auth.signing_out'
    case 'connection.connect': return 'tunnel.preparing_connection'
    case 'connection.resolve': return 'tunnel.selecting_server'
    case 'connection.disconnect': return 'tunnel.disconnecting'
    case 'connection.cancel': return 'tunnel.cancelling'
    case 'report_issue.submit': return 'support.submitting_report'
    case 'feature.set': return 'settings.applying_feature'
    case 'protocol.set': return 'settings.applying_protocol'
    case 'dns.set': return 'settings.applying_dns'
    case 'split_tunneling.set': return 'settings.applying_split_tunneling'
    case 'onboarding.complete':
    case 'preferences.set':
    case 'profiles.save':
    case 'profiles.delete':
    case 'excluded_locations.set':
    case 'recents.record':
    case 'recents.pin':
    case 'recents.delete':
    case 'default_connection.set': return 'store.saving'
    default: return method ? 'request.submitting' : ''
    }
  }

  function trackRequest(id, method) {
    var next = {}
    var keys = Object.keys(pendingRequests)
    for (var index = 0; index < keys.length; ++index)
      next[keys[index]] = pendingRequests[keys[index]]
    next[id] = {
      method: String(method),
      started_at_unix_ms: Date.now()
    }
    pendingRequests = next
    pendingCount = Object.keys(next).length
    localPendingMethod = String(method)
    requestStarted(id, String(method))
    syncSocketDemand()
  }

  function completeRequest(id, ok, errorCode) {
    var key = String(id || '')
    var completed = pendingRequests[key] || null
    var next = {}
    var keys = Object.keys(pendingRequests)
    for (var index = 0; index < keys.length; ++index) {
      if (keys[index] !== key)
        next[keys[index]] = pendingRequests[keys[index]]
    }
    pendingRequests = next
    var remaining = Object.keys(next)
    pendingCount = remaining.length
    localPendingMethod = remaining.length > 0
      ? String(next[remaining[0]].method || '') : ''
    var method = completed ? String(completed.method || '') : ''
    lastResponseMethod = method
    requestFinished(key, method, !!ok, String(errorCode || ''))
    syncSocketDemand()
    return method
  }

  function clearPendingRequests(code, message) {
    var keys = Object.keys(pendingRequests)
    for (var index = 0; index < keys.length; ++index) {
      var pending = pendingRequests[keys[index]] || {}
      requestFinished(
        keys[index],
        String(pending.method || ''),
        false,
        String(code || 'agent_disconnected')
      )
    }
    pendingRequests = ({})
    pendingConnectionRecents = ({})
    pendingPostConnectActions = ({})
    queuedPostConnectAction = null
    postConnectTimer.stop()
    pendingCount = 0
    localPendingMethod = ''
    if (code) lastErrorCode = String(code)
    if (message) lastError = String(message)
    lastErrorDetails = null
    lastErrorRetryable = true
  }

  function send(method, params) {
    if (!agentSocket.connected) {
      lastError = 'Agent socket is not connected'
      lastErrorCode = 'agent_disconnected'
      lastErrorDetails = null
      lastErrorRetryable = true
      return ''
    }

    if (method !== 'hello' && agentAvailable && !supportsMethod(method)) {
      lastError = 'This operation is unavailable on the active Proton backend'
      lastErrorCode = 'feature_unavailable'
      lastErrorDetails = { method: String(method || ''), backend: backendKind }
      lastErrorRetryable = false
      return ''
    }

    var id = String(nextRequestId++)
    var frame = JSON.stringify({
      v: 1,
      id: id,
      type: 'request',
      method: String(method),
      params: params || {}
    }) + '\n'

    if (frame.length > 64 * 1024) {
      lastError = 'Outgoing IPC frame exceeds 64 KiB'
      lastErrorCode = 'frame_too_large'
      lastErrorDetails = null
      lastErrorRetryable = false
      return ''
    }

    trackRequest(id, method)
    agentSocket.write(frame)
    agentSocket.flush()
    return id
  }

  function rememberConnectionRecent(requestId, recent) {
    var key = String(requestId || '')
    if (!key || !recent) return
    var next = {}
    var keys = Object.keys(pendingConnectionRecents)
    for (var index = 0; index < keys.length; ++index)
      next[keys[index]] = pendingConnectionRecents[keys[index]]
    next[key] = recent
    pendingConnectionRecents = next
  }

  function takeConnectionRecent(requestId) {
    var key = String(requestId || '')
    var recent = pendingConnectionRecents[key] || null
    var next = {}
    var keys = Object.keys(pendingConnectionRecents)
    for (var index = 0; index < keys.length; ++index) {
      if (keys[index] !== key)
        next[keys[index]] = pendingConnectionRecents[keys[index]]
    }
    pendingConnectionRecents = next
    return recent
  }

  function rememberPostConnectAction(requestId, action) {
    var key = String(requestId || '')
    if (!key || !action) return
    var next = {}
    var keys = Object.keys(pendingPostConnectActions)
    for (var index = 0; index < keys.length; ++index)
      next[keys[index]] = pendingPostConnectActions[keys[index]]
    next[key] = action
    pendingPostConnectActions = next
  }

  function takePostConnectAction(requestId) {
    var key = String(requestId || '')
    var action = pendingPostConnectActions[key] || null
    var next = {}
    var keys = Object.keys(pendingPostConnectActions)
    for (var index = 0; index < keys.length; ++index) {
      if (keys[index] !== key)
        next[keys[index]] = pendingPostConnectActions[keys[index]]
    }
    pendingPostConnectActions = next
    return action
  }

  function schedulePostConnectAction(action) {
    if (!action) return
    if (!supportsMethod('system.launch')) {
      deferFeature('connect_and_go_unavailable',
                   'Connect and Go is unavailable on the current backend.')
      return
    }
    queuedPostConnectAction = action
    postConnectTimer.restart()
  }

  function hello() {
    send('hello', {
      client: 'plugin',
      client_version: '0.8.0',
      client_instance_id: clientInstanceId
    })
  }

  function activateBackend() {
    backendDemanded = true
    demandAgent(true)
    if (agentSocket.connected && !backendActivationRequested) {
      backendActivationRequested = true
      send('account.get', {})
    }
  }

  function requestConnectionObservation() {
    if (!signedIn || connectionObservationKnown || connectionObservationRequested ||
        requestPending('connection.observe')) return ''
    connectionObservationRequested = true
    return send('connection.observe', {})
  }

  function queueAgentAction(action) {
    queuedAgentAction = String(action || '')
    activateBackend()
  }

  function maybeRunQueuedAction() {
    if (!queuedAgentAction || !agentSocket.connected) return
    if (accountStatus === 'signed_out' || accountStatus === 'two_factor_required' ||
        accountStatus === 'error') {
      queuedAgentAction = ''
      requestAction('login')
      return
    }
    if (!signedIn) return
    if (!connectionObservationKnown) {
      requestConnectionObservation()
      return
    }

    var action = queuedAgentAction
    queuedAgentAction = ''
    if (action === 'quick-connect') quickConnect()
    else if (action === 'disconnect') disconnect()
  }

  function login(username, password) {
    return send('account.login', {
      username: String(username || ''),
      password: String(password || '')
    })
  }

  function submitTwoFactor(code) {
    return send('account.submit_2fa', { code: String(code || '') })
  }

  function authenticateWithSecurityKey() {
    return send('account.authenticate_fido2', {})
  }

  function submitSecurityKeyPin(pin) {
    return send('account.submit_fido2_pin', { pin: String(pin || '') })
  }

  function cancelSecurityKey() {
    return send('account.cancel_fido2', {})
  }

  function logout() {
    return send('account.logout', {})
  }

  function openTrustedUrl(rawUrl) {
    var value = String(rawUrl || '').trim()
    if (value.length === 0 || value.length > 2048 || /[\u0000-\u001f]/.test(value)) {
      lastError = 'Refusing an invalid external URL'
      lastErrorCode = 'invalid_external_url'
      return false
    }
    var exact = [
      'https://protonvpn.com',
      'https://www.protonvpn.com',
      'https://proton.me',
      'https://account.proton.me',
      'https://account.protonvpn.com',
      'https://github.com/ProtonVPN',
      'https://www.gnu.org'
    ]
    for (var index = 0; index < exact.length; ++index) {
      if (value === exact[index] || value.indexOf(exact[index] + '/') === 0) {
        Qt.openUrlExternally(value)
        return true
      }
    }
    lastError = 'Refusing an untrusted external URL'
    lastErrorCode = 'untrusted_external_url'
    return false
  }

  function openAccountManagement() {
    return openTrustedUrl('https://account.protonvpn.com/')
  }

  function openUpgrade() {
    return send('account.upgrade_url', { modal_source: 'OmarchyPlugin' })
  }

  function completeOnboarding(selectedLocale, startAtLogin, connectAtLogin) {
    return send('onboarding.complete', {
      locale: String(selectedLocale || 'es-MX'),
      start_with_omarchy: !!startAtLogin,
      auto_connect: !!connectAtLogin
    })
  }

  function setPreferences(selectedLocale, startAtLogin, connectAtLogin) {
    return send('preferences.set', {
      locale: String(selectedLocale || locale),
      start_with_omarchy: !!startAtLogin,
      auto_connect: !!connectAtLogin,
      notifications_enabled: notificationsEnabled,
      port_forwarding_notifications_enabled: portForwardingNotificationsEnabled
    })
  }

  function setNotifications(enabled) {
    return send('preferences.set', { notifications_enabled: !!enabled })
  }

  function setPortForwardingNotifications(enabled) {
    return send('preferences.set', {
      port_forwarding_notifications_enabled: !!enabled
    })
  }

  function loadProfiles(offset) {
    return send('profiles.list', { offset: Number(offset || 0), limit: 100 })
  }

  function saveProfile(profile) {
    return send('profiles.save', { profile: profile || {} })
  }

  function deleteProfile(id) {
    return send('profiles.delete', { id: String(id || '') })
  }

  function loadExcludedLocations() {
    return send('excluded_locations.get', {})
  }

  function setExcludedLocations(items) {
    return send('excluded_locations.set', { items: items || [] })
  }

  function loadRecents(offset) {
    return send('recents.list', { offset: Number(offset || 0), limit: 100 })
  }

  function setRecentPinned(id, pinned) {
    return send('recents.pin', { id: String(id || ''), pinned: !!pinned })
  }

  function deleteRecent(id) {
    return send('recents.delete', { id: String(id || '') })
  }

  function setDefaultConnection(selection) {
    return send('default_connection.set', { selection: selection || {} })
  }

  function resolveConnection(selection) {
    defaultConnectCancelRequested = false
    var params = selection ? { selection: selection } : {}
    return send('connection.resolve', params)
  }

  function loadLocations() {
    return send('locations.get', {})
  }

  function loadServers(query, countryCode, gatewayName, feature) {
    desiredServerQuery = String(query || '').trim().toLowerCase()
    desiredServerCountry = String(countryCode || '').trim().toUpperCase()
    desiredServerGateway = String(gatewayName || '').trim()
    desiredServerFeature = String(feature || '').trim().toLowerCase()
    return send('servers.get', {
      offset: 0,
      limit: 100,
      query: desiredServerQuery,
      country_code: desiredServerCountry,
      gateway_name: desiredServerGateway,
      feature: desiredServerFeature
    })
  }

  function connectTarget(target, recent) {
    var requestId = send('connection.connect', { target: target || {} })
    if (requestId && recent)
      rememberConnectionRecent(requestId, recent)
    stateChangedByUser()
    return requestId
  }

  function connectCountry(country, feature) {
    if (!country) return ''
    var requestedFeature = ['secure_core', 'p2p', 'tor'].indexOf(feature) >= 0
      ? feature : 'standard'
    var target = { country_code: String(country.code || '') }
    if (requestedFeature === 'p2p') target.p2p = true
    else if (requestedFeature === 'tor') target.tor = true
    else if (requestedFeature === 'secure_core') target.secure_core = true
    return connectTarget(target, {
      kind: 'country',
      header: String(country.name || country.code || ''),
      description: 'Fastest server',
      countryCode: String(country.code || ''),
      countryName: String(country.name || ''),
      feature: requestedFeature
    })
  }

  function connectServer(server) {
    if (!server) return ''
    var gateway = String(server.gateway_name || '')
    var secureCoreServer = !!server.secure_core
    return connectTarget({
      country_code: String(server.country_code || ''),
      server_name: String(server.name || ''),
      gateway_name: gateway,
      secure_core: secureCoreServer
    }, {
      kind: gateway ? 'gatewayServer' : secureCoreServer ? 'secureCore' : 'server',
      header: gateway || String(server.country_name || server.country_code || ''),
      description: String(server.name || ''),
      gatewayName: gateway,
      countryCode: String(server.country_code || ''),
      countryName: String(server.country_name || ''),
      entryCountryCode: String(server.entry_country_code || ''),
      entryCountryName: String(server.entry_country_name || ''),
      city: String(server.city || ''),
      serverName: String(server.name || ''),
      load: Number(server.load || 0)
    })
  }

  function connectGateway(gateway) {
    if (!gateway) return ''
    return connectTarget({ gateway_name: String(gateway.name || '') }, {
      kind: 'gateway',
      header: String(gateway.name || ''),
      description: 'Fastest gateway',
      gatewayName: String(gateway.name || '')
    })
  }

  function connectProfile(profile) {
    if (!profile) return ''
    if (requestPending('connection.resolve')) return ''
    return resolveConnection({
      type: 'profile', profileId: String(profile.id || '')
    })
  }

  function connectRecent(recent) {
    if (!recent || requestPending('connection.resolve')) return ''
    return resolveConnection({
      type: 'recent', recentId: String(recent.id || '')
    })
  }

  function setProtocol(value) {
    if (tunnelConfigurationBusy) return ''
    return send('protocol.set', { value: String(value || '') })
  }

  function setFeature(name, value) {
    if (tunnelConfigurationBusy) return ''
    return send('feature.set', { feature: String(name || ''), value: value })
  }

  function setCustomDns(enabled, servers) {
    if (tunnelConfigurationBusy) return ''
    return send('dns.set', { enabled: !!enabled, servers: servers || [] })
  }

  function refreshTraffic() {
    if (!connected || requestPending('traffic.get')) return ''
    return send('traffic.get', {})
  }

  function refreshNetShieldStatistics() {
    if (!connected || netShieldLevel <= 0 || requestPending('netshield.stats.get')) return ''
    return send('netshield.stats.get', {})
  }

  function setConnectionFeedback(value) {
    if (!connectionFeedbackAvailable || requestPending('connection.feedback')) return ''
    return send('connection.feedback', { value: String(value || '') })
  }

  function loadApps(query) {
    desiredAppQuery = String(query || '').trim().toLowerCase()
    return send('apps.get', { offset: 0, limit: 100, query: desiredAppQuery })
  }

  function applySplitTunneling(enabled, mode, standardApps, inverseApps,
                               standardIpRanges, inverseIpRanges) {
    if (tunnelConfigurationBusy) return ''
    return send('split_tunneling.set', {
      enabled: !!enabled,
      mode: String(mode || 'standard'),
      standard: {
        app_paths: standardApps || [],
        ip_ranges: standardIpRanges || []
      },
      inverse: {
        app_paths: inverseApps || [],
        ip_ranges: inverseIpRanges || []
      }
    })
  }

  function loadReportCategories() {
    return send('report_issue.categories.get', {})
  }

  function loadDiagnostics() {
    return send('diagnostics.get', {})
  }

  function submitReport(category, email, fields, includeLogs) {
    reportSubmitted = false
    return send('report_issue.submit', {
      category: String(category || ''),
      email: String(email || ''),
      fields: fields || {},
      include_logs: includeLogs !== false
    })
  }

  function quickConnect() {
    if (!agentSocket.connected || accountStatus === 'unknown' ||
        (signedIn && !connectionObservationKnown)) {
      queueAgentAction('quick-connect')
      return
    }
    if (!signedIn) {
      lastError = 'Sign in to Proton VPN first.'
      lastErrorCode = 'not_authenticated'
      requestAction('login')
      return
    }
    if (connectionAvailabilityKnown && !connectionAvailable) {
      lastError = 'Proton Linux connection backend is unavailable.'
      lastErrorCode = 'backend_unavailable'
      return
    }
    if (connected || connecting) return

    if (!requestPending('connection.resolve'))
      resolveConnection(null)
  }

  function disconnect() {
    if (!agentSocket.connected || accountStatus === 'unknown' ||
        (signedIn && !connectionObservationKnown)) {
      queueAgentAction('disconnect')
      return
    }
    if (connecting) {
      cancelConnection()
      return
    }
    send('connection.disconnect', {})
    stateChangedByUser()
  }

  function cancelConnection() {
    send('connection.cancel', {})
    stateChangedByUser()
  }

  function toggleConnection() {
    if (requestPending('connection.resolve'))
      defaultConnectCancelRequested = true
    else if (connecting) cancelConnection()
    else if (tunnelOperationBusy) return
    else if (connected) disconnect()
    else quickConnect()
  }

  function deferFeature(code, message) {
    lastErrorCode = String(code || 'feature_unavailable')
    lastError = message
    lastErrorDetails = null
    lastErrorRetryable = false
  }

  function toggleKillSwitch() {
    if (tunnelConfigurationBusy) return
    if (!killSwitchWritable) {
      deferFeature('feature_unavailable',
                   'Kill Switch is unavailable on the current Proton backend.')
      return
    }

    send('feature.set', {
      feature: 'kill_switch',
      value: killSwitch ? 'off' : 'standard'
    })
    stateChangedByUser()
  }

  function toggleNetShield() {
    if (tunnelConfigurationBusy) return
    if (!netShieldWritable) {
      deferFeature('feature_unavailable',
                   'NetShield is unavailable on the current Proton backend.')
      return
    }

    send('feature.set', {
      feature: 'netshield',
      value: netShield ? 0 : 2
    })
    stateChangedByUser()
  }

  function toggleSplitTunneling() {
    if (tunnelConfigurationBusy) return
    if (!signedIn) {
      deferFeature('not_authenticated', 'Sign in to Proton VPN first.')
      requestAction('login')
      return
    }
    if (!splitTunnelingWritable ||
        (splitTunnelingAvailabilityKnown &&
         (!splitTunnelingAvailable || !splitAppPathsSupported))) {
      deferFeature('split_tunneling_unavailable',
                   'Split tunneling is unavailable on the current Proton backend.')
      return
    }
    if (killSwitch) {
      deferFeature('split_tunneling_kill_switch_conflict',
                   'Turn Kill Switch off before enabling Split Tunneling.')
      return
    }

    if (!splitTunneling && splitStandardApps.length === 0) {
      deferFeature('split_tunneling_empty_selection',
                   'Configure at least one excluded app first.')
      requestAction('split-tunneling-settings')
      return
    }

    if (splitTunneling) {
      send('split_tunneling.set', {
        enabled: false,
        mode: splitTunnelingMode === 'inverse' ? 'inverse' : 'standard',
        standard: {
          app_paths: splitStandardApps,
          ip_ranges: splitStandardIpRanges
        },
        inverse: {
          app_paths: splitInverseApps,
          ip_ranges: splitInverseIpRanges
        }
      })
    } else {
      send('split_tunneling.set', {
        enabled: true,
        mode: 'standard',
        standard: {
          app_paths: splitStandardApps,
          ip_ranges: splitStandardIpRanges
        },
        inverse: {
          app_paths: splitInverseApps,
          ip_ranges: splitInverseIpRanges
        }
      })
    }
    stateChangedByUser()
  }

  function toggleSecureCore() {
    if (tunnelOperationBusy) return
    if (!signedIn) {
      deferFeature('not_authenticated', 'Sign in to Proton VPN first.')
      requestAction('login')
      return
    }
    if (!secureCoreWritable ||
        (connectionAvailabilityKnown && !connectionAvailable)) {
      deferFeature('feature_unavailable',
                   'Secure Core is unavailable on the current Proton backend.')
      return
    }

    send('connection.connect', secureCore
      ? {}
      : { target: { secure_core: true } })
    stateChangedByUser()
  }

  function requestAction(action) {
    lastRequestedAction = String(action || '')
    actionRequested(lastRequestedAction)
  }

  function handleLine(line) {
    if (!line || line.length === 0) return
    if (line.length > 64 * 1024) {
      lastError = 'Incoming IPC frame exceeds 64 KiB'
      return
    }

    var message
    try {
      message = JSON.parse(line)
    } catch (error) {
      lastError = 'Invalid JSON from agent: ' + error
      return
    }

    if (message.v !== 1) {
      lastError = 'Unsupported agent protocol version'
      return
    }

    if (message.type === 'response') {
      var responseError = message.error || {}
      var completedMethod = completeRequest(
        message.id,
        !!message.ok,
        responseError.code || ''
      )
      var completedRecent = completedMethod === 'connection.connect'
        ? takeConnectionRecent(message.id) : null
      var completedPostConnect = completedMethod === 'connection.connect'
        ? takePostConnectAction(message.id) : null
      if (!message.ok) {
        if (completedMethod === 'account.get') {
          backendActivationRequested = false
          queuedAgentAction = ''
        }
        if (completedMethod === 'connection.observe')
          connectionObservationRequested = false
        lastError = responseError.message
          ? String(responseError.message)
          : 'Agent request failed'
        lastErrorCode = String(responseError.code || 'request_failed')
        lastErrorDetails = responseError.details || null
        lastErrorRetryable = !!responseError.retryable
        return
      }
      if (completedMethod && completedMethod !== 'hello' && completedMethod !== 'state.get') {
        lastError = ''
        lastErrorCode = ''
        lastErrorDetails = null
        lastErrorRetryable = false
      }
      if (message.result && message.result.protocol_version === 1) {
        agentAvailable = true
        backendKind = String(message.result.backend || '')
        requestMethods = Array.isArray(message.result.request_methods)
          ? message.result.request_methods : []
        capabilities = Array.isArray(message.result.capabilities)
          ? message.result.capabilities : []
        serverClientInstanceId = String(
          message.result.client_instance_id || clientInstanceId
        )
      }
      if (message.result && completedMethod === 'store.get')
        applyStoreSnapshot(message.result)
      else if (message.result && completedMethod === 'account.get') {
        if (message.result.logged_in) requestConnectionObservation()
        else maybeRunQueuedAction()
      }
      else if (completedMethod === 'connection.observe') {
        connectionObservationRequested = false
        maybeRunQueuedAction()
      }
      else if (message.result && completedMethod === 'profiles.list')
        profiles = Array.isArray(message.result.items) ? message.result.items : []
      else if (message.result && completedMethod === 'excluded_locations.get')
        excludedLocations = Array.isArray(message.result.items) ? message.result.items : []
      else if (message.result && completedMethod === 'excluded_locations.set')
        excludedLocations = Array.isArray(message.result.items) ? message.result.items : []
      else if (message.result && completedMethod === 'recents.list')
        recents = Array.isArray(message.result.items) ? message.result.items : []
      else if (message.result && completedMethod === 'connection.resolve') {
        if (!defaultConnectCancelRequested) {
          var connectParams = message.result.connect_params || {}
          var connectRequest = send('connection.connect', connectParams)
          if (connectRequest && message.result.recent)
            rememberConnectionRecent(connectRequest, message.result.recent)
          if (connectRequest && message.result.post_connect)
            rememberPostConnectAction(connectRequest, message.result.post_connect)
          if (connectRequest) stateChangedByUser()
        }
        defaultConnectCancelRequested = false
      }
      else if (completedMethod === 'connection.connect') {
        if (completedMethod === 'connection.connect' && completedRecent)
          send('recents.record', { recent: completedRecent })
        if (completedPostConnect)
          schedulePostConnectAction(completedPostConnect)
      }
      else if (message.result && completedMethod === 'locations.get') {
        countries = Array.isArray(message.result.countries) ? message.result.countries : []
        gateways = Array.isArray(message.result.gateways) ? message.result.gateways : []
      } else if (message.result && completedMethod === 'servers.get') {
        var responseQuery = String(message.result.query || '')
        var responseCountry = String(message.result.country_code || '')
        var responseGateway = String(message.result.gateway_name || '')
        var responseFeature = String(message.result.feature || '')
        if (responseQuery === desiredServerQuery && responseCountry === desiredServerCountry &&
            responseGateway === desiredServerGateway &&
            responseFeature === desiredServerFeature) {
          servers = Array.isArray(message.result.servers) ? message.result.servers : []
          serverTotal = Number(message.result.total || 0)
        }
      } else if (message.result && completedMethod === 'traffic.get') {
        trafficKnown = !!message.result.known
        downloadBytes = Number(message.result.download_bytes || 0)
        uploadBytes = Number(message.result.upload_bytes || 0)
        downloadBytesPerSecond = Number(message.result.download_bytes_per_second || 0)
        uploadBytesPerSecond = Number(message.result.upload_bytes_per_second || 0)
      } else if (message.result && completedMethod === 'feature.set' &&
                 message.result.reconnect_required) {
        lastError = 'Reconnect the VPN to apply this setting.'
        lastErrorCode = 'reconnect_required'
        lastErrorDetails = null
        lastErrorRetryable = false
      } else if (message.result && completedMethod === 'apps.get') {
        if (String(message.result.query || '') === desiredAppQuery) {
          installedApps = Array.isArray(message.result.apps) ? message.result.apps : []
          installedAppTotal = Number(message.result.total || 0)
        }
      } else if (message.result && completedMethod === 'report_issue.categories.get') {
        reportCategories = Array.isArray(message.result.categories)
          ? message.result.categories : []
      } else if (message.result && completedMethod === 'report_issue.submit') {
        reportSubmitted = !!message.result.sent
      } else if (message.result && completedMethod === 'diagnostics.get') {
        diagnosticsSources = Array.isArray(message.result.sources)
          ? message.result.sources : []
        diagnosticsFailures = Array.isArray(message.result.failures)
          ? message.result.failures : []
        diagnosticsRawContentsExposed = !!message.result.raw_contents_exposed
      } else if (message.result && completedMethod === 'account.upgrade_url') {
        if (message.result.url) openTrustedUrl(String(message.result.url))
      }
      else if (completedMethod === 'profiles.save' || completedMethod === 'profiles.delete')
        loadProfiles(0)
      else if (completedMethod === 'recents.record' || completedMethod === 'recents.pin' ||
               completedMethod === 'recents.delete')
        loadRecents(0)
      if (message.result && message.result.revision !== undefined)
        applySnapshot(message.result)
      return
    }

    if (message.type === 'event' &&
        (message.event === 'state.snapshot' || message.event === 'state.changed')) {
      agentAvailable = true
      applySnapshot(message.data || {})
    }
  }

  function applySnapshot(snapshot) {
    revision = Number(snapshot.revision || 0)

    var backend = snapshot.backend || {}
    coreAvailable = !!backend.core_available
    settingsKnown = !!backend.settings_known
    connectorInitialized = !!backend.connector_initialized
    connectionAvailable = !!backend.connection_available
    connectionAvailabilityKnown = !!backend.connection_availability_known
    backendCoreVersion = backend.core_version || ''
    networkBlockedKnown = !!backend.network_blocked_known
    networkBlocked = !!backend.network_blocked
    if (backendActivationRequested && !requestPending('account.get') &&
        (!coreAvailable || backend.error))
      backendActivationRequested = false

    var account = snapshot.account || {}
    accountStatus = String(account.status || 'unknown')
    accountName = account.name || ''
    accountTier = account.tier === null || account.tier === undefined
      ? -1 : Number(account.tier)
    twoFactorCodeSupported = !!account.two_factor_code_supported
    twoFactorSecurityKeySupported = !!account.two_factor_security_key_supported
    ssoSupported = !!account.sso_supported

    if (signedIn && !connectionObservationKnown && backendDemanded)
      requestConnectionObservation()

    applyStoreSnapshot(snapshot.store || {})

    var connection = snapshot.connection || {}
    connectionObservationKnown = !!connection.observation_known
    status = String(connection.status || 'unknown')
    countryCode = connection.country_code || ''
    countryName = connection.country_name || ''
    city = connection.city || ''
    serverName = connection.server_name || ''
    serverIp = connection.server_ip || ''
    protocol = protocolName(connection.protocol)
    connectionErrorCode = String(connection.error_code || '')
    restrictionReasonCode = Number(connection.restriction_reason_code || 0)
    latencyMs = Number(connection.latency_ms || 0)

    var device = snapshot.device_location || {}
    deviceLocationKnown = !!device.known
    deviceIpAddress = String(device.ip_address || '')
    deviceCountryCode = String(device.country_code || '')
    deviceIsp = String(device.isp || '')

    var features = snapshot.features || {}
    killSwitchMode = features.kill_switch && features.kill_switch.mode
      ? String(features.kill_switch.mode) : 'off'
    netShieldLevel = features.netshield
      ? Number(features.netshield.level || 0) : 0
    netShieldStatisticsKnown = !!(features.netshield && features.netshield.statistics_known)
    netShieldMalwareBlocked = features.netshield
      ? Number(features.netshield.malware_blocked || 0) : 0
    netShieldAdsBlocked = features.netshield
      ? Number(features.netshield.ads_blocked || 0) : 0
    netShieldTrackersBlocked = features.netshield
      ? Number(features.netshield.trackers_blocked || 0) : 0
    moderateNat = !!(features.moderate_nat && features.moderate_nat.enabled)
    ipv6 = features.ipv6 && features.ipv6.enabled !== undefined
      ? !!features.ipv6.enabled : true
    ipv6LeakProtection = features.ipv6_leak_protection &&
      features.ipv6_leak_protection.enabled !== undefined
      ? !!features.ipv6_leak_protection.enabled : true
    alternativeRouting = features.alternative_routing &&
      features.alternative_routing.enabled !== undefined
      ? !!features.alternative_routing.enabled : true
    allowLanConnections = !!(features.allow_lan_connections &&
      features.allow_lan_connections.enabled)
    allowLocalDns = !!(features.allow_local_dns &&
      features.allow_local_dns.enabled)
    secureCore = !!features.secure_core
    var split = features.split_tunneling || {}
    splitTunnelingMode = split.mode ? String(split.mode) : 'off'
    splitTunnelingAvailabilityKnown = !!split.availability_known
    splitTunnelingAvailable = !!split.available
    splitAppPathsSupported = !!split.app_paths_supported
    splitIpRangesSupported = !!split.ip_ranges_supported
    splitStandardApps = split.standard && split.standard.app_paths
      ? split.standard.app_paths : []
    splitInverseApps = split.inverse && split.inverse.app_paths
      ? split.inverse.app_paths : []
    splitStandardIpRanges = split.standard && split.standard.ip_ranges
      ? split.standard.ip_ranges : []
    splitInverseIpRanges = split.inverse && split.inverse.ip_ranges
      ? split.inverse.ip_ranges : []
    portForwarding = !!(features.port_forwarding && features.port_forwarding.enabled)
    activePort = features.port_forwarding && features.port_forwarding.active_port
      ? Number(features.port_forwarding.active_port) : 0
    selectedProtocol = features.protocol ? String(features.protocol.selected || '') : ''
    availableProtocols = features.protocol && Array.isArray(features.protocol.available)
      ? features.protocol.available : []
    availableProfileProtocols = features.protocol &&
      Array.isArray(features.protocol.profile_available)
      ? features.protocol.profile_available : availableProtocols
    vpnAccelerator = !!(features.vpn_accelerator && features.vpn_accelerator.enabled)
    anonymousCrashReports = !!(features.anonymous_crash_reports &&
      features.anonymous_crash_reports.enabled)
    anonymousUsageStatistics = !!(features.anonymous_usage_statistics &&
      features.anonymous_usage_statistics.enabled)
    connectionFeedbackAvailable = !!(features.connection_feedback &&
      features.connection_feedback.available)
    connectionFeedbackViewed = !!(features.connection_feedback &&
      features.connection_feedback.viewed)
    connectionFeedbackSent = !!(features.connection_feedback &&
      features.connection_feedback.sent)
    customDns = !!(features.custom_dns && features.custom_dns.enabled)
    customDnsServers = features.custom_dns && Array.isArray(features.custom_dns.servers)
      ? features.custom_dns.servers : []

    var writes = features.writes || {}
    killSwitchWritable = !!writes.kill_switch
    netShieldWritable = !!writes.netshield
    customDnsWritable = !!writes.custom_dns
    secureCoreWritable = !!writes.secure_core
    splitTunnelingWritable = !!writes.split_tunneling
    portForwardingWritable = !!writes.port_forwarding
    protocolWritable = !!writes.protocol
    vpnAcceleratorWritable = !!writes.vpn_accelerator
    anonymousCrashReportsWritable = !!writes.anonymous_crash_reports
    anonymousUsageStatisticsWritable = !!writes.anonymous_usage_statistics
    moderateNatWritable = !!writes.moderate_nat
    ipv6Writable = !!writes.ipv6
    ipv6LeakProtectionWritable = !!writes.ipv6_leak_protection
    alternativeRoutingWritable = !!writes.alternative_routing
    allowLanConnectionsWritable = !!writes.allow_lan_connections
    allowLocalDnsWritable = !!writes.allow_local_dns

    featuresKnown = !!features.known
    featuresWritable = !!features.writable

    var operations = snapshot.operations || {}
    activeOperations = Array.isArray(operations.active)
      ? operations.active : []
    recentOperations = Array.isArray(operations.recent)
      ? operations.recent : []

    if (recentOperations.length > 0) {
      var latest = recentOperations[0] || {}
      var instanceId = serverClientInstanceId || clientInstanceId
      if (latest.id && latest.id !== lastHandledOperationId &&
          latest.initiator_client_instance_id === instanceId) {
        lastHandledOperationId = String(latest.id)
        if (latest.state === 'failed') {
          var operationError = latest.error || {}
          lastErrorCode = String(operationError.code || 'operation_failed')
          lastError = 'Proton VPN operation failed'
          lastErrorDetails = operationError.details || null
          lastErrorRetryable = !!operationError.retryable
        }
      }
    }

    var backendError = backend.error || ''
    var connectionError = connection.error || ''
    if (connectionError) {
      lastErrorCode = connectionErrorCode || 'connection_failed'
      lastError = String(connectionError)
      lastErrorRetryable = connectionErrorCode !== 'p2p_not_allowed'
    } else if (backendError) {
      lastErrorCode = 'backend_unavailable'
      lastError = String(backendError)
      lastErrorRetryable = true
    }
    maybeRunQueuedAction()
  }

  function applyStoreSnapshot(store) {
    if (!store || store.revision === undefined) return
    var previousRevision = storeRevision
    storeReady = !!store.ready
    storeRevision = Number(store.revision || 0)
    onboardingComplete = !!store.onboarding_complete
    locale = String(store.locale || 'es-MX')
    startWithOmarchy = store.start_with_omarchy === undefined
      ? true : !!store.start_with_omarchy
    autoConnect = !!store.auto_connect
    notificationsEnabled = store.notifications_enabled === undefined
      ? true : !!store.notifications_enabled
    portForwardingNotificationsEnabled =
      store.port_forwarding_notifications_enabled === undefined
        ? true : !!store.port_forwarding_notifications_enabled
    accountScopeKnown = !!store.account_scope_known
    profileCount = Number(store.profile_count || 0)
    recentCount = Number(store.recent_count || 0)
    defaultConnection = store.default_connection || { type: 'fastest' }
    legacyMigrationAvailable = !!store.migration_available

    if (storeRevision !== previousRevision && agentAvailable) {
      if (profileCount > 0 || profiles.length > 0) loadProfiles(0)
      if (recentCount > 0 || recents.length > 0) loadRecents(0)
    }
    syncSocketDemand()
  }

  property FileView lifecycleFile: FileView {
    path: root.lifecyclePath
    watchChanges: true
    printErrors: false
    onLoaded: root.applyLifecycleCache(text())
    onLoadFailed: root.applyLifecycleCache('')
    onFileChanged: reload()
  }

  property Timer socketRetryTimer: Timer {
    repeat: false
    onTriggered: root.socketWanted = root.socketDemandActive()
  }

  property Timer postConnectTimer: Timer {
    interval: 1000
    repeat: false
    onTriggered: {
      var action = root.queuedPostConnectAction
      root.queuedPostConnectAction = null
      if (action) root.send('system.launch', action)
    }
  }

  property Socket agentSocket: Socket {
    id: agentSocket
    path: root.socketPath
    connected: false

    parser: SplitParser {
      splitMarker: '\n'
      onRead: data => root.handleLine(data)
    }

    onConnectedChanged: {
      if (connected) {
        root.socketRetryTimer.stop()
        root.socketRetryAttempt = 0
        root.hello()
        if (root.backendDemanded) root.activateBackend()
      }
      else {
        if (root.pendingCount > 0)
          root.clearPendingRequests(
            'agent_disconnected',
            'Proton VPN agent connection was lost'
          )
        root.markAgentUnavailable()
        root.backendActivationRequested = false
        root.scheduleSocketRetry()
      }
    }

    onError: error => {
      root.markAgentUnavailable()
      root.lastError = 'Unable to reach the Proton VPN agent'
      root.lastErrorCode = 'agent_socket_error'
      root.lastErrorDetails = { socket_error: Number(error) }
      root.lastErrorRetryable = true
      root.scheduleSocketRetry()
    }
  }
}
