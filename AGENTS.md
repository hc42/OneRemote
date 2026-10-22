# AGENTS.md

Guidance for AI coding agents (and humans) working on this repository.

## What this is

One Remote: a native SwiftUI app (iPhone, iPad, Mac) that controls an ONE / ONE HD amplifier
over Bluetooth LE. See `README.md` for features and structure, `docs/PROTOCOL.md` for the BLE
protocol and `docs/adr/` for the reasons behind the design.

## Build

- The Xcode project is generated and not committed. After adding, removing or renaming files,
  or changing `project.yml`, run `xcodegen generate`. The signing team ID lives in `Config/Local.xcconfig`
  (not tracked); never put it into `project.yml`.
- One target for iOS 16+ and macOS 13+. Anything newer needs an availability check or a
  different approach (for example no `onKeyPress`, see ADR 0013).
- Platform-specific code goes in `#if os(iOS)`, `#if os(macOS)` or `#if canImport(UIKit)`.
  Typical offenders: `navigationBarTitleDisplayMode`, `toolbarBackground(for: .navigationBar)`,
  haptics, `NSEvent`. Check that both platforms still compile.
- Unit tests live in `OneRemoteTests/` and run with Cmd+U or `scripts/test.sh` (all tests incl. UI tests; `scripts/test.sh mac` is the fast subset)
  (macOS destination or any iOS simulator). They compile only the pure logic files listed in
  `project.yml`, so put testable logic in such files and add the file to the test target (ADR 0018).
- Behavior on the real amplifier is verified with `docs/TESTING.md`; the amplifier accepts a
  single BLE connection, so other controllers must be disconnected.

## Conventions

- Code, comments, commit messages and docs are English.
- UI texts in code are English and are the localization keys. Every new user-visible text
  needs a German entry in `OneRemote/Resources/de.lproj/Localizable.strings`
  (interpolations: `%@` for strings, `%lld` for integers). SwiftUI literals localize
  automatically; text stored in a `String` needs `String(localized:)`. See ADR 0011.
- Do not use the amplifier manufacturer's brand in names, texts or assets. The product is
  "One Remote"; types use the `Amp` prefix. "ONE" / "ONE HD" are model names only.
- Demo mode (`SimulatedAmplifier`, ADR 0019) is part of every build and must keep working: App Review
  uses it. The launch arguments `-simulated-amplifier` / `-simulated-paired` exist in debug builds only.
- Keep the app local: no networking, analytics or third-party SDKs (links in the About section only
  open the browser), and no new persistent data
  or required-reason APIs without updating `OneRemote/PrivacyInfo.xcprivacy`, `docs/PRIVACY*.md`
  and a new ADR (see ADR 0016).
- Keep the app responsive: BLE writes for volume and balance are rate limited and the UI
  updates optimistically (`AmpController`).
- Knobs must stay usable with VoiceOver, keyboard and mouse (ADR 0012, 0013).

## Architecture in short

- `BLE/AmpProtocol.swift`: UUIDs, command frames, inputs, value conversions.
- `BLE/AmpController.swift`: owner of the connection logic and the app state (`ObservableObject`);
  scan, connect, reconnect by name, send, parse. It talks to Bluetooth only through the
  `BLETransport` protocols (`BLE/BLETransport.swift`); `CoreBluetoothTransport` is the real
  implementation, `SimulatedAmplifier` the simulated one (demo mode, UI tests, screenshots) and the unit
  tests use a fake.
- `Model/AppModel.swift`: holds the controller the views use, the real one or the demo one.
- `Views/`: SwiftUI views read the controller state and call its methods. `ControlView` is
  the main page, `RotaryKnob` the reusable knob.

## Decisions to respect

Read the matching ADR before changing these areas:

- Volume LED scale and its hysteresis, and dB-based scrolling: 0005, 0006.
- Reconnect by advertised name, never rely on the peripheral identifier alone: 0004.
- No Siri, widgets or Control Center controls (tried, too slow with a single connection): 0009.
- AV Direct toggle only when the state is known, with the confirmation flow: 0010.

## Versions and releases

- Versions live only in `project.yml` (`MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`); the
  Info.plist refers to them. Never hard-code them elsewhere.
- Record user-visible changes in `CHANGELOG.md` under "Unreleased" as part of the change.
- Release steps are in ADR 0017.

## Documentation

Documentation is part of every change, not a follow-up. Update it in the same commit (or the same
series of commits) as the code, before reporting the work as done:

| If you change... | update |
|---|---|
| Features, files, folders, scripts, build steps | `README.md` (features, structure, build) and this file if the rules change |
| What the user sees or does | `docs/USAGE.md`, `docs/TESTING.md` (manual checklist), `CHANGELOG.md` ("Unreleased"), German strings |
| Stored data, permissions, network, anything privacy related | `docs/PRIVACY.md` and `docs/PRIVACY.de.md` (both), `OneRemote/PrivacyInfo.xcprivacy`, a new ADR |
| BLE commands or responses | `docs/PROTOCOL.md` (mark what is confirmed on real hardware) |
| Tests, test plans, scripts | `docs/TESTING.md`, ADR 0018 |
| Store texts, screenshots, review notes, URLs | `docs/STORE.md` |
| A hard-to-reverse decision, or one that took trying alternatives | a new ADR in `docs/adr/` (copy the newest file, next number, add it to the table in `docs/adr/README.md`); change a superseded ADR's status instead of rewriting history |
| Security-relevant behavior, reporting or scanning | `SECURITY.md` |

- ADRs must be standalone: no references to chats, tickets or people.
- Docs are English, except the German privacy policy and the German store texts. Keep both language
  versions in step.
- Read the touched docs again before finishing: stale statements (old file names, removed options,
  counts that no longer match) are bugs. Search for the names you changed.
- Run `scripts/test.sh`; the localization tests also check the strings.

## Git

- Small, focused commits with an imperative subject line.
- `OneRemote.xcodeproj`, `xcuserdata` and `DerivedData` are ignored on purpose.
