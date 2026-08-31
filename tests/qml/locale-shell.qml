import QtQuick
import Quickshell

ShellRoot {
  property string selectedLocale: 'en'

  ProtonStrings {
    id: strings
    localeName: selectedLocale
  }

  Timer {
    interval: 50
    running: true
    onTriggered: {
      if (strings.text('welcome_title') !== 'Welcome to Proton VPN')
        throw new Error('English must be the default locale')
      if (strings.text('kill_switch') !== 'Kill switch' ||
          strings.protocolName('protun-udp') !== 'Proton WireGuard (UDP)' ||
          strings.text('default_profile_random') !== 'Random connection')
        throw new Error('Official English Proton terminology is incomplete')
      if (strings.preferredLocale('es-AR') !== 'es-MX')
        throw new Error('Every Spanish locale must select Spanish')
      if (strings.preferredLocale('fr-FR') !== 'en')
        throw new Error('Unsupported locales must fall back to English')

      selectedLocale = 'es-AR'
      Qt.callLater(function() {
        if (strings.text('welcome_title') !== 'Le damos la bienvenida a Proton VPN')
          throw new Error('Language changes must update visible text immediately')
        if (strings.countryName('MX', 'Mexico') !== 'México' ||
            strings.countrySearchNames('US', 'United States').indexOf('Estados Unidos') < 0)
          throw new Error('Localized country names and search aliases are incomplete')
        if (strings.text('kill_switch') !== 'Interruptor de bloqueo' ||
            strings.protocolName('protun-udp') !== 'WireGuard de Proton (UDP)' ||
            strings.text('default_profile_random') !== 'Conexión aleatoria')
          throw new Error('Official Spanish Proton terminology is incomplete')
        console.log('LOCALE_QML', true)
        Qt.quit()
      })
    }
  }
}
