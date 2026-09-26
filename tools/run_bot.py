import argparse
import json
import re
import shutil
import subprocess
import tempfile
import uuid
from pathlib import Path


def validate_report(result):
    outcome = result.get("outcome")
    if outcome not in {"death", "victory", "time_limit", "watchdog"}:
        raise ValueError("Missing or invalid outcome")
    if "SpellCast Survivors Bot/" not in result.get("save_directory", ""):
        raise ValueError("Run did not use an isolated bot profile")
    if outcome == "victory" and (result["survival_seconds"] < 1200 or result["health"] <= 0):
        raise ValueError("Victory contradicts run state")
    if outcome == "death" and result["health"] > 0:
        raise ValueError("Death contradicts remaining health")
    if result.get("runtime_errors"):
        raise ValueError("Godot runtime errors; see report and log")
    if outcome == "watchdog":
        raise ValueError("Bot stalled; see report and log")


def runtime_errors(text):
    plain = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", text)
    return [line for line in plain.splitlines() if re.match(r"^(SCRIPT ERROR|ERROR):", line)]


def main():
    parser = argparse.ArgumentParser(description="Run the ordinary game with an isolated scripted player")
    parser.add_argument("--godot", default=shutil.which("godot") or "/Applications/Godot.app/Contents/MacOS/Godot")
    parser.add_argument("--seeds", type=int, nargs="+", default=[11])
    parser.add_argument("--seconds", type=float, default=1200)
    parser.add_argument("--headless", action="store_true")
    parser.add_argument("--fast", action="store_true", help="Fixed 60 FPS simulation without wall-clock pacing; not identical to realtime")
    parser.add_argument("--output", type=Path, default=Path("builds/bot"))
    args = parser.parse_args()
    if not 0 < args.seconds <= 1200:
        parser.error("--seconds must be between 0 and 1200")
    root = Path(__file__).resolve().parents[1]
    output = args.output.resolve() / uuid.uuid4().hex[:10]
    output.mkdir(parents=True)
    revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip()
    dirty = bool(subprocess.check_output(["git", "status", "--porcelain"], cwd=root, text=True).strip())
    with tempfile.TemporaryDirectory(prefix="spellcast-bot-") as temporary:
        project = Path(temporary) / "project"
        shutil.copytree(root, project, ignore=shutil.ignore_patterns(".git", ".godot", "builds", "exports", "override.cfg", "__pycache__"))
        for seed in args.seeds:
            save_name = f"SpellCast Survivors Bot/{uuid.uuid4().hex}"
            project_text = (root / "project.godot").read_text()
            project_text = project_text.replace("[application]", "[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name=" + json.dumps(save_name))
            (project / "project.godot").write_text(project_text)
            (project / "override.cfg").write_text('[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name=' + json.dumps(save_name) + '\n[display]\nwindow/size/mode=0\nwindow/size/window_width_override=1280\nwindow/size/window_height_override=720\n')
            with (output / f"{seed}-import.log").open("w") as log:
                subprocess.run([args.godot, "--headless", "--path", str(project), "--editor", "--import", "--quit"], stdout=log, stderr=subprocess.STDOUT, check=True, timeout=180)
            import_errors = runtime_errors((output / f"{seed}-import.log").read_text())
            if import_errors:
                raise RuntimeError("Godot import errors: " + "\n".join(import_errors))
            report = output / f"{seed}.json"
            command = [args.godot, "--path", str(project), "--script", "res://tools/bot_player.gd"]
            if args.headless:
                command += ["--headless"]
            if args.fast:
                command += ["--fixed-fps", "60", "--disable-render-loop"]
            command += ["--", f"--seed={seed}", f"--limit={args.seconds}", f"--report={report}"]
            print(f"Running seed {seed}; results: {output}", flush=True)
            with (output / f"{seed}.log").open("w") as log:
                subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=3700)
            result = json.loads(report.read_text())
            errors = runtime_errors((output / f"{seed}.log").read_text())
            result.update(revision=revision, dirty_source=dirty, accelerated=args.fast, fixed_fps=60 if args.fast else None, runtime_errors=errors, command=command)
            report.write_text(json.dumps(result, indent=2) + "\n")
            print(f"Seed {seed}: {result['outcome']} at {result['survival_seconds']:.1f}s, level {result['level']}, {result['successful_casts']} casts", flush=True)
            validate_report(result)


if __name__ == "__main__":
    main()
