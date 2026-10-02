#!/usr/bin/env bash
# Runs focused bot builds for full-length games and summarizes damage per cast.
# Usage: tools/run_balance_matrix.sh [seconds] [seeds...]     e.g. tools/run_balance_matrix.sh 1200 11 12 13
# Pure DPS test by default: invulnerable bot with full-map XP magnet.
# Extra env: GODOT=/path/to/Godot  INVULNERABLE=0 (let the bot die)  MAGNET=0 (normal XP pickup)  BUILDS="a,b,c;d,e,f" (override the builds)
set -euo pipefail
cd "$(dirname "$0")/.."
SECONDS_LIMIT="${1:-1200}"; shift || true
SEEDS=("${@:-11 12 13}"); [ "$#" -eq 0 ] && SEEDS=(11 12 13)
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
BUILDS="${BUILDS:-meteor_shower,plague_seed,ice_blast;ember_trail,cinder_field,arcane_orbit;bolt,ember_lance,rune_trap;seeking_spirit,focus_ray,returning_blade;lightning_arc,plague_seed,meteor_shower}"
OUT="builds/balance/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT"
FLAGS=(--headless --fast --seconds "$SECONDS_LIMIT" --seeds "${SEEDS[@]}")
[ "${INVULNERABLE:-1}" = "1" ] && FLAGS+=(--invulnerable)
[ "${MAGNET:-1}" = "1" ] && FLAGS+=(--magnet)
IFS=';' read -ra SETS <<< "$BUILDS"
for build in "${SETS[@]}"; do
  echo "=== $build"
  python3 tools/run_bot.py --godot "$GODOT" "${FLAGS[@]}" --focus "$build" --output "$OUT/${build//,/+}" || echo "build $build failed; continuing"
done
python3 tools/summarize_bot.py "$OUT" | tee "$OUT/summary.md"
echo "Summary: $OUT/summary.md"
