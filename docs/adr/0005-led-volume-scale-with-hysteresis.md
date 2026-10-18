# 0005. Volume display: LED scale with hysteresis

Date: 2026-10-18 · Status: Accepted

## Context
The device shows the volume as one lit LED out of 21 on a ring, not as a number-only
display. The LED changes at different dB values when turning up than when turning down
(hysteresis), so a value near a threshold does not flicker. The thresholds are not
evenly spaced.

## Decision
Reproduce the device behavior with two tables (up and down thresholds in dB, from
−∞ and −88 up to 0 dB). `ledIndex(for:previous:)` takes the previously shown LED,
clamps it into the range allowed by the value and moves only when a threshold of the
current direction is crossed. LEDs above the configured volume limit are drawn dimmed.
The center shows the exact dB value (`−23`), "MUTE" or "FIXED" (see 0010).

## Consequences
- The ring matches the front panel, the number shows precision the LEDs cannot.
- The scale is pure logic with explicit tables, so it can be checked by hand against the
  device and would be easy to unit test.
