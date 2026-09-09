# Control-state correction

Full review within the reported scope: root navigation, Connection/Application
tabs, location search, location feature choices, protocol choices and header
spacing. Qt Quick/QML with native Omarchy Style, Color and Border tokens.
Backend, keyring and network behavior are outside this change.

| Category | Evidence | Result |
| --- | --- | --- |
| Typography | Spanish/English tabs and compact search, including 320px renders | Tabs wrap within equal-width destinations; search keeps a stable accessible name |
| Surfaces | Native button/cursor paint, click/focus tests, production renders | Pointer selection retains its native fill and underline without stuck hover/focus framing |
| Animations | Existing 120ms button/page behavior and motion runtime fixture | Existing transitions pass; no new motion choreography |
| Icons | Search magnifier, clear action and protocol rows | Existing native-sized assets; unnecessary feature-button icons removed |
| Performance | Shared component changes and runtime suite | No polling, network or backend changes |

| Severity | Location | Before | After | Why |
| --- | --- | --- | --- | --- |
| MEDIUM | ProtonButtonBase, PanelActionRow, ProtonBottomNavigation, ProtonSettingsView | Pointer clicks retained native keyboard borders/fills alongside selection | The original selected fill and underline remain; hover/focus no longer override the selected tab or leave a frame; keyboard keeps an explicit indicator | Distinguish selection, hover and keyboard focus |
| MEDIUM | ProtonLocationsView, ProtonTextField | Tall caption-plus-input search, separate clear action that resized it, reserved empty progress text row | Single 40px search row with magnifier, internal clear action and thin progress line; form captions remain | Keep routine search compact and stable while typing |
| MEDIUM | ProtonLocationsView | Four boxed feature buttons in a large grid | Compact wrapping single-choice controls with one selected fill | Reduce visual weight without losing selected state or radio semantics |
| MEDIUM | ProtonWorkspace | Host top padding plus centered label in a 40px header row | Header hit area overlaps 10 logical pixels of the existing top inset | Remove accumulated whitespace while retaining the close target |
| MEDIUM | ProtonBottomNavigation | Long translated destinations overflowed into a horizontal scrollbar | Equal-width wrapping labels with a common row height | Keep all normal-width destinations visible |

Considered and rejected: removing keyboard focus feedback would impair keyboard
navigation; shrinking the close button would reduce its hit area; changing global
Omarchy control tokens would affect unrelated applications and panels.

Validation: `scripts/check-ui-runtime` (including real pointer/key events in the
new control-states fixture) and `scripts/check-installer-runtime` pass. The fixture
checks pointer focus after leaving a clicked tab, settings-section selection,
Tab/arrow navigation, search geometry and clear/refocus, feature selection and
choosing the existing protocol without a backend mutation. Production captures
cover all 19 documentation views plus Spanish 320px locations and the expanded
protocol selector. All preview windows are offscreen FloatingWindow instances.

Verdict: Approve for the inspected scope after local runtime and render checks.
Not verified: 10% animation replay, GPU frame-time profiling and a full assistive
technology audit. The backend and credential storage were not modified.
