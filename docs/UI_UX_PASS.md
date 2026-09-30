# UI / UX pass

Approved scope: complete game menus, HUD, casting, upgrade/reward choices, run spellbook, collection, settings, endings, debug/modal interaction, and visual workshop export.

## Direction
Retain the authored pixel keycaps, logo and forest/stone styling. Ink #17231c and moss panel #25382b ground the UI; paper #eee8d8 is readable body text; gold #dfbd76 identifies choices/XP; cyan #79d9e8 communicates casting/focus; coral #ff8175 communicates health/errors. Keycap font for short actions/headings, existing body font for descriptions. The normal HUD shows compact health/XP at upper left, time at upper right, equipped spells below. Debug diagnostics remain opt-in. Do not reintroduce boss countdowns or permanent control instructions.

## Execution and ownership
Root is sole implementation owner in feature/game-ui-ux. Read-only audit and independent review agents inspect without editing. Baseline 7c03c477cc05549d273b0e5ac1396adedbe42b8a. Existing untracked Typecast source art stays user-owned.

## Coverage obligations
| Surface | Journey / expected result |
|---|---|
| Main menu | Keyboard and pointer to Play, Options, Help, Necronomicon; focus restored on return |
| HUD | New run and full six-spell kit; health, XP, time readable; no debug or boss spoilers; small window |
| Casting | Owned long spell, mismatch, unknown spell, backspace, cancel, completion, slowdown expiry; next cast resets |
| Upgrades | Learn/upgrade/synergy/passive; six-slot limits; reroll/lock/banish; queued rewards stay paused |
| Spellbook | This-run spells and extras, passives, scrolling; cast selection and return to pause |
| Necronomicon | Collection vs owned distinction; locked/known recipes; scrolling and Back |
| Pause/options | Nested menus and console preserve pause; escape closes topmost; no input leakage |
| Settings | Current values, edit/reopen/restart persistence, reduced effects, fullscreen/vsync |
| Ending | Death and 20-minute victory; retry and main menu reset lifecycle |
| Workshop | Effect switching, play/pause/replay/step, per-effect size and reset, downloadable export |

Test at 1280x720, 800x600 and narrow 480x640 where supported. Record immediate and settled results, reopen/restart persistence, and subsequent transitions. Preserve screenshots and logs with candidate revision. Mechanical assertions, operated journeys and visual judgment are separate. Missing coverage stays open; known-bad controls must fail. Full game balance, new artwork, audio design and typed menu navigation are outside this pass.

## Task status
- [x] Scope approved and isolated worktree created
- [x] Baseline captures and source audit
- [x] HUD, navigation and settings repairs
- [x] Operated candidate journeys and regression gates
- [ ] Independent review, PR, integration and cleanup

## Confirmed repairs and evidence
The initial audit found unconditional Console unpause, stale console animation callbacks, missing menu focus/Escape paths, inaccurate Options defaults with no audio/display persistence, inaccessible catalog scrolling, and an outdated five-shortcut instruction. Native input journeys exposed full-kit word splitting; operated Web release exposed high-density UI scaling, black-tinted console text, narrow boss/debug overlap, and a cooldown handoff from the spellbook. These were repaired together with sibling transitions.

Evidence lives in the build output under `evidence/ui-ux`. Native `ui_ux_journeys.gd` uses real key events through menu/casting/reward flows, with setup calls explicitly limited to arranging full kits/rewards/endings. Visual judgments use rendered captures separately from containment checks. Browser download event automation timed out, but the actual downloaded JSON file was found and parsed: schema 2, selected Bolt, Ice Blast size 1.2, independent per-effect settings.

Desktop and small-window native coverage includes menus, six-spell HUD, long casting, book navigation and endings. Browser release journeys cover menu navigation, saved volume reopen, instructions, collection End scrolling, unavailable casts, pause/spellbook navigation and workshop controls. Exact final revision/results are recorded in the build verification manifest after integration.

Scope limits: endings and full-kit/reward states are arranged fixtures, not a fresh natural 20-minute run. Native windowed/vsync-off restoration is tested across processes; entering platform fullscreen is not yet operated. This is a focused repaired-candidate gate, not certification of every possible upgrade permutation or platform display mode.

## 2026-09-28 bounded playtest follow-up

This follow-up implements compact active/passive/combination inventory with ranks, short acquisition guidance, queued level-up safety, Space suppression on choices, boss direction, and shared version labels. The player's title is Shoulda Joined a Party; `application/config/name` remains the legacy save-directory identifier. No full keyboard-navigation overhaul is included.

Functional journeys exercise actual `Viewport.push_input` pointer/key events: click a slot-free combination; type Bolt while earning two levels; finish it and consume exactly one reward at a time; press Space without choosing; cancel an incantation to release a pending choice; die with a queued choice; pause and display results. Rendering covers menu, choices, full inventory, off-screen boss, pause and results at desktop 1280×720 and narrow 640×480. Existing UI journeys also cover 480×640. Known-bad hidden-combination and interrupted-casting fixtures verify the relevant state checks reject incorrect states before checking the restored state.

Mechanical/functional evidence: `tests/playtest_ux_regression.gd`, `tests/gameplay_ux_regression.gd`, `tests/minimal_interface_regression.gd`, and `tests/ui_ux_journeys.gd`. Run with a dedicated `SpellCast Survivors Synergy Test` user-data directory. Rendered evidence is generated under ignored `builds/ux-evidence` by running the new regression without `--headless`; headless runs do not claim screenshots. The final revision and counts are recorded with the PR and preserved evidence manifest.

Visual judgment: preserve stone lettering and existing moss/teal/gold palette; distinguish combinations from active slots, use readable rank labels, keep explanatory copy transient, and reserve the main field for gameplay. The Windows-only flicker report remains OPEN: this macOS run cannot establish that it is fixed. This follow-up does not claim a browser or Windows runtime gate; integration verifies the HTML export separately.

## Approved focused HUD feedback pass — 30 September 2026

Baseline e3c7b6b; priorities 3 and 4 of the player-feedback checklist. Preserve the carved-stone rank composition. Keep exact current combo beside its meter, move the quieter banked run score under the health/XP cluster, and use the established paper/cyan/gold/coral palette and existing body/keycap fonts. No rank-progress fraction, tutorial prose or success toast. Inventory remains a reference of learned spell names/levels and existing passives; this is not completion of the broader inventory-readability priority.

- Accepted manual casts briefly illuminate/release the typed incantation; MEGA receives a distinct gold emphasis. Cancellation, rejection and failed/locked casts produce no success animation. New typing clears the prior animation. Reduced effects retains color feedback without extra motion.
- Actual combo gain pulses the stone meter; promotions emphasize the rank glyph. Health damage uses a distinct coral loss response; ordinary decay drains without a damage flash. Existing scoring, repetition, cap, Atomic costs, damage and timing remain unchanged.
- Normal HUD duration state is selective: maintained extendable fields/trails/orbit, infection and regeneration can show remaining activity; traps show armed state and Earth Shield shows charges/next expiry. Bolt, Ice Blast and Lightning stay name-only; Focus Ray, Seeker and Meteor rely on visible world effects, not unnecessary HUD clocks. Timers label activity, never cooldown or recast unavailability.
- Remaining per-cast focus and the incantation remain visible. Diagnostics retain explanatory information behind the existing debug flag.

Verification obligations: baseline/final desktop and narrow fixtures; normal/MEGA/Atomic success versus cancel/rejected casts; repeated awards/cap; gain/promotion/hit versus smooth decay; shield/overheal exclusions; mixed maintained instances and recast extension; reduced-effects behavior; clipping/overlap and next-state clearing. Regression assertions include deliberate broken-policy controls. Operated native casting/resize/modal journeys are a separate root review gate before integration. No balance, new art/audio, archive/tutorial or export work.
