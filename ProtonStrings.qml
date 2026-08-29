import QtQuick
import "i18n/Catalogs.js" as Catalogs

QtObject {
  property string localeName: String(Qt.locale().name || 'en')
  readonly property string localeCode: Catalogs.normalizeLocale(localeName)
  readonly property bool catalogsComplete: Catalogs.catalogsAreComplete()

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
