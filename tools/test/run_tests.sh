#!/bin/bash
# Runs the headless test suite, 4 at a time, and compares failures with a baseline.
#
#   tools/test/run_tests.sh                    every test, results in builds/test-results.txt
#   tools/test/run_tests.sh spell_ engine_     only tests whose names start with these
#   OUT=my.txt BASELINE=tools/test/baseline.txt tools/test/run_tests.sh
#
# Resumable: tests already listed in OUT are skipped, so a stopped run continues where it was.
# Each line of OUT is "<exit code> <test> <first FAIL / SCRIPT ERROR lines>".
# A test may raise its time limit (default 75 s) with a line "## timeout: <seconds>".
# Exit codes: 0 pass, 1 checks failed, 2 needs a display/audio (visual tests), 124 timed out (visual tests headless).
# GODOT: path to a Godot 4.4 binary (default: godot on PATH). JOBS: parallel tests (default 4).
# BUDGET: stop starting new tests after this many seconds (default: no limit); rerun to continue.
set -u
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
GODOT=${GODOT:-godot}
JOBS=${JOBS:-4}
OUT=${OUT:-$ROOT/builds/test-results.txt}
BASELINE=${BASELINE:-$ROOT/tools/test/baseline.txt}
mkdir -p "$(dirname "$OUT")"; touch "$OUT"
cd "$ROOT"
tests=()
if [ $# -eq 0 ]; then tests=(tests/*.gd); else for p in "$@"; do tests+=(tests/${p}*.gd); done; fi
run_one() {
  local r c f
  local limit; limit=$(grep -m1 -oE '^## timeout: [0-9]+' "$1" | grep -oE '[0-9]+$'); limit=${limit:-75}
  r=$(timeout "$limit" "$GODOT" --headless --path . --script "$1" 2>&1); c=$?
  f=$(echo "$r" | grep -E "^FAIL|SCRIPT ERROR|Parse Error" | head -3 | tr "\n" "|")
  echo "$c $1 $f" >> "$OUT"
}
BUDGET=${BUDGET:-0}
START=$(date +%s)
i=0
for t in "${tests[@]}"; do
  [ -f "$t" ] || continue
  if [ "$BUDGET" -gt 0 ] && [ $(( $(date +%s) - START )) -gt "$BUDGET" ]; then echo "Budget reached; rerun to continue."; break; fi
  grep -q " $t " "$OUT" && continue
  run_one "$t" &
  i=$((i+1)); if (( i % JOBS == 0 )); then wait; fi
done
wait
total=0; for t in "${tests[@]}"; do [ -f "$t" ] && total=$((total+1)); done
echo "Ran $(wc -l < "$OUT") / $total tests; results in $OUT"
[ "$(wc -l < "$OUT")" -lt "$total" ] && exit 3
if [ -f "$BASELINE" ]; then
  new=$(comm -13 <(grep -v "^0 " "$BASELINE" | awk '{print $1,$2}' | sort) <(grep -v "^0 " "$OUT" | awk '{print $1,$2}' | sort))
  if [ -n "$new" ]; then echo "NEW FAILURES compared with $BASELINE:"; echo "$new"; exit 1; fi
  echo "No new failures compared with $BASELINE."
fi
