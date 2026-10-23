# Architecture decision records

Design decisions of One Remote, one short record per decision (context, decision,
consequences). A decision is never edited away: if it changes, a new record supersedes
it and the old one is marked "Superseded by".

| # | Title | Status |
|---|---|---|
| [0001](0001-record-architecture-decisions.md) | Record architecture decisions | Accepted |
| [0002](0002-native-swiftui-multiplatform.md) | Native SwiftUI app, one multiplatform target, XcodeGen | Accepted |
| [0003](0003-direct-ble-protocol-client.md) | Talk BLE directly with a single connection | Accepted |
| [0004](0004-reconnect-by-name.md) | Reconnect by advertised name, not by identifier | Accepted |
| [0005](0005-led-volume-scale-with-hysteresis.md) | Volume display: LED scale with hysteresis | Accepted |
| [0006](0006-db-based-nonlinear-scrolling.md) | Volume scrolling in dB with a non-uniform path per dB | Accepted |
| [0007](0007-knob-gestures.md) | Knob gestures: circular drag, swipe zones, tap on LEDs | Accepted |
| [0008](0008-input-change-blink.md) | Blink the input LED only for changes the viewer witnesses | Accepted |
| [0009](0009-no-siri-widgets-controls.md) | No Siri, widgets or Control Center controls | Accepted |
| [0010](0010-av-direct-safeguards.md) | AV Direct: explicit warning flow and state-checked toggle | Accepted |
| [0011](0011-localization-english-source.md) | Localization: English source texts, German as translation | Accepted |
| [0012](0012-accessibility-adjustable-knobs.md) | Accessibility: each knob is one adjustable element | Accepted |
| [0013](0013-desktop-input.md) | Keyboard shortcuts and mouse wheel | Accepted |
| [0014](0014-splash-and-launch-screen.md) | Launch screen plus in-app splash | Accepted |
| [0015](0015-mit-license.md) | MIT license | Accepted |
| [0016](0016-privacy-by-design.md) | Privacy by design: local only, no network | Accepted |
| [0017](0017-versioning-and-releases.md) | Versioning, changelog and release steps | Accepted |
| [0018](0018-testing-strategy.md) | Testing strategy | Accepted |
| [0019](0019-demo-mode.md) | Demo mode with a simulated amplifier | Accepted |
| [0020](0020-verify-the-link-instead-of-trusting-it.md) | Verify the link instead of trusting its state | Accepted |

New record: copy the newest file, increase the number, add it to this table.
