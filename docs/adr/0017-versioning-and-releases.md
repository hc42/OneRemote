# 0017. Versioning, changelog and release steps

Date: 2026-10-18 · Status: Accepted

## Context
TestFlight and the App Store identify an upload by a version string and a build number: the
version is shown to users, the build number must be higher than every earlier upload of the
same version. The project has one target for iOS and macOS. A hard-coded version in a
generated Info.plist can silently override the build settings.

## Decision
- **Single source:** `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.yml`. The
  generated Info.plist refers to them (`$(MARKETING_VERSION)`, `$(CURRENT_PROJECT_VERSION)`).
  Both platforms share them.
- **Version:** Semantic Versioning `MAJOR.MINOR.PATCH`. `0.x.y` while the app is for testers,
  `1.0.0` for the first public release. New feature: minor, fix: patch.
- **Build number:** a plain integer, +1 for every upload to App Store Connect (TestFlight
  included), never reset and never derived from the commit count, because rewriting history
  would lower it.
- **Changelog:** `CHANGELOG.md` in "Keep a Changelog" format, English. User-visible changes are
  added under "Unreleased" together with the change. The text for TestFlight ("What to Test")
  and the App Store ("What's New") is taken from it.
- **Tags:** an upload is tagged `v<version>+<build>`, for example `v0.1.0+1`.

Release steps:
1. Move the "Unreleased" entries of `CHANGELOG.md` to a new section `## [x.y.z] - date`.
2. Set `MARKETING_VERSION` (if it changes) and increase `CURRENT_PROJECT_VERSION` in
   `project.yml`.
3. Run `xcodegen generate`, go through `docs/TESTING.md`.
4. Archive for iOS and macOS in Xcode and upload via the Organizer.
5. Commit ("Release x.y.z (build n)") and create the tag.

## Consequences
- Uploads are always accepted by version and build rules; a repeated upload of the same version
  only needs a build bump.
- Uploading requires a paid Apple Developer Program membership and a team other than a
  Personal Team; `DEVELOPMENT_TEAM` in `project.yml` has to be changed accordingly.
- External TestFlight testers need a Beta App Review for the first build of each new version.
