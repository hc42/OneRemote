# 0008. Blink the input LED only for changes the viewer witnesses

Date: 2026-10-18 · Status: Accepted

## Context
On the amplifier the LED of the newly selected input blinks (about 3 s, twice per
second) until the input is active. Copying this exactly feels too slow on a phone,
so frequency and duration were tuned empirically.

## Decision
Blink the LED of the new input for 1.5 s, four times per second (6 cycles of 125 ms on
and 125 ms off). Blink only for a real change while the app is open and active, not for
the first reading after connecting, after unlocking or after returning to the app (a
2 s quiet period after becoming active). Another change restarts the blinking.
Do not blink when "Reduce Motion" is enabled.

## Consequences
The behavior resembles the device without suggesting a change that did not just happen.
The timing is an approximation and can be tuned in `ControlView`.
