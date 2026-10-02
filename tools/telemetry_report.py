#!/usr/bin/env python3
"""Turn CombatTelemetry logs into an HTML page of graphs (DPS over time, kills per minute, enemies, ranks).

Usage: python3 tools/telemetry_report.py <telemetry.json or folder> [...] [-o report.html]
A folder is searched recursively for *-telemetry.json (bot runs) and run-*.json (debug builds).
Each log becomes one line per spell; the label is the bot's focus folder name or the file name.
"""
import json, sys, html
from pathlib import Path

COLORS = ["#2a78d6", "#eb6834", "#1baf7a", "#c98500", "#d55181", "#008300", "#4a3aa7", "#e34948",
          "#5598e7", "#9c6b30", "#7a7a7a", "#0d9fb5", "#b04fc4", "#6b8e23"]

def load(paths):
    runs = []
    for arg in paths:
        p = Path(arg)
        files = [p] if p.is_file() else sorted(list(p.rglob("*-telemetry.json")) + list(p.rglob("run-*.json")))
        for f in files:
            data = json.loads(f.read_text())
            label = f.parent.parent.name if f.name.endswith("-telemetry.json") else f.stem
            runs.append((label, data))
    return runs

def rolling(values, window):
    out, total = [], 0.0
    for i, v in enumerate(values):
        total += v
        if i >= window:
            total -= values[i - window]
        out.append(total / min(i + 1, window))
    return out

def chart(title, series, y_label, width=980, height=360):
    """series: list of (label, color, [(x_minutes, y)])"""
    pad_l, pad_r, pad_t, pad_b = 64, 150, 30, 40
    xs = [x for _, _, pts in series for x, _ in pts] or [0, 1]
    ys = [y for _, _, pts in series for _, y in pts] or [0, 1]
    x_max = max(xs) or 1
    y_max = max(ys) * 1.08 or 1
    sx = lambda x: pad_l + x / x_max * (width - pad_l - pad_r)
    sy = lambda y: height - pad_b - y / y_max * (height - pad_t - pad_b)
    parts = [f'<svg viewBox="0 0 {width} {height}" role="img" aria-label="{html.escape(title)}">']
    for k in range(5):
        v = y_max * k / 4
        parts.append(f'<line x1="{pad_l}" x2="{width - pad_r}" y1="{sy(v):.1f}" y2="{sy(v):.1f}" class="grid"/>')
        parts.append(f'<text x="{pad_l - 8}" y="{sy(v) + 4:.1f}" text-anchor="end" class="tick">{v:,.0f}</text>')
    for m in range(0, int(x_max) + 1, max(1, int(x_max) // 10 or 1)):
        parts.append(f'<text x="{sx(m):.1f}" y="{height - pad_b + 18}" text-anchor="middle" class="tick">{m}m</text>')
    parts.append(f'<text x="{pad_l}" y="18" class="axis">{html.escape(y_label)}</text>')
    labels = []
    for label, color, pts in series:
        if not pts:
            continue
        d = " ".join(f"{sx(x):.1f},{sy(y):.1f}" for x, y in pts)
        parts.append(f'<polyline points="{d}" fill="none" stroke="{color}" stroke-width="2" stroke-linejoin="round"><title>{html.escape(label)}</title></polyline>')
        labels.append((sy(pts[-1][1]), label, color, pts[-1][1]))
    labels.sort()
    last = -99
    for y, label, color, value in labels:
        y = max(y, last + 14)
        last = y
        parts.append(f'<text x="{width - pad_r + 8}" y="{y + 4:.1f}" class="lbl" fill="{color}">{html.escape(label)} · {value:,.0f}</text>')
    parts.append("</svg>")
    return f"<section><h2>{html.escape(title)}</h2>{''.join(parts)}</section>"

def main():
    args = [a for a in sys.argv[1:] if a != "-o"]
    out = Path(sys.argv[sys.argv.index("-o") + 1]) if "-o" in sys.argv else None
    if out:
        args.remove(str(out))
    runs = load(args or ["builds/balance"])
    if not runs:
        sys.exit("No telemetry logs found")
    names = {}
    catalog = Path("data/spells.json")
    if catalog.exists():
        names = {k: v.get("name", k) for k, v in json.loads(catalog.read_text()).get("spells", {}).items()}
    names["mana_bolt"] = "Magic Missile"
    dps, cumulative, kills, enemies, ranks = [], [], [], [], []
    xp_series, ttk_series, flow_series = [], [], []
    color_i = 0
    for label, data in runs:
        samples = data.get("samples", [])
        spells = sorted({s for smp in samples for s in smp.get("damage", {})})
        for spell in spells:
            color = COLORS[color_i % len(COLORS)]; color_i += 1
            name = names.get(spell, spell) if len(runs) == 1 or label == spell else f"{names.get(spell, spell)} ({label})"
            per_second = [float(s.get("damage", {}).get(spell, 0.0)) for s in samples]
            times = [s["t"] / 60 for s in samples]
            dps.append((name, color, list(zip(times, rolling(per_second, 30)))))
            running, cum = 0.0, []
            for t, v in zip(times, per_second):
                running += v; cum.append((t, running))
            cumulative.append((name, color, cum))
            per_min = {}
            for s in samples:
                m = int(s["t"] // 60) + 1
                per_min[m] = per_min.get(m, 0) + int(s.get("kills", {}).get(spell, 0))
            kills.append((name, color, sorted(per_min.items())))
            ranks.append((name, color, [(s["t"] / 60, s.get("ranks", {}).get(spell, 0)) for s in samples if spell in s.get("ranks", {})]))
        enemies.append((f"{label} enemies", COLORS[len(enemies) % len(COLORS)], [(s["t"] / 60, s.get("enemies", 0)) for s in samples]))
        color = COLORS[len(enemies) % len(COLORS)]
        by_minute = {}
        for s in samples:
            m = int(s["t"] // 60) + 1
            b = by_minute.setdefault(m, {"xp": 0.0, "spawned": 0, "killed": 0, "ttk_total": 0.0, "ttk_count": 0})
            b["xp"] += float(s.get("xp", 0.0))
            b["spawned"] += int(s.get("spawned", 0))
            for entry in s.get("time_to_kill", {}).values():
                b["killed"] += int(entry["count"]); b["ttk_total"] += float(entry["avg"]) * int(entry["count"]); b["ttk_count"] += int(entry["count"])
        xp_series.append((label, color, [(m, b["xp"]) for m, b in sorted(by_minute.items())]))
        ttk_series.append((label, color, [(m, b["ttk_total"] / b["ttk_count"]) for m, b in sorted(by_minute.items()) if b["ttk_count"]]))
        flow_series.append((f"{label} spawned", color, [(m, b["spawned"]) for m, b in sorted(by_minute.items())]))
        flow_series.append((f"{label} killed", COLORS[(len(enemies) + 6) % len(COLORS)], [(m, b["killed"]) for m, b in sorted(by_minute.items())]))
    hp = [(s["t"] / 60, s.get("health_multiplier", 1.0)) for s in runs[0][1].get("samples", [])]
    body = "".join([
        chart("Damage per second (30 s rolling average)", dps, "damage / second"),
        chart("Total damage over the run", cumulative, "damage"),
        chart("Kills per minute", kills, "kills"),
        chart("Spell rank over time", ranks, "rank"),
        chart("Average time to kill per minute (seconds an enemy lived)", ttk_series, "seconds"),
        chart("XP gained per minute", xp_series, "XP"),
        chart("Enemies spawned vs killed per minute", flow_series, "enemies"),
        chart("Enemies alive", enemies, "enemies"),
        chart("Enemy HP multiplier", [("HP ×", "#7a7a7a", hp)], "× base HP"),
    ])
    page = f"""<!doctype html><meta charset="utf-8"><title>Combat Telemetry</title>
<style>
:root{{--bg:#f7f7fb;--ink:#15141f;--muted:#6b6980;--rule:#e3e2ec}}
@media (prefers-color-scheme:dark){{:root{{--bg:#121119;--ink:#f2f1f8;--muted:#9a98b0;--rule:#2e2d3b}}}}
body{{background:var(--bg);color:var(--ink);font:14px system-ui,sans-serif;max-width:1040px;margin:0 auto;padding:24px 16px}}
h1{{font-size:22px}} h2{{font-size:16px;margin:28px 0 6px}} svg{{width:100%;height:auto}}
.grid{{stroke:var(--rule)}} .tick,.axis{{fill:var(--muted);font-size:11px}} .lbl{{font-size:11px}}
</style><h1>Combat telemetry</h1><p>{len(runs)} run(s): {html.escape(", ".join(l for l, _ in runs))}</p>{body}"""
    out = out or (Path(args[0]) if args and Path(args[0]).is_dir() else Path(".")) / "telemetry.html"
    out.write_text(page)
    print(f"Wrote {out}")

if __name__ == "__main__":
    main()
