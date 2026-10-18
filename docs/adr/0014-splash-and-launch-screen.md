# 0014. Launch screen plus in-app splash

Date: 2026-10-18 · Status: Accepted

## Context
The launch screen kept showing the old icon: iOS caches launch screens aggressively,
even when the asset and configuration are correct. The launch image should not contain
text, so it works in every language.

## Decision
- Launch screen via `UILaunchScreen` (black background color plus the device image
  without text), generated into `Config/Info.plist` by XcodeGen.
- Additionally an in-app splash overlay with the same image for about 1.2 s, so the
  intended image always appears regardless of the system cache.

## Consequences
The launch screen may still show the cached image on an upgraded install until iOS
refreshes it (deleting the app clears it); the splash hides the difference.
