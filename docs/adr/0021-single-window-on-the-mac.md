# 0021. Single window on the Mac, quit when it closes

Date: 2026-10-23 · Status: Accepted

## Context
The Mac app used a `WindowGroup`, so File > New Window opened more windows. All windows share one
`AmpController`, and the amplifier accepts a single BLE connection, so a second window only shows
the same controls twice. After the last window was closed the app kept running without a window,
still holding the Bluetooth connection, which blocked other controllers (phone, tablet).

## Decision
- On macOS the scene is a single `Window` (available from macOS 13). There is no "New Window"
  command; the window can be reopened from the Window menu.
- An `NSApplicationDelegate` returns `true` from `applicationShouldTerminateAfterLastWindowClosed`,
  so closing the window quits the app and releases the connection.
- iOS and iPadOS keep the `WindowGroup`.

## Consequences
- One window, one connection: the Mac behaves like a small utility app.
- Closing the window frees the amplifier for other controllers right away.
- Multiple windows on the iPad are unaffected.
