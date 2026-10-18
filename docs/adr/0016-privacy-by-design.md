# 0016. Privacy by design: local only, no network

Date: 2026-10-18 · Status: Accepted

## Context
The app needs only one thing: a Bluetooth link to the amplifier. Publishing it (TestFlight,
App Store) requires privacy declarations (privacy policy, privacy manifest, App Store privacy
details). Fewer data flows mean less to declare and less to get wrong.

## Decision
- The app stays local: no networking code, no analytics or crash reporting, no accounts, no
  third-party SDKs. The macOS sandbox has the Bluetooth entitlement but no network entitlement.
- The only persistent data is the chosen amplifier (name, identifier) and two settings (volume
  limit, sensitivity), kept in `UserDefaults`. Amplifier state and the connection log stay in
  memory.
- `OneRemote/PrivacyInfo.xcprivacy` declares no tracking, no collected data and the single
  required-reason API in use (`UserDefaults`, reason `CA92.1`).
- The user-facing policy is `docs/PRIVACY.md` (English) and `docs/PRIVACY.de.md` (German);
  the App Store answer is "Data Not Collected".

## Consequences
- Adding network access, analytics, another persistent store or a required-reason API (for
  example file timestamps or disk space) is a privacy-relevant change: update the manifest
  and the policy and add a new ADR in the same change.
- A public privacy policy URL is needed before an App Store release. The contact address in the
  policy is a dedicated alias, not a personal mailbox.
