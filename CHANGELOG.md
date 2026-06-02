# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[semantic versioning](https://semver.org/) — bump `version` in
`sauna/manifest.xml` to match every release.

## [1.1.0] — 2026-06-01

### Added
- Support for Garmin watches with a sub-display lens (Instinct 2 / 2S / 2X
  and similar): the current mode is rendered as an icon **inside the lens**
  — ▶ for READY, a flame for SAUNA, a "Z" for RELAX, and "||" for PAUSED.
  Phase timer and total time sit to the left of the lens; heart rate,
  temperature, calories, counts and clock fill the area below.

### Fixed
- Layout on Instinct 2/2S/2X no longer clips the title and timer behind the
  sub-display lens.

## [1.0.0] — 2026-05-27

Initial release.

### Added
- Records each sauna as a Garmin **Cardio** FIT activity (no GPS) that syncs
  to Garmin Connect with duration, heart rate and calories.
- **Sauna ⇄ relax phase toggle** on the BACK button — every switch is a lap
  in the FIT, so Garmin Connect shows the duration of every phase.
- Single dashboard with: phase (SAUNA orange / RELAX blue), large current
  phase time, total session time, current heart rate, ambient temperature
  (°C or °F per device settings), calories, sauna/relax phase counts, and
  time of day.
- **Temperature recorded as a custom FIT field** via `FitContributor`, sampled
  once per second from `SensorHistory` (built-in altimeter or external *tempe*).
- **Finish menu** (Resume / Save / Discard) via START while running, or
  long-press of the menu button.
- **Contextual BACK**: switches phase while running, resumes from pause when
  paused, exits only when idle — protects against losing data by accident.
- Haptic feedback on start, pause, phase switch and save.
- Auto-save fallback in `App.onStop` if the app is force-closed while a
  session is open.
- Custom sauna-themed launcher icon.
- `build.sh`, `run.sh`, `install.sh` for one-step build / simulator / sideload.
