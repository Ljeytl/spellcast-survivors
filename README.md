# Shoulda Joined a Party

**Version 0.3.0** · [changelog](Changelog.md) · [design and roadmap](docs/expedition-design/README.md)

A wizard horde-survivor where you cast by typing. Spells are words; keywords change them: `fiery double bolt`, `mega meteor shower`, `homing toxic ember spear`. Built in Godot 4.4 (GDScript). Working title formerly SpellCast Survivors.

## Play

- **Move:** WASD.
- **Cast:** press **Space** (or a slot number 1–6), type a spell you have prepared, press **Enter** (a complete name casts on its own). Typing slows time from a shared budget that refills while you are not typing.
- **Keywords:** say them before the spell name, in any order. Every keyword is listed in the **Necronomicon** with what it does. A word that can't change that spell cracks and the spell casts without it.
- **Before a run:** in the tower, walk into the Woodland doorway to prepare up to six spells in order. Slot 1 is ready at once; the others open at levels 2, 4, 7, 11 and 16. Magic Missile fires on its own.
- **Elements and statuses:** hits split into raw and elemental damage against an element cycle and resistances; burn, bleed, poison, chill/freeze and shock (a mark that lightning chains, water conducts and earth grounds).
- **Esc:** cancel typing, or pause. **Backtick (`)**: developer console (`help`).

## Builds

- **Web (itch.io):** `python3 tools/export_web.py`, then `python3 tools/serve_previews.py --directory builds/web-<timestamp>/web --port 8765` and open `http://127.0.0.1:8765/`. The export writes a ZIP with `index.html` at its root for an itch HTML project (Embed options → click to launch in fullscreen). Desktop keyboard game; check typing, audio and saved settings in the browser before sharing.
- **Windows and macOS:** `python3 tools/export_playtest.py` (needs Godot 4.4 with export templates).
- Exports require a clean checkout and no `override.cfg`. Exported files go to `builds/` and are not committed.

## Develop

- **Data is the source of truth:** spells, keywords, statuses, resistances, recipes, encounters live in `data/*.json`, each validated against `data/schemas/` at load (debug builds) and in tests. See `tools/data-schemas/README.md`.
- **Architecture:** [engine (doc 19)](docs/expedition-design/19-engine-architecture.md) and [game systems (doc 20)](docs/expedition-design/20-game-systems-architecture.md).
- **Tests:** `GODOT=/path/to/godot tools/test/run_tests.sh` runs the headless suite and reports failures not in `tools/test/baseline.txt` (see `tools/test/README.md`). Tests need an isolated profile: an ignored `override.cfg` with `[application]`, `config/use_custom_user_dir=true`, `config/custom_user_dir_name="SpellCast Survivors Synergy Test"` (remove it before exporting).
- **VFX:** `docs/VFX_EVENTS.md`; the in-game showcase `tools/vfx-showcase/Showcase.tscn` (`?spell=<id>&words=fiery+double&mega=1&slow=0.3` in the web build) and the test arena `tools/vfx-arena`.
- **Console:** `speed 2`, `damage 1.5`, `add_xp 10`, `heal`, `invincibility on`, `spawn_enemy pursuer 5`, `kill_all`, `difficulty 5`, `day`, `vfx cast <text>`. Modifying commands exclude the run from local scores. Full list: [CONSOLE_COMMANDS.md](CONSOLE_COMMANDS.md).
- **Performance:** Options → Graphics → Show FPS; profiling notes in [travel performance](docs/travel-performance.md).
- Older prototype notes are in `docs/archive/`; the per-version history before 0.3 is in [PATCH_NOTES.md](PATCH_NOTES.md) and the changelog.
