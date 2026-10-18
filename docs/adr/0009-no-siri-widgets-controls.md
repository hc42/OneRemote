# 0009. No Siri, widgets or Control Center controls

Date: 2026-10-18 · Status: Accepted (feature removed)

## Context
Siri shortcuts, interactive widgets (volume up/down/mute buttons) and iOS 18 controls
for Control Center and the lock screen were implemented and evaluated, including a
shared App Group. Results:
- Each press had to connect first and the amplifier accepts one BLE connection only
  (0003), so every action was too slow to be usable.
- Stale App Intents metadata from the removed Siri intents caused identifier errors
  ("Could not find an intent with identifier …") until the intents were renamed.

## Decision
Remove Siri support, widgets and controls completely, including the extension target,
App Group and entitlements. Restore the deployment targets (iOS 16 / macOS 13) and
the plain Bluetooth connection behavior.

## Consequences
The app has no entry point outside its own UI. This could be revisited if a persistent
background connection becomes possible (not with the current iOS behavior), or with a
bridge that keeps the connection in the app and lets extensions only send intents to it.
