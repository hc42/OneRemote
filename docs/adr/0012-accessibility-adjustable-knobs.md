# 0012. Accessibility: each knob is one adjustable element

Date: 2026-10-18 · Status: Accepted

## Context
The knobs are drawn by hand: LEDs, labels and tap areas are plain shapes and invisible
to VoiceOver, and circular dragging is not usable with it.

## Decision
`RotaryKnob` hides its parts from accessibility and exposes one element with a label
("Volume"/"Input"), a spoken value ("−23 dB", "Muted", "Fixed", the input name), a hint,
an adjustable action (swipe up/down: volume ±1 dB, input next/previous) and a default
action (double tap = mute). The captions are hidden as they only repeat the label.
"Reduce Motion" disables the input blinking (0008).

## Consequences
Everything on the main screen is reachable with VoiceOver, and the texts are localized
(0011). The per-LED tap areas are intentionally not exposed; swiping steps through inputs.
