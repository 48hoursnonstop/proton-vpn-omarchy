import QtQuick
import "i18n/Catalogs.js" as Catalogs
import "i18n/CountryNames.js" as CountryNames

QtObject {
  property string localeName: String(Qt.locale().name || 'en')
  readonly property string localeCode: Catalogs.normalizeLocale(localeName)
  readonly property string systemLocaleName:
    Catalogs.preferredLocale(Qt.locale().name || 'en')
  readonly property bool catalogsComplete: Catalogs.catalogsAreComplete()

  function preferredLocale(locale) {
    return Catalogs.preferredLocale(locale)
  }

  function localeOptions() {
    return Catalogs.localeOptions()
  }

  function languageName(locale) {
    var options = localeOptions()
    var normalized = Catalogs.normalizeLocale(locale)
    for (var index = 0; index < options.length; ++index) {
      if (Catalogs.normalizeLocale(options[index].value) === normalized)
        return String(options[index].label)
    }
    return String(locale || '')
  }

  function protocolName(protocol) {
    switch (String(protocol || '').toLowerCase()) {
    case 'smart':
    case 'protun-smart': return text('protocol_smart')
    case 'wireguard': return text('protocol_wireguard')
    case 'wireguard-udp': return text('protocol_wireguard_udp')
    case 'wireguard-tcp': return text('protocol_wireguard_tcp')
    case 'wireguard-tls': return text('protocol_stealth')
    case 'protun-udp': return text('protocol_protun_udp')
    case 'protun-tcp': return text('protocol_protun_tcp')
    case 'protun-tls': return text('protocol_protun_tls')
    case 'openvpn': return text('protocol_openvpn')
    case 'openvpn-udp': return text('protocol_openvpn_udp')
    case 'openvpn-tcp': return text('protocol_openvpn_tcp')
    default: return String(protocol || '')
    }
  }

  function countryName(code, fallback) {
    return CountryNames.name(localeName, code, fallback)
  }

  function countrySearchNames(code, fallback) {
    return CountryNames.aliases(localeName, code, fallback)
  }

  function profileCopyName(name) {
    return Catalogs.translate(
      localeName, 'format', 'profile_copy',
      { name: String(name || '').trim() }, undefined, String(name || '').trim()
    )
  }

  function networkConflictWarning(conflicts) {
    var values = Array.isArray(conflicts) ? conflicts.slice(0, 3) : []
    var message = Catalogs.translate(
      localeName, 'format', 'network_conflict', {}, undefined, ''
    )
    for (var index = 0; index < values.length; ++index)
      message += '\n• ' + String(values[index])
    return message
  }

  function text(key, replacements, count) {
    var value = String(key || '')
    return Catalogs.translate(
      localeName, 'text', value, replacements || {}, count, value
    )
  }

  function installerStage(stage) {
    var value = String(stage || '')
    return Catalogs.translate(
      localeName, 'installer_stage', value, {}, undefined,
      Catalogs.translate(localeName, 'installer_stage', '_default', {}, undefined, value)
    )
  }

  function installerError(code) {
    var value = String(code || '')
    return Catalogs.translate(
      localeName, 'installer_error', value, {}, undefined,
      Catalogs.translate(localeName, 'installer_error', '_default', {}, undefined, value)
    )
  }

  function operationStage(stage) {
    var value = String(stage || '')
    return Catalogs.translate(
      localeName, 'operation_stage', value, {}, undefined, value
    )
  }

  function error(code, fallback) {
    var value = String(code || '')
    return Catalogs.translate(
      localeName, 'error', value, {}, undefined,
      Catalogs.translate(
        localeName, 'error', '_default', {}, undefined,
        String(fallback || value)
      )
    )
  }
}
