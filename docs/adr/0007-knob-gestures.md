# 0007. Knob gestures: circular drag, swipe zones, tap on LEDs

Date: 2026-10-18 · Status: Accepted

## Context
Turning in a circle alone is slow for large changes. Straight swipes (volume and input,
horizontal or vertical) and direct selection of an input by tapping its LED or label
are wanted as well. A swipe recognizer on the knob itself conflicts with the circular drag.

## Decision
- On the knob: relative circular drag (only angle changes count, the knob never jumps
  to the touched spot), tap = mute (volume knob). No turning in the center area, where
  the angle is unstable.
- Around the knob (the whole zone of each knob): straight swipe, right/up = more,
  left/down = less; 135° of rotation per knob width, minimum distance 6 pt. The knob has
  priority on its own area.
- Input arc: a tap area over each LED and label selects that input directly.
- Haptic tick on each LED / step change (iOS).
- Bigger knobs: margins kept small, size capped at 560 pt; captions ("Volume",
  "Input") moved close to the knob with negative spacing.

## Consequences
Gestures are reported in degrees so volume (non-linear, 0006) and input (steps) share
the same recognizers. Keyboard and mouse wheel add to these (0013).
