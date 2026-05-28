#!/usr/bin/env bash
# Build the Sauna app for one device.
#   ./build.sh [device]   (default: fenix6s)
set -euo pipefail

SDK="$(sed 's:/*$::' "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")"
ROOT="$(cd "$(dirname "$0")" && pwd)"
DEVICE="${1:-fenix6s}"

"$SDK/bin/monkeyc" \
  -o "$ROOT/sauna/bin/sauna.prg" \
  -f "$ROOT/sauna/monkey.jungle" \
  -y "$ROOT/developer_key" \
  -d "$DEVICE" \
  -w

echo "Built sauna/bin/sauna.prg for $DEVICE"
