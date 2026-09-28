# Spellcast: expedition design package

**Version 0.1 · 27 September 2026 · design proposal, not a gameplay patch**

This is a separate design for the next iteration of SpellCast Survivors. The playable prototype remains unchanged. The goal is to feel like a wizard learning and preparing an expanding magical vocabulary, then performing increasingly elaborate spells under pressure.

For **what to build next**, start with [Development order](15-development-order.md). For **how spells are constructed**, use [Spell system reference](14-spell-system-reference.md). Milestone lists track development inventory; final acquisition and independent-spell versus family-tier counting remain design decisions.

## Read in this order

1. [Game design](01-game-design.md): the experience, expedition loop and scope.
2. [Decisions and feedback](02-decisions.md): confirmed direction, recommendations requiring judgment, superseded rules and preserved ideas.
3. [Spell catalog](03-spells.md): verified existing roster, proposed complete first-campaign roster and reserved ideas.
4. [Keywords and composition](04-composition.md): syntax, property model, compatibility, formulas and worked examples.
5. [Progression and preparation](05-progression.md): tutorial rewards, ordered loadout, mana, unlocks, death and extraction.
6. [Levels and encounters](06-levels.md): authored graphs, procedural rules, tutorial, four proposed realms, objectives and bosses.
7. [Combat and balance](07-combat-balance.md): enemy numbers, spawn director, casting clocks, targeting, status and sustain.
8. [Art and feedback](08-art-feedback.md): direction alternatives, asset list, impact timelines, VFX and audio language.
9. [UI and accessibility](09-ui-accessibility.md): preparation, casting, journals, menus and workshop.
10. [Engineering specification](10-engineering.md): data contracts, responsibilities, persistence and migration boundaries.
11. [Validation and delivery](11-validation.md): implementation tranches, executable acceptance criteria and playtest worksheet.
12. [Research](12-research.md): primary sources, evidence limits and design applications.
13. [Review record](13-review-record.md): completed design checks, remaining decisions and feasibility risks.
14. [Spell system reference](14-spell-system-reference.md): reusable components, property and keyword tables, spell recipes, and elemental-tier ideas.
15. [Development order](15-development-order.md): concrete playable milestones, beginning with Level 1 and normal slimes; included enemies, spells, keywords, mechanics and exit gates.

## How to interpret this package

- **Confirmed** means the user explicitly established the principle, not that it is implemented.
- **Baseline** means observed in source at `0cb22e90f4d4a2e8416c1d3e2dfe5c73d1c1ca6c`.
- **Proposed v0.1** means a concrete, internally specified design to discuss and prototype. Every new numeric value is in this category unless explicitly marked baseline.
- **Reserved** means an idea is recorded but excluded from the initial implementation scope.
- **Unresolved decision** means a proposed default is supplied so the design is reviewable; it is not silently promoted to user approval.

All new combat distances are **world units (wu)**; all times are seconds. Reference player collision radius is 12 wu. Presentation uses a proposed 640 × 360 logical viewport; asset pixels and world units are not interchangeable. Damage is HP, rates are per simulation second unless stated otherwise. Typing assistance is measured in unpaused real time. Decimal calculations retain precision; labels round for readability.

The proposed initial campaign is **tutorial plus four realms**, with 36 manual spell identities available by its end, including existing bonus spells. That campaign count and its names are design recommendations. Four ley lines per expedition and 20-minute extraction are confirmed direction. The large reserved catalog is an inventory, not a promise to ship every spell.

## Source of truth and review status

The next design lives here; existing `docs/CORE_GAME_DESIGN.md` continues to describe the playable prototype. Runtime behavior wins over old documentation when describing that prototype. New design values in this package intentionally do not match every existing value.

Central ownership: root integrates all document edits. Research and inventory agents are read-only. No gameplay code, assets, project settings or exports are changed by this package. Validation is document consistency and research review; fun, accessibility and tuning remain unproven until the proposed candidate is built and operated.

See [decision register](02-decisions.md#decisions-to-review-first) before implementing. See [delivery gates](11-validation.md) before claiming a build is ready.

## Documentation checks

Run `python3 docs/expedition-design/validate_documentation.py` from the repository root. It checks 36 unique spell rows, 36 compatibility rows, 14 keywords, seven recipes, acquisition-name coverage, local links, JSON examples, table structure and worked arithmetic. One deliberately missing-spell control verifies that the roster gate fails. These are document checks, not gameplay tests. See [review record](13-review-record.md) for the remaining tuning gates.
