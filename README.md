# Proton VPN for Omarchy

A lightweight, native Omarchy Quattro 4.x client for Proton VPN. The UI runs
as an Omarchy bar plugin; connection and account operations run in a per-user
Rust agent, while app/IP split tunneling is enforced by a small Rust/eBPF
system service.

This is an independent community project and is not affiliated with or
endorsed by Proton AG.

## Install

The Omarchy plugin is intentionally unprivileged, so installation has two
parts: install the backend package from the GitHub release, then add this Git
repository through Omarchy.

```bash
curl -fLO https://github.com/48hoursnonstop/proton-vpn-omarchy/releases/download/v0.8.0/proton-vpn-omarchy-0.8.0-3-x86_64.pkg.tar.zst
curl -fLO https://github.com/48hoursnonstop/proton-vpn-omarchy/releases/download/v0.8.0/SHA256SUMS
grep 'proton-vpn-omarchy-0.8.0-3-x86_64.pkg.tar.zst$' SHA256SUMS | sha256sum -c -
sudo pacman -U ./proton-vpn-omarchy-0.8.0-3-x86_64.pkg.tar.zst
proton-omarchy-setup backend
omarchy plugin add https://github.com/48hoursnonstop/proton-vpn-omarchy.git --enable
```

Omarchy warns before enabling third-party plugins because they execute inside
the shell process. Review the source in this repository before confirming.

### Package-managed alternative

The Arch package also contains the same plugin frontend. To use that copy
instead of a Git-managed checkout, replace the last two commands above with:

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

Backend updates are published as `.pkg.tar.zst` assets under GitHub Releases
and can be installed with `sudo pacman -U`.

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
