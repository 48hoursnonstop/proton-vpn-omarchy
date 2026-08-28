import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui
import 'components' as ProtonComponents

ShellRoot {
  id: showcaseShell

  readonly property string route: Quickshell.env('PROTON_SHOWCASE_ROUTE') || 'home'
  readonly property string outputPath: Quickshell.env('PROTON_SHOWCASE_OUTPUT')
  property bool captureWarmed: false
  property var navigationDestinations: [
    { route: 'home', icon: 'house', label: 'Home' },
    { route: 'locations', icon: 'earth', label: 'Countries' },
    { route: 'profiles', icon: 'window_terminal', label: 'Profiles' },
    { route: 'settings', icon: 'cog_wheel', label: 'Settings' }
  ]

  ShowcaseState { id: showcaseState }

  ProtonStrings {
    id: stringTable
    localeName: 'en'
  }

  // A real xdg-toplevel constrained to the plugin panel's publication size.
  // grabToImage samples only its production surface, never the desktop.
  FloatingWindow {
    id: window
    title: 'Proton VPN Showcase - ' + route
    visible: true
    implicitWidth: Style.space(380)
    implicitHeight: Style.space(590)
    minimumSize: Qt.size(Style.space(380), Style.space(590))
    maximumSize: minimumSize
    color: 'transparent'

    BorderSurface {
      id: captureRoot
      anchors.fill: parent
      color: Color.popups.background
      borderSpec: Border.surfaceSpec(
        'popups', 'border', Color.popups.border, Math.max(1, Style.space(2)))
      padding: Style.spacing.popupPadding
      radius: Style.cornerRadius

      Item {
        id: contentHolder
        anchors.fill: parent
        anchors.topMargin: captureRoot.contentTopInset
        anchors.rightMargin: captureRoot.contentRightInset
        anchors.bottomMargin: captureRoot.contentBottomInset
        anchors.leftMargin: captureRoot.contentLeftInset

        Flickable {
          id: viewport
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: navigation.visible ? navigation.top : parent.bottom
          contentWidth: width
          contentHeight: pageColumn.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          interactive: false

          Column {
            id: pageColumn
            width: viewport.width
            spacing: Style.space(8)

            ProtonComponents.ProtonIconButton {
              visible: route === 'details'
              iconName: 'chevron_left'
              label: stringTable.text('home')
              foreground: Color.popups.text
              fontFamily: Style.font.family
            }

            Loader {
              id: pageLoader
              width: parent.width
              height: item ? item.implicitHeight : 0
              sourceComponent: {
                switch (route) {
                case 'locations': return locationsComponent
                case 'profiles': return profilesComponent
                case 'details': return detailsComponent
                case 'settings': return settingsComponent
                default: return homeComponent
                }
              }
            }
          }
        }

        ProtonComponents.ProtonBottomNavigation {
          id: navigation
          z: 10
          visible: route !== 'details'
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          destinations: showcaseShell.navigationDestinations
          currentRoute: showcaseShell.route
          foreground: Color.popups.text
          dim: Qt.darker(Color.popups.text, 1.55)
          fontFamily: Style.font.family
        }
      }
    }
  }

  Component {
    id: homeComponent
    ProtonHomeView {
      vpnState: showcaseState
      strings: stringTable
      foreground: Color.popups.text
      urgent: Color.urgent
      dim: Qt.darker(Color.popups.text, 1.55)
      fontFamily: Style.font.family
    }
  }

  Component {
    id: locationsComponent
    ProtonLocationsView {
      vpnState: showcaseState
      strings: stringTable
      foreground: Color.popups.text
      urgent: Color.urgent
      dim: Qt.darker(Color.popups.text, 1.55)
      fontFamily: Style.font.family
      section: 'countries'
      sectionSwitcherVisible: false
    }
  }

  Component {
    id: profilesComponent
    ProtonProfilesView {
      vpnState: showcaseState
      strings: stringTable
      foreground: Color.popups.text
      urgent: Color.urgent
      dim: Qt.darker(Color.popups.text, 1.55)
      fontFamily: Style.font.family
    }
  }

  Component {
    id: detailsComponent
    ProtonConnectionDetailsView {
      vpnState: showcaseState
      strings: stringTable
      foreground: Color.popups.text
      urgent: Color.urgent
      dim: Qt.darker(Color.popups.text, 1.55)
      fontFamily: Style.font.family
    }
  }

  Component {
    id: settingsComponent
    ProtonSettingsView {
      vpnState: showcaseState
      strings: stringTable
      foreground: Color.popups.text
      urgent: Color.urgent
      dim: Qt.darker(Color.popups.text, 1.55)
      fontFamily: Style.font.family
    }
  }

  Timer {
    id: captureTimer
    interval: route === 'home' || route === 'details' ? 3400 : 1800
    running: true
    onTriggered: {
      if (!captureWarmed) {
        // Prime every text/icon texture and the chart layer before the image
        // that is persisted. Some Wayland renderers complete those uploads
        // only after the first off-screen grab.
        captureRoot.grabToImage(function(_result) {
          captureWarmed = true
          captureTimer.interval = 500
          captureTimer.restart()
        })
        return
      }
      captureRoot.grabToImage(function(result) {
        var saved = outputPath.length > 0 && result.saveToFile(outputPath)
        console.log('SHOWCASE_CAPTURE', route, saved, outputPath)
        Qt.quit()
      })
    }
  }
}
