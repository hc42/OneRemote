# 0004. Reconnect by advertised name, not by identifier

Date: 2026-10-18 · Status: Accepted

## Context
After the amplifier is switched off and on, a reconnect by the stored peripheral
identifier fails, because the iOS identifier of the amplifier changes after a power
cycle. The advertised name (`ONEHDxx`), the system name and the advertised services
stay the same.

## Decision
- Remember identifier and name of the chosen device.
- Connect attempts alternate between a direct connect by identifier and a scan; the
  scan runs in parallel and matches by identifier or advertised name.
- When the connection is ready, save the (possibly new) identifier.
- Failures and connection loss schedule automatic retries; coming to the foreground
  triggers a refresh when connected or an immediate retry when not.
- Selecting another device is a separate screen; the settings screen is dismissed first
  so the search is visible at once.

## Consequences
- Two amplifiers with the same name would be ambiguous; the saved identifier is tried
  first, the name is only the fallback.
- No diagnostic log is shown in the UI any more (it was only needed to find this).
