# Validation, delivery plan and playtest evidence

## Status of this package

This package specifies a design. It does not prove its game feel, difficulty, accessibility or performance. Document checks cover roster/reward consistency, formulas, references and conflicting rules. Gameplay gates below are **future requirements**, not passed tests.

For the updated concrete build contents and normal-slime Level 1, use [Development order](15-development-order.md). The older tranche table below describes engineering responsibilities; its earlier slice-size proposal is superseded by that page for development scope. Its validation obligations still apply.

## Implementation tranches

Each independently releasable tranche gets a dedicated branch/worktree, reviewed PR, exact-revision checks and cleanup after merge. Parallel agents may investigate or own separate isolated tranches; they must not edit the same worktree. Integrate dependent changes in order. Keep a playable comparison build at each stage.

| Stage | Deliverable / ownership | Exit gate |
|---|---|---|
|0: Design review|Root integrates decisions; user judges D01–D14; read-only agents challenge combat/content/presentation|No unresolved implementation-blocking rule silently assumed; roster and grammar frozen for slice|
|1: Spell foundation|Systems engineer: parser, capabilities, compiler, clocks, scheduler; independent reviewer reads contracts|Property/order/cap/lifecycle tests; no invisible damage; legacy build intact|
|2: Representative effects|Combat engineer adapts 17 slice spells; art owner works in separate dependent branch after geometry contract lands|All 17 previews/game contacts match; Big/Repeat/Charge cases operated|
|3: Knowledge and preparation|Progression/UI owner: ordered pages, recipes, saves, menu journeys|Unlock/activation/death/crash tests and keyboard/narrow-layout review|
|4: Tutorial and one realm|Level owner: graph, generator, objectives, director, guardian, extraction|Seed gates, all tutorial steps, 20-minute terminal paths, meaningful cast openings|
|5: Feedback and feel|Presentation owner: coherent placeholder art board, impact/audio hooks, workshop exports|Real-scale art approval; reduced effects retains mechanics; performance stress pass|
|6: External playtest|Test coordinator observes fresh players; no coaching except blockers|Evidence sheet below; decide iterate/pivot/expand|
|7: Content expansion|Separate realm/content tranches after shared contracts are stable|Remaining 19 spells and three realms meet same gates, not a bulk unchecked drop|
|8: Release preparation|Packaging/save compatibility/accessibility/art provenance/signing where applicable|Operated target-platform packages and complete concerns ledger|

Suggested agent roles when implementation is approved: architecture reviewer for compiler/data boundaries; gameplay worker for effects; level-design/research worker for generator/content; UI worker for preparation/journals; test specialist for deterministic scenarios and operated workflows. Root owns integration and decision register. Use at most three active specialist agents alongside root; technical tasks wait on explicit contracts rather than racing shared files.

## Required automated or deterministic checks

| ID | Journey / invariant | Expected evidence | Known-bad control |
|---|---|---|---|
|T01|Unknown/unprepared/inactive spell submit|No output; text retained; correct reason|Bypassing unlock validation must fail|
|T02|Longest suffix and Fire Bolt/Fiery Bolt|Distinct spell IDs and effects; keyword order does not change mechanics|A shortest-suffix parser must fail|
|T03|Powerful + Delayed + Charged math|Additive base bonuses capped at 3.0; exact examples match|Multiplicative bonuses must fail|
|T04|Duplicating + Repeating|Bounded counts and potency; child generation at most one|Recursive child compilation must fail|
|T05|Big geometry|Core and collision change together; beam/fan mappings correct; Big rejects healing without area|Visual-only scaling must fail|
|T06|Ice Blast contact|No hit before arrival; untouched targets safe; one hit per target/generation|Cone-query damage must fail|
|T07|Dead target/release reservation|New outputs select valid targets; straight bodies do not home; guided expiry unchanged|Resetting lifetime on reacquisition must fail|
|T08|Plague host death|Orphan visible for 3 seconds and can infect; six-host and 18-second root caps|Deleting infection on host death must fail|
|T09|Heal filters and caps|Steam does not heal; seed consumed once; Regeneration does not stack; healing caps enforced|An all-entities recipient mask must fail|
|T10|Assist cancel/backspace/pause|Finite assist; empty toggles do not refill; pause preserves state; hit-stop does not extend assist|Resetting assist on text clearing must fail|
|T11|Prepared order/mana/recipes|Exact thresholds; both recipe ingredients active; originals remain|A bonus replacing a prepared slot must fail|
|T12|Discovery/save interruption|Atomic grant once; death retains knowledge; backup recovers; legacy untouched|Crash between event recording and save must not duplicate rewards|
|T13|Generation|Four objectives reachable; independent routes and widths validated; seed reproducible|A blocker that disconnects an objective must fail|
|T14|Director|Ranged gates, caps and encounter suppression work; no banked-budget burst|Ambient peak during guardian must fail|
|T15|Terminal race|Extraction at 20:00; no post-terminal damage; death tie and one-time reward policy|A queued hit after extraction must fail|
|T16|Crystals|Exact merged value; reachable location; one pickup grant|Rounding or dropping merged value must fail|
|T17|Workshop|Same compiler/runtime; every implemented spell previews and exports|Separate preview with different collision must fail|
|T18|Reduced effects|Hazard boundaries and player/contact meaning preserved; zero shake works|Quality settings hiding an active boundary must fail|

Record nonzero collected/asserted counts, exact revision, content version, seed and command. A green exit code with no collected tests is not a pass. Each known-bad control must fail for the named invariant, then be removed/restored before final candidate checks. Do not add huge implementation-mirroring tests for every cosmetic constant; focus on boundaries above.

## Operated UX gate

Inventory every route/state in the UI chapter. Operate the exact candidate at desktop and narrow geometry, 100% and 150% text, keyboard-only and ordinary pointer use. For material actions inspect immediate result, settled result, refresh/reopen when persistent and next transition. Capture source SHA, start command, screenshots/video, console/runtime errors and concern-by-concern disposition.

Mandatory journeys: fresh profile → tutorial → prepare → enter; reorder pages → mana activation → derived spell; typo → cancel → reopen → correct cast; charge cancellation → normal cast; ley failure → retry → discovery → death → knowledge present; four ley lines → guardian → chest → extract; late boss → 20:00 extract; settings → restart → settings retained; workshop select Ice Blast → play → size change → export → open actual export. Test all primary controls, not one screenshot per page.

Missing routes, unavailable runtime, untested save boundaries or skipped named user concerns are **incomplete/blocked**, never PASS. Separate functional results, layout/accessibility checks and independent design judgment. A good-looking GIF cannot prove targeting, saved settings or a full expedition.

## Fresh-player observation sheet

Target first cohort 6–8 players with varied typing familiarity, then repeat after changes. This sample gives directional evidence, not statistical proof. Record assistance settings and prior horde/action game experience; do not shame slower typists or teach optimal combos during observation.

| Question | Observe | Initial success signal | Failure to investigate |
|---|---|---|---|
|Do they understand choices?|After tutorial, ask what Big/Repeating will do to a new spell|Most predict shape and timing without memorizing exact statistics|Words treated as opaque names|
|Do they make openings?|Count intentional control or movement before long casts|At least two deliberate openings in first realm|Long casts only spammed or never attempted|
|Does payoff justify effort?|Ask after major casts; record hit count and survival|Player names the benefit and uses it appropriately again|Nothing happened, offscreen impact or complete overkill|
|Do basics remain useful?|Track short casts after full activation|Player chooses short casts under pressure|Always longest safe phrase, or new spells never help|
|Is preparation meaningful?|Ask why that order; compare second run|Player changes order or role for a reason|Random ordering without observable effect|
|Do discoveries motivate replay?|Observe next-run choice and ask a follow-up question|Voluntary preparation or specific build idea|Continues only because observer asks|
|Can they read danger?|Replay deaths and ask what caused them|Explanation agrees with recorded events|Invisible hitboxes, clutter or missing warnings|

Session: 10-minute tutorial, 15–20-minute realm, five-minute reflection and optional second run. Ask “What were you trying to do?” rather than “Did the spell feel powerful?” Distinguish usability failure, numerical tuning and fundamental loop failure. One clip, enthusiastic friend or bot result is not market validation.

## Metrics and experiment plan

Log cast-text length, spell and keyword IDs, typing duration, correction count, assist used, commit/cancel events, contacts, actual damage/healing, overkill, rooted time, cause of death, objective arrival/completion, mana thresholds, living enemy counts and FPS. Do not log arbitrary input outside the game. Use local opt-in exports until a data policy is deliberately designed.

Run A/B experiments one change at a time: 1.25 versus 2 seconds of assist; six versus four pages; manual casting versus weak automatic assistance; immediate versus extraction-only knowledge banking if the user chooses to explore it; Big at 1.25 versus 1.35. Record hypothesis, outcome and stopping rule before testing. Do not conclude “make everything harder” from one strong late-run build.

Bots: idle without casting; movement only; simple Bolt; random compatible casts; deliberate opening followed by long cast. Use the same seeds and settings, with at least 20 runs per variant for initial distributions. Report median, range, objectives and death causes; inspect outliers. Bots cannot judge readability, fantasy or willingness to replay.

## Ready-for-expansion decision

Expand beyond one realm only when the slice demonstrates: reliable input and save lifecycle; visible trustworthy effects; usable keyword composition; repeated evidence of intentional openings and worthwhile release; comprehensible preparation; and no ordinary broken UI controls. If a pillar fails, revise its rule before authoring dozens more spells. All numbers remain tunable data, but changing core semantics requires updating contracts and acceptance cases together.
