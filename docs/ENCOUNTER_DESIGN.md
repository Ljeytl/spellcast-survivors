# Enemy encounters and combat direction

## Agreed direction

The goal is a publishable game. First make the gameplay loop work well, then tackle art direction and release qualification. A run targets twenty minutes, with bosses at 5, 10, 15 and 20 minutes. Time advances tiers independently of whether a previous boss is alive.

Elements are themes, not mandatory counters. Spell decisions concern timing, coverage, precision, positioning, sustained damage and casting commitment. Multiple builds must have workable answers to each encounter. No spell, element or specific loadout is required. The discussion of twenty spells and five slots was an example, not approval to replace the current slot count.

## Implemented roster

`data/encounters.json` owns the roster, introduction times, stats and scaling. Individual monsters can reuse a behavior and override their tuning and appearance.

| Family | Variant | Behavior | First appearance |
|---|---|---|---|
| Grunt | Pursuer | Direct pursuit, two starting passive hits | 0:00 |
| Runner | Sprinter | One starting passive hit; 2.54 times grunt speed | 0:45 |
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

## Outstanding run-ending decision

The final boss milestone is implemented at 20:00. Victory behavior is deliberately not implemented pending the user's choice between immediate timed victory and stopping ordinary spawns while remaining bosses must be defeated. The current candidate can continue past the final milestone; it is not a finished twenty-minute game.

## Follow-on gameplay work

- New-spell acquisition and meaningful upgrades during a run.
- Spell combinations whose advantages arise from behavior and complementary uses.
- Broader playtests of different builds, boss health, overlapping bosses and late-stage pressure.
- Art direction, interface scaling, save/settings verification, platform/export decisions and release qualification.

## Verification scope

Automated tests exercise all twelve variants, spawn gates, all four boss milestones, overlapping bosses, shield angles, warnings and damage timing, duplicate death protection, regeneration and multiple earned level-up choices. Opening simulations use the actual player/enemy/projectile/XP scenes with passive attacks and movement toward XP; these support tuning but do not replace human playtesting. Controlled late-stage visual fixtures are identified separately from ordinary runs.

Shutdown regression checks now exit cleanly: damage-number completion uses a node-bound signal connection, and particle cleanup uses a resettable child timer that pauses with the effect and is destroyed with it. Test evidence under `builds/` is excluded from Godot imports. Full release lifecycle and platform qualification remain follow-on work.
