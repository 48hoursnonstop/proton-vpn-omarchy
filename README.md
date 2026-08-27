# Proton VPN for Omarchy

A lightweight, native Omarchy Quattro 4.x client for Proton VPN. The UI runs
as an Omarchy bar plugin; connection and account operations run in a per-user
Rust agent, while app/IP split tunneling is enforced by a small Rust/eBPF
system service.

This is an independent community project and is not affiliated with or
endorsed by Proton AG.

## Install

Add and enable the plugin with Omarchy:

```bash
omarchy plugin add https://github.com/48hoursnonstop/proton-vpn-omarchy.git --enable
```

Open the Proton VPN bar icon and choose **Install backend**. The first-run
installer pins the project's OpenPGP fingerprint, verifies the downloaded
package signature in an isolated keyring, and only then asks Polkit to install
the package. It configures and starts the per-user agent automatically. No
`curl | bash` or root shell is used.

Omarchy warns before enabling third-party plugins because they execute inside
the shell process. Review the source in this repository before confirming.

### Manual backend installation

If the guided installer cannot be used, its equivalent manual flow is:

```bash
curl -fLO https://github.com/48hoursnonstop/proton-vpn-omarchy/releases/download/v0.8.0/proton-vpn-omarchy-0.8.0-3-x86_64.pkg.tar.zst
curl -fLO https://github.com/48hoursnonstop/proton-vpn-omarchy/releases/download/v0.8.0/proton-vpn-omarchy-0.8.0-3-x86_64.pkg.tar.zst.sig
curl -fLO https://github.com/48hoursnonstop/proton-vpn-omarchy/releases/download/v0.8.0/RELEASE-SIGNING-KEY.asc
test "$(gpg --show-keys --with-colons RELEASE-SIGNING-KEY.asc | awk -F: '$1 == "fpr" { print $10; exit }')" = "4D0124DE09788D29E3A8798B12BE3422BDA2422C"
gpg --import RELEASE-SIGNING-KEY.asc
gpg --verify proton-vpn-omarchy-0.8.0-3-x86_64.pkg.tar.zst.sig proton-vpn-omarchy-0.8.0-3-x86_64.pkg.tar.zst
sudo pacman -U ./proton-vpn-omarchy-0.8.0-3-x86_64.pkg.tar.zst
proton-omarchy-setup backend
```

### Package-managed alternative

The Arch package also contains the same plugin frontend. To use that copy
instead of a Git-managed checkout, install the verified package manually and
run:

```bash
proton-omarchy-setup install
```

Do not install both frontend copies. The backend package is required in either
case.

## Update

Update the Git-managed frontend with:

```bash
omarchy plugin update proton.omarchy
```

When that frontend requires a newer backend, opening the plugin offers the same
signed update flow. Backend updates are also available as `.pkg.tar.zst`
assets under GitHub Releases for manual installation.

Release packages and checksum manifests are signed with the project's
dedicated OpenPGP key. Its primary fingerprint is
`4D01 24DE 0978 8D29 E3A8 798B 12BE 3422 BDA2 422C`; the public key is tracked
as [RELEASE-SIGNING-KEY.asc](RELEASE-SIGNING-KEY.asc) and attached to each
release. Verify the fingerprint before trusting a newly downloaded copy.

## Included functionality

- SRP login, TOTP, security keys, SSO and Human Verification handoff
- Smart, ProTun UDP/TCP/Stealth and OpenVPN UDP/TCP
- countries, cities, servers, Secure Core, P2P, Tor and gateways
- profiles, recents, favorites, default connection and Connect and Go
- Kill Switch, NetShield, VPN Accelerator, NAT and port forwarding
- app and IPv4/IPv6 CIDR split tunneling, LAN and local-DNS policies
- Spanish and English UI with native Omarchy layout and Proton mobile icons

Only protocols actually advertised by installed NetworkManager backends are
shown. The package uses Proton's official ProTun service and NetworkManager
OpenVPN engine; it does not ship a tunnel implementation.

## Requirements

- Arch Linux with Omarchy Quattro 4.x
- x86-64 Linux with cgroup v2 and eBPF support
- NetworkManager
- curl, GnuPG and a working Polkit agent (included by Omarchy)

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
recipe. Project code is licensed under GPL-3.0-or-later; individual upstream
assets retain their original notices. See [NOTICE.md](NOTICE.md).
