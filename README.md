# One Remote (iOS / macOS)

Native SwiftUI app that remotely controls an ONE / ONE HD amplifier over Bluetooth Low Energy.

Documentation:

- [Using the app and troubleshooting](docs/USAGE.md)
- [BLE protocol](docs/PROTOCOL.md)
- Privacy: [English](docs/PRIVACY.md), [Deutsch](docs/PRIVACY.de.md)
- [Testing: automated tests and manual checklist](docs/TESTING.md)
- [App Store listing texts](docs/STORE.md)
- [Changelog](CHANGELOG.md)
- [Security policy](SECURITY.md)
- [Architecture decision records](docs/adr/README.md): why the app is built the way it is
- [Notes for AI agents and contributors](AGENTS.md)

## Features

- Two large endless rotary controls on a black background, modeled on the device: source selector
  (8 inputs, tap an input LED or label to select it directly) and volume (21 LEDs; tapping mutes).
- Turn on the knob, or swipe straight in the area around it, to change the value. The sensitivity
  can be set in the settings.
- Volume follows the LED scale of the amplifier (not linear in dB) with its hysteresis; the volume
  limit and the AV Direct lock are respected.
- The LED of a newly selected input blinks briefly.
- Automatic reconnect after the amplifier was switched off and on again. The amplifier may show up
  with a new identifier, so it is recognized by its name as well.
- Keyboard shortcuts (arrow keys, space for mute), mouse wheel on the Mac and VoiceOver support.
- English and German user interface.
- Settings: device selection, balance, display brightness, volume limit, sensitivity,
  AV Direct (with two-step confirmation), device info and an About section (version, license,
  privacy policy, source code).
- Demo mode ("Try the demo" in the device search): a simulated amplifier, for trying the app
  without the hardware.

The power switch of the amplifier is purely mechanical and cannot be controlled by the app.

## Structure

```
OneRemote/
├── project.yml                  XcodeGen configuration (generates the .xcodeproj), versions
├── .github/                     Dependabot configuration, workflows for tests and CodeQL
├── Config/                      Info.plist, signing settings (Local.xcconfig is not tracked)
├── CHANGELOG.md                 Notable changes per release
├── AGENTS.md, CLAUDE.md         Notes for AI agents (CLAUDE.md just includes AGENTS.md)
├── SECURITY.md                  How to report a vulnerability
├── scripts/                     test.sh (all tests), screenshots.sh (App Store screenshots)
├── TestPlans/                   Xcode test plans: Unit, UI, All, Screenshots
├── OneRemoteTests/              Unit tests (LED scale, protocol, parser, translations, connection handling)
├── OneRemoteUITests/            UI tests and screenshot tests against the simulated amplifier
├── docs/USAGE.md                Using the app, troubleshooting
├── docs/TESTING.md              Automated tests and manual checklist
├── docs/PROTOCOL.md             BLE protocol description
├── docs/PRIVACY.md, PRIVACY.de.md  Privacy policy
├── docs/STORE.md                App Store texts (English, German) and review notes
├── docs/adr/                    Architecture decision records (see docs/adr/README.md)
└── OneRemote/
    ├── OneRemoteApp.swift       App entry point (@main)
    ├── OneRemote-macOS.entitlements   Sandbox + Bluetooth (macOS only)
    ├── Assets.xcassets          App icon, logo, launch screen images
    ├── PrivacyInfo.xcprivacy    Privacy manifest (no tracking, no data collected)
    ├── Resources/de.lproj/      German translations
    ├── Model/
    │   ├── AppModel.swift       Holds the active controller (real amplifier or demo)
    │   ├── AmpParser.swift      Decodes the amplifier's responses
    │   └── VolumeScale.swift    LED scale, dB mapping
    ├── BLE/
    │   ├── AmpProtocol.swift    UUIDs, commands, frame format, inputs
    │   ├── AmpController.swift  Connection logic: scan, connect, send, reconnect
    │   ├── BLETransport.swift   Protocols that separate the logic from CoreBluetooth
    │   ├── CoreBluetoothTransport.swift  The CoreBluetooth implementation
    │   └── SimulatedAmplifier.swift      Simulated amplifier: demo mode, UI tests, screenshots
    └── Views/
        ├── ContentView.swift    Switches between search / connection / controls, splash image
        ├── ConnectionView.swift Connection setup, errors, switch to the search
        ├── ScanView.swift       Device search, demo entry
        ├── ControlView.swift    Main page: volume and input knobs, LED scale
        ├── RotaryKnob.swift     Endless rotary knob with LED ring, input symbols, swipe gesture
        ├── ScrollWheel.swift    Mouse wheel on the Mac
        ├── SettingsView.swift   Settings and About
        ├── HoldRepeatButtonStyle.swift  Buttons that repeat while held
        └── AVDirectView.swift   AV Direct with two-step confirmation
```

## Build and install

One Remote works only with ONE and ONE HD amplifiers. Without one you can still try the app: choose
"Try the demo" in the device search.

### Requirements

- A Mac with a current Xcode (iOS 16 / macOS 13 or newer as deployment targets, see `project.yml`)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- An Apple ID. The free one is enough to run the app on your own devices (see below).

### Steps

```
git clone https://github.com/hc42/OneRemote.git
cd OneRemote
cp Config/Local.xcconfig.example Config/Local.xcconfig   # enter your team ID, see below
xcodegen generate
open OneRemote.xcodeproj
```

1. Your team ID: in Xcode under Settings > Accounts add your Apple ID; the ID of the "Personal Team"
   (or of your paid team) is shown at Signing & Capabilities after you select a team once. Put it into
   `Config/Local.xcconfig` as `DEVELOPMENT_TEAM = ...` (the file is ignored by git), then run
   `xcodegen generate` again.
2. Choose the run destination: "My Mac", or your iPhone/iPad (connect it, enable Developer Mode under
   Settings > Privacy & Security, trust the computer).
3. Press Run. The simulator has no Bluetooth; there you can only use the demo.

The bundle identifier (`de.halfbrodt.OneRemote`) belongs to the author's team. If Xcode reports that it
cannot be registered for your team, change `PRODUCT_BUNDLE_IDENTIFIER` for the three targets in `project.yml`
(use your own prefix) and run `xcodegen generate` again.

### Limits of a free Apple ID

- On iPhone and iPad the app stops working after 7 days. Run it from Xcode again (cable or Wi-Fi);
  the settings are kept as long as you do not delete the app.
- Only a few apps can be installed this way at the same time per device.
- A paid Apple Developer Program membership removes these limits and is needed for TestFlight and the
  App Store.
- A Mac build runs without expiry when you keep the signed app (Product > Show Build Folder in Finder,
  `Release` configuration, copy `One Remote.app` to Applications).

### Tests

`scripts/test.sh` runs the unit tests and the UI tests, see [`docs/TESTING.md`](docs/TESTING.md).

## Notes

- The amplifier accepts only one connection. Disconnect other apps and devices first.
- On first connect a pairing dialog may appear. Connect again afterwards.
- The volume is shown in dB (value minus 90, so 0 to 90 is -90 to 0 dB). The maximum volume is
  limited to -30 dB (value 60 of 90) by default and is stored between
  launches.
- Volume and balance are sent live while turning, at most every 0.1 s with the latest value; the
  last value is always sent (`volumeSendInterval`, `balanceSendInterval` in `AmpController.swift`).

## Languages

English is the source and fallback language. German is provided in `OneRemote/Resources/de.lproj` (`Localizable.strings`, `InfoPlist.strings`). To add a language, copy that folder as `<code>.lproj` and translate the values; the keys are the English texts.

## Design decisions

The reasons behind the main design choices, including options that were tried and dropped, are
recorded as architecture decision records in [`docs/adr/`](docs/adr/README.md). Add a record when
you make a decision of that kind.

## License

[MIT](LICENSE). This is an independent, unofficial project and is not affiliated with the
manufacturer of the amplifier.
