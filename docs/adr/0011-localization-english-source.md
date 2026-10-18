# 0011. Localization: English source texts, German as translation

Date: 2026-10-18 · Status: Accepted

## Context
The app originally had German UI texts and German code comments. It should be usable in
German and English, with English as default.

## Decision
- Code, comments and documentation are English.
- UI texts in code are English and serve as the keys; `Resources/de.lproj` holds
  `Localizable.strings` and `InfoPlist.strings`. English is the development language
  and the fallback for every other device language.
- SwiftUI literals (`Text("…")`, `Button("…")`) localize automatically. Strings stored in
  `String` variables (status messages, hints) use `String(localized:)`.
- The Bluetooth usage description in `project.yml` is English; the German one is in
  `InfoPlist.strings`.

## Consequences
New texts need an entry in `de.lproj/Localizable.strings` (interpolations become `%@`
or `%lld`). A missing entry shows the English text, never a broken key. Another language
is a copied `.lproj` folder.
