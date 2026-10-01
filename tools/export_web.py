import argparse
import hashlib
import json
import html
import re
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
from export_playtest import BENIGN

ALLOW_DIRTY = False


def version_label():
    project = (ROOT / "project.godot").read_text()
    found = re.search(r'^config/version="(.*)"$', project, re.MULTILINE)
    version = found.group(1) if found else "0.0.0"
    dirty = bool(subprocess.check_output(["git", "status", "--porcelain"], cwd=ROOT, text=True).strip())
    return version + ("-dirty" if dirty else ""), dirty


def require_clean_source():
    if (ROOT / "override.cfg").exists():
        raise RuntimeError("Remove local test overrides before exporting a player build.")
    if ALLOW_DIRTY:
        return
    state = subprocess.check_output(
        ["git", "status", "--porcelain", "--untracked-files=all"], cwd=ROOT, text=True
    )
    if state.strip():
        raise RuntimeError("Commit source changes before exporting a versioned web build.")


def export_web(godot, output):
    require_clean_source()
    revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    label, dirty = version_label()
    output = (output or ROOT / "builds" / ("web-" + label + "-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S"))).resolve()
    output.mkdir(parents=True, exist_ok=False)
    web = output / "web"
    web.mkdir()
    for name, args in [
        ("import", ["--editor", "--import"]),
        ("web", ["--export-release", "Web", str(web / "index.html")]),
    ]:
        log = output / f"{name}.log"
        with log.open("w") as stream:
            subprocess.run(
                [godot, "--headless", "--path", str(ROOT), *args],
                cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT, check=True, timeout=300,
            )
        errors = [line for line in log.read_text().splitlines() if "SCRIPT ERROR" in line or ("ERROR:" in line and not any(p.search(line) for p in BENIGN))]
        if errors:
            raise RuntimeError(f"Export errors in {log}: " + "\n".join(errors))
    for name in ["index.html", "index.js", "index.wasm", "index.pck"]:
        if not (web / name).is_file() or (web / name).stat().st_size == 0:
            raise RuntimeError(f"Missing web artifact: {name}")
    project = (ROOT / "project.godot").read_text()
    title = re.search(r'^config/display_name="(.*)"$', project, re.MULTILINE)
    if title:
        page = web / "index.html"
        page.write_text(re.sub(r"<title>.*?</title>", lambda _: "<title>" + html.escape(title.group(1)) + "</title>", page.read_text(), count=1))
    shutil.copy2(ROOT / "audio/tactile/CREDITS.md", web / "SOUND-CREDITS.txt")
    artifact = Path(shutil.make_archive(str(output / ("SpellCast-Survivors-" + label + "-Web")), "zip", web))
    require_clean_source()
    current = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    if current != revision:
        raise RuntimeError("Source revision changed during export")
    manifest = {
        "source_revision": revision,
        "version": label,
        "uncommitted_changes": dirty,
        "built_at": datetime.now(timezone.utc).isoformat(),
        "engine": subprocess.check_output([godot, "--version"], text=True).strip(),
        "artifact": artifact.name,
        "sha256": hashlib.sha256(artifact.read_bytes()).hexdigest(),
        "runtime_verification": "pending; export success does not establish browser gameplay",
    }
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Build the current committed game for browser playtesting.")
    parser.add_argument("--godot", default=shutil.which("godot") or "/Applications/Godot.app/Contents/MacOS/Godot")
    parser.add_argument("--output", type=Path, default=None)
    parser.add_argument("--allow-dirty", action="store_true", help="Build with uncommitted changes; the build is labelled <version>-dirty")
    args = parser.parse_args()
    ALLOW_DIRTY = args.allow_dirty
    export_web(args.godot, args.output)
