# AGENTS.md

Guidance for AI coding agents (and humans) working on this repository.

## What this is

One Remote: a native SwiftUI app (iPhone, iPad, Mac) that controls an ONE / ONE HD amplifier
over Bluetooth LE. See `README.md` for features and structure, `docs/PROTOCOL.md` for the BLE
protocol and `docs/adr/` for the reasons behind the design.

## Build

- The Xcode project is generated and not committed. After adding, removing or renaming files,
  or changing `project.yml`, run `xcodegen generate`.
- One target for iOS 16+ and macOS 13+. Anything newer needs an availability check or a
  different approach (for example no `onKeyPress`, see ADR 0013).
- Platform-specific code goes in `#if os(iOS)`, `#if os(macOS)` or `#if canImport(UIKit)`.
  Typical offenders: `navigationBarTitleDisplayMode`, `toolbarBackground(for: .navigationBar)`,
  haptics, `NSEvent`. Check that both platforms still compile.
- There is no test target yet. Verify behavior on a device using `docs/TESTING.md`; the amplifier
  accepts a single BLE connection, so other controllers must be disconnected.

## Conventions

- Code, comments, commit messages and docs are English.
- UI texts in code are English and are the localization keys. Every new user-visible text
  needs a German entry in `OneRemote/Resources/de.lproj/Localizable.strings`
  (interpolations: `%@` for strings, `%lld` for integers). SwiftUI literals localize
  automatically; text stored in a `String` needs `String(localized:)`. See ADR 0011.
- Do not use the amplifier manufacturer's brand in names, texts or assets. The product is
  "One Remote"; types use the `Amp` prefix. "ONE" / "ONE HD" are model names only.
- Keep the app responsive: BLE writes for volume and balance are rate limited and the UI
  updates optimistically (`AmpController`).
- Knobs must stay usable with VoiceOver, keyboard and mouse (ADR 0012, 0013).

## Architecture in short

- `BLE/AmpProtocol.swift`: UUIDs, command frames, inputs, value conversions.
- `BLE/AmpController.swift`: the only owner of the CoreBluetooth connection and the app state
  (`ObservableObject`); scan, connect, reconnect by name, send, parse.
- `Views/`: SwiftUI views read the controller state and call its methods. `ControlView` is
  the main page, `RotaryKnob` the reusable knob.

## Decisions to respect

Read the matching ADR before changing these areas:

- Volume LED scale and its hysteresis, and dB-based scrolling: 0005, 0006.
- Reconnect by advertised name, never rely on the peripheral identifier alone: 0004.
- No Siri, widgets or Control Center controls (tried, too slow with a single connection): 0009.
- AV Direct toggle only when the state is known, with the confirmation flow: 0010.

## Documentation

- A decision that is hard to reverse, or that took trying alternatives, gets a new ADR in
  `docs/adr/` (copy the newest file, next number, add it to the table in `docs/adr/README.md`).
  ADRs must be standalone: no references to chats, tickets or people.
- Protocol facts go in `docs/PROTOCOL.md`; mark what is confirmed on real hardware.

## Git

- Small, focused commits with an imperative subject line.
- `OneRemote.xcodeproj`, `xcuserdata` and `DerivedData` are ignored on purpose.
