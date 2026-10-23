# 0022. Continuous integration with GitHub Actions

Date: 2026-10-23 · Status: Accepted

## Context
ADR 0018 postponed continuous integration until the repository was hosted with a CI service. It is
now on GitHub, which already runs CodeQL on macOS. The tests only ran when someone remembered
`scripts/test.sh`, so a failing test could land on `main` unnoticed.

## Decision
- The workflow `.github/workflows/tests.yml` runs on every push to `main`, on pull requests to
  `main` and by hand. It calls `scripts/test.sh`, so CI and local runs use the same test plans and
  the same pass/fail check; there is no second definition of the suites.
- Job "unit" runs `scripts/test.sh mac` (Unit plan on macOS, fast). Job "ui" runs
  `scripts/test.sh ui` (UI plan on an iPhone simulator, demo mode with the simulated amplifier) and
  starts only when the unit tests passed, to save runner minutes.
- The runner has no signing team (`Config/Local.xcconfig` is not tracked). The workflow sets
  `XCODEBUILD_ARGS` for ad-hoc signing (`CODE_SIGN_IDENTITY=-`); `scripts/test.sh` appends it to
  every `xcodebuild` call. Simulator builds need no signing.
- On failure the result bundles (`build/test-results/`) are uploaded as an artifact for 7 days.
- Not in CI: the Mac UI tests (only a start test, ADR 0018), the store screenshots and everything on
  real hardware (`docs/TESTING.md`).

## Consequences
- Every change to `main` and every pull request shows whether the tests pass.
- macOS runner minutes count tenfold on private repositories; the UI job is the expensive part.
- The runner's Xcode may lag behind the local one; code must build with the runner image's Xcode
  (the same image as the CodeQL workflow).
