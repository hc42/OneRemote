# 0002. Native SwiftUI app, one multiplatform target, XcodeGen

Date: 2026-10-18 · Status: Accepted

## Context
The app must run on iPhone, iPad and Mac, talk Bluetooth LE and feel like the
amplifier's front panel (custom drawn knobs and LEDs).

## Decision
- Native SwiftUI with CoreBluetooth, no cross-platform framework.
- One target for iOS and macOS (`supportedDestinations`), deployment iOS 16 and
  macOS 13. Platform differences are `#if os(...)` blocks (for example
  `navigationBarTitleDisplayMode`, `toolbarBackground`, haptics, scroll wheel).
- The Xcode project is generated from `project.yml` with XcodeGen and not committed
  (`*.xcodeproj` is ignored).

## Consequences
- Custom drawing and gestures are straightforward, no web or bridge layer in the
  latency path.
- After adding files or changing targets, run `xcodegen generate`.
- APIs newer than iOS 16 / macOS 13 (for example `onKeyPress`) are not available;
  keyboard shortcuts use `keyboardShortcut` instead (see 0013).
