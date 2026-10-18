# 0018. Testing strategy

Date: 2026-10-18 · Status: Accepted

## Context
The behavior that is easiest to get wrong is pure logic: the LED scale with its hysteresis,
the mapping between dB and scroll position, the decoding of the amplifier's responses, the
command frames and the translations. The BLE connection itself (reconnect, rate limiting) and
the gestures need a device or a simulated amplifier. The iOS simulator has no Bluetooth.

## Decision
Tests are added in layers, cheapest first:
1. **Unit tests (XCTest)** for pure logic. The logic lives in files without UI and without
   CoreBluetooth objects: `Model/VolumeScale.swift`, `Model/AmpParser.swift` and
   `BLE/AmpProtocol.swift`. The test target compiles exactly these files instead of hosting
   the app, so tests start fast and need no app launch. New logic that is worth testing goes
   into such files too.
2. **Localization tests** read the source files and `de.lproj/Localizable.strings` and check
   that every user-facing text has a German translation, that no key is stale and that the
   placeholders match.
3. `AmpController` tests with a simulated amplifier (`FakeAmplifier.swift`): connecting,
   reconnecting by name, connection loss, retry, rate limits, AV Direct lock.
4. **Later:** UI tests against a simulated amplifier, which can also create the store
   screenshots.
5. **Real hardware** stays a manual check (`docs/TESTING.md`).

Continuous integration is deliberately postponed until the repository is hosted somewhere that
offers it; the tests run from Xcode (Cmd+U) or `xcodebuild test`.

## Consequences
- A change to the scale tables, the protocol or a UI text fails a test instead of being found by
  chance on the device.
- The localization test uses a small scanner for string literals. It knows which calls show text
  to the user; a new kind of call needs to be added to its list.
- Code that is compiled into both the app and the tests must not depend on app-only files.
- `AmpController` talks to Bluetooth only through the `BLETransport` protocol. The real
  implementation (`CoreBluetoothTransport`) wraps CoreBluetooth; tests can substitute a simulated
  amplifier. The controller also takes its `UserDefaults` and its waiting times as parameters.
