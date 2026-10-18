# 0013. Keyboard shortcuts and mouse wheel

Date: 2026-10-18 · Status: Accepted

## Context
On the Mac (and an iPad with keyboard) circular dragging is awkward. The deployment
target (iOS 16 / macOS 13) excludes `onKeyPress`.

## Decision
- Hidden zero-size buttons with `keyboardShortcut` and no modifiers: up/down arrow =
  volume ±1 dB, left/right arrow = previous/next input, space = mute.
- macOS: an `NSView` background with a local scroll-wheel event monitor, active only
  while the pointer is over the knob zone. The direction is the physical one, independent
  of "natural scrolling". One wheel notch is about a third of an LED step for volume and
  one step for the input; a trackpad swipe of about 60 pt counts as one notch.

## Consequences
Works without newer APIs. The monitor is removed with the view. Shortcuts only work
while the control screen is shown, which is intended.
