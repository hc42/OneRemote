# Datenschutz

One Remote arbeitet vollständig auf deinem Gerät und spricht nur per Bluetooth mit deinem
Verstärker. Die App erhebt, überträgt und teilt keine Daten.

## Was die App mit Daten macht

| Daten | Herkunft | Verwendung |
|---|---|---|
| Bluetooth-Geräte in der Nähe | Die App sucht nach Bluetooth-Geräten und listet nur solche, deren Name mit `ONE` beginnt. | Dient dem Finden deines Verstärkers. Wird nicht gespeichert, außer dem Gerät, das du auswählst. |
| Gewählter Verstärker (Name und Systemkennung) | Deine Auswahl in der Geräteliste. | Wird auf dem Gerät gespeichert, damit die App sich selbst wieder verbinden kann. |
| Einstellungen (Lautstärkegrenze, Empfindlichkeit) | Deine Eingaben in den Einstellungen. | Werden auf dem Gerät gespeichert. |
| Zustand des Verstärkers (Lautstärke, Eingang, Balance, Seriennummer, Firmware, ...) | Wird vom Verstärker gelesen. | Wird im Arbeitsspeicher gehalten, solange die App läuft, und angezeigt. Nicht gespeichert. |
| Kurzes technisches Verbindungsprotokoll | Entsteht in der App während der Verbindung. | Nur im Arbeitsspeicher (letzte 200 Zeilen), wird weder angezeigt noch gespeichert noch gesendet. |

Die gespeicherten Werte liegen im lokalen Einstellungsspeicher der App (`UserDefaults`). Sie
werden beim Löschen der App entfernt.

Der Demo-Modus („Demo ausprobieren“ in der Gerätesuche) zeigt einen simulierten Verstärker innerhalb der App.
Er nutzt weder Bluetooth noch das Netzwerk, liest und speichert nichts über dich, und seine Werte werden beim
Beenden verworfen.

## Was die App nicht tut

- Kein Netzwerkzugriff: Die App enthält keinen Netzwerkcode und hat auf dem Mac keine
  Netzwerkberechtigung in der Sandbox.
- Keine Analyse, kein Absturzbericht, keine Werbung, kein Tracking, keine Fremd-SDKs.
- Kein Konto, keine Anmeldung, keine Cloud-Synchronisation.
- Kein Zugriff auf Standort, Kontakte, Fotos, Kamera oder Mikrofon.

## Berechtigungen

- **Bluetooth** wird gebraucht, um den Verstärker zu finden und zu steuern. Ohne Bluetooth kann
  die App nicht arbeiten. Du kannst die Berechtigung jederzeit in den Systemeinstellungen
  widerrufen.

## Angaben für den App Store

- Datenerhebung: **Daten werden nicht erhoben**.
- Tracking: keines.
- Die Nutzung des lokalen Einstellungsspeichers ist in `OneRemote/PrivacyInfo.xcprivacy`
  deklariert (Grund `CA92.1`: Zugriff auf Informationen, die die App selbst geschrieben hat).

## Kontakt

Hans-Christian Halfbrodt, oneremote-hc@halfbrodt.org
