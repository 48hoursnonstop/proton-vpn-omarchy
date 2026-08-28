import QtQuick

// Deterministic publication fixture. Every value is synthetic and reserved
// for documentation; this object never opens the agent socket or user store.
QtObject {
  id: root

  property bool agentAvailable: true
  property bool backendReady: true
  property bool signedIn: true
  property bool connected: true
  property bool connecting: false
  property string status: 'connected'
  property string countryCode: 'CH'
  property string countryName: 'Switzerland'
  property string city: 'Zurich'
  property string serverName: 'CH#42'
  property string serverIp: '198.51.100.42'
  property string deviceIpAddress: '203.0.113.24'
  property bool deviceLocationKnown: true
  property string deviceIsp: 'Example Network'
  property string protocol: 'Stealth'

  property bool trafficKnown: true
  property double downloadBytes: 483393536
  property double uploadBytes: 70254592
  property double downloadBytesPerSecond: 2752512
  property double uploadBytesPerSecond: 438272
  property int trafficStep: 0

  property bool operationBusy: false
  property string operationStage: ''
  property string lastError: ''
  property string lastErrorCode: ''
  property bool lastErrorRetryable: false
  property bool tunnelOperationBusy: false
  property bool tunnelConfigurationBusy: false
  property bool storeOperationBusy: false
  property bool authBusy: false

  property string locale: 'en'
  property string accountName: 'demo@proton.example'
  property int accountTier: 2
  property bool startWithOmarchy: true
  property bool autoConnect: true
  property bool notificationsEnabled: true
  property bool portForwardingNotificationsEnabled: true
  property var defaultConnection: ({ type: 'fastest' })

  property var recents: [
    {
      id: 'sample-recent-1', kind: 'country', pinned: true,
      header: 'Switzerland', description: 'Zurich · Fastest', countryCode: 'CH'
    },
    {
      id: 'sample-recent-2', kind: 'profile', pinned: false,
      header: 'Streaming', description: 'United States · Smart', countryCode: 'US'
    }
  ]
  property var countries: [
    { code: 'CH', name: 'Switzerland', available_server_count: 86, server_count: 86,
      secure_core: true, p2p: true, tor: true },
    { code: 'NL', name: 'Netherlands', available_server_count: 132, server_count: 135,
      secure_core: true, p2p: true, tor: false },
    { code: 'CA', name: 'Canada', available_server_count: 104, server_count: 108,
      secure_core: true, p2p: true, tor: false },
    { code: 'JP', name: 'Japan', available_server_count: 74, server_count: 74,
      secure_core: true, p2p: true, tor: false },
    { code: 'IS', name: 'Iceland', available_server_count: 24, server_count: 24,
      secure_core: true, p2p: true, tor: false }
  ]
  property var gateways: []
  property var servers: []
  property bool locationsLoading: false
  property bool serversLoading: false

  property var profiles: [
    {
      id: 'sample-profile-1', name: 'Everyday privacy', iconName: 'Protection',
      color: '#4DC73D', targetKind: 'fastest', profileProtocol: 'smart'
    },
    {
      id: 'sample-profile-2', name: 'Streaming', iconName: 'Streaming',
      color: '#C857E7', targetKind: 'country', countryCode: 'US',
      countryName: 'United States', profileProtocol: 'protun-tls'
    },
    {
      id: 'sample-profile-3', name: 'Secure Core', iconName: 'Security',
      color: '#0E7AD2', targetKind: 'secureCore', countryCode: 'CH',
      countryName: 'Switzerland', entryCountryCode: 'IS',
      entryCountryName: 'Iceland', profileProtocol: 'smart'
    }
  ]
  property var availableProfileProtocols: [
    'smart', 'protun-udp', 'protun-tcp', 'protun-tls',
    'openvpn-udp', 'openvpn-tcp'
  ]

  property string selectedProtocol: 'smart'
  property var availableProtocols: [
    'smart', 'protun-udp', 'protun-tcp', 'protun-tls',
    'openvpn-udp', 'openvpn-tcp'
  ]
  property bool protocolWritable: true
  property string killSwitchMode: 'standard'
  property bool killSwitchWritable: true
  property bool killSwitch: true
  property int netShieldLevel: 2
  property bool netShieldWritable: true
  property bool netShieldStatisticsKnown: true
  property int netShieldMalwareBlocked: 3
  property int netShieldAdsBlocked: 128
  property int netShieldTrackersBlocked: 47
  property bool vpnAccelerator: true
  property bool vpnAcceleratorWritable: true
  property bool portForwarding: false
  property bool portForwardingWritable: true
  property int activePort: 0
  property bool moderateNat: false
  property bool moderateNatWritable: true
  property var customDnsServers: []
  property bool customDnsWritable: true
  property bool alternativeRouting: true
  property bool alternativeRoutingWritable: true
  property bool ipv6: true
  property bool ipv6Writable: true
  property bool ipv6LeakProtection: true
  property bool ipv6LeakProtectionWritable: true
  property bool allowLanConnections: false
  property bool allowLanConnectionsWritable: true
  property bool allowLocalDns: false
  property bool allowLocalDnsWritable: true
  property bool splitTunneling: true
  property bool splitTunnelingWritable: true
  property bool anonymousCrashReports: false
  property bool anonymousCrashReportsWritable: true
  property bool anonymousUsageStatistics: false
  property bool anonymousUsageStatisticsWritable: true

  property bool splitTunnelingAvailabilityKnown: true
  property bool splitTunnelingAvailable: true
  property string splitTunnelingMode: 'standard'
  property bool splitIpRangesSupported: true
  property var splitStandardApps: ['/usr/bin/example-browser']
  property var splitInverseApps: []
  property var splitStandardIpRanges: ['192.0.2.0/24']
  property var splitInverseIpRanges: []
  property var installedApps: [
    { id: 'example-browser', name: 'Example Browser', executable: '/usr/bin/example-browser' },
    { id: 'example-player', name: 'Example Player', executable: '/usr/bin/example-player' }
  ]

  property bool connectionFeedbackAvailable: false
  property bool connectionFeedbackViewed: true
  property bool connectionFeedbackSent: false

  signal requestFinished(string requestId, string method, bool ok, string errorCode)
  signal trafficUpdated()

  function protocolName(value) {
    switch (String(value || '').toLowerCase()) {
    case 'smart':
    case 'protun-smart': return 'Smart'
    case 'protun-udp': return 'WireGuard UDP'
    case 'protun-tcp': return 'WireGuard TCP'
    case 'protun-tls': return 'Stealth'
    case 'openvpn-udp': return 'OpenVPN UDP'
    case 'openvpn-tcp': return 'OpenVPN TCP'
    default: return String(value || '')
    }
  }

  function refreshTraffic() {
    var down = [2752512, 4194304, 3325952, 5767168, 3670016, 4980736]
    var up = [438272, 720896, 524288, 983040, 610304, 786432]
    trafficStep = (trafficStep + 1) % down.length
    downloadBytesPerSecond = down[trafficStep]
    uploadBytesPerSecond = up[trafficStep]
    downloadBytes += downloadBytesPerSecond
    uploadBytes += uploadBytesPerSecond
    trafficUpdated()
  }

  function requestPending(_method) { return false }
  function toggleConnection() {}
  function loadRecents(_delay) {}
  function connectRecent(_recent) {}
  function deleteRecent(_id) { return 'showcase-delete-recent' }
  function setRecentPinned(_id, _pinned) { return 'showcase-pin-recent' }
  function setDefaultConnection(_value) { return 'showcase-default' }
  function loadLocations() {}
  function loadServers(_query, _country, _gateway, _feature) {}
  function connectCountry(_country, _feature) {}
  function connectGateway(_gateway) {}
  function connectServer(_server) {}
  function loadProfiles(_delay) {}
  function connectProfile(_profile) {}
  function saveProfile(_profile) { return 'showcase-save-profile' }
  function deleteProfile(_id) { return 'showcase-delete-profile' }
  function loadApps(_query) {}
  function refreshNetShieldStatistics() {}
  function setConnectionFeedback(_value) {}
  function setProtocol(_value) {}
  function setFeature(_feature, _value) {}
  function setCustomDns(_enabled, _servers) { return 'showcase-dns' }
  function setPreferences(_locale, _start, _auto) {}
  function setNotifications(_enabled) {}
  function setPortForwardingNotifications(_enabled) {}
  function logout() {}
  function applySplitTunneling(_enabled, _mode, _standardApps, _inverseApps,
                               _standardRanges, _inverseRanges) {}
}
