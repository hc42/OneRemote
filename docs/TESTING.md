# Manual test checklist

There are no automated tests yet. Run this list on a real amplifier before a release and after
changes to `AmpController`, `ControlView`, `RotaryKnob` or the localization. Test on at least
one iPhone and the Mac; use an iPad if layout code changed.

Preparation: no other controller connected, volume limit at the default, headphones unplugged.

## Connection

- [ ] First start: Bluetooth permission prompt appears with the English or German text matching the device language.
- [ ] Search lists the amplifier; selecting it connects and shows the main screen.
- [ ] Force quit and reopen: connects automatically.
- [ ] Switch the amplifier off and on: the app reconnects without manual search (identifier may change).
- [ ] Amplifier off while the app is open: connection screen with status text; "Try again" works once it is on.
- [ ] Bluetooth switched off in the system: status text, no crash; reconnects when switched on again.
- [ ] Lock and unlock the phone or return from the background: values refresh.
- [ ] "Search for another device" from Settings opens the search at once.

## Volume

- [ ] Turning and swiping change the volume in single dB steps; the LED moves with hysteresis (check a few thresholds up and down against the amplifier).
- [ ] The center shows the same dB value as the amplifier's display behaviour implies; sign and digits are centered.
- [ ] Tap mutes and unmutes; the ring dims while muted.
- [ ] Volume limit: the knob and keys stop at the limit; LEDs above are dimmed.
- [ ] Sensitivity slider: sluggish and sensitive both feel usable; "Default" resets.
- [ ] Haptic tick on LED change (iOS).

## Input

- [ ] Turning, swiping and tapping an LED or label select inputs; labels are correct (symbols for Bluetooth, USB and Phono; red for Bluetooth, USB, 3, 4).
- [ ] The new input's LED blinks only for a change made while the app is open, not on start, unlock or reconnect.
- [ ] Changing the input at the amplifier updates the app.

## Settings

- [ ] Balance: slider and "Center" work; greyed out with headphones connected.
- [ ] Display brightness buttons repeat while held.
- [ ] Device info shows serial number, firmware, DAC model; "Refresh values" updates them.

## AV Direct

- [ ] Not offered below firmware 2.0 (hint shown) and while the state is unknown.
- [ ] Enable: warning sheet needs the checkbox, then the final dialog; cancel at each step leaves it off.
- [ ] On the AV input with AV Direct on: volume locked, "FIXED", three top LEDs lit.
- [ ] Disable asks for one confirmation; the state matches the amplifier afterwards.

## Languages and accessibility

- [ ] Run once with the device in German and once in English; all texts, status lines and the Bluetooth permission text are translated; another language falls back to English.
- [ ] VoiceOver: both knobs are announced with name and value; swiping up and down changes them; double tap mutes.
- [ ] Reduce Motion: no input blinking.

## Mac

- [ ] Window opens, Bluetooth permission works with the sandbox.
- [ ] Arrow keys and space work; the mouse wheel changes volume and input over their areas.
- [ ] No iOS-only UI artifacts (navigation bar title, haptics).
