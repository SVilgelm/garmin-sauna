#!/usr/bin/env bash
# Build the Sauna app and copy it to a USB-connected Garmin watch.
#
#   ./install.sh [device]     build for [device] (default: fenix6s) and install
#   EJECT=1 ./install.sh      also eject the watch when finished
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
DEVICE="${1:-fenix6s}"

# 1) Build a signed .prg.
"$ROOT/build.sh" "$DEVICE"

# 2) Find the watch's Connect IQ app folder (e.g. /Volumes/GARMIN/GARMIN/Apps).
APPS=""
for candidate in /Volumes/*/GARMIN/Apps; do
  if [ -d "$candidate" ]; then
    APPS="$candidate"
    break
  fi
done
if [ -z "$APPS" ]; then
  echo "Error: no Garmin watch found. Connect it by USB and make sure the GARMIN drive is mounted." >&2
  exit 1
fi

# 3) Copy the app. COPYFILE_DISABLE stops macOS writing a ._SAUNA.PRG sidecar.
DEST="$APPS/SAUNA.PRG"
COPYFILE_DISABLE=1 cp "$ROOT/sauna/bin/sauna.prg" "$DEST"
rm -f "$APPS/._SAUNA.PRG"
sync
echo "Installed -> $DEST"

# 4) Optionally eject so the watch can be unplugged safely.
if [ "${EJECT:-0}" = "1" ]; then
  VOLUME="${APPS%/GARMIN/Apps}"
  diskutil eject "$VOLUME" && echo "Ejected $VOLUME — safe to unplug."
else
  VOLUME="${APPS%/GARMIN/Apps}"
  echo "Eject before unplugging:  diskutil eject \"$VOLUME\""
fi
