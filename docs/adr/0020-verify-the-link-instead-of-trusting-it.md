# 0020. Verify the link instead of trusting its state

Date: 2026-10-23 · Status: Accepted

## Context
The app is suspended in the background. If the amplifier is switched off in the meantime, or the
system drops the link, the app may never be told: after hours or a day it still believes it is
connected (empty controls, no values), or it holds a connection attempt whose timers never ran.
Coming to the foreground then neither reconnected nor showed a usable state.

## Decision
- Whenever a link is opened, and whenever the app comes to the foreground while connected, the
  controller asks the amplifier for its values and expects any answer within a few seconds
  (`AmpTiming.probeTimeout`). It asks again once or twice. If nothing arrives, it drops the link and
  connects from scratch after a short pause (`restartDelay`). The amplifier answers every request,
  so silence means the link is dead.
- Coming to the foreground while not connected starts a new connection attempt. An attempt that has
  been open longer than its time limit is considered stale and is restarted.
- The disconnect report for a request the controller cancelled itself, arriving after a new attempt
  has started, is ignored; otherwise it would reset the new attempt.

## Consequences
- A dead link is replaced within a few seconds of opening the app, without user action.
- A very slow amplifier (several seconds to answer after power-up) is asked a few times, then the
  link is reopened, which does no harm.
- The checks only run while the app is running; no Bluetooth background mode is used.
