# Using One Remote

## First start

1. Switch the amplifier on (its power switch is mechanical, the app cannot do that).
2. Make sure no other controller is connected to it. The amplifier accepts only one
   Bluetooth connection at a time, so close or disconnect other remote apps first.
3. Open the app and allow Bluetooth access when asked.
4. Choose your amplifier in the list "Devices found" (the name starts with `ONE`). A
   pairing dialog may appear the first time; if the connection fails afterwards, connect again.

No amplifier at hand? Choose **Try the demo** at the bottom of the device search. The app then
controls a simulated amplifier (no Bluetooth, no network, nothing is stored). Leave it with
**Exit demo** in the settings.

The app remembers the device and connects to it automatically from now on, also after the
amplifier was switched off and on again.

## Main screen

Two large knobs, modeled on the front panel: **Input** and **Volume**. They sit side by side on
wide screens and one above the other on narrow ones. The gear icon at the top right opens the
settings.

### Volume

- **Turn** the knob along its edge, or **swipe** straight in the area around it (right or up =
  louder, left or down = quieter).
- **Tap** the knob to mute or unmute.
- The LED ring follows the scale of the amplifier; the center shows the exact value in dB.
  LEDs above your volume limit are dimmed (see Settings).
- With AV Direct on and the AV input selected the volume is fixed on the amplifier. The ring
  shows the three top LEDs, "FIXED" appears and the controls are locked.

### Input

- **Turn** or **swipe** like the volume knob to step through the inputs.
- **Tap** an input's LED or its label to select it directly.
- The LED of a newly selected input blinks briefly until the input is active. The labels for
  Bluetooth, USB, 3 and 4 are red like on the device.

### Keyboard and mouse

| Action | Key / mouse |
|---|---|
| Volume up / down | Up / Down arrow, mouse wheel over the volume area (Mac) |
| Input next / previous | Right / Left arrow, mouse wheel over the input area (Mac) |
| Mute | Space |

### VoiceOver

Each knob is one adjustable element: swipe up or down to change the value, double tap on the
volume knob to mute.

## Settings

| Section | What it does |
|---|---|
| Device | Shows the connected amplifier and its status. "Search for another device" opens the search. In demo mode: "Exit demo". |
| Balance | Left/right balance, "Center" resets it. Disabled while headphones are connected. |
| Display brightness | Dimmer / brighter for the amplifier's display; hold the button to repeat. |
| Volume limit | The knobs and keys do not go above this value (default -30 dB). It is stored. |
| Sensitivity | How far you must turn or swipe per step, from sluggish to sensitive. "Default" resets it. |
| AV Direct | Switches the amplifier to power-amplifier mode, see the warning below. |
| About | Version, license, privacy summary and the contact address. |
| Device info | Serial number, firmware, DAC model, headphones, AV Direct state. "Refresh values" queries them again. |

### AV Direct (read before use)

In AV Direct mode the amplifier works as a power amplifier and, on the AV input, its volume is
fixed at a high level. With a wrongly set up system this can damage your speakers. Set the
level of the source (AV receiver, processor) first and read the amplifier's manual. The app asks
you to acknowledge a warning and confirm once more before it enables the mode. It is only
offered from firmware 2.0.

## Troubleshooting

| Symptom | What to try |
|---|---|
| "Could not connect" or the connection screen stays up | Is the amplifier on and in range? Close other apps or devices connected to it. Tap "Try again". |
| Bluetooth is turned off / access denied | Switch Bluetooth on, or allow it for the app in the system settings (Privacy & Security, Bluetooth). |
| The amplifier is not in the list | Switch it off and on, move closer, and open the search again ("Search for devices"). |
| The app does not reconnect after switching the amplifier off and on | Wait a few seconds, it retries by itself; bring the app to the front to trigger a retry. If it still fails, use "Search for another device" once. |
| Values look outdated | They refresh when the app comes to the front. Settings has "Refresh values". |
| The volume knob does nothing | The volume is locked (AV Direct on the AV input), or the volume limit is reached. |
| Balance is greyed out | Headphones are connected to the amplifier. |
| Old icon on the launch screen after an update | iOS caches launch screens. Restart the device or reinstall the app. |
| After a rename of the app the old copy stays | Delete the old app; the bundle id differs. Then search for the amplifier again. |
