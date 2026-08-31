# Icon sources

This directory separates assets by their actual upstream role instead of by
the platform of this plugin.

- `status/` contains the four unmodified monochrome notification images from
  Proton VPN for Android at revision
  `31b1a57fe32e467a0db52f4b4f25582bcafecab5`, under
  `app/src/main/res/drawable-xxhdpi/ic_vpn_status_*.webp`. The Rust agent uses
  the same files for desktop notifications; the bar reuses them as state
  glyphs.
- `windows/profiles/` contains 2x compatibility renders of the twelve active
  profile illustrations from Proton VPN for Windows at revision
  `4d9ac60d1db5d3f2908498470a9d1646723afcfd`, under
  `src/Client/Common/ProtonVPN.Client.Common.UI/Assets/Icons/Profiles/`.
  Runtime colorization follows the six official profile colors declared in
  `Styles/Converters.xaml`.
- `windows/flags/` contains the 250 country flags, placeholder, and the
  dark/light Fastest, Random, Latest, and Gateway destination marks from the
  same Proton VPN for Windows revision, under
  `src/Client/Common/ProtonVPN.Client.Common.UI/Assets/Flags/`. The files are
  copied without artwork changes; QML supplies the simple and Secure Core
  two-flag layouts at Omarchy's logical display scale.
- `mobile/icons/` and `navigation/` contain white-mask adaptations of Proton
  Core Android glyph geometry, primarily from revision
  `1b87f94ebfdfaf5e67145e8668efc52dbb931e0b`. Individual vector files retain
  source comments where applicable and are tinted from Omarchy theme tokens.

All upstream assets remain covered by their upstream GPL license and
copyright notices. The surrounding QML rendering and integration code is part
of Proton VPN for Omarchy.
