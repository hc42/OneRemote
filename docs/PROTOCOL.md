# ONE BLE protocol

BLE protocol of the ONE / ONE HD amplifier as used by this app. Where a point has
been confirmed on a real ONE HD, it says so; everything else is unverified.

## Connection

| Topic | Value |
|---|---|
| Device name | starts with `ONE` |
| Service | `bc2f4cc6-aaef-4351-9034-d66268e328f0` |
| Data characteristic (write + notify) | `06d1e5e7-79ad-4a71-8faa-373789f7d93c` |
| Further characteristic (unused) | `818ae306-9c5b-448d-b51a-7add6a5d314d` |
| MTU | a larger MTU (512) can be requested; iOS negotiates it itself |

The app enables notifications on the data characteristic and then queries the
initial values.

The iOS peripheral identifier of the amplifier changes after a power cycle. The
advertised name and the service stay the same, so the app finds the device again by
name (see `AmpController`).

## Commands (app to amplifier)

Frame: `@` `+` command, length as an ASCII digit, payload, `%`

| Function | Bytes (ASCII) | Example |
|---|---|---|
| Query a value | `@+F1<cmd>%` | volume: `@+F1V%` |
| Set volume | `@+V2<dd>%` (00 to 90) | 45: `@+V245%` |
| Mute | `@+M1<0/1>%` | on: `@+M11%` |
| Input | `@+I1<n>%` | Bluetooth: `@+I11%` |
| Display brightness | `@+B1<+/->%` | brighter: `@+B1+%` |
| Toggle AV Direct | `@+A11%` | see below |
| Set balance | `@+X2<dd>%` (00 to 20, 10 = center) | center: `@+X210%` |

The volume value is `dB + 90`, so 00 is the minimum and 90 is 0 dB. The app limits
the volume to 60 by default (user-configurable).

## Responses (amplifier to app)

Byte 0 = `@`, byte 2 = command, byte 4 (and 5) = data.

| Command | Meaning | Data |
|---|---|---|
| `A` | AV Direct | `0` = off, otherwise on |
| `D` | Model with DAC (ONE HD) | `0` = no, otherwise yes |
| `H` | Headphones connected | `0` = no, otherwise yes |
| `I` | Current input | one ASCII digit |
| `M` | Mute | `0` = off, otherwise on |
| `S` | Serial number | text from byte 4, without the last character |
| `T` | Firmware | two digits, "21" means "2.1" |
| `V` | Volume | two digits |
| `X` | Balance | two digits (00 to 20) |

## AV Direct

- **Enabling and disabling send the same command** `@+A11%`. It toggles. The state
  comes back as response `A` (`0` = off, otherwise on). The command must therefore
  only be sent when the current state is known.
- The function is only offered from firmware 2.0.
- With AV Direct active and the AV input selected, the volume on the amplifier is
  fixed, so the app locks its volume controls.
- Before enabling, the app shows a warning sheet with a mandatory checkbox and a final
  confirmation dialog (`Views/AVDirectView.swift`).

## Inputs

With DAC (ONE HD), in the order on the device:

| Code | Input |
|---|---|
| 1 | Bluetooth |
| 2 | USB-B |
| 3 | Optical |
| 4 | S/PDIF |
| 6 | Aux 5 |
| 7 | Aux 6 |
| 5 | Phono |
| 8 | AV |

Confirmed on a ONE HD: code 6 is Aux 5, code 7 is Aux 6, and Phono sits directly
before AV.

Without DAC (ONE): 1 Bluetooth, 2 Phono, 3 to 5 Aux 3 to 5, 6 AV. The app only uses
the ONE HD table.

## Open points

- The balance query `@+F1X%` is answered by the ONE HD (confirmed on the device).
- Display brightness only has relative commands (`+` and `-`). No command or response
  with the current brightness value is known.
- Long responses might be fragmented across notifications. The app assumes one
  message per notification.
