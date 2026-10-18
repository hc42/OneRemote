# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow
[Semantic Versioning](https://semver.org/) (see `docs/adr/0017-versioning-and-releases.md`).

## [Unreleased]

First release will be 0.1.0.

### Added
- Demo mode: "Try the demo" in the device search controls a simulated amplifier without Bluetooth
  or network, so the app can be tried (and reviewed) without the hardware.
- Two endless rotary controls for input and volume with the LED scale of the amplifier,
  including its hysteresis; volume in single dB steps with a sensitivity setting.
- Control by turning, swiping around the knob, tapping an input LED or label, keyboard
  shortcuts and the mouse wheel (Mac).
- Blinking LED for the newly selected input.
- Automatic reconnect after the amplifier was switched off and on, also when its Bluetooth
  identifier changes.
- Settings: device selection, balance, display brightness, volume limit, sensitivity, AV Direct
  with a two-step confirmation, device info.
- English and German user interface; VoiceOver support.
- iPhone, iPad and Mac from one code base.
- Privacy manifest and privacy policy (the app collects no data).
