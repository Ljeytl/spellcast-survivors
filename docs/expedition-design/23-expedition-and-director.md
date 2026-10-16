# Expedition structure and the threat director

Agreed with Aditya on 16 October 2026. Owns the shape of an expedition (days, nightfall, camp, death) and how monsters are paid for (the threat director, `data/director.json`). [Game systems architecture](20-game-systems-architecture.md) §4 owns the module design; [enemy design](22-enemy-design.md) owns what each enemy asks of the player.

## 1. Decisions

| Topic | Decision |
|---|---|
| Model | Risk of Rain 2: a director earns credits and spends them on monster cards. |
| Expedition | About 20 minutes: four days of about 5 minutes. Each day ends in nightfall. |
| Nightfall | The teleporter event: a named boss arrives and a night multiplier sits on top of difficulty, so it feels like more is coming. Night lasts until the boss dies, and the multiplier creeps up the longer it takes. |
| Boss dies | Everything runs away (rout), XP is pulled in, then camp. |
| Camp | The breather between days. The director earns nothing. |
| Difficulty clock | Never resets across days. It raises income and, on a gentler curve, monster health and damage. It never raises card costs. |
| Cards | Each monster has a fixed cost and group size. A realm may change costs and weights or ban cards. |
| Elite words | Cost multipliers: an elite costs its card x the word's `cost_mult` (QUICK 2, MASSIVE 3, FIERY/ICY/SHOCKING 4, IRON 3, LEECHING 2). |
| Champions | Unnamed bosses: big cards at boss size and toughness, bought from a separate share of income. No named bar or boss chest; a small arrow and a potion. |
| Named bosses | Nightfall bosses and ley guardians: big top bar, big arrow, boss rewards. |
| Events | Named bosses, patrols, packs, ley waves (our shrines) and later the stampede and flood are events outside the director with their own budgets; ley sieges already lower the director's income while they run. |
| Death | Ends the expedition. Unlocks are kept. |
| Rewards | No gold. Ley lines are the opt-in fights; unlocks are the loop. A progression currency can be added later (a pickup, a saved number, a tower screen). |

## 2. The director

Income per second = `base_per_second` x coefficient^`income_exponent` x phase multiplier x ambient share, where coefficient = 1 + `difficulty_growth_per_minute` x run minutes. Phase multipliers follow the existing day phases (light, medium, heavy), night is `night` and grows by `night_creep_per_minute`, and rest is 0.

Spending comes in bursts: after a random wait it keeps buying (up to `burst_max` purchases) while it can afford a card's smallest group, then waits again. If it cannot, it saves and retries soon. A purchase is one card bought a group's worth of times, all arriving from one side. With `elites.chance` once `elites.from_minute` has passed, a purchase becomes one elite instead. Champions are paid from `income_share` of income once `champions.from_minute` has passed, with a cooldown and `max_alive`. The monster cap holds money back rather than wasting it.

The spawn timer is still the on/off switch (stopping it stops the director). `encounters.json` `pacing` selects `director` (default) or `interval_phases`, the 0.3 timer spawner kept as a fallback and still covered by its own tests.

## 3. First-pass numbers

`tools/simulate_director.gd` prints a whole expedition minute by minute (60-second nights, nothing killed early, cap ignored) next to the old timer spawner. First pass, 16 October 2026: day 1 runs about 35-80 monsters a minute, each night roughly doubles that (about 190 on night 1, 300 on night 3), elites appear from minute 4, and champions from about minute 11, roughly one every 2 to 3 minutes. The old timer spawner climbed to 600 a minute by the end but was held at 160 alive by the cap. These are starting points for playtest tuning, not targets.

## 4. Later

Realm card tables beyond the grove; a favoured elite word per realm; the stampede and flood as events; the new archetypes from doc 22 as cards; player-called nightfall if the fixed clock feels flat; endless after the last night; a progression currency.
