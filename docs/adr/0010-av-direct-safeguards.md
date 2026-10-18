# 0010. AV Direct: explicit warning flow and state-checked toggle

Date: 2026-10-18 · Status: Accepted

## Context
AV Direct makes the amplifier a power amplifier with a fixed, high volume on the AV input.
With a wrongly configured system this can damage speakers. The command that switches it
is a toggle (`@+A11%`), the same for on and off.

## Decision
- Enabling needs a warning sheet with a mandatory "I have read and understood" checkbox
  and then a final confirmation dialog. Disabling needs one confirmation.
- The toggle is only sent while the state is known and still the one the confirmation was
  based on (`toggle(whileAVDirectIs:)`); the buttons are disabled for 1.5 s afterwards.
- Offered only from firmware 2.0; otherwise a hint explains why it is unavailable.
- With AV Direct on and the AV input selected, the volume controls are locked and the
  ring shows the three top LEDs and "FIXED".

## Consequences
A stale or unknown state can never flip the mode by accident, at the cost of an extra
tap or two.
