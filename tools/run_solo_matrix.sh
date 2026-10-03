#!/usr/bin/env bash
# One 20-minute bot game per spell, each spell alone (Magic Missile off, invulnerable, full-map XP), N at a time.
# Usage: tools/run_solo_matrix.sh [parallel=6] [seconds=1200] [seed=11]   Output: builds/balance/solo-<timestamp>/
# Env: SPELLS="a b c" picks spells; SEEDS="11 12 13" runs each spell on several seeds (overrides the seed argument).
# Env: RANK_SCHEDULE="1.4,2.9,4.3,5.7,7.1,8.6,10" grants ranks 2..8 at those minutes instead of from cards (removes rank luck).
set -uo pipefail
cd "$(dirname "$0")/.."
PARALLEL="${1:-6}"; LIMIT="${2:-1200}"; SEED="${3:-11}"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
SPELLS="${SPELLS:-bolt ice_blast rune_trap focus_ray ember_lance arcane_orbit meteor_shower seeking_spirit plague_seed cinder_field lightning_arc returning_blade}"
OUT="${OUT:-builds/balance/solo-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$OUT"
# Plain batches (macOS ships bash 3.2 and a BSD xargs that rejects long -I commands).
JOBS=""
for spell in $SPELLS; do for seed in ${SEEDS:-$SEED}; do JOBS="$JOBS $spell:$seed"; done; done
set -- $JOBS
while [ "$#" -gt 0 ]; do
  batch=0
  while [ "$#" -gt 0 ] && [ "$batch" -lt "$PARALLEL" ]; do
    job="$1"; shift
    spell="${job%%:*}"; seed="${job##*:}"
    echo "start $spell seed $seed"
    python3 tools/run_bot.py --godot "$GODOT" --headless --fast --seconds "$LIMIT" --seeds "$seed" --focus "$spell" --invulnerable --magnet --no-missile ${RANK_SCHEDULE:+--rank-schedule "$RANK_SCHEDULE"} --output "$OUT/$spell" > "$OUT/$spell-$seed.log" 2>&1 &
    batch=$((batch + 1))
  done
  wait
done
python3 tools/summarize_bot.py "$OUT" > "$OUT/summary.md"
python3 tools/telemetry_report.py "$OUT" -o "$OUT/telemetry.html"
echo "Done: $OUT/summary.md and $OUT/telemetry.html"
