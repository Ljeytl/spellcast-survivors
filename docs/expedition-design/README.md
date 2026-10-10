# Should Have Joined a Party — design package

> **Current development slate:** preserve the playable roguelike and style system. Earth Shield 0.1.36 is implemented and merged. Next build a tutorial introducing meaningful, visibly multiplicative keywords, then preparation/tower/ley-line expeditions. Keyword selection and numeric stacking remain proposals. Keep the friend’s art; 2D, 3D and hybrid art direction are a later exploration.

**Version 0.1 · 27 September 2026 · design proposal, not a gameplay patch**

This package evolves the existing playable SpellCast Survivors game toward the working title **Should Have Joined a Party**. The user finds the current game fun; preserve that foundation while adding permanent vocabulary, prepared spells and expeditions. Typing expresses complex magic; typing-game branding and keycap presentation are being retired in favor of readable magical inscriptions. These documents change no runtime behavior.

Latest vocabulary discussion: [spell forms, Golem, additive elements and the Seed lifecycle](14-spell-system-reference.md#14-spell-forms-identities-and-additive-modifiers). These are design clarifications, not implemented keywords.

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
15. [Development order](15-development-order.md): shield, tutorial/keywords and connected expeditions; concrete playable milestones and exit gates.
16. [Element × family matrix](16-element-family-matrix.md): implemented spells, user ideas and explicitly unselected proposals.

17. [Element and spell ideas](17-element-spell-ideas.md): exhaustive latest user concepts, alternatives, rejections and unresolved taxonomy.
18. [Spell system rewrite](18-spell-system-rewrite.md): spells as parts × axes, keywords, effects, statuses and resistance, enemy requirements, every current and approved spell specified, art list, starting numbers and the rewrite plan.

## How to interpret this package

- **Confirmed** means the user explicitly established the principle, not that it is implemented.
- **Baseline** means observed in source at `0cb22e90f4d4a2e8416c1d3e2dfe5c73d1c1ca6c`.
- **Proposed v0.1** means a concrete, internally specified design to discuss and prototype. Every new numeric value is in this category unless explicitly marked baseline.
- **Reserved** means an idea is recorded but excluded from the initial implementation scope.
- **Unresolved decision** means a proposed default is supplied so the design is reviewable; it is not silently promoted to user approval.

All new combat distances are **world units (wu)**; all times are seconds. Reference player collision radius is 12 wu. Presentation uses a proposed 640 × 360 logical viewport: a compact 16:9 reference that scales evenly to 1280 × 720 (2×), 1920 × 1080 (3×) and 2560 × 1440 (4×), making it a useful starting point for crisp pixel-art presentation. It is not a required display resolution or a confirmed constraint; typing readability, UI space and combat visibility still need validation, and may justify a larger logical viewport or independently scaled UI. Asset pixels and world units are not interchangeable. Damage is HP, rates are per simulation second unless stated otherwise. Typing assistance is measured in unpaused real time. Decimal calculations retain precision; labels round for readability.

The proposed initial campaign is **tutorial plus four realms**. The intended roster goal is **36 independent spells, with combinations additional**. The current tables contain only 29 base rows plus seven derived rows (36 total); the independent roster needs reconciliation before implementation. Four ley lines and a 20-minute default recall remain the expedition direction. The reserved catalog records ideas, not a promise to ship every entry.


## Source of truth and review status

This package takes the playable prototype’s core gameplay loop to the next level through extensive expansion, not a departure from or merely a list of changes to the prototype. The prototype remains the foundation; this package develops that foundation into a fuller experience. Existing `docs/CORE_GAME_DESIGN.md` continues to describe the playable prototype, with runtime behavior taking precedence over old documentation. Proposed systems and tuning values here extend that foundation and are not claims about what is already implemented.

Central ownership: root integrates all document edits. Research and inventory agents are read-only. No gameplay code, assets, project settings or exports are changed by this package. Validation is document consistency and research review; the user reports the current game is fun; new composition/progression, accessibility and tuning still require operated evidence.

See [decision register](02-decisions.md#decisions-to-review-first) before implementing. See [delivery gates](11-validation.md) before claiming a build is ready.

## Documentation checks

Run `python3 docs/expedition-design/validate_documentation.py` from the repository root. It checks the current family matrix against the live 16-base roster and explicitly excludes unselected Arcane Seed/Shield examples, plus 36 unique proposed spell rows, 36 compatibility rows, 14 keywords, seven recipes, acquisition-name coverage, local links, JSON examples, table structure and worked arithmetic. One deliberately missing-spell control verifies that the roster gate fails. These are document checks, not gameplay tests. See [review record](13-review-record.md) for the remaining tuning gates.

The [wizard tower and rotary destination chamber](09-ui-accessibility.md#wizard-tower-rotary-destination-chamber) records the physical level selector, preparation book and automatic recall concept.
