# Sauna — Garmin Connect IQ activity tracker

Version history is in [CHANGELOG.md](CHANGELOG.md).

A simple watch app that records time spent in the sauna as a Garmin activity.
It logs **elapsed time, heart rate, calories and temperature**, alternates
between **sauna** and **relax** phases (each is a lap in the FIT), and saves the
session to **Garmin Connect** as a FIT activity. No GPS / location is used.

> **Temperature note:** the value comes from the watch's built-in thermometer.
> Worn on the wrist it reads close to body temperature, not true sauna air
> temperature, and a sauna's heat can exceed the watch's rated operating range.
> An external Garmin *tempe* sensor gives an accurate ambient reading.

## On-watch controls (Fenix / Epix)

| Button                | Action                                                  |
|-----------------------|---------------------------------------------------------|
| START (top-right)     | Start; press again to pause + open the finish menu      |
| BACK (bottom-right)   | Switch sauna ⇄ relax while running; resume from pause; exits when idle |
| MENU (long-press UP)  | Open the finish menu (Resume / Save / Discard)          |

A session starts in the **sauna** phase; each BACK press ends the current phase
and starts the other one (recorded as a new lap). The finish menu pauses the
session and offers **Resume / Save / Discard**. Saving writes the activity to
your watch's history, which syncs to Garmin Connect on the next sync.

### Single dashboard

Everything is shown on one screen, no paging:

```
        SAUNA          phase / status (orange = sauna, blue = relax)
        3:01           time in the current phase (big)
      total 12:34      total elapsed time
  HR 132      78°C     heart rate | temperature
  84 kcal     S2 R1    calories   | sauna/relax counts
       14:35           time of day
```

## Build

```sh
./build.sh            # builds for fenix6s -> sauna/bin/sauna.prg
./build.sh fenix7     # or any product id from sauna/manifest.xml
```

## Run in the simulator

```sh
./run.sh              # builds, launches the simulator, loads the app
```

In the simulator, use the on-screen buttons (or the arrow keys) for START/DOWN/BACK.

## Install on a real watch

Plug the watch in by USB (the `GARMIN` drive should mount), then:

```sh
./install.sh             # builds for fenix6s, copies to the watch
EJECT=1 ./install.sh     # …and also ejects so you can unplug right away
```

`install.sh` finds the watch's `GARMIN/Apps` folder automatically, copies the
signed `.prg`, and skips macOS's `._SAUNA.PRG` resource-fork sidecar.

If you'd rather do it by hand: `./build.sh fenix6s` then
`cp sauna/bin/sauna.prg /Volumes/GARMIN/GARMIN/Apps/SAUNA.PRG`, eject, unplug.

The app appears in the watch's **activity list** (press START from the watch
face). Updating is the same `./install.sh` — it just overwrites `SAUNA.PRG`.

> ⚠️ The `developer_key` is the cryptographic identity tied to your apps in
> the Connect IQ Store. It's `.gitignore`'d so it isn't tracked by git —
> **keep a backup somewhere safe**: losing it means you can't publish updates
> to your apps in the store.

## Project layout

```
sauna/
  manifest.xml              app id, type, targets, permissions (Fit, FitContributor, Sensor, SensorHistory)
  monkey.jungle             build config
  source/
    saunaApp.mc             AppBase; wires up the activity + saves on exit
    saunaView.mc            data screens (custom drawn, 1s refresh)
    saunaDelegate.mc        button handling
    StopMenuDelegate.mc     Resume / Save / Discard menu
    SaunaActivity.mc        ActivityRecording wrapper: state, phases, temperature
  resources/                strings + launcher icon
```
