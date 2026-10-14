#!/bin/bash
# Web export of the game into builds/<version>-web (version from project.godot).
# GODOT: path to a Godot 4.4 binary with the Web export templates installed (default: godot on PATH).
set -eu
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
GODOT=${GODOT:-godot}
VERSION=$(sed -n 's/^config\/version="\(.*\)"/\1/p' "$ROOT/project.godot")
OUT="$ROOT/builds/$VERSION-web"
mkdir -p "$OUT"
cd "$ROOT"
"$GODOT" --headless --editor --import --path . > "$ROOT/builds/web-import.log" 2>&1 || true
"$GODOT" --headless --path . --export-release Web "$OUT/index.html" > "$ROOT/builds/web-export.log" 2>&1
if grep -q "SCRIPT ERROR\|Parse Error" "$ROOT/builds/web-import.log" "$ROOT/builds/web-export.log"; then
  echo "Script errors during export; see builds/web-*.log"; exit 1
fi
echo "Web build: $OUT/index.html (serve the folder over http to play)"
