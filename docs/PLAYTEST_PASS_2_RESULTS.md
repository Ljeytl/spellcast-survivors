Historical results: the middle-game pressure envelope below was superseded on 2026-09-28 by the repeating two-minute rhythm. Recorded measurements remain evidence for their original revision only.

# Playtest pass 2 — implementation and evidence

Controlling specification: [PLAYTEST_PASS_2_SPEC.md](PLAYTEST_PASS_2_SPEC.md).
Tested gameplay revision: `2003331` (all targeting, readability, spell, reward and encounter tranches integrated). Subsequent documentation and test-window-focus changes do not change shipped gameplay. The packaged-build manifest records final source and merge revisions.

## Delivered behavior

- Shared useful-target selection covers repeated projectiles, passive volleys and homing reacquisition. Straight Bolt stays straight. Group selection accounts for planned Meteor damage so weak clusters do not receive every impact; a healthy lone boss can still receive the whole volley. Pool return/reuse releases old commitments.
- Lightning is a radius160, 0.2-second burst, hitting each enemy once. Orbit reaches130 with42-radius bodies,28 damage and6-second duration. Cross Blade deals60 on each leg and30 at0.3-second intervals during a0.9-second linger. Firewalk leaves65-radius burning ground patches for6seconds, dealing24 per0.5seconds per enemy rather than per overlapping sample.
- Filled/outlined geometry now communicates circular spells, persistent ground effects, trap triggers and cone shape. Meteor impact radius is220 with at least0.65seconds warning. Firewalk loops preserve their unburned centers. Plague remains an infection with more visible markers; its death-ground redesign was not added. Focus Ray behavior is unchanged.
- Camera1.2x, player/enemy sprites1.75x baseline, staff repositioned; background world sizes unchanged. Deliberately retained physical footprints pass operated trunk/clearance tests. Typing uses a readable single row with horizontal tail reveal on narrow windows. Cosmetic particles enlarged independently of hit areas.
- XP crystals stay steady: blue below25, green25–99, purple100+. Local stationary offscreen XP consolidates in220-unit cells every2seconds, excluded near the player/attraction range and inside an expanded screen boundary. Value is preserved and color refreshes on merge.
- Each boss defeat before run completion drops one visually distinct upgrade chest. Collection uses existing slot-aware offers without awarding a player level; it queues correctly beside XP level-ups. An exhausted offer pool supplies Recovery rather than resurrecting banished cards.
- Successful contact damage produces0.24seconds recoil:320base speed,0.6heavy/0.35boss multipliers. The Pursuer boss uses3.8x speed for1second, versus ordinary charger2.5x for0.65seconds; warning remains0.9seconds, and the longer warning direction line reflects dash travel. Trunks still block dash and recoil.

Full spell-by-spell values and roles: [SPELL_PASS_2_AUDIT.md](SPELL_PASS_2_AUDIT.md). Shared target policies: [TARGETING_PASS_2.md](TARGETING_PASS_2.md). Scale evidence: [READABILITY_PASS_2_EVIDENCE.md](READABILITY_PASS_2_EVIDENCE.md).

## Difficulty evidence and limits

The middle pressure envelope is data-driven: multiplier1 at120seconds,1.3at180,1.65at300,1.6at420,1.4at480,1at540. Only spawn throughput changes; enemy HP, passive power, existing archetype unlocks and the160-enemy cap are not globally raised. Parameters through120seconds and from540seconds onward retain the previous curve.

| Time | Previous spawn interval | Candidate interval |
|---|---:|---:|
| 0:00 |3.000|3.000|
| 2:00 |1.200|1.200|
| 3:00 |2.500|1.923|
| 5:00 |2.121|1.285|
| 7:00 |1.799|1.124|
| 8:00 |1.657|1.183|
| 9:00 |1.526|1.526|
|11:00 |1.294|1.294|

A48-sample controlled probe compares the old/new pressure envelope at0/2/3/5/7/8/9/11 minutes with stationary, moving and casting behavior. Same seed44, rank4 Mana Bolt and30-second windows; high health prevents truncation and prior bosses are suppressed. These are comparable encounter measurements, not natural survival outcomes. No sample hit the population cap. In stationary five-minute windows, actual spawns increased16→33 and peak population4→10; at seven minutes16→28 and4→9; at eight20→26 and5→9.

A120-second stationary comparison starting at8:00 produced94→110 actual spawns, peak population22→42, and higher received damage. Again, its artificial health pool makes it a pressure probe, not evidence that a player should take thousands of damage. Prior enemies, extra XP and build choices can change later outcomes even though later spawning parameters are preserved. Final human balance judgment remains open; do not call nine/eleven-minute subjective difficulty conclusively preserved from parameter checks alone.

Natural bot results are stored with exact source revision, seed, profile, commands, damage causes, casts and upgrades under `builds/current/evidence/pass2/final-bots`. The pre-effects control seed44 died at598.6seconds, level20,174 casts. Final natural runs: seed11 died at439.6seconds (7:20), level17,126 casts; seed44 at759.3seconds (12:39), level27,221 casts; seed77 at633.2seconds (10:33), level20,187 casts. All three reports contain zero runtime errors. These accelerated scripted players are a baseline, not a guarantee of player difficulty.

## Requirement disposition

| ID | Disposition | Evidence |
|---|---|---|
|P2-01|Implemented; mechanical verification and review complete|22 shared-targeting checks, including real owned casts and actual pooled return/checkout; Meteor distribution tests|
|P2-02|Implemented roster audited; subjective payoff remains playtestable|24-spell audit; preserved Focus Ray regression|
|P2-03|Implemented; mechanics and native fixture verified|Real Lightning cast, boundary/expiry/unique-hit tests; blue native area|
|P2-04|Implemented; coverage/cadence verified|Orbit real-enemy and old-small-orbit negative control|
|P2-05|Implemented; legs/linger/range verified|Cross Blade lifecycle and speed-scaling regressions|
|P2-06|Implemented; controlled actual-boss chase and geometry verified|Firewalk patch/overlap tests, short-patch negative control, native closed-loop pixel check|
|P2-07|Previous repair retained; real-enemy regression and native marker verified|15 Plague checks and arranged multi-effect native scene|
|P2-08|Implemented; geometry/lifecycles and reduced-effects fixture verified|43 spell-area checks,3 native pixel assertions, multi-effect/reduced fixture|
|P2-09|Candidate implemented; native appearance and operated trunk navigation verified|Scale fixture plus19-check native journey; final preference remains user's judgment|
|P2-10|Implemented; real input and settled captures verified|244 casting checks; desktop800/1280 and narrow480 typing/backspace/complete/reopen/cancel; larger-particle fixture|
|P2-11|Implemented; conservation/appearance/collection/reset verified|11 consolidation checks, setter/tier tests; disabled-consolidation negative control|
|P2-12|Implemented; parameters/probes/bots verified; human feel provisional|439 curve checks,48 short+2 extended samples, natural bot reports|
|P2-13|Implemented; successful-hit trigger and collisions verified|Contact/dash checks and native recoil/dash against trunk|
|P2-14|Implemented; real reward flow and queued choices verified|21 reward/encounter checks; native walk into chest/select/resume; full-run lifecycle|
|P2-15|Implemented; independent review and integration gates complete|Modular targeting/area/XP/reward components, data tuning, parser and diff checks; no separate configured lint/typecheck tool|

## Validation ledger

At gameplay revision2003331:16 integrated mechanical suites,2741 checks,zero failures; native input/collision journeys19 checks; native area rendering3 pixel checks; Python bot-report validation8 tests. Parser/import and diff checks pass. Additional tranche-specific scale/forest/interface suites and negative-control logs are preserved rather than conflated with the integrated count.

The full-clock smoke iterates all1200seconds with scripted enemy kills and an invulnerable player:1224 checks cover three boss milestones, three rewards, immediate20:00 victory and teardown. This is lifecycle coverage, not a naturally won run.

Negative controls cover ineffective targeting, wrapped keycaps, short Firewalk/small Orbit, incorrect closed-loop fill, and disabled XP consolidation. Each produces nonzero failures for its intended defect. Two invocation mistakes (an incorrect delayed-test filename and Python discovery selecting zero tests) are retained in `attempts`; corrected named suites ran and passed. They are not counted as passing checks.

Native evidence uses no-focus offscreen test windows and real key events/button actions where stated. Arranged effect fixtures are labelled as fixtures; they are not represented as organic crowded gameplay or completed human balance testing. At480wide, keycaps remain readable via tail reveal, but the existing scaled HUD/world text is small/blurred; overall phone-like responsive polish is not claimed.

## Release and follow-up

Integrated in PR38 at6d9276b. The exported pack passed97 additional checks across targeting, spell areas, rewards and XP consolidation. The canonical pack/launcher has been refreshed after source review and merge. The running older user game is not interrupted; relaunch is required to use the new build. Preserve user-owned untracked artwork. Archive completed isolated worktrees after evidence is copied; retain any checkout still used by a live game.

Next human playtest: judge character size/sight range, whether Firewalk/Orbit/Cross Blade now feel worth typing, and whether the3–8-minute pressure blends well into the later game. Tune values from those observations. Keep shader work, comprehensive audio, Plague death-ground rework and new-spell expansion deferred.
