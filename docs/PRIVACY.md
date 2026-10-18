# Privacy

One Remote works entirely on your device and talks only to your amplifier over Bluetooth.
It does not collect, transmit or share any data.

## What the app does with data

| Data | Where it comes from | What happens to it |
|---|---|---|
| Bluetooth devices nearby | The app scans for Bluetooth devices and lists only those whose name starts with `ONE`. | Used to find your amplifier. Not stored, apart from the device you choose. |
| Chosen amplifier (name and system identifier) | Your selection in the device list. | Stored on the device so the app can reconnect by itself. |
| Settings (volume limit, sensitivity) | Your input in the settings. | Stored on the device. |
| Amplifier state (volume, input, balance, serial number, firmware, ...) | Read from the amplifier. | Kept in memory while the app runs and shown in the app. Not stored. |
| Short technical connection log | Created by the app while connected. | Kept in memory only (last 200 lines), not shown, not stored, not sent anywhere. |

The stored values live in the app's own local settings storage (`UserDefaults`). They are
removed when you delete the app.

## What the app does not do

- No network access: the app contains no networking code and, on the Mac, has no network
  entitlement in its sandbox.
- No analytics, crash reporting, advertising, tracking or third-party SDKs.
- No account, no sign-in, no cloud sync.
- No access to location, contacts, photos, camera or microphone.

## Permissions

- **Bluetooth** is required to find and control the amplifier. Without it the app cannot work.
  You can withdraw it at any time in the system settings.

## App Store privacy details

- Data collection: **Data Not Collected**.
- Tracking: none.
- The app declares its use of the local settings storage in `OneRemote/PrivacyInfo.xcprivacy`
  (reason `CA92.1`: access to information written by the app itself).

## Contact

Hans-Christian Halfbrodt, oneremote-hc@halfbrodt.org

Changes to the data handling are documented here and in the architecture decision records
(`docs/adr/`).
