# Security policy

One Remote is a hobby project, maintained in spare time. Security reports are still welcome and
are handled on a best-effort basis.

## Supported versions

Only the latest release and the current `main` branch receive fixes. The project is at version
0.x; there are no long-term support branches.

## Reporting a vulnerability

Please do not open a public issue for a vulnerability.

- Use GitHub's private reporting: **Security > Report a vulnerability** on
  <https://github.com/hc42/OneRemote>, or
- write to **oneremote-hc@halfbrodt.org** with "One Remote security" in the subject.

Helpful details: the affected version or commit, the platform (iPhone, iPad, Mac), steps to
reproduce, and what an attacker could achieve. You should get an answer within about a week. A fix
is released as soon as it is ready, and you are credited in the changelog if you like.

## What is in scope

- The app code in this repository, including how it handles Bluetooth data from the amplifier and
  the data it stores locally (see [docs/PRIVACY.md](docs/PRIVACY.md)).
- Anything that could make the app send commands the user did not give, for example bypassing the
  volume limit or the confirmation steps for AV Direct
  ([ADR 0010](docs/adr/0010-av-direct-safeguards.md)).
- The build and signing setup in this repository (workflows, configuration).

## What is out of scope

- The amplifier itself, its firmware and its Bluetooth protocol. The amplifier accepts commands
  from any device in range that connects first; this is a property of the hardware, not of the
  app ([docs/PROTOCOL.md](docs/PROTOCOL.md)). Please report such issues to the manufacturer.
- Vulnerabilities in Apple's operating systems, Xcode or other third-party tools.
- Problems that need a jailbroken device or physical access to an unlocked device.

## Design notes that limit the risk

The app has no networking code, no accounts and no third-party libraries, and it collects no data
([ADR 0016](docs/adr/0016-privacy-by-design.md)). The links in the About section only open the
browser. Code is scanned with CodeQL (`.github/workflows/codeql.yml`) and GitHub Actions are kept
current by Dependabot.
