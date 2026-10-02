#!/usr/bin/env python3
"""Summarize focused bot reports: damage, casts and damage per cast for each spell, averaged over seeds.

Usage: python3 tools/summarize_bot.py <folder with bot reports>  (searches recursively for <seed>.json)
"""
import json, sys, statistics
from pathlib import Path
from collections import defaultdict

root = Path(sys.argv[1] if len(sys.argv) > 1 else "builds/balance")
runs = [json.loads(p.read_text()) for p in sorted(root.rglob("*.json")) if p.stem.isdigit()]
if not runs:
    sys.exit(f"No bot reports under {root}")
catalog = json.loads(Path("data/spells.json").read_text()).get("spells", {})
names = {sid: info.get("name", sid) for sid, info in catalog.items()}
rows = defaultdict(lambda: defaultdict(list))  # (build, spell) -> metric lists
builds = defaultdict(list)
for run in runs:
    build = "+".join(run.get("focus_spells", [])) or "random"
    builds[build].append(run)
    casts = run.get("casts_by_spell", {})
    for spell, damage in run.get("damage_by_spell", {}).items():
        n = casts.get(names.get(spell, spell), 0)
        r = rows[(build, spell)]
        r["damage"].append(damage); r["casts"].append(n)
        r["rank"].append(run.get("focus_ranks", {}).get(spell, ""))
        if n:
            r["per_cast"].append(damage / n)
avg = lambda xs: statistics.mean(xs) if xs else 0
print(f"# Bot balance summary — {root}\n")
for build, group in builds.items():
    minutes = avg([g["survival_seconds"] for g in group]) / 60
    print(f"## {build}  ({len(group)} seed(s), {minutes:.1f} min, level {avg([g['level'] for g in group]):.0f}, kills {avg([g['kills'] for g in group]):.0f}, outcomes {sorted({g['outcome'] for g in group})})\n")
    print("| Spell | Rank | Damage | Casts | Damage per cast |\n|---|---|---|---|---|")
    spells = sorted({s for (b, s) in rows if b == build}, key=lambda s: -avg(rows[(build, s)]["damage"]))
    for s in spells:
        r = rows[(build, s)]
        ranks = [x for x in r["rank"] if x != ""]
        print(f"| {names.get(s, s)} | {avg(ranks):.1f} | {avg(r['damage']):,.0f} | {avg(r['casts']):.0f} | {avg(r['per_cast']):,.0f} |" if r["per_cast"] else f"| {names.get(s, s)} | {avg(ranks) if ranks else '-'} | {avg(r['damage']):,.0f} | - | - |")
    print()

# Damage per minute: each checkpoint holds cumulative damage_by_spell; differences give damage dealt in that minute.
per_minute = defaultdict(lambda: defaultdict(list))  # (build, spell) -> minute -> [damage]
for run in runs:
    build = "+".join(run.get("focus_spells", [])) or "random"
    previous = {}
    for checkpoint in run.get("checkpoints", []):
        minute = round(checkpoint["seconds"] / 60)
        totals = checkpoint.get("damage_by_spell", {})
        for spell, total in totals.items():
            per_minute[(build, spell)][minute].append(total - previous.get(spell, 0.0))
        previous = totals
    final_minute = round(run.get("survival_seconds", 0) / 60)
    if previous and final_minute not in {round(c["seconds"] / 60) for c in run.get("checkpoints", [])}:
        for spell, total in run.get("damage_by_spell", {}).items():
            per_minute[(build, spell)][final_minute].append(total - previous.get(spell, 0.0))
if per_minute:
    print("## Damage per minute (average across seeds)\n")
    minutes = sorted({m for series in per_minute.values() for m in series})
    print("| Build | Spell | " + " | ".join(f"m{m}" for m in minutes) + " |")
    print("|---|---|" + "---|" * len(minutes))
    csv = ["build,spell," + ",".join(f"m{m}" for m in minutes)]
    for (build, spell), series in sorted(per_minute.items()):
        values = [avg(series.get(m, [])) for m in minutes]
        print(f"| {build} | {names.get(spell, spell)} | " + " | ".join(f"{v:,.0f}" for v in values) + " |")
        csv.append(f"{build},{spell}," + ",".join(f"{v:.0f}" for v in values))
    (root / "damage_per_minute.csv").write_text("\n".join(csv) + "\n")
    print(f"\nCSV: {root / 'damage_per_minute.csv'}")
