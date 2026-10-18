# 0003. Talk BLE directly with a single connection

Date: 2026-10-18 · Status: Accepted

## Context
The amplifier is controlled over one GATT service with a write/notify characteristic
(see `docs/PROTOCOL.md`). It accepts only one BLE connection at a time. There is no
cloud or network API.

## Decision
`AmpController` owns the only `CBCentralManager` and the connection. It sends
framed ASCII commands (`@+<cmd><len><data>%`), keeps the last known state from
notifications and queries all values after connecting and when the app becomes
active again. The view layer only reads `@Published` state and calls controller
methods.

## Consequences
- While this app is connected, no other controller (including the manufacturer's app)
  can connect, and the other way round.
- Anything that wants to talk to the amplifier from outside the app process
  (extensions, intents) would need its own connection and fails this limit (see 0009).
- Setting the volume is optimistic: the UI value changes at once, the echo from the
  amplifier is ignored for a short guard time to avoid values jumping back.
