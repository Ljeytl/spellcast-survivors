# Spellbook and Necronomicon

The pause Spellbook contains only the current run's learned active and bonus spells, with exact typing phrases, short descriptions and ranks. Persistent discoveries belong in the main-menu Necronomicon. Passives remain visible in the run book.

The Necronomicon lists the runtime base-spell IDs, automatic Mana Bolt and enabled synergy recipes. Disabled Reaping Spirit is omitted. All implemented recipes are readable immediately; discovered status reflects the existing persistent record. Opening or closing the catalog does not teach a spell or mark a discovery. Its static themed geometry previews are illustrative icons, not combat simulations.

Validation uses `override.cfg` with application name `SpellCast Survivors Synergy Test`; the fixture refuses the user's normal profile. Run Godot with `--path . --script tests/necronomicon_regression.gd` for native desktop/narrow captures under ignored `builds/book-evidence/`, or add `--headless` for behavioral checks. The fixture visits the real main-menu route, scrolls through the last recipe, returns to the menu, learns a bonus, opens the run book and starts another run. Existing `run_spellbook_regression.gd` checks casting selection and full slot capacity. `menu_key_font_regression.gd` checks menu typography and bounds.

No damage, capacity, acquisition, save schema or balance changes are included.
