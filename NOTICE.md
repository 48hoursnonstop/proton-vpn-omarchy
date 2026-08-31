# Notices and provenance

Proton VPN for Omarchy is an independent community project. It is not an
official Proton product and is not affiliated with, sponsored by, or endorsed
by Proton AG. Proton, Proton VPN, and their product marks are trademarks of
their respective owners.

The plugin reuses or translates selected icon geometry from the GPL-licensed
Proton Core Android project. Its notification status images are unmodified
assets from the GPL-licensed Proton VPN Android client. Country flags,
destination marks, and profile illustrations come from the GPL-licensed
Proton VPN Windows client; the profile illustrations retain its six-color
model. Exact source revisions and paths are documented in `assets/README.md`.
Those assets remain subject to their upstream copyright notices and licenses.

Selected Proton product labels, descriptions, and default-profile names in the
English and Latin American Spanish catalogs are derived from the GPL-licensed
Proton VPN Windows client. The pinned source revision is documented in
`i18n/README.md`; Omarchy-specific text remains original to this project.

Spanish ISO 3166-1 common territory names in `i18n/CountryNames.js` are
generated from iso-codes 4.20.1. The iso-codes data is distributed under
LGPL-2.1-or-later; the generated map is shipped as editable source and its
provenance is documented in `i18n/README.md`.

The backend integrates with the separately installed official Proton ProTun
NetworkManager service. ProTun itself is not redistributed in this repository
or release package.

The project's shared Rust runtime, IPC protocol, split-tunneling service and
packaging source are published separately at
https://github.com/48hoursnonstop/proton-vpn-omarchy-core so the plugin remains
lightweight.

All original project code is distributed under GPL-3.0-or-later. See LICENSE.
