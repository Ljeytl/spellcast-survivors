# Experiment (experiment/day-cycle) — Four-day expedition

- A run is four days of 5 minutes of daylight each (the wizard sleeps till 3 pm). The world's colour grade shifts from plain afternoon through golden hour and dusk to night; a "Dusk falls" warning comes at 80% of the day.
- When daylight runs out it turns to night and that day's boss emerges (The Gatekeeper, The Pursuer, The Iron Guard, then The Warden). The day clock stops at night; the run timer keeps counting, so runs last longer than 20 minutes.
- Killing the boss opens a camp screen: the game pauses, combo is kept. Waking up starts the next day at 3 pm with a 10 s no-decay grace. The fourth boss leads to extraction ("4 DAYS SURVIVED"); continuing into endless keeps the days going with tougher repeat bosses.
- MonsterManager.day_cycle_driven turns off the fixed 5/10/15-minute bosses and the 20:00 end. New GameState.CAMP. Training has no day cycle.
- The grade is a screen shader (shaders/day_grade.gdshader) that tints like coloured light and restores each pixel's brightness, so night reads through colour, not darkness. The HUD is above it and never tinted. Colours are a Gradient in data/day_sky.tres, editable in the Godot editor (colour = hue, alpha = strength).
- Tests: new day_cycle_regression.

# Unreleased — Ley lines (cut-down)

- Three ley-line sites per normal run (none in Training), 1500–2200 units from the start in different directions, each with four words. Edge arrows point to unfinished sites (violet asleep, gold awake, red guardian).
- Ley words are made-up incantations generated from syllables each run (e.g. grunothor, broxethoth, kruzugon): 6–11 letters, never repeated in a run, never a spell name. GENERATED_WORDS = false switches back to the fixed WORDS list.
- Standing in a site for 0.4 s wakes it. While awake, a wave arrives every 8 s (4 enemies plus one per two minutes, max 12) as long as the player is within 900 units. Walking away pauses the site; bound words are kept.
- Words are typed only inside the circle: Space, the word, Enter (SpellManager.cast_freeform_spell hands the text to LeyLines.try_word first). A panel lists the words and marks bound ones.
- Binding the last word stops the waves and summons the Ley Guardian (juggernaut boss, 900 HP + 100 per minute). Killing it attunes the site; it drops the normal boss rewards: one bonus chest, a health potion and three style runes.
- Standing in an attuned circle gives +20% Spell Power (through SpellManager.spell_property_multiplier, so it reaches every spell) and stops combo decay (the site joins the style_holds group, which StyleSession treats like a channelled spell).
- Tunables are constants at the top of scripts/LeyLines.gd. Later the reward becomes a permanent spell/keyword discovery (M3 in docs/expedition-design).
- Tests: new ley_lines_regression.

# Unreleased — Property upgrades past rank 8

- Once every slot is filled and every equipped spell is rank 8, rank-up cards raise one of that spell's own passive properties: Spell Power, Spell Size, Spell Duration or Velocity, +10% per pick (SpellProgression.OVERFLOW_STEP), stacking. Replaces the flat +10% damage per overflow rank.
- It is a per-spell layer on the existing passives: SpellManager.cast_stat and SpellGeometry's size/duration/power readers multiply in the casting spell's picks (identified by DamageSource.current). Anything that already scales with a passive, including healing and Earth Shield retaliation, scales with the pick.
- Cards offered are the properties the spell has actually read while casting (SpellManager.spell_properties); a never-cast spell offers Spell Power. Counts are never offered.
- Training bench ranks now stop at 8.
- Tests: rank_overflow_regression rewritten for property cards.

# Unreleased — Combo score and Atomic charges

- Three style values: total score (whole run, never drops, leaderboard), combo score (banked points this combo; shown as "COMBO" under the rank bar) and the style rank bar itself. The bar's raw number is no longer shown.
- A combo ends only when the bar is completely empty (decay to an empty F, or a hit at F). Hits above F still drop one rank and keep the combo.
- Atomic: every 10,000 combo score earns a charge, up to 3 (placeholder numbers). Casting needs rank S or better and spends one charge; it no longer costs combo. Below S, charges are kept but cannot be used; when the combo ends, unspent charges are lost. Pips beside the bar show charges, bright when castable.
- Results show best combo score. Not hand-played.

# Unreleased — Training Grounds

- New tower doorway (one step left of Woodland, violet glass) opens Training Grounds in the normal game scene.
- Dummies with effectively infinite HP that deal no damage: one single target, a tight trio for area spells, and a loose cluster of ten that drifts on a figure-eight around the arena.
- Spell bench (right side, Tab hides it): every spell and combination the Necronomicon lists is equipped at once (everything for now; filter in TrainingGrounds.available_ids() once discovery gating exists). Space casts any of them by name, 1-6 cast the first six; clicking a name switches it off; ranks 1 to 8 per spell. SpellManager.slot_limit lifts the six-slot cap only in training; the bottom spell reference is hidden there.
- Live readout: damage per second over the last 5 s, total, and top spells; Reset damage and Return home buttons.
- Safe by construction: no enemy spawns, chests, XP or level-ups; player cannot be hurt; the run is excluded from scores; equipping combinations does not record Necronomicon discoveries (learn_spell gains a record_discovery flag).
- Dummies react to slows and knockback: they walk back to their spot at a speed slows cut, knockback shoves them off it, and the frozen tint shows and clears.
- Tests: new training_grounds_regression; tower_regression updated for the open training doorway. Not hand-played.

# Unreleased — Spell scaling pass, MEGA charge, Earth Shield grace, rank-8 cap

Spells start smaller and weaker at rank 1 and grow to their rank-8 values. Damage per hit or tick, rank 1 → rank 8:

| Spell | Damage | Size / count / time |
|---|---|---|
| Ice Blast | 15 → 45 per shard | 5 → 13 shards, 50° → 90° cone, reach 250 → 400 |
| Lightning | 60 → 180 | radius 100 → 160 |
| Meteor Shower | 30 per meteor (flat) | radius 75 → 145 (r3) → 215 (r6) → 280 (r8); 3 → 10 meteors |
| Ember Lance | 45, +15% per rank | unchanged |
| Rune Trap | 45, +15% per rank | blast 90 → 130, trigger 50 → 70 |
| Cross Blade | 15 outbound, 30 on return (flat) | 1 → 6 blades, blade radius 20 → 40, travel 350 → 460; volley aims at the nearest enemy |
| Fire Walk | 12 → 36 per tick | trail radius 25 → 65 |
| Cinder Field | 12 → 36 per tick | radius 100 → 150 |
| Arcane Orbit | 20 → 60 per hit | 2 → 4 orbs, orbit radius 100 → 130 |
| Focus Ray | 9 → 27 per tick | 2 → 3 beams |
| Plague Seed | 4 → 12 per tick | infected 3 → 5 s; jump range 60 → 130; spread speed 300 → 460; ground spores 1.5 → 3 s; spread still unlimited |
| Seeker | 15 → 45 per hit | hits each enemy at most once per second; speed 220; lasts 8 → 10 s; 2 → 3 spirits |

- Earth Shield, Magic Missile, Life and Regeneration unchanged. Combinations unchanged except Soul Bloom and Steam Field now follow Plague Seed's and Cinder Field's damage curves; combinations inherit full ingredient sizes.
- Rank cap: spells stop at rank 8 until every spell slot (MAX_EQUIPPED_SPELLS) is filled and every equipped spell is rank 8. Past that, each extra rank adds +10% of rank-8 damage; sizes and counts stop at rank 8.
- MEGA: charge 0.12 s → 0.35 s, charge and release sounds, roughly 3× the charge particles plus an orbiting halo, larger release burst and ring.
- Earth Shield: a blocked hit grants 0.25 s of invulnerability, so one crowd contact cannot strip every charge. Blocked hits still cost no combo.
- New rank_growth support for integer counts and damage; SpellProgression.resolve is idempotent; upgrade cards describe per-rank damage and size growth.
- Tests: suites asserting old tuning values updated to the new numbers or pinned to fixed fixture values where they test behaviour; new rank_overflow_regression. 71-suite headless comparison against e7875b1: no new failing checks. Not hand-played.

# Unreleased — Spell tuning, damage attribution and kill combo

- Fire Walk: renamed from Firewalk, cast as "fire walk" only. Trail radius starts at 32.5 and grows to 65 by rank 8. New ember inventory icon.
- Meteor Shower: impact radius 110 / 195 / 280 (was 220 / 250 / 280); meteors 3 at rank 1, +1 every rank to 10 (was 2,3,3,4,5,5,6,8).
- Plague Seed: jump range 100, spread speed 345 and ground-spore time 1.5 s at rank 1, growing to 130 / 460 / 3 s by rank 8. Uses a new capped per-rank growth field in SpellProgression.
- Cinder Field, Steam Field and Lightning only centre on enemies that are on screen.
- Combinations are offered only once both ingredients reach rank 8.
- Screen shake on kill is boss-only. Bosses drop three style runes.
- Damage attribution (scripts/DamageSource.gd): every hit records its spell and cast time. Kills bank score equal to enemy XP × rank multiplier; combo gets the same XP at full value for 5 s after the cast, halving every 5 s after. Magic Missile and Atomic kills give score only. Kills never refresh combo grace.
- End-of-run screen shows damage by spell with share of total; ending panel is taller.
- Tests updated for the new radii, counts, rank-8 combinations and wrapped timers; new checks for kill combo, cast-age decay, Missile score-only, damage-by-spell and off-screen area targeting. 70-suite headless comparison against 9ae31a8: no new failing checks. Not hand-played.

# Unreleased — HUD readability, MEGA archive entry and current-build page (checklist 5–7)

- SEP30-10/11/12: passives read as words with totals ("Spell Power +20%") instead of two-letter glyphs; narrow windows use short names. HP bar is 34 px tall (was 15) and the XP bar 12 px (was 6); the XP label reads "Level N · XP current / needed". Windows shorter than 560 px keep the old compact bars.
- SEP30-17: Necronomicon opens with a KEYWORDS section documenting MEGA, read from KeywordRules so the numbers cannot drift.
- SEP30-18: the run spellbook shows each owned spell's current numbers ("Now: 62.4 damage"), passive totals with what they affect, the live keyword, and Magic Missile's current damage and interval. No new menu. Shared logic lives in scripts/BuildSummary.gd.
- Tests: update four suites that hardcoded the 3.0 s slowdown or 4 contact damage to the committed 1.5 s and doubled damage; add archive, spellbook and passive-chip checks. Against the previous commit, 70 headless suites show no new failing check names. playtest_ux "Reference clears inventory" already failed for the 16-card boss fixture at 640×480 and 480×640 and now reports 11 intersections instead of 7.
- Rendered captures under builds/claude-shots/. Uncommitted; no version bump or export.

# 0.2.0 — Approved local tuning integration

- Commit the existing local tuning: double base damage for all twelve enemy variants and reduce the fresh per-cast slowdown duration from 3.0 to 1.5 seconds.
- Preserve the local spell-design table revisions, including the possible Shillelagh/Life Lance distinction.
- This captures only the three approved files; ongoing inventory, spellbook and test edits remain separate. No export or additional balance changes.

# 0.2.0 — Combined development milestone

- Identify the merged 0.1.45 casting-feel work, walkable rotating tower, inward-facing arches and E/Space interactions as development version 0.2.0 using the shared menu/gameplay version setting.
- No new export is produced by this version update. New uncommitted casting, encounter and design edits are not included.

# Unreleased — Casting feel 0.1.45

- Move incantations to a compact lower-center strip, sized to the text and fitted above the spell reference. Fit known long incantations on one line, retain a bounded trailing window for arbitrary input, and reduce world dimming to 3.5% beneath the HUD.
- MEGA commits an independent spell/stat/style snapshot, gathers particles at the moving staff for 0.12 seconds of unpaused gameplay time, then releases. Ordinary casts remain immediate. Later typing or cancellation cannot overwrite committed casts; terminal states discard them.
- Apply MEGA ×1.1 after existing cast-style bonuses and penalties, with a separate brief stamp. Power and size remain ×1.5. Failed target-dependent casts produce no award and clear no-target feedback.
- Permit immediate next-incantation input during committed MEGA charging while retaining ordinary cooldown; keep invalid-cast text in a bounded error line without a scrollbar.
- Development version 0.1.45. 313 focused assertions pass, deliberate bad controls fail, and scoped desktop/narrow native casting journeys pass on 0f9179b. Verification limits are recorded in the feedback tracker; GitHub records integration status. No public patch notes or export.

# Tower 0.2.0 controls — Space interaction

- Space works alongside E to enter/leave orb control and open the Necronomicon. Update nearby interaction prompts; keep rotation keys and gameplay casting unchanged.

# 0.1.43 — Inward-facing tower arches

- Replace four coarse tower view buckets with continuous inward-facing arch projection at all twelve clock positions and throughout rotation. Side views foreshorten naturally; southern positions show the outward back instead of repeating one front-facing frame.
- Preserve the approved grey/moss stone and Level 1 woodland artwork; project stone depth and aperture surfaces separately. Keep the arch feet on the rotating ring and book blockers on their doorway's inner side.
- Add native twelve-angle contact-sheet and midpoint evidence, actual render-basis mirrored controls, screenshot-save checks and sustained rotation timing. Existing walkable hub, orb controls, selected top doorway and run lifecycle are unchanged.
- Future art polish: authored stone depth textures and rotating bookshelf perspectives; this correction uses simple code-drawn matching masonry, not new level art.

# Unreleased — Walkable wizard tower home

- Play now enters a walkable tower using the approved crimson carpet, stone arches, orb, tome and modular furniture art. The fixed central floor stays still while twelve outer doorways and their book blockers rotate together under orb control.
- Level 1 Woodland is the only open destination; walk through its top doorway to begin a fresh run. Other arches stay blank and unavailable. E near the tome opens the existing Necronomicon, without adding a loadout system.
- Death and successful extraction retain their results, then return home. Endless Continue remains in the run; pause Retry deliberately retains its existing direct restart behavior.
- Verify physics collisions, doorway selection, keyboard journeys, narrow layout, archive input isolation, repeat runs and exactly-once progression. No version bump or shareable export in this tranche.
- Future: authored perspective frames throughout rotation, level unlocks/clearing blockers and spell preparation; see docs/tower-home.md.

# Unreleased — Focused cast and style HUD feedback

- Implement the approved priority 3/4 presentation pass: incantation success/MEGA response, distinct style gain/loss, separated banked score, and selective active spell status; preserve scoring and spell mechanics.
- Preserve carved-stone style assets and debug detail; omit normal-HUD tutorial prose and rank-progress fractions. Broader inventory readability remains a separate priority.
- Targeted HUD/style/ground/MEGA checks pass; deliberate score-overlap/rank-fraction controls fail. Native review found and corrected typing/inventory overlap and stale focus during cast confirmation. Scoped desktop/narrow operated journeys passed on 0ba1365; details and limits are in docs/UI_UX_PASS.md. Implemented and verified, pending merge; no export refreshed.

# Unreleased — Travel performance and FPS diagnostics

- Cache deterministic offscreen grove queries with a bounded 256-entry recency cache; enemy steering no longer regenerates the same distant terrain every physics tick. Preserve layout, enemy cap, recycling rate and encounter difficulty.
- Add a persisted Show FPS option under Graphics, default off. Display above the build label across menus/gameplay, update every 250 real milliseconds, and keep pause/typing slowdown from distorting update cadence.
- Add seeded component and real physics-frame travel profiles plus cache/settings regression and known-bad uncached control. Separate measured simulation cost from unverified rendering claims; record evidence in docs/travel-performance.md.
- Native review caught an FPS-only narrow-window scaling defect; give the overlay the existing responsive root treatment and verify readable screen-space font size, placement and a deliberately unscaled negative control.
- Verify the corrected FPS control and overlay through native 640×720/3024×1726 menu, gameplay, pause/resume, resize and fresh-process journeys at f3d52b1; retain candidate-bound evidence.
- No version bump or refreshed itch export in this tranche.

# Unreleased — Agreed feedback execution order

- Save the approved priority order and explicit implementation/verification/shipping states in the existing feedback tracker. Fix reproduced SEP30-01 fractional-health display; travel profiling and FPS support remain next.
- Display positive health/overheal below one as <1, reserving 0 for actual zero; leave damage/death mechanics unchanged. Baseline reproduces four misleading labels; fixed runtime/native tests pass.
- Verify lethal death, recovery, invincibility and terminal healing guards. Refresh the shield regression’s obsolete version assertion to inspect the current HUD version setting.

# Unreleased — Testing console repair

- Repair movement speed, Spell Power, XP, health/death, invincibility, noclip, upgrade resources, enemy spawning, encounter-time jumps, chest placement and learned spell listing against current game APIs.
- Make `bighead` double current sprite sizes relative to their original art, with idempotent on/off restoration. Route kill commands through normal death/reward bookkeeping.
- Hide unfinished novelty commands and unstable time-scale control; direct invocation reports unavailable instead of fake success. These effects remain deferred.
- Strictly validate numeric/toggle inputs, including persistent progression and save-slot controls. Keep read-only/unknown/unavailable console use leaderboard-eligible; supported modifying commands mark the run assisted conservatively, even on rejected arguments.
- Add isolated console regression coverage for real state changes, invalid input, score eligibility, death/upgrade pause transitions, boss milestones and extraction. No version bump or rebuilt shareable export.

# 2026-09-30 — Capture playtest feedback

- Log all 28 reports, questions and positive observations with individual IDs and dispositions in the feedback tracker.
- Preserve 0-HP and travel-performance reports as unverified bugs; separate UX, debug commands, Firewalk balance, settings and deferred ideas.
- Link optional follow-ups from the roadmap; no gameplay changes, score deletion or blanket implementation commitment.

# 0.1.41 — Progressive style-rank hotfix

- Correct rank gaps to 100/200/400/600/800/1000/1200/1400 raw combo; verify promotion boundaries, bar fractions and hit grade loss.
- Preserve Atomic cost, cap, decay and casting formula; use scoring revision 3 with previous leaderboard files retained.
- Update version and player patch notes; duration-spell decay proposal remains deferred.

# 0.1.4 web packaging

- Track the MEGA regression script UID and ignore generated import metadata for excluded design-reference art so Godot imports preserve a clean export checkout.
- Prepare the itch HTML5 ZIP from a committed revision; browser verification recorded with the build manifest.

# 0.1.4 — MEGA and Magic Missile

- Added PATCH_NOTES.md with recent version history and the 0.1.4 notes for MEGA and Magic Missile.
- Linked notes from README; keep future implemented changes under Unreleased until an agreed version and export are prepared. Bumped the shared project version to 0.1.4; a fresh export remains pending.

# MEGA keyword

- Added `mega` before learned manual spell names: 1.5× Spell Power and Spell Size, including healing and combination effects. Ordinary casts and Magic Missile stay unchanged.
- Numbered and Space casting accept MEGA; spellbook explains it. Style counts the additional letters while retaining the base spell repetition identity.
- Delayed and persistent effects retain cast snapshots; mixed recasts queue strength segments rather than creating extra streams. Repeated MEGA and unsupported spell names are rejected.
- Future tuning: playtest the deliberately strong 50% power/size difference before adding more words.

# Automatic attack rename

- Renamed automatic Mana Bolt to Magic Missile across player-facing labels, workshop previews, upgrade descriptions and documentation. Manual Bolt and automatic attack behavior are unchanged.
- Kept internal IDs and asset keys stable for compatibility.

# Documentation: readable spell fantasies

- Added spell fantasies directly to the school/family matrix; moved historical commentary into detailed notes.
- Removed Tidal Push, added undecided Plague Lance, and placed Shillelagh in Life Lance.
- Names and unspecified mechanics remain open; gameplay unchanged.

# Documentation: school and family consolidation

- Recorded agreed school mergers and shared Nova/Wave, Slice/Whip columns; multiple spells per cell.
- Moved Tsunami and Shrapnel to Blast, replaced proposed Frost Ray with Water Jet, and separated Sun/Moon combination ideas.
- Names, Sunbeam recipe and new spell tuning remain future design work; no gameplay changes.

# Design capture — element and family exploration (29 September 2026)

- Populate the family matrix with latest user concepts while preserving 16 implemented bases and seven combinations; separate brainstorms, alternatives and rejected examples.
- Record Snowball as Bolt, Water Jet as Ray, Mana Storm as Shower, and infection-specific Seed exceptions; preserve school/grouping questions without runtime changes.
- Record all elemental spell proposals, uncertain names, rejected palette swaps and new Prismatic Shield independently from the old unselected Arcane Shield.
- Mark 0.1.36 merged and align the active slate to tutorial/keywords, followed by preparation/expeditions. No gameplay or assets changed.

# 0.1.36 — Earth Shield redesign and spell-family documentation

- Implement stacked one-hit Earth Shield charges, combo-safe blocks and attacker-directed damage/knockback; provisional tuning and release gates are in docs/releases/0.1.36-earth-shield.md.
- Reconcile current spell behavior and populate element × family matrices with 16 bases, seven combinations and separately labelled user ideas. Keep unselected assistant examples out of the main matrix.
- Update development order: shield, tutorial/meaningful keywords, then tower/preparation/expeditions; defer art-medium exploration.

# 0.1.35 — Spell scaling and combination progression

- Reopen Seed as a generalizable plant/grow/bloom family with distinct buff or turret payoffs; record Flame Seed and the possible Infestation rename. Supersede the premature generic-Seed exclusion; design only.

- Document spell-form vocabulary, Golem as the castable word, unique Seed identity, authored elemental variants and additive Flaming Earth Wall. Keep unresolved wall/shield mechanics and keyword numbers explicit; no gameplay changes.

- Correct 0.1.35 Prism Ray to track at 0.25 radians/second instead of locking its direction; retain piercing damage and update descriptions and regression checks.

- Added Spell Duration (+10% active effect lifetime), including brief damaging AoE aftermaths without slower impacts.
- Spell Power now scales healing and protection; Size and Velocity affect meaningful spell geometry and movement.
- Reworked seven combinations with explicit ingredient-rank contributions and their own progression; removed old combination damage penalties.
- Prism Ray is a broad slowly tracking penetrating laser. Lightning Bolt explodes at every contact. Soul Bloom deaths leave collectible healing areas while spores continue spreading.
- Health drops are 1%; separate 1% style runes grant 200 raw combo plus 200 times the pre-pickup multiplier in run score.
- Updated upgrade copy and documented scope, tuning, tests and deferred Earth Shield/Frost Sigil ideas in docs/releases/0.1.35-spell-scaling.md.
- Added runtime, real-physics and native UI checks plus failing negative controls; reviewed component/pickup integration and completed an isolated bot smoke run. Final revision evidence: builds/spell-scaling-0135/.

## 2026-09-29 — Seeker targeting and combo grace (0.1.31)

- Seekers reserve different visible enemies when available, retarget on death or leaving view, and share a lone target. When new enemies enter view they spread out again; absent targets, they return to the wizard.
- Extend combo grace from three to five seconds after successful manual casts and the final active ray channel. Decay rates remain unchanged.
- Set shared playtest version to0.1.31. Global offscreen-target filtering for other spells remains pending, as do the earlier Focus/rank/recycling proposals.

## 2026-09-29 — Playtest version 0.1.3

- Set the shared project version to 0.1.3 for menu, gameplay, pause, result labels and new score records. Existing exported packages require rebuilding to carry this version.

## 2026-09-29 — Disable clear-based difficulty escalation

- Set `scaling.adaptive_clear_pressure_strength` to zero. Preserve sustained-clear tracking and all adaptive logic for later tuning; setting it to one restores the previous behavior.
- Gate adaptive spawn frequency, group size, refill target and specialist weighting through the same setting. Normal respawn/refill and timed difficulty remain unchanged.
- Record pending playtest decisions separately: graduated style thresholds, shorter Focus duration, closer enemy recycling and visible-target preference.

## 2026-09-28 — Style pacing, crowd pressure and readable rays (0.1.28)

- Set every rank gap to 800 raw combo points; rank multiplier still applies only to run score. Atomic costs 10,000 with a 12,000 combo cap. Separate revision-2 local scores preserve older records without mixing balance versions.
- Refill depleted populations outside the view and ramp spawn frequency and fractional group size together. Reach the former final cadence at minute 11, continue group growth thereafter, and add bounded pressure for sustained clearing. One screen wipe alone cannot trigger it; timed enemy unlocks and health remain intact.
- Make Focus and Prism share target reservations across simultaneous casts, including repeated Prism casts. Beam width now intersects actual enemy hurtboxes; every pierced enemy receives repeated ticks. Add capped beam tips and a brief visual-only expiry fade.
- Suspend style decay during finite active ray channels, including retarget gaps, then restart normal grace. Lingering visual effects do not hold combo or award extra points.
- Start Lightning Bolt with four additional bounces; each spell rank adds one bounce with sufficient travel lifetime and matching upgrade text.
- Reassemble the colored carved-stone meter as an attached rank medallion, framed incision and stone endcap; separate score/feedback at narrow sizes.
- Follow-up: human tuning of encounter density, Atomic affordability and beam/meter feel; fuller visual/audio polish and online boards remain deferred.

## 2026-09-28 — Style scoring and Atomic (0.1.27)

- Add F–SSS combo ranks and separately banked run score, with length, relative typing speed, clean execution and spell-variety bonuses.
- Connect successful manual casts through one attempt receipt; passive effects, duplicate callbacks, locked spells and canceled attempts award nothing. Pauses freeze scoring; per-cast slowdown uses real active time.
- Add grade loss on actual health damage, rank-scaled idle decay, the colored stone-rune meter, local high scores and result summaries. Bot, invincibility and console-assisted runs do not enter the board.
- Add Atomic: type it at S, spend 1,500 combo, then nuke the captured screen after a visible warning. Ordinary enemies/projectiles clear; bosses take 60% maximum health. Reduced effects keep the warning without flash/shake.
- Fix the existing no-argument console heal error discovered while checking score eligibility; use the player’s actual healing API.
- Update stale regression expectations to the already shipped 15 HP Regeneration and 20-minute extraction choice; no healing or run-length balance change.
- Keep the existing roguelike, spells, progression, difficulty and 20-minute extraction choice. Follow-up: human tuning of rank cadence/Atomic cost and later art/audio polish; online scores remain deferred.

## 2026-09-28 — Prepare colored style-meter sprites

- Generated one transparent scratched-stone/rune sheet, including colored D/C/B/A and high-rank variants.
- Added 24 named Godot AtlasTexture regions and a manifest for individual use without destructive slicing.
- No runtime HUD or scoring changes; assembly and small-size legibility remain review steps.

## 2026-09-28 — Record style-meter color feedback

- Preserve scratched-stone/circle direction and record richer color at all intermediate ranks, including D/C/B/A.
- Separate suggested palette from confirmed feedback; no image or gameplay changes, implementation pending readiness.

## 2026-09-28 — Style scoring design and stone-inscription UI concept

- Recorded combo/run score separation, length and speed bonuses, typo treatment, freshness, rank/decay, special-spell alternatives and local leaderboard.
- Added a single segmented concept sheet with carved-stone glyphs, meter parts and assembly examples; no runtime integration.
- Kept unapproved numerical choices explicit and documented verification journeys.

## 2026-09-28 — Attributed playtester feedback

- Preserve the full LJ, Dead, Brad and Guer feedback batch in `docs/PLAYER_FEEDBACK.md`, including positive reactions and deferred ideas.
- Distinguish prior implementations from open reports, explicit deferrals and unapproved design suggestions; no gameplay changes or fresh verification claims.

## 2026-09-28 — Infection spread and crowd collision

- Disable the eight-host lifetime limit for Plague Seed and Soul Bloom behind a reversible switch; retain active-cast and healing limits.
- Charging enemies pass through other enemies during their dash; bosses pass through crowds at all times. Trees and obstacles still block both.
- Record additional bosses at higher/endless difficulties as a future encounter idea.
- Validate 441 checks across infection geometry/visibility, Soul Bloom healing, crowd physics and encounter rewards.

## 2026-09-28 — Playtest 0.1.26

- Package the Firewalk layering and normal-HUD instruction fixes with the 20-minute extraction/endless choice.
- Extract records victory; Continue resumes the same run with increasing enemy pressure and no victory banked in advance.
- Set menu, gameplay and result version labels through the shared v0.1.26 project setting.
- Combined validation: six regression suites, 1,149 checks/assertions passing, plus rendered desktop/narrow extraction and Firewalk evidence.

## 2026-09-28 — Ground-effect layering and minimal HUD

- Fix F41: draw Firewalk and other ground fields/traps beneath the wizard without changing damage or lifetime.
- Fix F42: keep bottom instructional messages in debug only; preserve the casting reference and duration indicators.
- Verify before/after fire overlap, recasting, startup/acquisition guidance and desktop/narrow layouts.

## 2026-09-28 — Record post-0.1.25 playtest reports

- Log Firewalk obscuring the wizard and unwanted bottom instructional messages as open feedback (F41–F42).
- Record weak upgraded Bolt as explicitly deferred feedback (F43). No gameplay or build changes.

## 2026-09-28 — Playtest 0.1.25: maintained spell recasts

- Add data-driven recast behavior. Arcane Orbit, Firewalk, Regeneration and Earth Shield extend existing duration; independent fields, beams, summons and traps retain separate casts. No new duration cap.
- Firewalk extends only the time spent laying fire; existing patches retain their original linger time. Recasting after emission stops resumes at the player without laying a trail across the intervening gap.
- Show live duration beneath spell names, active-instance counts, armed trap states, and brief added-time feedback. Firewalk distinguishes emission time from remaining burning ground.
- Set the shared menu/gameplay version to v0.1.25.

## 2026-09-28 — Guaranteed boss recovery

- Each defeated boss drops exactly one 10-HP potion beside its upgrade chest, bypassing the ordinary random-drop roll and potion cap. Full-health players can leave it for later.
- Ordinary enemies retain their 2% drop chance; bosses no longer also roll a random potion.
- Preserve boss cadence and other playtester ideas in the roadmap; no timing or difficulty changes in this pass.

## 2026-09-28 — Casting reference HUD

- Show equipped spell numbers and exact incantations along the bottom; discovered combinations show names without numeric shortcuts.
- Keep the left inventory focused on icons and levels; distinguish Focus Ray with a narrow beam icon.
- Wrap complete name chips at narrow widths without splitting spell names; hide the reference only when a compact typing panel overlaps it.

## 2026-09-28 — Playtest 1.1

- Stamp menus and gameplay with v1.1 using the shared project version.
- Reduce Ice Blast base damage from 18 to 11 (39%); retain its existing movement, control, geometry and visual behavior.
- Clarify itch fullscreen setup in the web export instructions.

## 2026-09-28 — Playtest follow-up scope and web packaging

- Consolidate approved fixes and explicit exclusions in the feedback tracker and roadmap.
- Add a repeatable HTML export command with revision manifest and itch-ready ZIP; runtime verification is reported separately from export success.

## 2026-09-28 — Playtest inventory and casting UX

- Display active spells, slot-free combinations, and passive ranks with compact themed icons; click spells to start their actual incantation, with acquisition feedback explaining the binding.
- Queue level-up and boss choices until the current incantation completes or cancels; prevent Space from silently selecting a focused upgrade.
- Add the off-screen living-boss arrow and a shared v0.1.0 Playtest label on main menu, gameplay, pause, and results. Use Shoulda Joined a Party as the visible title while preserving the legacy save-directory identifier.
- Verify desktop/narrow actual input journeys and rendered states; Windows-specific flicker remains unverified on macOS. Full keyboard-menu overhaul remains deferred.

## 2026-09-28 — Casting feedback and ingredient progression

- Allow three independent Focus Rays and Prism Rays per spell, distribute new beams across targets, smoothly rotate tracking, and narrow matching beam visuals/hit areas. Prism Ray pierces its full line.
- Ingredient upgrades add 7.5% combination base damage each; Life improves healing seeds, Ice improves combination area, and Regeneration improves Soul Bloom recovery. Player damage buffs apply once.
- Reduce Seeker contact damage from 22 to 18. Verify Cross Blade pierces multiple enemies on its return without adding a damage bonus.

## 2026-09-28 — Recovery pickups and world readability

- Sort loaded tree canopies by trunk-base height across scenery chunks while preserving collision and player occlusion fading.
- Add red health potion drops with initial tunable values: 2% per defeated enemy, 10 HP on contact, up to 12 waiting pickups. Full-health players leave potions available for later; drops do not depend on owning healing spells. At the cap, a successful roll replaces the farthest off-screen potion beyond 2,000 units so abandoned pickups cannot stop future drops.
- Extend XP crystals to four value tiers: blue below 25, green from 25, purple from 100, gold from 500. Consolidation retains all XP and refreshes the resulting gem tier.

## 2026-09-28 — Preserve multi-stage incantation idea

- Record the long-chant Explosion concept, intended payoff, per-cast slowdown constraint, and open movement/interruption decisions; index as I20 and link the spell catalog/roadmap. Documentation only.

## 2026-09-28 — Confirm spell naming sources

- Confirm Shillelagh and record its traditional Irish origin separately from its D&D mechanics.
- Preserve the preference for mystical vocabulary drawn from mythology, folklore or popular fantasy, with source tracing where possible. Documentation only.

## 2026-09-28 — Mystical vocabulary and relic-granted Dash

- Record Boots of Hermes as a relic that could unlock Dash, retaining open activation and equipment rules.
- Expand naming direction: evocative mystical words, short reactive exceptions, and Yggdrasil as the existing ultimate-healing-tree reference. No current spells renamed.
- Reopen the earlier root-spell reference rather than treating the first search match as confirmed intent. Documentation only.

## 2026-09-28 — Magical names and Disruptor concept

- Preserve Shillelagh as the player's chosen name and separate magical public names from functional internal descriptions.
- Record The Disruptor boss idea, same-length corrupted incantations and unresolved scrambling cadence; link it from feedback and roadmap.
- Record local-play-first delivery preference. Documentation only; no runtime renames, boss implementation or new exports.

## 2026-09-28 — Preserve storm, nature and movement spell ideas

- Add the personal dwell-triggered lightning aura, directional root wave, immediate-versus-stored Dash and Swiftness to the spell catalog and feedback tracker (I13–I16).
- Record accumulated, non-consumable mana as a progression framing proposal (I17), retaining unresolved threshold and persistence decisions.
- Clarify aura duration: fixed per cast, increased by level-ups; kills do not extend it. Preserve naming candidates, character counts, visual/mechanical intent and category questions. Documentation only; no new spell or progression implementation.

## 2026-09-28 — Playtest healing, trap and boss balance

- Reduce rank-one Regeneration to 15 total HP over five seconds and Rune Trap to 40 base damage; preserve trap persistence, single trigger and three-trap cap.
- Give the first two scheduled bosses explicit final health budgets of 1,200 and 1,800, independent of normal-enemy HP scaling. Boss two dashes at 600 speed, still affected by slows; its warning line matches travel distance while warning duration and normal chase speed stay unchanged.
- Preserve the repeating spawn rhythm while authoring a gentler early multiplier and steeper ramp after minute13, reaching light0.9s / medium0.6s / heavy0.3s at17. No boss-death reset exists.
- Cross Blade uses three-to-six radial blades with distinct count, size and range ranks; Meteor Shower uses two-to-eight meteors with separate area ranks, visible weighted targeting and fixed per-meteor damage. Shared rank tables drive mechanics and upgrade descriptions; both cap at rank8.
- Correct an older infection test to assert lifetime host budget rather than eight simultaneous hosts after the first host expires.

## 2026-09-28 — Capture Rune Trap and boss tuning refinement

- Record Rune Trap balance concern F40 and distinguish indefinite untriggered placement from its single damage burst; no knockback found in its damage path.
- Preserve proposed final boss health of approximately 1,200 / 1,800 and a faster second boss, with speed details unresolved. Documentation only; no gameplay changes.

## 2026-09-28 — Refine deferred spell balance proposals

- Preserve four-way returning Cross Blade, Regeneration at 10–15 total HP over five seconds, visible proximity/threat-weighted meteor targeting, and a substantially stronger second boss.
- Add illustrative source-derived boss-one cast counts, distinguishing ideal hits from measured fight duration. Exact tuning and implementation remain pending.

## 2026-09-28 — Record healing, meteor, blade and boss feedback

- Add F36–F39 to the player feedback tracker and link them from the roadmap, preserving observations, current source-derived values and open tuning decisions.
- Record Regeneration overlap, Meteor Shower count/damage growth and unrestricted targeting, Cross Blade usefulness concerns, and boss HP inherited from ordinary enemy variants.
- Documentation only; no runtime changes or new playtest verification claimed.

## 2026-09-28 — Preserve deferred Cross Blade tuning

- Record the stronger-return-hit idea in the roadmap and player feedback tracker (I12), including tentative alternatives and the unresolved percentage reference.
- Documentation only; Cross Blade damage and current builds are unchanged.

## 2026-09-28 — Repeating spawn pressure and spell balance

- Repeat a 120-second spawn rhythm: 15s light, 30s heavy, 15s medium, 10s light, 10s medium, 30s heavy, 10s medium. Base intervals are light 3s, medium 2s and heavy 1s.
- Apply one monotonic difficulty multiplier to all phases; remove the temporary midgame pressure boost/reversal. Configurable difficulty thresholds support future multi-spawn ticks; current regular batches stay at one roll (Swarmer packs unchanged).
- Earth Shield now uses its configured 16-second duration for actual protection and visuals instead of a separate five-second timer. Cross Blade body and damage radius shrink 20%; its damage/travel stay unchanged. Blue Sprinter speed stays270 versus player300.
- Future tuning: larger batches can be enabled in encounters.json after playtesting the repeating rhythm.

## 2026-09-28 — Consolidate local work into main

- Preserve and reconcile five local design edits with the documentation updates.
- Track the original Typecast source archive and artwork; no runtime art replacement.
- Consolidate historical playtest exports into the main checkout before retiring task worktrees.

## 2026-09-28 — Central player feedback and current slate

- Added a feedback tracker with stable IDs, open/verification/deferred statuses and evidence requirements for marking fixes.
- Logged difficulty priority, health-potion idea, missing rocks and forest paths; indexed earlier playtest concerns and future concepts.
- Kept current roguelike progression and deferred keyword/expedition work. No gameplay fixes claimed.

## 2026-09-28 — Record wizard tower hub concept

- Documented rotary room level selection, stained-glass destinations, physical preparation book and automatic tower recall.
- Kept placement, capacity, presentation medium and future level-specific pacing explicitly open; linked the concept from the design index and roadmaps.
- Documentation only; no models, assets or gameplay changed.

# 2026-09-28 — Align roadmap with the existing game and wizard fantasy

- Replace fresh-build milestones with keywords in current combat, then preparation, ley lines and connected expeditions.
- Record reusable runtime systems, distinguish migration from new content, and preserve existing spell inventory.
- Align art/UX with readable inscriptions and the working title Should Have Joined a Party; mark older plans and unresolved progression decisions explicitly.
- Documentation only; no runtime or art changes.

## 2026-09-28 — Playable development milestones

- Added a dedicated development-order page specifying enemies, spells, keywords, mechanics, dependencies and acceptance gates for each playable increment. Level 1 starts with normal slimes; complex systems and experiments come later.
- Distinguished development order from player acquisition and linked documents 13, 14 and 15 in the README index.
- Documentation only; existing gameplay and user-owned in-progress design edits are preserved.

## 2026-09-28 — Elemental word tiers idea

- Recorded an exploratory base-form model: Wall supplies shared behavior, while elemental words such as Fire, Flame, Cinder or Incinerating could select an element and power tier.
- Kept vocabulary, coefficients, compatibility, stacking and unlock rules undecided. No gameplay or existing spell-definition changes.

## 2026-09-28 — Composable spell-system reference (documentation only)

- Added a standalone component/property reference before the named spell recipes: origin, geometry, delivery, propagation, targeting, payloads, timing, elements and lifecycle.
- Defined keyword-to-property bindings, meaningful size behavior for projectiles and infection, all 36 campaign recipe mappings, and the remaining spell ideas and additional reusable components they need.
- Kept unsupported keyword choices, cone delivery alternatives, infection refresh and draft Soul Bloom/Meteor Lance identities explicit rather than treating them as approved mechanics.
- Added two document coverage checks. Gameplay and user-owned in-progress design edits remain unchanged; next work is product review of the reference, followed by a small component-based implementation when authorized.

## 2026-09-27 — Expedition design and implementation specification (documentation only)

- Added `docs/expedition-design/` as a separate researched proposal for permanent spell/keyword knowledge, prepared expeditions, four ley lines and 20-minute extraction.
- Audited the current spell runtime; specified a proposed 36-spell campaign, 14 keywords, per-spell compatibility, four realms, tutorial, enemy budgets, progression, visual language, impact timing, UI, save contracts and staged delivery gates.
- Preserved unselected spell ideas and explicitly separated user decisions, current implementation, proposed numbers and unresolved choices. Existing gameplay, art and exports are unchanged.
- Added documentation checks for roster/recipe/keyword coverage, local links, JSON examples, table structure and worked arithmetic; gameplay balance remains untested.
- Next: review the decision register, then build and playtest the tutorial/one-realm slice before expanding content. Art production, shader work and release asset replacement remain separate decisions.

## 2026-09-27 — Shareable playtest exports

- Added a repeatable Windows ZIP and universal Mac DMG export command, with controls, sound credits, source revision and artifact hashes.
- Export refuses dirty source, preserves separate build attempts, and avoids the optional Windows resource-editor dependency (custom executable branding remains a later release task).
- The Mac image includes an Applications shortcut. Both packages include all game data and require no Godot installation.
- Future release work: publisher signing/notarization and a real Windows launch check.

## 2026-09-27 — UI, HUD and menu usability

- Compact health/level/XP and timer panels, moss-colored spell cards, balanced narrow-window spell grid, and fitted spell names keep combat readable without debug clutter.
- Crisp scalable body text complements the existing stone keycap headings; web layouts account for browser CSS pixels on high-density displays.
- Main menus, help, pause, Options, collection and run spellbook have consistent keyboard focus/return paths. Collection keyboard scrolling and spellbook focus-follow scrolling reach the full contents.
- Run spellbook separates six active slots, slot-free bonus spells, six passive families and the automatic attack. Recovering spells stay in the book with an explanation.
- Console transitions preserve the current pause owner, cancel stale animations and block input leakage. XP/rewards queued from paused menus appear when play resumes. Cast completion clears when pausing.
- Audio/display preferences save across launches, Options reflects actual values and displays percentages, and music preference gain is applied once. Reduced-effects settings share the config safely.
- Console text no longer inherits a black tint; controls explain six spell shortcuts. Workshop export uses a durable download handoff and truthful status.
- Added operated keyboard journeys, fresh-process settings checks, narrow-window captures and a known-bad pause control. Full verification details are in docs/UI_UX_PASS.md.

## 2026-09-27 — Compact moving spell bodies

- Reduced Magic Missile and Life Bolt to 80%, Lightning Bolt to 75%, Ember Lance to 70%, and Meteor Lance to 85% of their previous body sizes; Bolt keeps its approved 75% baseline.
- Ember and Meteor Lance preserve the original generated sprite's proportions instead of squashing it. Lightning Bolt uses the original mana motif with a thin blue-white electrical tail instead of a thick purple block.
- Visual body and hit geometry use the same per-spell factor. Decorative particles, spell damage, timing, bounce mechanics, and Meteor Lance explosion area remain unchanged.
- Workshop camera framing stays correct when paused and resized.

## 2026-09-27 — Healing readability and individual spell previews

- Regeneration has a loose orbit of leaves; actual healing shows rising green pluses only when health increases.
- Bolt body and collision reduced by 25%; camera zoom reduced by 7.5%. Other spells retain their sizes.
- Workshop remembers size, artwork, and particle adjustments per effect; schema 2 exports separate those from world settings.
- Corrected Lightning area and six-slot copy; removed the repeated casting instruction.
- Regenerating enemy design remains tabled; wider spell art polish is future work.

## 2026-09-27 — Sample-based gameplay audio

- Replace active keyboard-like SFX mappings with 23 licensed CC0 samples for spells, material impacts, enemy damage/death, XP, typing, menus, player damage, level-ups and chests. Add source credits and conservative normalization.
- Emit spell cues from the shared successful cast path, covering direct/bot casts and newer spells without duplicating typed casts; tie enemy hit cues to actual health loss and remove duplicate level-up menu audio.
- Add per-event repetition limits, quiet passive/pickup/hit gains, bounded unique voices and priority admission under horde saturation. Missing assets no longer produce procedural fallback tones.
- Disable placeholder music autoplay pending a proper soundtrack. Preserve its files/settings; future music uses the dedicated music player.
- Add isolated-profile audio regression and actual-engine WAV capture harness. Dedicated elemental sound design, human listening/mix judgment and optional workshop audio remain follow-up work.

## 2026-09-27 — Simple pixel spell motif atlas

- Visual workshop: redraw the floor after preview camera/size updates so spell replay and zoom do not leave uncovered gray regions.

- Add one transparent 4 × 4 motif atlas for current spell projectiles, hunters, orbit bodies, shield stones and supporting particles. Preserve supplied Typecast artwork and draw hit boundaries, warnings, beams and paths from their existing gameplay geometry.
- Give Magic Missile, Bolt, lances, ice shards, plague spores, Cross Blade, Firewalk/Cinder, Steam, Meteor, healing and Prism Ray distinct restrained silhouettes; keep impact, healing and infection timing tied to existing combat behavior.
- Record the image prompt, source, cell map and geometry contract in `docs/SPELL_PIXEL_ART_PASS.md`; add an atlas and Spell Size contract check. Audio remains outside this visual change.

## 2026-09-27 — Spell geometry and persistent plague spores

- Add Spell Size as a six-slot passive family: +12% projectile/body width, beam width and area/trail/trap radii, with matching artwork. Preserve travel distance, orbit path, piercing and stop-on-contact behavior. Shared authored dimensions account for stamp padding; Focus Ray keeps its existing damaging width and now shows it.
- Refresh pooled projectile geometry after upgrades and keep hostile shots independent of player size.
- Add a gameplay Spell Size workshop control that rebuilds casts; label separate art-only projectile and decorative-particle controls explicitly.
- Remove generic hit sparks from enemy damage and projectile callbacks. Keep red damage flashes, ice fragments, elemental effects and death feedback.
- Infected host deaths from any source transfer immediately if possible or leave a pulsing spore for three seconds. Late arrivals receive a full infection duration. Each cast can infect eight unique hosts; pending retargets preserve their deadline and do not consume the infection budget. Unclaimed spores expire without invisible damage.
- Add actual 1×/2× hit-boundary checks, pooled reuse and passive-cap checks, late-death/arrival, delayed death, expiry, retarget-budget and bounded-chain regressions with known-bad controls.

## 2026-09-27 — Projectile impacts and consistent preview sizing

- Added native before/after render checks for thirteen projectile bodies; caught and fixed meteor particle stamps resetting the rock drawing transform.

- Ice Blast fires a non-homing fan of thirteen ice shards. Damage, slowing, knockback and hit feedback occur on swept contact with enemy hurtboxes; gaps miss and each enemy takes at most one damage application per cast.
- Plague Seed and Soul Bloom spores travel before infection appears. First damage waits for an infection tick, spread and death transfers travel too, and pending spores reserve the eight-host cap. Spores whose host dies can redirect within the original acquisition range.
- Apply the workshop projectile size control to bolts, ice shards, lances, Cross Blade, Seeker, orbit bodies, plague spores and descending meteors using drawing-only sizing. Preserve collision, movement, orbit radius and meteor warning/impact areas. Decorative ice fragments respond to the particle control.
- Add contact, miss, infection-arrival, retarget, cap and sizing regression checks, including deliberately incorrect early-damage and area-scaling controls.

## 2026-09-27 — Visual workshop and clearer spell feedback

- Preview server supports HTTP byte ranges so browser video seeking and frame stepping work.

- Separate current-run Spellbook from the full implemented Necronomicon, with exact incantations, simple previews, recipes and discovery labels. Browsing grants no spells.
- Improve Bolt/Mana body visibility; distinguish warm damage flashes, gray steam/cyan slowing, and green healing. Add simple lightning, meteor descent and plague transfer drawings while preserving combat rules.
- Add a transparent four-stamp particle sheet for impact, smoke, embers and ice; retain procedural spell boundaries and paths.
- Replace sparse gallery playback with complete native 30fps casts, frame inspection and downloadable GIF loops. Add a browser workshop using the actual Godot renderer, independent size controls, all regular enemy variants, pause/replay/speed, reset and preview configuration export.
- Add a brief red health-damage overlay for wizard/enemies that preserves status tint and transparency; repeated hits restart it, blocked/zero/shield-only hits do not flash.
- Execute preview learning/casting outside debug assertions so manual spells work in release browser exports as well as native captures.
- Selecting an effect or Replay starts playback explicitly, fixing short effects appearing broken after a paused preview.
- Future: animate slimes with reviewed pixel keyframes; introduce 10–15% tree/bush size variation in the game after baseline sizing, plus saved per-variant presets and optional boss lineups.

## 2026-09-27 — Spell and particle visual atlas

- Add a repeatable isolated-save capture tool and searchable comparison page for all 24 implemented spells and 28 particle factories. Every native-rendered panel uses the same wizard and camera scale; captured phases can be stepped through or played. Gameplay remains unchanged.
- Future: use this atlas to judge minimum projectile body size against the wizard head before resizing effects. Record smooth animation exports, a browser sizing sandbox, slime animation, run-local Spellbook versus full Necronomicon, and simple matching pixel-art direction in the roadmap.

## 2026-09-27 — Enemy visibility adjustment

- Enlarge every enemy and boss visual by 15%, preserving the individual size hierarchy. Existing fitted health bars and boss labels follow the artwork; camera, wizard, scenery, particles and collision sizes stay at the reviewed settings.

## 2026-09-27 — Reviewed world proportions

- Set camera zoom to1.5 and restore baseline wizard, staff and scenery proportions. Keep floor detail, readable keycaps and gameplay collision/spell areas unchanged.
- Give each enemy an authored visual scale: tiny swarmers, small runners, medium grunts, large brutes and distinct King Slime bosses. Normalize supplied art footprints and align health bars above their visible artwork with consistently sized, centered boss names, without changing enemy HP/speed or physical size.
- Keep XP crystals stable and color-coded at baseline size; use restrained pickup sparkles, clearer hit/death bursts and a larger boss-death burst.
- Future: tune crowded combat readability through player sessions before adding shaders or new art.

## 2026-09-27 — Encounter rushes and distant enemy recycling

- Preserve distant regular enemies and their health/status by moving them to a new offscreen approach angle; bosses stay in the world. Camera-aware spawn geometry respects zoom, offset and terrain clearance.
- Add eight modest timed melee rushes between 3:30 and 18:30, staggered from one sector, respecting unlocks and the population cap. Clock jumps skip expired rushes and victory stops encounters. Existing continuous spawn and stat curves remain unchanged.
- Future: distinct passing formations and human tuning of rush pressure.

## 2026-09-27 — Existing grass variants in patches

- Group the nine supplied grass tiles into sparse, mixed and leafy patches instead of uniformly scattering every variant. Keep the original art, ground palette, scale and collision unchanged; deterministic world coordinates preserve patches when revisiting.
- Future: additional authored ground families can extend the same selection without adding visual noise to combat.

## 2026-09-27 — Integrated second playtest pass

- Release closeout: PR38 merged; exported pack passed97 checks and replaced the canonical current build. Coordination state now reflects verified delivery.

- Integrate targeting, readable spell areas, stronger Orbit/Cross Blade/Firewalk, larger characters and stable XP tiers, single-line incantations, boss rewards, contact recoil and the Pursuer dash.
- Raise spawn pressure only through the previously flat middle stretch, tapering back to existing nine-minute parameters. Preserve Focus Ray and passive power.
- Verify actual input, reward acquisition, trunk collisions, XP conservation, real projectile pooling, geometry, natural bot runs and the full timed run lifecycle. Record measured tuning and remaining human judgments in `docs/PLAYTEST_PASS_2_RESULTS.md`.
- Future: tune the candidate from human feedback; narrow-window HUD polish, shaders and a Plague death-ground redesign remain outside this pass.

## 2026-09-27 — Pass two rewards and encounter interactions

- Add one upgrade-choice chest on boss defeat, reusing the existing slot-aware upgrade flow without granting a player level; exhausted offer filters fall back to recovery without restoring banished upgrades.
- Make successful contact hits briefly recoil enemies with weight-scaled movement and collision. The Pursuer boss dash is faster and longer with its existing windup; ordinary chargers retain their values.
- Consolidate stationary distant offscreen XP locally without losing value or collecting moving pickups.
- Record implementation approval and resolved choices in the shared specification.
## 2026-09-26 — Spell area payoff and visible geometry

- Make Lightning a160-radius blue burst lasting0.2s, with once-per-enemy damage and group selection; reuse its existing electrical sound. Give Meteor Shower data-driven220-radius growing telegraphs before every impact.
- Enlarge Arcane Orbit to130orbit/42body radius with bounded contact damage. Strengthen Cross Blade to60damage per pass,42radius and0.9s of controlled lingering damage. Preserve Focus Ray.
- Extend Firewalk patches from2s to6s, widen them to65radius, and draw continuous burning ground using the same path geometry as damage. Shared circle/cone boundaries also cover fields, traps, Meteor Lance splash and Ice Blast.
- Fit infection markers above enlarged enemies; retain existing host-death spread repair. Audit all24implemented spells including passive and bonuses in docs/SPELL_PASS_2_AUDIT.md.
- Distribute Meteor Shower impacts using per-cast expected damage; preserve full telegraphs and healthy-boss concentration. Preserve unburned holes when Firewalk loops back on itself.
- Add real-enemy geometry/cadence/boss-chase tests and native crowded/narrow fixtures plus a rendered closed-path negative control. Future: player judgment of integrated balance and crowded visibility; Plague death-ground redesign remains deferred.

## 2026-09-26 — Shared spell targeting

- Select useful targets for rapid and delayed Bolt, Magic Missile, Life Bolt and Lightning Bolt attacks using expiring in-flight damage estimates. Homing attacks reacquire after target death; straight attacks retain their trajectory.
- Release estimates on misses, impact, expiry, despawn and pooled reuse. Add reusable group-coverage selection for downstream area spells and document the entire implemented library targeting policy.
- Verify real enemies and typed casts with a reservation-disabled negative control. Future: integrate ground-area selection and judge crowded-scene gameplay with the effects pass.

## 2026-09-26 — Readability and world scale candidate

- Enlarge player/enemy sprites 1.75x and camera zoom 1.2x; preserve background world sizes and collision footprints. Fit staff orbit and enemy health bars to the larger bodies.
- Keep incantations on one row with readable 48px keycaps, a wider prompt, and horizontal overflow that follows the latest key. Preserve placement, backspace, cancellation and completion feedback.
- Replace XP pulsing with steady crystals roughly twice the prior apparent size. Blue is below 25 XP, green is 25–99, and purple is 100+; stored-value changes immediately refresh appearance for consolidation.
- Enlarge cosmetic burst particles independently of affected-area geometry. Keep particle counts unchanged.
- Verification: isolated native rendering plus mechanical regressions; final integrated crowded readability and player judgment of sight range remain required.

## 2026-09-26 — Second playtest pass specification

- Consolidate targeting, spell payoff, shared AoE/fire visuals, scale, typing, particles, XP consolidation, minutes 3–8 pressure, contact recoil and boss rewards in `docs/PLAYTEST_PASS_2_SPEC.md`.
- Separate agreed outcomes, tuning proposals, open decisions, deferred ideas, agent ownership and acceptance evidence. Gameplay implementation remains pending approval.

## 2026-09-26 — Plague host deaths and canopy visibility

- Only the player fades tree canopies; nearby enemies no longer make scenery transparent.
- Preserve Plague Seed propagation when another attack kills its infected host before or between ticks. Each death transfers once within the existing 130-pixel range, eight-host cap and five-second duration.
- Enlarge plant infection markers and brighten transfer trails above the canopy layer.
- Add real EncounterEnemy regression coverage through an owned typed cast, external deaths, damage, expiry, own-kill deduplication, chain limits and player-only fading. Future: judge infection readability during a crowded human run.

## 2026-09-26 — Clean native quit

- Drain active audio streams before menu quit or window close so the native playtest no longer reports audio resources still in use at shutdown. Both routes share an idempotent quit path.

## 2026-09-26 — Player-controlled reduced effects

- Add a persistent Reduced effects option in both title and pause menus. It disables screen shake immediately and lowers the cosmetic particle budget without changing spell mechanics.
- Verify persistence across reopening and a new run, pause behavior, and control containment at desktop and narrow sizes.

## 2026-09-26 — Integrated casting and compact-window verification

- Integrate owned bonus spells, per-cast slowdown, simple effects and provisional encounter pressure. Correct bonus hints and hide unavailable discoveries.
- Keep enlarged typing keys fully visible in short windows; use the lower casting area and temporarily hide the spell bar while the prompt is visible. Preserve health, timer and player visibility.
- Update UI regression expectations for additive bonuses and per-cast windows; include Regeneration in healing metadata.

## 2026-09-26 — Readable keys and ordinary run spellbook

- Enlarge typed keys and stone menu headings, preserving original artwork and wrapping. Add a pause spellbook with owned active/bonus casting, passive ranks and discovered recipes; keep technical diagnostics separate.
- Replace shared-meter debug copy with per-cast duration language. Verify menus and spellbook flows at desktop and narrow sizes after foundation integration.
## 2026-09-26 — Forest groves and clearer XP crystals

- Replace evenly scattered single trees with deterministic groves of varied sizes, occasional isolated trees, empty stretches, and clustered decorative bushes using the existing art.
- Preserve the starting clearing and broad connected routes between groves. Halve physical trunk radius from 22 to 11 pixels without shrinking canopies, anchor both tree variants on their visible lower trunk, keep bushes nonblocking, and scenery, collision, enemy/chest spawn clearance consistent when cells stream out and return. Spawn clearance checks square enemy footprints so boss corners stay outside trunks.
- Enlarge mana-crystal visuals and their pulse by 1.5× without changing XP values, magnet range, collection shapes, or movement.
- Future: evaluate grove density and canopy fading during crowded human playtests before adding new terrain types or obstacles.
## 2026-09-27 — Casting and acquisition foundations

- Give each cast a fresh finite real-time slowdown window; remove idle refill dependency and add the Focus duration passive at fixed slowdown strength.
- Support six primary spells and six passive families. Passive ranks stay in their family slot; Mana Mastery bundles automatic Magic Missile rank and attack rate. Only passives with working effects enter the offer pool.
- Learn authored bonus spells separately at rank 1 while preserving both ingredients and their ranks. Add unified owned-spell lookup/library APIs, reject unowned casts, and keep discovery memory separate from run ownership.
- Separate quick Life from Regeneration and Bolt from Lightning. Reserve Lightning Bolt's bouncing-projectile contract and Life Bolt's collectable healing-seed contract for the effects integration; defer Reaping Spirit acquisition.
- Future: integrate the effects contracts and player spellbook, audit remaining passive families, and validate the combined candidate before delivery.
## 2026-09-26 — Simple spell behavior and feedback

- Give Plague Seed bounded visible plant transfers, Cross Blade an outbound/linger/return path, persistent armed traps, and projectile-speed snapshots for lances, hunters and blades.
- Add capped Lightning Bolt ricochets and collectible Life Bolt healing seeds; actual pickup requests six healing over two seconds, with full-health preservation and ten-second expiry.
- Replace oversized projectile circles and animated texture trails with small outlined pixel shapes. Keep functional shield/charge/hazard indicators; hide decorative enemy-family circles outside debug. Bound impact feedback and camera shake.
- Validate focused effect mechanics, legacy magic behaviors, encounter timing and delayed-target teardown in an isolated profile. Integrated ownership/UI validation and final player-healing hooks remain with the combined build.

## 2026-09-26 — Simple combat feedback foundation

- Add bounded pixel-shaped spell, healing, pickup and impact helpers, with directional cone/link feedback and readable hazard telegraphs. Preserve supplied art and pause behavior; no shader or audio additions.

## 2026-09-26 — Implementation authorized

- Begin the approved staged repair of the existing roster, casting/progression, simple matching art, UX/world and integrated balance. Preserve unselected ideas and defer shader/audio polish.

## 2026-09-26 — Simple art matched to supplied assets (documentation only)

- Record the user's direction to follow the friend's supplied art style closely, reuse existing assets and keep additions simple placeholders.
- Limit art work to the repaired current roster and selected additions. Treat effect lifecycles as readability requirements, not demands for elaborate bespoke animation. Shaders and audio remain deferred.

## 2026-09-26 — Table coverage audit (documentation only)

- Move remaining modifier phrases and broader saved concepts into explicit status/source tables in the [spell library](docs/SPELL_LIBRARY.md); preserve the full discussion notes as supporting detail.
- Record alternate-name references and unnamed Whip variants without counting them as implemented spells. Correct the historical notes' stale equipped-slot reference to the superseding six-slot rule.

## 2026-09-26 — Spell direction accepted (documentation only)

- Record user acceptance of the spell direction and endorsement of circular Frost Nova alongside cone-shaped Ice Blast. Keep concept endorsement separate from playable status, expansion selection and implementation authorization.

## 2026-09-26 — Defer shaders (documentation only)

- Record shader work as a later roadmap item, explicitly outside the current design and implementation scope. No runtime or asset changes.

## 2026-09-26 — Spell geometry contracts (documentation only)

- Correct Ice Blast to the user-confirmed directional cone and retain radial Frost Nova as a distinct idea.
- Add geometry and targeting to the full library, plus detailed origin, dimensions, timing, collision and upgrade requirements for current spell families.
- Require ordinary VFX to communicate the real affected shape; reserve exact hitbox overlays for opt-in debug. Keep unapproved shape and aim choices explicitly proposed.

## 2026-09-26 — Preserve the baseline and separate debug from play (documentation only)

- Keep and repair the implemented roster; select library expansions separately instead of silently replacing existing spells.
- Define normal play, ordinary spellbook and opt-in debug as distinct information surfaces. Keep technical overlays and test controls out of normal runs.
- Record Earth Wall/Earth Walls separately from Earth Shield, retain Thunderwave as a user concept, and leave protective versus terrain behavior explicit for design selection.

## 2026-09-26 — Complete spell library and naming feedback (documentation only)

- Add the [full spell library](docs/SPELL_LIBRARY.md) with individual status, source, letter count, fantasy and visual identity rows. Preserve user concepts, inactive drafts and name alternatives; add clearly labelled water, sun, earth and arcane suggestions. Rows are not a promised playable spell count.
- Separate quick Life (about 4 HP) from stronger Regeneration, specify straight non-homing Bolt, document Seeker versus stronger Seeking Spirit, recommend Firewalk as a working trail name, and revise Earth Shield toward damageable terrain which decays.
- Reopen affected recipes explicitly rather than silently mapping Life Bolt or Reaping Spirit to new ingredients. Keep implementation, generated art and merges paused for design review.

## 2026-09-26 — Playtest design package (documentation only)

- Consolidate playtest feedback into [core design v0.4](docs/CORE_GAME_DESIGN.md), the [spell/passive catalog](docs/SPELL_AND_UPGRADE_CATALOG.md), [art and feedback matrix](docs/ART_AND_FEEDBACK_PLAN.md), and [agent delivery plan](docs/PLAYTEST_REWORK_PLAN.md).
- Record six active/six passive slots, additional slot-free combinations, distinct Bolt/Lightning/Lightning Bolt, per-cast slowdown, useful long-incantation payoff, readable effects and revised opening pressure. These are intended rules, not completed runtime changes.
- Preserve frozen implementation branches and distinguish canonical build, remote UI changes and candidate evidence. Resume implementation only after design approval.
- Keep Moonfall, Tree of Life, Grasping Hand, modifier words, alternate starters, map challenges, typed menus and audio separately scoped or deferred; do not silently add them to this pass.

## 2026-09-26 — Minimal player interface and retained diagnostics

- Hide tier labels, advance boss schedules, passive/rank/refill telemetry, permanent control paragraphs and empty spell slots during normal play. Show active boss health only after arrival; retain health, XP/level, clock, equipped spells and casting feedback.
- Level-up cards show stone-letter names and one authored sentence; percentages come from the actual upgrade value, damage ranks show the actual added damage, and evolutions state the replacement and essential cost. Retain selection, reroll, banish and lock behavior.
- Shorten help, collection entries and run endings; use compact HUD and ending panels. Keep full original card descriptions, encounter schedules, recipe rules and run summaries accessible through F3 / `ui_debug`, plus the `ui_details` console report.
- Future: human-test the reduced text density and discoverability; typing-based menu navigation remains deferred.

## 2026-09-26 — Stone-letter menus

- Reuse the generated stone letters for menu actions and headings, upgrade names, and discovered recipe titles across the main menu, settings, instructions, pause, collection, level-up, and run-end screens. Keep descriptions in readable body text.
- Add a reusable bitmap font with printable ASCII coverage, wrapping, hover/focus/disabled states, and responsive upgrade-card spacing. Preserve click and keyboard controls.
- Future: typing to activate menu choices remains deferred; tune visual density through human playtests.

## 2026-09-26 — Mana-crystal XP pickups

- Replace yellow square XP drops with a transparent cyan mana-crystal sprite, a dark outline and pale facet highlights for contrast against grass. Preserve the existing pulse, magnet movement, collection radius, sound, and XP values.
- Keep the source artwork outside runtime imports and export a compact 24×24 texture with nearest-neighbor sampling.
- Future: consider distinct crystal clusters for larger XP drops once value tiers are designed.

## 2026-09-26 — Stone typing keys and orbiting staff

- Add matching 32×32 stone keys for A–Z, digits, and all standard keyboard punctuation. Typed combat letters drop into place with a soft impact; backspace breaks the removed key into fading fragments with a crumble sound. Long incantations wrap and scroll; successful casts briefly retain their completed word.
- Add the supplied floating staff around the wizard, smoothly orbiting toward the nearest visible living enemy and prioritizing visible bosses. Preserve existing attacks, spell ownership, input acceptance, and menu controls.
- Keep the high-resolution source atlases out of runtime exports and provide a repeatable native-size export tool. Retain symbol assets for future incantations that use them.
- Future: tune sound and impact feel in human playtests; keep layered character animation and typing-based menu navigation on the roadmap.

## 2026-09-26 — Save friend-proposed ritual and boss concepts

- Document map unlock locations, timed long-word rituals and leylines, possible XP risk, the mouse final boss, skill-versus-speed lore, and a keyboard-sized spell-catalog Easter egg. Preserve attribution, example words, and open decisions; no mechanics or run rules change.

## 2026-09-26 — Defer typing-based menu navigation

- Add typing to navigate menus and select upgrades/spells to the later roadmap. Preserve current controls; keep this separate from keycap visuals while typing combat spells. No gameplay changes.

## 2026-09-26 — Authored keycaps and remaining art

- Use the supplied worn keycap art for menu/action buttons and blank keys behind numbered spell shortcuts, with readable ink and distinct hover, pressed, disabled, and keyboard-focus states. Keep long upgrade descriptions on high-contrast panels.
- Add supplied grass and resting flower-slime art to the main menu. Use both tree drawings and both king-slime designs in the arena. Preserve existing control behavior and readable body typography.

## 2026-09-26 — Typecast art and forest arena

- Integrate the supplied assembled wizard, nine slime variants, king-slime bosses, ranged wisps, nine grass tiles, trees, bushes, keyboard logo, and health-bar art with nearest-neighbor sampling.
- Add sparse deterministic trunk obstacles, an open starting clearing, bounded scenery streaming, enemy steering, and spawn clearance. Trees block movement while spells continue through foliage; nearby canopies fade to preserve player visibility.
- Preserve the separate wizard components and alternate exported designs under assets/typecast for future animation. Keep unsupplied spell effects as placeholders and retain combat stats, encounter timing, and hitbox sizes.
- Record future layered wizard animation and obstacle-aware bot improvements in the roadmap.

## 2026-09-26 — Casting decisions and branch reconciliation

- Confirm the existing survivors premise, long-incantation power fantasy, and fixed-strength per-cast slowdown with upgradeable duration. Record that the shipped shared budget/refill still needs replacement.
- Document thirteen supporting upgrade categories, bundled Magic Missile mastery, enemy population as risk/reward growth, and spell-appropriate Multicast instead of a projectile-only stat. Preserve open Magic Missile interactions and secondary-slot rules.
- Refresh stale core-design descriptions of movement, incorrect input, passive slots, and the repaired attack-rate stat. Mark prior pivot discussions and roadmap milestones as historical.
- Reconcile the original opening-balance branch only after auditing its already-reapplied changes against the recovered and subsequently tested mainline; retain current gameplay behavior.

## 2026-09-26 — Creator pitch and alchemist concept

- Expand the [casting fantasy notes](docs/CASTING_FANTASY_NOTES.md) with the creator’s full explanation: frantic typed spells, siege/PvZ-like alternatives, the desired swing from panic to crowd-erasing power, and an alchemist defending a tower with about ten ingredients and four-to-five-ingredient potions. Preserve open questions about input, recipes, preparation and resources; no gameplay changes or approved pivot.

## 2026-09-26 — Casting fantasy discussion preserved

- Record the creator’s movement-versus-casting panic, possible defense pivots, language composition ideas, and proposed playtest questions in [casting fantasy notes](docs/CASTING_FANTASY_NOTES.md). Distinguish user priorities, assistant suggestions, current mechanics, and unresolved decisions; no gameplay changes or pivot approval.

## 2026-09-26 — Playtest-driven balance corrections

- Rename Quick Cast to Mana Tempo and describe its actual +10% automatic Magic Missile attack-rate benefit. Preserve the internal upgrade key and existing attack cadence while keeping typing slowdown at 20% world speed regardless of attack-rate upgrades.
- Ignore dying, zero-health, queued-for-removal, and freed enemies when computing contact damage and its attacker count. Live enemies still deal their normal damage.
- Extend ordinary bot reports with contact/projectile/blast damage, damage while typing, recent hits, boss arrivals/defeats/surviving health, and uncollected XP. Validate contradictory damage reports rather than infer balance from survival time alone.
- Add real-time typed-cast and physical-contact regressions with baseline failure evidence. Preserve the three-second typing budget, ten-second recharge, encounter curve, spell damage, and twenty-minute ending.
- Next experiments: distinguish boss target access from boss durability, and XP left behind from insufficient XP rewards before changing middle-run pressure. Small random bot batches do not establish human difficulty or final balance.

## 2026-09-26 — Optional evolution tradeoffs

- Keep basic spells useful beside their evolutions. Life Bolt retains equal damage per bolt but gives up ranked Bolt's extra projectiles for healing. Meteor Lance and Prism Ray deal 40% less direct/per-target damage in exchange for crowd coverage; Soul Bloom and Reaping Spirit deal 25% less damage for sustain or kill bursts.
- Steam Field slows enemies but lasts three seconds instead of five. Frost Sigil has a larger slowing burst but arms in 1.4 seconds instead of 0.8; its visual arming progress uses the same delay as damage logic.
- Show both gains and costs before replacement and in discovered collection entries. Damage penalties scale once with retained rank and player bonuses; rank cards identify the evolved base damage.
- Prevent ordinary offers, rerolls, and banishes from forcing three evolutions: preserve a non-evolution choice, preferring an offered recipe's primary rank. Preserve explicit locks and banishes; all three explicitly locked evolutions remain the player's choice.
- Compare basic/evolved damage, healing, crowd coverage, duration, and preparation at equal investment. Preserve basic damage, encounters, spell ownership, catalysts, and run rules. Next: compare ordinary base-heavy and evolved builds before further tuning.

## 2026-09-26 — Tactical spell variety

- Expand the manual catalog from ten to fifteen base spells with Focus Ray, Rune Trap, Seeking Spirit, Ember Trail, and Returning Blade. Their roles reward tracking, preparation, pursuit, movement, and positioning without elemental immunities.
- Add three authored hidden evolutions: Prism Ray, Frost Sigil, and Reaping Spirit. Existing ingredient ownership, primary replacement, retained ranks/catalysts, persistent discovery, and five-slot limits apply.
- Bound effect lifetimes, moving-target tracking, per-leg blade hits, trail spacing, and simultaneous casts. Primary/evolution variants share their family cap; Focus/Prism permits one beam. Show beam endpoints and trap arming truthfully.
- Cover actual owned typing, rank damage, enemy/caster cleanup, pause, ordinary seeded offers, and evolution caps. Seeded strategic offer simulations record failed full-kit attempts as well as successful acquisition; they do not establish natural discovery rates.
- Keep run length, encounter difficulty, offer odds, shared slowdown, and existing spell balance unchanged. Next: ordinary build playtests, discovery-frequency evaluation, and crowded-combat readability before full art direction.

## 2026-09-26 — Gameplay interaction pass

- Preserve incomplete or mistyped numbered incantations on Enter; Escape cancels. Ignore held activation/letter repeats while preserving repeated Backspace editing.
- Let owned spell cards start the same guarded typing flow as number keys; empty cards explain acquisition. Add compact movement, automatic attack, and casting guidance plus a nonmodal acknowledgement after an applied upgrade.
- Focus the first level-up choice and provide deterministic arrows/Tab navigation. Ignore held accept-key repeats across new offers. Right-click consistently locks/unlocks; banishing remains an explicit action.
- Record actual health and bonus-health loss with contact, projectile, area-blast, or unknown source context. Defeat results explain the final hit without attributing aggregate contact to a single enemy.
- Guard the first 350 ms of results from keyboard acceptance and ignore repeated accept keys; deliberate mouse actions remain immediate.
- Add operated-input regressions and known-bad controls. Run length, bosses, difficulty, spell ownership, shared slowdown, camera, and visual direction remain unchanged.

## 2026-09-26 — Gameplay readability pass

- Give gameplay HUD and menus readable window-relative sizing without changing the world camera or combat scale. Use slate panels, parchment text, cyan casting feedback, gold choices, and coral danger.
- Show five spell slots with full names, ranks, selected state, and empty-slot guidance; separate automatic Magic Missile and always-visible slowdown availability/recharge.
- Keep the incantation prompt above the player, report typing mistakes and owned-name matches, and retain bounded scrolling for long input.
- Label choices as new spells, spell upgrades, passive upgrades, or evolutions; preserve functional descriptions and replacement details.
- Darken the floor and outline enemies; retain conspicuous square hostile projectiles and outlined area warnings without altering their collision, damage, or timing.
- Show final spell kit, survival time, and discoveries made during the current run in scrollable results. Guard result actions against repeated activation.
- Keep pause options interactive in the UI layer and return Escape to the paused menu. Apply the same readable sizing to menu, help, options, and collection.
- Add layout/state regressions with known-bad controls; desktop/narrow operated verification is recorded with the candidate evidence. Full art direction, additional spell effects, and balance changes remain later work.

# Changelog

## 2026-09-26 — Limited typing slowdown

- Give each run a shared three-second typing slowdown budget, refilling fully over ten seconds outside typing. Casting, cancelling, or reopening does not reset it.
- At exhaustion, restore normal world speed while preserving input and the ability to cast. Show remaining time inside the casting box; pause and level-up freeze consumption/refill.
- Restore normal speed and close typing on death or victory. Keep capacity/refill configurable for later duration upgrades.
- Preserve the pre-input time scale when measuring a transition frame; a 15 FPS integration check measured 2.999 seconds. The old calculation failed the same check at 2.733 seconds.
- Correct help text for the 20-minute win and spell names; exclude local build fixtures from exports.
- Stop bot audio before shutdown and detect ANSI-colored engine errors in its report gate; an accelerated smoke run exposed both gaps. Use real-time bot runs for casting cadence because fast mode also compresses cooldown time.
- Validation: 20 budget, 6 timed integration, 30 layout, 615 acquisition, 36 synergy, and 24 ending assertions. Duration upgrades and revisiting Quick Cast remain future balance work.

## 2026-09-26 — Contained UI text

- Wrap upgrade titles/descriptions inside padded, content-sized cards; scroll long offers while keeping reroll, banish, and lock controls visible.
- Remove duplicate hover descriptions and hover scaling that could clip card edges.
- Wrap casting text, grow its box up to a bounded height, and scroll longer input without truncating it.
- Render How to Play formatting tags correctly.
- Validation: 29 layout assertions (including a known-bad unwrapped control), 615 acquisition assertions, clean Godot import, desktop/narrow three-card fixtures, scroll then select, long casting error, and help scroll/back. Full visual redesign and narrow-window text scaling remain future work.

## 2026-09-25 — Forgiving opening and regeneration

- Lower early XP thresholds to 25, 40, 55, then +15 per level.
- Set opening Goblin/Rat/Hobgoblin base HP to 20/12/25. Rat archetype health is 60% of base. The preserved local playtest previously used 80/60/80.
- Keep tier 1 for the first three minutes; introduce later tiers every two minutes. Keep two-second spawning during the opening and gently increase pressure afterward.
- Use configured base stat scaling rather than the hidden +30% multiplier. Delay additional health/speed growth until after the opening.
- Remove ordinary-letter difficulty, invincibility, and XP cheats; retain console commands.
- Dispatch regeneration for both numbered and freeform casting, clamp healing to remaining duration, and avoid competing HUD tweens.
- Initialize health and XP labels from actual player properties; show the active spawner's tier and interval.
- Preserve every upgrade choice when one XP reward earns multiple levels. Finish closing each modal before opening the next and reject duplicate selections.

Validation: 37 focused Godot assertions passed on the isolated candidate containing the pre-existing local work plus this patch. Known-bad controls failed for wrong XP, premature tiers, and broken regeneration in both casting paths. A visible run reached level 2 at 00:29 and level 3 at 00:39; regeneration cast successfully and health recovered from 75 to 88 between observations. These times are game time and one short run, not a statistical balance qualification.

Integration remains blocked: committed baseline 5735e53 contains a dangling `else` in Player.gd and incomplete SpellManager.gd definitions. Local unfinished work repairs those paths but is not included in this patch. The validation candidate is not the standalone PR revision. Existing enemy-data JSON, console VBox, missing enemy Visual node and collision-callback errors remain open. This is not a full release or UX pass.

Next: integrate the separately owned unfinished baseline, validate the combined revision, then add level-up spell acquisition and the first three spell combinations before art direction. Continue tuning late-run balance after the forgiving opening is playtested.


## 2026-09-25 — Runnable integration baseline

Preserved the existing unfinished work in its own prerequisite commit, then integrated the balance patch. Repaired the enemy catalog structure, invalid console node, enemy hit flash, duplicate death/XP collection, deferred collision cleanup, and pooled-object cleanup. Added the referenced source sprites and bundled license/readme so scene loads do not depend on an ignored local asset pack. Original working files remain unchanged.

The integrated source passes all 37 balance assertions and imports without script errors. Ordinary combat smoke testing no longer reports invalid data, missing Visual nodes, or physics-callback mutations. Forced engine termination with an active scene still reports resource leaks; normal scene teardown in the regression harness exits cleanly. Publication qualification remains pending.

## 2026-09-25 — Timed enemy archetypes

- Added four families with three behavior variants each, including the agreed Grunt Skirmisher and Runner Swarmer.
- Added timed introductions, a ten-minute ranged gate, and independently scheduled bosses at 5/10/15/20 minutes.
- Replaced enemy spell sprites with red-square projectiles; added charge, shot and area-attack warnings.
- Kept elemental matchups optional: shields reduce frontal projectiles rather than creating immunities, and positioning/area attacks provide alternatives.
- Unified the visible timer with the encounter manager, removed the disabled legacy spawner, and retained source sprites matching each roster entry.
- Retuned the opening after a poor first playtest: two-hit Pursuers, higher fodder XP and slower initial spawning. Prevented duplicate player deaths from simultaneous attacks.
- Added encounter behavior tests and three seeded opening simulations. Final victory rules remain pending; this is an encounter-system milestone, not a production release.

Validation: 33 balance checks, 3,321 encounter assertions and three seeded opening simulations pass. The simulations reached the first upgrade around seventeen seconds at full health. Exclude test evidence from resource imports. Headless encounter/pacing teardown still reports unfinished Tween/SceneTreeTimer leaks; release lifecycle qualification remains open.

## 2026-09-25 — Encounter shutdown cleanup

- Removed suspended damage-number animation awaits and initialize damage numbers after adding them to the scene.
- Give pooled particles a resettable child timer, so reuse cancels stale cleanup and pausing freezes the effect lifetime.
- Encounter and opening simulations now exit without the previous Tween/SceneTreeTimer leaks. Added reuse, pause and expiry assertions.
- Include the runtime JSON catalogs in the playtest export and exclude test scripts and local overrides.

## 2026-09-26 — Immediate twenty-minute victory

- Win immediately at 20:00; stop the clock, spawning and combat, and show VICTORY with run statistics.
- Keep zero health as a loss and record progression once for either outcome. Ignore late level-up callbacks after a result.
- Keep bosses at 5/10/15 minutes and remove the 20-minute boss, which would coincide with victory.
- Leave the narrative reason for winning to later design work.
- Verify cutoff, no early victory, losses, duplicate results and post-result guards with twenty-four ending assertions.

## 2026-09-26 — Reconciled core design draft

- Added Core Game Design v0.2 and preserved the original agent draft for reference.
- Incorporated immediate twenty-minute victory and agreed encounter/playstyle principles.
- Separated approved direction, current prototype behavior, proposed content and experimental tuning.
- Added typing/input constraints, the upgrade-choice budget, combination alternatives and a focused list of remaining product choices.
- Documentation only; proposals do not change or approve game behavior.

## 2026-09-26 — Learn spells during a run

- Start with manual Bolt and the passive Magic Missile; learn Regeneration, Ice Blast, Earth Shield, Lightning Arc and Meteor Shower from level-up choices in their existing six numbered slots.
- Offer an eligible learning card while unlearned, unbanished spells remain. Once learned, spells receive rank upgrades instead; ownership and ranks reset each run.
- Share acquired spell state between numbered and freeform casting. Fix ID/name mismatches that prevented upgrades from applying and remove the ordinary Y unlock cheat.
- Repair reroll, banish and lock actions to use eligible, unique, applicable cards; prevent changes while a choice resolves. Remove unimplemented passive effects from the offer pool.
- Describe actual rank benefits and dim unlearned HUD icons. Authored combinations and the wider proposed spell library remain follow-up work.

## Casting playtest follow-up

- Keep the player fully visible during typing.
- Consume cast cancellation before pause handling and remove the duplicate polled Escape handler.
- Live playtest reached 1:28 with full health; movement and normal XP collection remain unverified because the UI controller could not hold movement keys.

## Developer baseline bot

- Added an opt-in scripted player that flees threats, seeks XP, types owned spells and randomly chooses normal level-up buttons.
- Added per-seed isolated launch profiles and JSON/log reports, with explicit death, victory and incomplete outcomes.
- Kept bot tooling outside normal exported builds; accelerated mode is smoke testing only.
- Next: exercise Space casting and authored synergies after those mechanics land, then compare several realtime seeds and human playtests.

## Space casting and first hidden synergy

- Space opens an owned-spell casting box; Enter commits the name, Backspace edits, and Escape cancels. Numbered shortcuts remain available. Typing stops movement.
- Added authored Life Bolt recipe: Bolt + Regeneration makes a learning card eligible. Selection unlocks the spell for the run and records a permanent discovery for the current save slot. Ingredients remain usable.
- Life Bolt fires one green homing projectile using Bolt damage scaling and heals up to 6 HP on actual damage, capped by damage dealt. No healing on misses or defeated enemies; no rank choices for this first synergy.
- Added Spell Collection with hidden undiscovered recipes, persisted requirements/effects/incantations, empty state and Back/Escape navigation.
- Clear profile state before loading another slot, preventing discoveries from leaking into missing/malformed saves. Older saves default to no discoveries.
- Updated the baseline bot to type owned spell names via Space/Enter and report casts per spell.
- Next: more authored recipes, richer behavior upgrades and full-run balance; difficulty numbers remain unchanged.

## September 26, 2026 — Spell builds and authored evolutions

- Ten base spells compete for five manual slots; automatic Magic Missile stays separate. Slot keys and HUD names follow actual acquisition order.
- Added piercing Ember Lance, spreading Plague Seed, persistent Cinder Field and close-range Arcane Orbit, each with working rank scaling.
- Added Meteor Lance, Soul Bloom and Steam Field; Life Bolt now evolves Bolt in place. Every evolution retains its primary slot and rank, preserves its catalyst, and remains upgradeable.
- Full kits still receive eligible evolutions, rank upgrades and passives. Consumed primaries cannot be cast or relearned; invalid evolution requests leave ownership intact.
- Bound infection spreading and persistent effect counts/lifetimes; healing uses actual enemy health lost. Collection records only selected discoveries.
- Casting cooldown uses active unscaled run time, keeping accelerated bot tests consistent with ordinary play. Difficulty and art remain unchanged.
- Next: compare complete runs and spell choices across human play and multiple bot seeds before changing balance.

- Reserved HUD space for wrapped spell names above ranks, and made the developer unlock command fill only available slots with truthful output.
- Delayed mana, spread-bolt and chain callbacks now resolve weak target references and disconnect safely when their run ends; freed targets cancel pending hits.
- Verified delayed-target cleanup with 7 targeted assertions, 182 spell-build assertions and 611 acquisition assertions. Diagnostic accelerated seed 11 ended in death at 452.2 seconds with 100 successful casts and no runtime errors; broader final-revision runs remain the next validation step.
- Balance regression now waits for bounded observable level-up transitions instead of fixed timer delays, preserving the queued-choice and duplicate-input assertions under headless scheduling.

- Follow-up: Ice Blast now uses a forward 90-degree cone with matching damage/control bounds; Lightning is one direct strike. Personal stone protection follows the player through the effects API; heal/hurt visuals respond to actual health changes.

- Integrated healing seeds and bouncing-projectile effect contracts for regression validation. Migrated old replacement/shared-reserve tests to additive bonuses and fresh per-cast timing; coalesce healing feedback to one burst per 150 ms while preserving all health restoration.
## September 26, 2026 — Opening pressure and behavioral controls

- Replaced the flat early spawn grace period with opening pressure and recovery windows, then the existing exponential density growth.
- Kept early enemies at two passive hits for grunts and one for runners; introduced runners after twelve seconds, below player speed. Health, contact damage, ranged gates, boss times and immediate twenty-minute victory remain unchanged.
- Added isolated bot modes for idle, movement only, stationary casting and active play, with first-damage telemetry and checks against mode contamination.
- Added deterministic checks for the pressure/recovery transitions. Full behavioral evidence and remaining balance limitations accompany this change.

### Opening pressure timer follow-up

- Spawn phase boundaries restart the running timer with the new interval, so pressure/recovery changes no longer wait for the previous deadline. Stopped timers remain stopped.
- Unsorted phase rows use the latest valid start; invalid/nonpositive rows are ignored and missing configuration retains safe baseline defaults. Pressure values remain provisional.
- Bot reports must match the requested behavior mode.
- Verified 7 real-timer assertions, 44 balance assertions and 8 Python report tests. Removing the boundary update makes four timer assertions fail.

- Migrated seeded magic, acquisition and typing-presentation fixtures to six active slots, separate Life/Regeneration, additive bonus spells and distinct Bolt identities. Preserve real input, reroll/banish, effect-cap and deferred-recipe coverage.

- Plague Seed and Soul Bloom acquire only visible living hosts, optionally respecting an authored initial cast range. No-target attempts remain editable with “No target in range,” preserve the current slowdown allowance, and do not count or flash as successful casts. Shield-only absorption emits stone feedback; health loss emits red feedback, with both on overflow.


- HUD cast confirmation hides the finished focus countdown and restores it on the next incantation; the release animation no longer displays stale focus time.
