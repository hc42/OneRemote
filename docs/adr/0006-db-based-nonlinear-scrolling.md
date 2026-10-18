# 0006. Volume scrolling in dB with a non-uniform path per dB

Date: 2026-10-18 · Status: Accepted

## Context
Movement that is linear in dB does not match the display: the LEDs are far apart in dB
at the low end (−88 to −69) and close together at the top (−3 to 0). Stepping by whole
LEDs is too coarse, single-dB changes are wanted. A setting to choose between "dB"
and "LED" scrolling was considered and rejected as unnecessary complexity.

## Decision
Scrolling always works in single dB steps. A continuous position is kept in LED units
and converted to dB by piecewise-linear interpolation over the LED knots, so the finger
travel per dB is short where LEDs are far apart and long near 0 dB. The position keeps
fractions of a dB for 0.6 s and restarts from the device value after a pause.

Speed has one user setting, "Sensitivity" (slider, default in the middle, "Default"
resets): `slowdown = 3 · 4^(1 − sensitivity)`, applied to the degrees per LED and per
input step. The default is deliberately slow; faster defaults made fine adjustments hard.

## Consequences
- One mental model (equal LED distance on screen), single-dB precision.
- The sensitivity applies to turning, swiping and the mouse wheel for volume and input.
