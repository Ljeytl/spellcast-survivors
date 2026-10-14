#!/bin/bash
# Runs the headless test suite, 4 at a time, and compares failures with a baseline.
#
#   tools/test/run_tests.sh                    every test, results in builds/test-results.txt
#   tools/test/run_tests.sh spell_ engine_     only tests whose names start with these
#   OUT=my.txt BASELINE=tools/test/baseline.txt tools/test/run_tests.sh
#
# Resumable: tests already listed in OUT are skipped, so a stopped run continues where it was.
# Each line of OUT is "<exit code> <test> <first FAIL / SCRIPT ERROR lines>".
# Exit codes: 0 pass, 1 checks failed, 2 needs a display/audio (visual tests), 124 timed out (visual tests headless).
# GODOT: path to a Godot 4.4 binary (default: godot on PATH). JOBS: parallel tests (default 4).
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
  r=$(timeout 75 "$GODOT" --headless --path . --script "$1" 2>&1); c=$?
  f=$(echo "$r" | grep -E "^FAIL|SCRIPT ERROR|Parse Error" | head -3 | tr "\n" "|")
  echo "$c $1 $f" >> "$OUT"
}
i=0
for t in "${tests[@]}"; do
  [ -f "$t" ] || continue
  grep -q " $t " "$OUT" && continue
  run_one "$t" &
  i=$((i+1)); if (( i % JOBS == 0 )); then wait; fi
done
wait
echo "Ran $(wc -l < "$OUT") tests; results in $OUT"
if [ -f "$BASELINE" ]; then
  new=$(comm -13 <(grep -v "^0 " "$BASELINE" | awk '{print $1,$2}' | sort) <(grep -v "^0 " "$OUT" | awk '{print $1,$2}' | sort))
  if [ -n "$new" ]; then echo "NEW FAILURES compared with $BASELINE:"; echo "$new"; exit 1; fi
  echo "No new failures compared with $BASELINE."
fi
