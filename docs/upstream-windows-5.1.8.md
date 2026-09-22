# Windows 5.1.8 parity — frontend checkpoint

Implemented on `feat/windows-5.1.8-parity`, paired with the same branch in
`proton-vpn-omarchy-core`. This is not a published release; the verified
installer continues to pin 0.9.7.

- Countries and server search/list rows disclose the physical host countries
  used by Smart Routing. Home shows the Smart Routing label; Details names the
  physical country separately from the VPN exit and Secure Core entry.
- Connection feedback uses the upstream timeout supplied by the agent
  (10 seconds by default). The timer pauses when Details is hidden or a feedback
  request is pending, preserves elapsed time across navigation, dismisses once
  per connection, and resets on reconnect. Timeout is not a vote and does not
  enable statistics. Backends without the new interval retain their old behavior.
- The short fade uses `ProtonUi.transitionMs`, including reduced motion. Existing
  Omarchy colors, rows, typography, focus styling and panel spacing are reused.
- Server verification failures have EN/ES copy. Added IPC fields are optional
  to preserve compatibility with older snapshots.

Validation: all 11 fixtures in `scripts/check-ui-runtime`, including the new
`upstream-parity` fixture, and the closed native Wayland host passed. These
fixtures use floating offscreen windows and synthetic data. A timing failure in
an existing workspace fixture during a concurrent build passed on isolated
retry and in the final full run.

The backend also implements endpoint signature checks and consistent city/state
normalization. Its report is
`proton-vpn-omarchy-core/reference/WINDOWS_PARITY_IMPLEMENTATION_2026-09-22.md`.
A trusted production signed-catalog response and live tunnel validation remain
required before release; the API probes in this environment failed with network,
TLS pin or authorization errors. No installed files or release pins were changed.
