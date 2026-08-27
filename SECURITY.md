# Security

Please report security issues privately through GitHub's **Report a
vulnerability** flow instead of opening a public issue. Do not include Proton
credentials, session tokens, VPN configuration secrets, or diagnostic logs
containing personal data in public reports.

This project never needs a Proton password outside its own local login UI.
The guided installer accepts only the pinned release key fingerprint and a
valid detached package signature before invoking Polkit. For manual installs,
download packages only from this repository's Releases page and verify the
OpenPGP signature; `SHA256SUMS.sig` authenticates the complete checksum
manifest.
