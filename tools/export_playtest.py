import argparse
import hashlib
import json
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GODOT = "/Applications/Godot.app/Contents/MacOS/Godot"


def run(command, log):
    with log.open("w") as stream:
        subprocess.run(command, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT, check=True)
    output = log.read_text()
    if "SCRIPT ERROR" in output or "ERROR:" in output:
        raise RuntimeError(f"Build reported errors; inspect {log}")


def clean_source():
    state = subprocess.check_output(["git", "status", "--porcelain", "--untracked-files=all"], cwd=ROOT, text=True)
    if state.strip():
        raise RuntimeError("Export requires a clean dedicated checkout; commit source changes first.")


def build(godot):
    clean_source()
    revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    output = ROOT / "builds" / ("playtest-" + revision[:7] + "-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ"))
    output.mkdir(parents=True, exist_ok=False)
    logs = output / "logs"
    logs.mkdir()
    run([godot, "--headless", "--path", str(ROOT), "--editor", "--import"], logs / "import.log")
    windows = output / "windows" / "SpellCast Survivors"
    windows.mkdir(parents=True)
    run([godot, "--headless", "--path", str(ROOT), "--export-release", "Windows Desktop", str(windows / "SpellCast Survivors.exe")], logs / "windows.log")
    mac_zip = output / "mac-app.zip"
    run([godot, "--headless", "--path", str(ROOT), "--export-release", "macOS", str(mac_zip)], logs / "mac.log")
    mac = output / "mac"
    mac.mkdir()
    subprocess.run(["ditto", "-x", "-k", str(mac_zip), str(mac)], check=True)
    apps = list(mac.glob("*.app"))
    if len(apps) != 1:
        raise RuntimeError("Expected exactly one Mac application")
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(apps[0])], check=True)
    readme = f"""SPELLCAST SURVIVORS / TYPECAST — PLAYTEST
Build: {revision[:7]}

Windows: Extract the entire ZIP, then open SpellCast Survivors.exe.
Keep the EXE and PCK game-data file together. Godot is not required.

Mac: Open the DMG, drag the app to Applications, then launch it.
This private playtest is not Apple-notarized or publisher-signed for Windows.
Your system may show an unidentified-developer warning.

CONTROLS
WASD or arrow keys: move.
1–6 or click a learned spell: select it and type its name to cast.
Space: type any spell learned in this run; Enter confirms.
Escape: cancel typing or pause. The spellbook is in the pause menu.
Magic Missile fires automatically. Your starting typed spell is Bolt.
Choose upgrades at level-up. Survive to 20:00 to win.

Please send feedback with the build ID, your OS, what happened, and a
screenshot/video if possible. Saves and settings stay on your own computer.
"""
    for folder in [windows, mac]:
        (folder / "README.txt").write_text(readme)
        shutil.copy2(ROOT / "audio/tactile/CREDITS.md", folder / "SOUND-CREDITS.txt")
    (mac / "Applications").symlink_to("/Applications", target_is_directory=True)
    win_zip = Path(shutil.make_archive(str(output / "SpellCast-Survivors-Windows"), "zip", windows.parent))
    dmg = output / "SpellCast-Survivors-Mac.dmg"
    run(["hdiutil", "create", "-volname", "SpellCast Playtest", "-srcfolder", str(mac), "-ov", "-format", "UDZO", str(dmg)], logs / "dmg.log")
    clean_source()
    if subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip() != revision:
        raise RuntimeError("Source revision changed during export")
    files = [{"name": p.name, "bytes": p.stat().st_size, "sha256": hashlib.sha256(p.read_bytes()).hexdigest()} for p in [win_zip, dmg]]
    manifest = {"source_revision": revision, "artifacts": files, "windows": "x86_64; exported, requires Windows launch verification", "mac": "universal Intel/Apple Silicon; ad-hoc signed, not notarized", "runtime_verification": "pending"}
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2))
    print(output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default=GODOT)
    build(parser.parse_args().godot)
