# 0001. Record architecture decisions

Date: 2026-10-18 · Status: Accepted

## Context
The app evolved through many small iterations (gestures, LED scale, reconnect). The
reasons behind such choices are easy to lose, and some options were tried and then
reversed (for example widgets).

## Decision
Keep short, numbered decision records in `docs/adr/`, one file per decision, including
rejected and reverted options and why.

## Consequences
New design decisions get a record in the same commit. Reverted experiments stay
documented so they are not repeated blindly.
