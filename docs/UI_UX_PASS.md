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
