#!/usr/bin/env bash
# Build, start the Connect IQ simulator (if needed), and load the app.
#   ./run.sh [device]   (default: fenix6s)
set -euo pipefail

SDK="$(sed 's:/*$::' "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")"
ROOT="$(cd "$(dirname "$0")" && pwd)"
DEVICE="${1:-fenix6s}"

"$ROOT/build.sh" "$DEVICE"

# Launch the simulator if it isn't already running.
if ! pgrep -qf "ConnectIQ.app"; then
  "$SDK/bin/connectiq" &
  sleep 4
fi

"$SDK/bin/monkeydo" "$ROOT/sauna/bin/sauna.prg" "$DEVICE"
