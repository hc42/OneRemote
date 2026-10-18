# One Remote (iOS / macOS)

Native SwiftUI app that remotely controls an ONE / ONE HD amplifier over Bluetooth Low Energy.
The BLE protocol is described in `docs/PROTOCOL.md`.

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
- Settings: device selection, balance, display brightness, volume limit, sensitivity,
  AV Direct (with two-step confirmation) and device info.

The power switch of the amplifier is purely mechanical and cannot be controlled by the app.

## Structure

```
OneRemote-iOS/
├── project.yml                  XcodeGen configuration (generates the .xcodeproj)
├── docs/PROTOCOL.md             BLE protocol description
├── docs/adr/                    Architecture decision records
└── OneRemote/
    ├── OneRemoteApp.swift       App entry point (@main)
    ├── OneRemote-macOS.entitlements   Sandbox + Bluetooth (macOS only)
    ├── Assets.xcassets          App icon, logo, launch screen images
    ├── BLE/
    │   ├── AmpProtocol.swift    UUIDs, commands, frame format, inputs
    │   └── AmpController.swift  CoreBluetooth: scan, connect, send, parse, reconnect
    └── Views/
        ├── ContentView.swift    Switches between search / connection / controls, splash image
        ├── ConnectionView.swift Connection setup, errors, switch to the search
        ├── ScanView.swift       Device search
        ├── ControlView.swift    Main page: volume and input knobs, LED scale
        ├── RotaryKnob.swift     Endless rotary knob with LED ring, input symbols, swipe gesture
        ├── SettingsView.swift   Settings
        ├── HoldRepeatButtonStyle.swift  Buttons that repeat while held
        └── AVDirectView.swift   AV Direct with two-step confirmation
```

## Generate and run the project

```
brew install xcodegen
cd OneRemote-iOS
xcodegen generate
open OneRemote.xcodeproj
```

Then pick your own team under Signing & Capabilities and choose "My Mac" or a connected iPhone as
the run destination.

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

The reasons behind the main design choices are recorded in [`docs/adr/`](docs/adr/README.md).
