## Current balance override — 2026-09-28, playtest 0.1.28

The 120-second wave cycle stays: 0–15 light, 15–45 heavy, 45–60 medium, 60–70 light, 70–80 medium, 80–110 heavy, 110–120 medium. Base light/medium/heavy intervals remain 3/2/1 seconds. Cadence and group size now grow in parallel; reaching the fastest cadence is not the end of progression.

| Run time | Cadence multiplier | Average regular spawn rolls per event |
|---|---:|---:|
| 0:00 | 1.0 | 1.0 |
| 1:00 | 1.15 | 1.1 |
| 3:00 | 1.6 | 1.3 |
| 5:00 | 2.4 | 1.5 |
| 8:00 | 4.0 | 1.75 |
| 11:00 | 4.5 | 2.0 |
| 20:00 | 4.5 | 3.0 |

Cadence uses exponential interpolation, batches linear interpolation with a carried fractional budget (1.5 alternates one/two, 2.5 alternates two/three). At minute 11 the old minute-20 cadence is reached. Endless adds 0.5 average batch size per two minutes; regular population stays capped at 160. Swarmer rolls can still create packs of three; bosses and timed waves remain separate.

When depleted, queue up to six regular enemies outside the camera every 0.6 seconds until the population target is met. Refill uses a 64-unit margin with at least 1.5× body-radius clearance, while normal arrivals retain 160 units / 4× radius. All twelve current sprites remain wholly offscreen. Target rises from six initially to 24 at ten minutes. Enemies physically travel into view; a clear still buys that travel time. Sustained clearing across at least three separate seconds and six kills per five-second sample raises bounded pressure, while a single mass kill cannot. Pressure can add one spawn roll, up to 30% faster cadence within its 4.5 cap, eight incoming enemies, and 75% extra selection weight for already unlocked specialists. It eases without sustained clearing. Enemy health, timed unlocks and boss milestones are unchanged.

These are testable first-pass tuning values, not a completed human balance verdict. This section supersedes older spawn tuning below.

# Enemy encounters and combat direction

## Agreed direction

The goal is a publishable game. First make the gameplay loop work well, then tackle art direction and release qualification. A run targets twenty minutes, with bosses at 5, 10 and 15 minutes. Time advances tiers independently of whether a previous boss is alive.

Elements are themes, not mandatory counters. Spell decisions concern timing, coverage, precision, positioning, sustained damage and casting commitment. Multiple builds must have workable answers to each encounter. No spell, element or specific loadout is required. The approved loadout is now five manual spells, with automatic Mana Bolt separate. Elements remain thematic rather than mandatory counters.

## Implemented roster

`data/encounters.json` owns the roster, introduction times, stats and scaling. Individual monsters can reuse a behavior and override their tuning and appearance.

| Family | Variant | Behavior | First appearance |
|---|---|---|---|
| Grunt | Pursuer | Direct pursuit, two starting passive hits | 0:00 |
| Runner | Sprinter | One starting passive hit; 3 times grunt speed | 0:12 |
| Grunt | Flanker | Angled approach toward the player's side | 2:00 |
| Grunt | Skirmisher | Alternates approach with short retreats | 3:00 |
| Runner | Swarmer | Three fragile, fast enemies per spawn | 4:00 |
| Brute | Juggernaut | Slow, durable obstacle | 5:00 |
| Runner | Charger | Warns, locks its direction, rushes, recovers | 6:00 |
| Brute | Shieldbearer | Turns slowly; frontal projectiles do 65% damage; other angles and area attacks do full damage | 7:00 |
| Brute | Slammer | Stops and marks a nearby area before striking | 8:00 |
| Shooter | Marksman | Warns before one aimed red-square shot | 10:00 |
| Shooter | Fan Caster | Warns before three shots with dodgeable gaps | 11:00 |
| Shooter | Mortar | Marks a position before delayed area damage | 12:00 |

These within-tier introduction times and numeric values are initial tuning, not immutable design constraints. The timer gates ranged enemies until ten minutes even if a roster entry is accidentally assigned an earlier unlock.

Health stays flat for three minutes and then grows by a factor of 1.16 per two minutes. Speed stays fixed so upgrades do not create an unavoidable pursuit race. Fodder remains in the pool. Initial spawning is one enemy every three seconds, then pressure rises gradually. Bosses are marked, enlarged variants, not yet bespoke encounters.

## Run ending

Reaching 20:00 pauses combat and offers Extract or Continue, regardless of living enemies or bosses. Extract ends the run with victory and records progression once. Continue resumes the same run in endless mode, preserving enemies, spells, health and queued upgrades; no reward is banked at the choice. Dying afterward is a loss and records the full elapsed survival time once. The choice never appears again in that run. Held casting keys cannot select a choice; use a button or navigate to it with Tab before confirming. There is no boss at 20:00 and no repeating boss schedule.

Endless mode extends the existing health and damage curves. Spawn pressure extrapolates the last authored log-linear segment (17:00=3.3333 to 20:00=4.5), retaining the 120-second rhythm, minimum 0.1-second interval, existing spawn batches and 160-enemy limit. The pressure multiplier stops growing when even the light phase reaches the interval floor; enemy health and damage continue increasing. This is a continuity rule, not evidence that arbitrarily long runs are balanced.

## Follow-on gameplay work

- New-spell acquisition and meaningful upgrades during a run.
- Spell combinations whose advantages arise from behavior and complementary uses.
- Broader playtests of different builds, boss health, overlapping bosses and late-stage pressure.
- Art direction, interface scaling, save/settings verification, platform/export decisions and release qualification.

## Verification scope

Automated tests exercise all twelve variants, spawn gates, all three boss milestones and the twenty-minute extraction boundary, overlapping bosses, shield angles, warnings and damage timing, duplicate death protection, regeneration and multiple earned level-up choices. Opening simulations use the actual player/enemy/projectile/XP scenes with passive attacks and movement toward XP; these support tuning but do not replace human playtesting. Controlled late-stage visual fixtures are identified separately from ordinary runs.

Shutdown regression checks now exit cleanly: damage-number completion uses a node-bound signal connection, and particle cleanup uses a resettable child timer that pauses with the effect and is destroyed with it. Test evidence under `builds/` is excluded from Godot imports. Full release lifecycle and platform qualification remain follow-on work.


## Opening pressure revision — September 26, 2026

The earlier one-off opening sequence was replaced by the repeating rhythm above on September 28. Health growth and the 160-enemy cap are unchanged.

Pursuers remain 30 HP with four contact damage and now move at 90. Sprinters become eligible at twelve seconds with twelve HP, three contact damage and 270 speed: one passive hit, three times grunt speed, still slower than the player's 300 speed. Early health scaling is unchanged. Bosses remain at 5/10/15 minutes, no shooter is eligible before ten minutes, and surviving twenty minutes immediately wins.

Behavioral evaluation uses ordinary inputs and four modes: idle, movement without typed casts, stationary casting, and the original moving/typing bot. Active bots choose random upgrades and spells and type five characters per second. They measure a deliberately weak policy; surviving a time-limited probe is not a victory or proof that human balance is finished. Movement-only kiting is reported honestly rather than defeated through artificial damage or forced deaths. Paired fast-runner drafts were rejected because they killed every tested active bot within the first minute.

Phase boundaries restart a running spawn timer using the new interval: the fifteen-second heavy phase schedules its next spawn at sixteen seconds. Recovery similarly starts a full new interval. Stopped/debug simulations are not restarted. Phase rows may be unordered; the latest valid nonnegative start with a positive interval wins. Missing phase data falls back to the original three-second opening.
