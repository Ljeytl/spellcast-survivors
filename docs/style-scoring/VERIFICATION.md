# Style scoring — 0.1.28 verification

Scope: current roguelike scoring, Atomic, rune HUD, result summary and local leaderboard. This is a functional/visual release check, not evidence that the balance is finished.

## Candidate and reproduction

The exact tested Git revision, Godot version and command log are captured in `builds/style-pressure-verification/candidate.txt` and the pull request. Godot 4.4.1 was used. All runs use a separate **SpellCast Survivors Synergy Test** user directory via ignored `override.cfg`; no player leaderboard is used. The integration test preserves/restores its test score files.

```ini
[application]
config/name="SpellCast Survivors Synergy Test"
config/use_custom_user_dir=true
config/custom_user_dir_name="SpellCast Survivors Synergy Test"
[display]
window/size/mode=0
window/size/window_width_override=1280
window/size/window_height_override=720
```

Run scripts using `Godot --headless --path . --script tests/<name>.gd`. Rendered operation uses `Godot --path . --script tests/style_integration_regression.gd -- --screenshots` with the actual renderer and viewport input events. The headless variant emits button actions because there is no desktop window; it is not substituted for rendered UI evidence.

## Mechanical and functional gates

| Suite | Assertions/checks | Coverage |
|---|---:|---|
| style_score_regression | 146 | Formula, speed, typo bonuses, freshness, rotations, duplicate receipts, rank boundaries, cap hit, decay, atomic persistence/backup and malformed metadata |
| style_integration_regression | 52 | Actual key input, release timing, correction, locked spells, passive exclusion, live slowdown/pause, health damage, all rank segments, Atomic gate/cost, save/reload, retry, local board and debug/bot eligibility |
| atomic_blast_regression | 14 | Real ordinary/armored/shieldbearer/boss enemies, boundary exclusion, hostile projectiles, delay, pause, reduced effects and single impact |
| casting_foundations_regression | 91 | Existing spell/slot foundations; stale healing expectation corrected to existing 15 HP behavior |
| ray_contact_regression | 28 | Transformed hurtbox contact, second/further targets, repeated ticks, shared ray reservations, retarget gaps and finite visual-only fade |
| crowd_replenishment_regression | 141 | Actual refill/timer groups, sustained vs single clearing, population cap, tier gates and whole-sprite offscreen entry for all variants |
| encounter_waves_regression | 96 | Existing waves/recycling under new ramp |
| spawn_phase_timer_regression | 8 | Real timer transitions; fixture dynamically loads after autoload initialization |
| pass2_rewards_encounters_regression | 25 | Boss/pickup rewards and encounter boundaries |
| typing_budget_regression | 20 | Per-cast slowdown and lifecycle |
| casting_feedback_regression | 54 | Existing casting feedback |
| minimal_interface_regression | 88 | Existing compact interface behavior |
| full_run_lifecycle_smoke | 1225 | Accelerated 20-minute lifecycle, boss rewards, extraction then finalization, teardown; invulnerable fixture, not balance evidence |

Godot editor import provides script parsing/type checks. `git diff --check` provides whitespace checks; this repository has no separate configured lint/typecheck command.

Known-bad controls deliberately introduce duplicate adapter scoring, decay during pause and passive scoring; the integration suite fails the matching assertions. Atomic's committed `--known-bad-double-impact` option fails its real-boss duplicate-damage assertion. These expected failures are stored separately from passing candidate logs.

## Operated surfaces and visual judgment

| Journey/state | Expected/observed result | Evidence |
|---|---|---|
| Slot and Space casting | One score award after accepted release; submit delay does not inflate speed | Input regression log |
| Typo → correction; invalid spell; cancel | Reduced clean bonus, no rejected/canceled award, original spell behavior retained | Input regression log |
| Real slowed typing → pause → resume | Real-time decay while typing; no clock movement while paused | Live-clock assertions |
| F, S, SSS HUD; nine rank mappings | Separate score, readable plain rank alongside rune, clipped rank-segment fill, no HUD overflow | `game-f.png`, `game-s.png`, `game-sss.png`, rank assertions |
| Narrow gameplay (480×800) | Meter/score fit beside inventory; large scores compact to K/M | `game-narrow.png` |
| Atomic below S / at 9,999 / at 10,000 before Enter | Successful cast spends once; rejected cast keeps text/cost untouched | Gate assertions |
| Atomic warning → impact | Locked visible footprint, warm rune warning and blast; reduced setting retains boundaries | `atomic-warning.png`, `atomic-impact.png`, real-enemy suite |
| Death → settled result → Retry | Score/peak rank visible; no duplicate finalization; fresh live scoring on retry | `result-narrow.png`, retry assertions |
| Result → Menu → High Scores → Back | Saved record reloaded; overlay opens/exits; keyboard Escape works | `menu-desktop.png`, `menu-narrow.png`, `leaderboard-narrow.png` |
| Practice/bot/console-assisted run | Ineligible result cannot enter local board, even after disabling invincibility | Eligibility assertions |

Screenshots use controlled rank fixtures to make the requested states repeatable; they are not organic playtest scores. Result/menu images are captured after transition settling. Relevant new surfaces fit at 1280×720 and 480×800. The rune shapes remain legible through a plain-text rank label, and the finisher's footprint matches its warning. Existing menu/keycap art is retained.

## Open product work

Human playtesting still needs to judge rank cadence, repeated starter Bolt, longer casts, variety incentives, recovery after hits, Atomic cost/boss damage and overall excitement. Online verification, abandoned-run recovery, additional finishers and final audiovisual polish are deferred. This pass does not retest every existing debug command or every platform export.

### Follow-up visual and diagnostic evidence

Native desktop and narrow screenshots show the attached stone rank medallion and framed bar; narrow score/feedback overlap found in review was corrected. `atomic-ready.png` covers 10,000-point readiness; `ray-contact.png` covers the capped beam tip and actual multi-enemy contact. A short native stress fixture began at 160 enemies, exercised simultaneous Focus/two Prism rays and 114 scripted deaths over ten seconds, and reported no runtime errors (585 rendered frames). This is a local smoke check, not a general frame-rate or balance guarantee.

New discriminating controls disable a second enemy collider (its two tick checks fail) and population refill (its targeted spawn checks fail). Legacy magic-variety/evolution suites retain respectively two trail and fourteen old cost-expectation failures, reproduced on untouched baseline 967bbc9 by the ray reviewer. They are not counted as passing gates. Debug console direct deletion can leave stale population counts; it is tracked separately and ordinary combat/Atomic use the correct death path.
