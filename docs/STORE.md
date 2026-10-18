# App Store listing

Texts for App Store Connect, in English (default) and German. Limits: name 30 characters, subtitle 30,
promotional text 170, keywords 100 (comma separated, no spaces), description 4000.

The amplifier maker's name and model names are third-party trademarks. They are not used in the name,
subtitle or keywords; the description says what the app works with in general terms and states that it is
unofficial. Check this again before every submission.

## English (U.S.)

**Name:** One Remote
**Subtitle:** Bluetooth amp remote control
**Promotional text:**
A calm, focused remote for your amplifier: two big knobs for volume and input, just like on the device.

**Keywords:** amplifier,remote,bluetooth,volume,input,hifi,audio,stereo,knob,controller,dac

**Description:**
One Remote controls your compatible Bluetooth amplifier from your iPhone, iPad or Mac.

Two large knobs, just like on the front panel: one for the input, one for the volume. Turn them, swipe them or
tap them. The LEDs light up the way they do on the device, and the volume changes in single dB steps.

FEATURES
• Volume in single dB steps, with a safety limit you set yourself
• Input selection by turning, swiping or tapping a label
• Tap the volume knob to mute
• Balance, display brightness and AV Direct
• Reconnects automatically when you switch the amplifier off and on
• Mouse wheel and keyboard shortcuts on the Mac (arrow keys, space for mute)
• Full VoiceOver support and Reduce Motion
• English and German

PRIVATE BY DESIGN
No account, no analytics, no tracking. The app only talks to your amplifier over Bluetooth and stores a few
settings on your device.

One Remote is an independent app and is not affiliated with or endorsed by the amplifier's manufacturer.
It needs a compatible amplifier with Bluetooth.

**What's new (first version):** First release.

## Deutsch

**Name:** One Remote
**Untertitel:** Bluetooth-Fernbedienung
**Werbetext:**
Eine ruhige, klare Fernbedienung für deinen Verstärker: zwei große Regler für Lautstärke und Eingang, wie am Gerät.

**Schlüsselwörter:** verstärker,fernbedienung,bluetooth,lautstärke,eingang,hifi,audio,stereo,regler,dac

**Beschreibung:**
One Remote steuert deinen kompatiblen Bluetooth-Verstärker von iPhone, iPad oder Mac aus.

Zwei große Regler wie an der Frontplatte: einer für den Eingang, einer für die Lautstärke. Du kannst sie drehen,
wischen oder antippen. Die LEDs leuchten wie am Gerät, und die Lautstärke ändert sich in einzelnen dB-Schritten.

FUNKTIONEN
• Lautstärke in einzelnen dB-Schritten, mit einem Sicherheitslimit, das du selbst festlegst
• Eingangswahl durch Drehen, Wischen oder Antippen einer Beschriftung
• Lautstärkeregler antippen zum Stummschalten
• Balance, Display-Helligkeit und AV Direct
• Verbindet sich automatisch wieder, wenn du den Verstärker aus- und einschaltest
• Mausrad und Tastenkürzel am Mac (Pfeiltasten, Leertaste für Stumm)
• Volle VoiceOver-Unterstützung und „Bewegung reduzieren“
• Deutsch und Englisch

PRIVATSPHÄRE
Kein Konto, keine Analyse, kein Tracking. Die App spricht nur per Bluetooth mit deinem Verstärker und speichert ein
paar Einstellungen auf deinem Gerät.

One Remote ist eine unabhängige App und steht in keiner Verbindung zum Hersteller des Verstärkers und wird von
ihm nicht empfohlen. Du brauchst einen kompatiblen Verstärker mit Bluetooth.

**Neu in dieser Version:** Erste Veröffentlichung.

## Other fields

- **Category:** Utilities (secondary: Music)
- **Price:** free
- **Age rating:** 4+ (no objectionable content)
- **Support URL / Marketing URL:** the repository page or a small page on the project's own domain
- **Privacy policy URL:** public address of `docs/PRIVACY.md` (needed before submission)
- **App privacy ("nutrition label"):** Data Not Collected
- **Contact for review:** `oneremote-hc@halfbrodt.org`

## App Review

The reviewers do not own the amplifier. Without a way to try the app, it is rejected under guideline 2.1
(app completeness). Provide at least one of:

1. A demo mode inside the app that is visible to everyone (preferred), described in the review notes.
2. A screen recording that shows connecting, volume, input and reconnecting with the real amplifier.

Implemented (ADR 0019): the device search ends with **Try the demo**, which controls a simulated amplifier in every
build. Put this in the App Review notes:

> The app controls a Bluetooth amplifier that reviewers do not have. Open the app, scroll to the end of the device
> search and tap "Try the demo": it shows all controls (volume, input, balance, settings) with a simulated amplifier.
> The demo uses no Bluetooth and no network. "Exit demo" in the settings returns to the search.
