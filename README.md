# Proton VPN for Omarchy

A lightweight, native Omarchy Quattro 4.x client for Proton VPN. The UI runs
as an Omarchy bar plugin; connection and account operations run in a per-user
Rust agent, while app/IP split tunneling is enforced by a small Rust/eBPF
system service.

This is an independent community project and is not affiliated with or
endorsed by Proton AG.

The product is intentionally split at its IPC boundary: this repository holds
the lightweight Omarchy frontend, installer and publication assets; the shared
Rust agent, protocol, Rust/eBPF service and reproducible Arch packaging live in
[proton-vpn-omarchy-core](https://github.com/48hoursnonstop/proton-vpn-omarchy-core).
Proton's official ProTun service remains an external dependency and is not
redistributed by either repository.

## Screenshots

The same production Home view inherits each Omarchy theme without a separate
plugin skin:

| Vantablack | Tokyo Night | Flexoki Light |
| --- | --- | --- |
| ![Home in Vantablack](docs/screenshots/home-vantablack.png) | ![Home in Tokyo Night](docs/screenshots/home-tokyo-night.png) | ![Home in Flexoki Light](docs/screenshots/home-flexoki-light.png) |

| Countries | Profiles |
| --- | --- |
| ![Country browser](docs/screenshots/countries-catppuccin.png) | ![Connection profiles](docs/screenshots/profiles-catppuccin.png) |
| Connection details | Settings |
| ![Connection details and live traffic](docs/screenshots/connection-details-catppuccin.png) | ![VPN settings](docs/screenshots/settings-catppuccin.png) |

All screenshots are rendered in English from the production QML components
with deterministic documentation data. No user account, IP address, setting,
recent connection or profile is read for publication captures.

## Install

Add and enable the plugin with Omarchy:

```bash
omarchy plugin add https://github.com/48hoursnonstop/proton-vpn-omarchy.git --enable
```

Open the Proton VPN bar icon and choose **Install backend**. The first-run
installer pins the project's OpenPGP fingerprint, verifies the downloaded
package's exact byte size and SHA-256, verifies its GitHub/Sigstore build
provenance against the pinned release workflow, tag and commit, verifies the
detached signature in an isolated keyring, and checks the exact package
identity. Only then does it ask Polkit to install the package. It configures
and starts the per-user agent automatically. No `curl | bash` or root shell is
used.

Omarchy warns before enabling third-party plugins because they execute inside
the shell process. Review the source in this repository before confirming.

### Manual backend installation

If the guided installer cannot be used, its equivalent manual flow is:

```bash
curl -fL --proto '=https' --max-filesize 4276945 -o proton-vpn-omarchy-0.8.8-1-x86_64.pkg.tar.zst https://github.com/48hoursnonstop/proton-vpn-omarchy-core/releases/download/v0.8.8/proton-vpn-omarchy-0.8.8-1-x86_64.pkg.tar.zst
curl -fL --proto '=https' --max-filesize 119 -o proton-vpn-omarchy-0.8.8-1-x86_64.pkg.tar.zst.sig https://github.com/48hoursnonstop/proton-vpn-omarchy-core/releases/download/v0.8.8/proton-vpn-omarchy-0.8.8-1-x86_64.pkg.tar.zst.sig
curl -fL --proto '=https' --max-filesize 11490 -o proton-vpn-omarchy-0.8.8-1-x86_64.pkg.tar.zst.intoto.jsonl https://github.com/48hoursnonstop/proton-vpn-omarchy-core/releases/download/v0.8.8/proton-vpn-omarchy-0.8.8-1-x86_64.pkg.tar.zst.intoto.jsonl
curl -fL --proto '=https' --max-filesize 880 -o RELEASE-SIGNING-KEY.asc https://github.com/48hoursnonstop/proton-vpn-omarchy-core/releases/download/v0.8.8/RELEASE-SIGNING-KEY.asc
printf '%s  %s\n' ac5079c455611a01aace5e3d6f2dfb87c20d4fe07c0b0b9a3f199193ec68a65b proton-vpn-omarchy-0.8.8-1-x86_64.pkg.tar.zst | sha256sum -c -
printf '%s  %s\n' 3573fe3e96cd1ba703b7ad3bcc666b0f502387f634fe3c42d15f8ab9782e21bb proton-vpn-omarchy-0.8.8-1-x86_64.pkg.tar.zst.sig | sha256sum -c -
printf '%s  %s\n' 07fa728b15c75e1627e75f9141189792e88445d3be1914a4fd5b08f2f0e1db4e proton-vpn-omarchy-0.8.8-1-x86_64.pkg.tar.zst.intoto.jsonl | sha256sum -c -
gh attestation verify proton-vpn-omarchy-0.8.8-1-x86_64.pkg.tar.zst --bundle proton-vpn-omarchy-0.8.8-1-x86_64.pkg.tar.zst.intoto.jsonl --repo 48hoursnonstop/proton-vpn-omarchy-core --signer-workflow 48hoursnonstop/proton-vpn-omarchy-core/.github/workflows/release.yml --source-ref refs/tags/v0.8.8 --source-digest 4b4c807486d58a74e785d50ec089d1cb72b89690 --deny-self-hosted-runners
test "$(gpg --show-keys --with-colons RELEASE-SIGNING-KEY.asc | awk -F: '$1 == "fpr" { print $10; exit }')" = "4D0124DE09788D29E3A8798B12BE3422BDA2422C"
gpg --import RELEASE-SIGNING-KEY.asc
gpg --verify proton-vpn-omarchy-0.8.8-1-x86_64.pkg.tar.zst.sig proton-vpn-omarchy-0.8.8-1-x86_64.pkg.tar.zst
sudo pacman -U ./proton-vpn-omarchy-0.8.8-1-x86_64.pkg.tar.zst
proton-omarchy-setup backend
```

The package is backend-only. Omarchy owns the frontend checkout, so backend
updates can never install or downgrade a second copy of the UI.

## Update

Update the Git-managed frontend with:

```bash
omarchy plugin update proton.omarchy
```

When that frontend requires a newer backend, opening the plugin offers the same
signed update flow. Backend updates are also available as `.pkg.tar.zst`
assets in the core repository's GitHub Releases for manual installation.

Release packages and checksum manifests are signed with the project's
dedicated OpenPGP key. Its primary fingerprint is
`4D01 24DE 0978 8D29 E3A8 798B 12BE 3422 BDA2 422C`; the public key is tracked
as [RELEASE-SIGNING-KEY.asc](RELEASE-SIGNING-KEY.asc) and attached to each
release. Verify the fingerprint before trusting a newly downloaded copy.

## Included functionality

- SRP login, TOTP, security keys, SSO and Human Verification handoff
- Smart, ProTun UDP/TCP/Stealth and OpenVPN UDP/TCP
- countries, states, cities, servers, Secure Core entry countries, P2P, Tor and gateways
- profiles, explicit duplication, recents, favorites, default connection and Connect and Go
- Kill Switch (including split-tunneling coexistence), NetShield, VPN Accelerator, NAT and port forwarding
- app and IPv4/IPv6 CIDR split tunneling, LAN and local-DNS policies
- automatic warnings for conflicting VPNs, tunnel interfaces and insecure Wi-Fi
- suspend/resume reconnection and Windows-compatible random-country selection
- Spanish and English catalogs with BCP 47 aliases, English fallback, placeholders,
  plurals and validated extension points for additional languages

## Support and reporting

Plugin/core bugs belong in this repository's GitHub issue form. The Support
page can copy a sanitized summary that excludes account names, IP addresses,
connection IDs and raw journals.

The separate official report form sends directly to Proton AG and says so
before submission. Account name, entered email, country/ISP and the typed
description are included; recent journals are opt-in and disabled by default.
Never paste credentials or tokens into either flow.

Only protocols actually advertised by installed NetworkManager backends are
shown. The package uses Proton's official ProTun service and NetworkManager
OpenVPN engine; it does not ship a tunnel implementation.

## Requirements

- Arch Linux with Omarchy Quattro 4.x
- x86-64 Linux with cgroup v2 and eBPF support
- NetworkManager
- curl, GnuPG and a working Polkit agent (included by Omarchy)
- GitHub CLI for offline bundle verification; the guided installer obtains the
  Arch-signed `github-cli` package when it is not already installed

## Remove

For a Git-managed installation:

```bash
omarchy plugin remove proton.omarchy
systemctl --user disable --now proton-omarchy-agent.service proton-omarchy-agent.socket
sudo pacman -Rns proton-vpn-omarchy
```

User preferences and account state are retained under the XDG data/config
directories so reinstalling does not silently erase them.

## Source and license

The release contains the backend's corresponding source archive and Arch build
recipe; the same code is browsable in the
[core repository](https://github.com/48hoursnonstop/proton-vpn-omarchy-core/tree/v0.8.8).
Project code is licensed under GPL-3.0-or-later; individual upstream assets
retain their original notices. See [NOTICE.md](NOTICE.md).
