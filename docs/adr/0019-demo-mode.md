# 0019. Demo mode with a simulated amplifier

Date: 2026-10-18 · Status: Accepted

## Context
The app needs an amplifier that most people, including the App Review team, do not have.
Guideline 2.1 requires that reviewers can try the app. The simulator `SimulatedAmplifier`
already exists for the UI tests (ADR 0018) but was limited to debug builds.

## Decision
- `SimulatedAmplifier` is compiled into every build. The launch arguments
  `-simulated-amplifier` / `-simulated-paired` stay debug-only, for tests and screenshots.
- The device search ends with a visible "Try the demo" entry. It starts an `AmpController` with the
  simulator, already connected, with its own settings suite (`OneRemote-Demo`, reset on every start),
  so the saved real device and the volume limit are never touched.
- `AppModel` holds the controller the screens use (real or demo); `AmpController.isDemo` marks the
  demo. The title shows "Demo", the settings offer "Exit demo" instead of the device search.
- The demo uses no Bluetooth and no network, so privacy (ADR 0016) is unchanged; PRIVACY and
  USAGE mention it.

## Consequences
- Reviewers and users without hardware can try every screen.
- The real controller keeps running in the background while the demo is shown.
- The simulator code ships in the release build (small).
