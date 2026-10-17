# Enemy design: every enemy is a question, every answer is a word

Drafted 16 October 2026 for review by Aditya; nothing here is approved or built. Owns **what** each enemy is for (its threat, its answer, its telegraph and its read) and the rules the roster follows. [Game systems architecture](20-game-systems-architecture.md) §3 owns **how** enemies are built (behaviour modules, actions, data). Target milestone: 0.5 ([release plan](15-development-order.md): "different threats reward different spell choices").

## 1. The model: Doom's combat chess, played with words

Doom (2016) and Doom Eternal make every demon a question with a clean answer: a grenade in the Cacodemon's mouth staggers it, shooting the Mancubus's arm cannons disables them, the Marauder is only open when its eyes flash. You read the arena, pick the answer in about a second, and the right answer changes the fight. Fodder is a resource (chainsaw ammo, glory-kill health), priority targets (the Archvile) make everything worse if ignored, and the puzzle comes from combinations that want different answers at once.

In this game switching weapons is typing a word. So: **an enemy appears → you recognise it → you type its counter under pressure → it breaks.** That is the game's identity: a typing game where the counter is a word you have to remember while things come at you.

## 2. Rules for every enemy

1. **One threat, one answer.** Each enemy has a single readable job and a single best response. Variety comes from mixing enemies, not from one enemy doing five things.
2. **Answers are soft counters.** Everything dies to everything. The right answer is roughly three times faster, or disables the threat, or both. Never a lock: a player whose six prepared spells lack the answer must still have a slower way through.
3. **The answer is in the player's vocabulary.** An element (the type chart), a shape (area, beam, trap, ring, orbit, projectile), a keyword (HOMING, PIERCING, CHAINING, PULLING…), a status (burn, chill, shock) or movement. If the answer is "deal more damage", the enemy is fodder or a sponge, not a question.
4. **The answer does something beyond damage.** Breaks a shield, staggers, interrupts a windup, strips armour, pulls a burrower up. That is the reward that makes knowing the answer feel good.
5. **Everything is telegraphed.** Same rule as elites: a windup you can see, in hostile colours, never off screen.
6. **Typing takes time.** A word costs 0.5–1.5 seconds, against Doom's one button. Attack windows are longer than Doom's, and the director limits how many different answers are demanded at once (three by default, tunable).
7. **Fodder gives back.** Weak enemies killed the right way drop something useful (health, a charge, XP burst), Doom's chainsaw and flame belch.
8. **Priority targets exist.** A few enemies make the fight worse while alive (heal, shield, summon, buff). Killing them first should be obviously right.
9. **Looks per realm, behaviour per archetype.** About a dozen core behaviours, re-skinned per realm and given element variants. The answer stays the same under a new skin, so knowledge carries over.

## 3. The answer vocabulary we already have

| Kind | What exists | Typical answer it gives |
|---|---|---|
| Element | Type cycle: Storm > Water > Fire > Plague > Life > Earth > Storm; Arcane and raw neutral (`TypeChart.gd`) | Element-armoured enemies: type the element that beats theirs |
| Shape | Projectile, area, ring, beam, trap, orbit, field | Areas ignore shields and facing; traps catch burrowers; beams reach through crowds |
| Keyword | HOMING, PIERCING, CHAINING, EXPLODING, SPLITTING, PULLING, REPULSING, HUNTING, RINGED, LINED, BIG/MASSIVE, QUICK, CHARGED, WARDING… | HOMING curves around shields; PIERCING snipes through crowds; PULLING drags things out of cover; REPULSING clears a pincer |
| Status | Burn, chill, shock (and the player versions) | Chill stops a charge; shock interrupts a windup; burn finishes splitters |
| Movement | Walk, dodge | Sidestep a dash, leave a slam circle, close on a shooter |

## 4. The current roster, assessed

| Enemy | What it does today | What it asks of you | Verdict |
|---|---|---|---|
| Pursuer | Walks straight at you | Nothing | Fodder. Fine, but gives nothing back |
| Flanker | Steers to a point beside you, up to 160 px off your line | Nothing readable | Real behaviour, but it reads as a pursuer. Rework (§5) |
| Skirmisher | Backs off for 1.5 s out of every 3.5 s when within 140 px | Nothing readable | Real behaviour, but on a clock, not a reaction. Rework (§5) |
| Sprinter | Very fast, fragile | Auto damage | Fodder |
| Swarmer | Spawns in threes, fragile | Damage that hits a crowd | OK. Becomes the stampede event's body |
| Charger | Telegraphed dash | Sidestep, then punish | **Good** |
| Slammer | Ground slam when you are close | Leave the circle | OK |
| Juggernaut | 135 health | More damage | Sponge. Rework (§5) |
| Shieldbearer | 35% less damage from the front | Flank it | Right idea, too weak to be a question (replaced by the shield, §7) |
| Marksman, Fan Caster, Mortar | Shoot from range | Move, close the distance | **Good** |

About four real asks today (move, dodge, hit a crowd, kite), and every answer is movement or more damage. **No enemy asks for a specific word.** That is the gap this document closes.

## 4a. The three rules that shape every enemy (agreed 17 October 2026)

The reference games' resources (Doom's ammo and weapon swaps, Hades' dash) do not transfer. Ours is **time at the keyboard**, under three rules the code already enforces:

1. **Typing roots you.** Speed is zero while you type (`Player.handle_movement`). Every cast is a commitment to standing still.
2. **Each word gets a slow-motion window.** Typing runs the world at 0.2× (`SpellManager.TIME_SCALE_DURING_TYPING`) for `typing_slowdown_capacity` real seconds (1.5), and the window **resets to full at the start of every cast**. Short words fit inside it; a long keyworded word runs past it, and you finish it rooted at full speed. Telegraphs therefore read twice: a 0.9 s wind-up seen while typing inside the window lasts about 4.5 real seconds; seen past it, 0.9 s.
3. **Spells target the nearest enemy.** You do not aim; you move until the thing you want is nearest. **Moving is aiming**, and moving is time not spent typing.

So every few seconds the player decides: **what to type** (shape and keywords), **how long a word to risk** (inside the window or past it) and **where to stand while typing it**. Each archetype pulls hard on one of those, and no two pull the same way.

| Role | Pulls on | The right play | Ours |
|---|---|---|---|
| **Punisher** | standing still to type | short words, or kill it first | Marksman; the **Imp** (new: chases and hits close, throws a slow orb when you get distance, so running is never an answer) |
| **Telegrapher** | how much of the window is left | finish the word in slow motion, or abandon it and move | Charger, Slammer, Mortar |
| **Rusher** | cast frequency | areas, efficient short words | Pursuer, Sprinter |
| **Heavy** | nearest-target (it soaks your shots) | the long keyworded word, damage over time, walk around it | Juggernaut, Shieldbearer |
| **Swarm** | number of casts | one area | Swarmer |
| **Harasser** | never being nearest | reposition (moving is aiming), or chain, piercing, areas | the **spear goblin** (new: the Skirmisher reworked to sit at mid range and lunge with a telegraph, then back off) |

The best fights put **opposite pulls together**: a heavy with rushers (you want the long word and are not allowed to finish it), a swarm with a telegrapher (the area is right, the charge makes you move mid-word), a harasser behind heavies (auto-target keeps hitting the wall). The director's card pairings (doc 23) are where these combinations come from; pairing cards on purpose is the next director feature worth building.

**Telegraphs are tuned in typing time.** A wind-up about the length of a short word inside the window means "finish a short word or abandon a long one", so every telegraph is a typing decision as well as a dodge.

### Parked idea: kills extend the slow-motion window (documented, not built)

Doom's push-forward combat hands ammo back for kills. The translation here: a kill made while you are typing adds a little to the current word's slow-motion window (fodder a sliver, elites a chunk), so aggression buys time for the long word. Kept because the current rule, a full window on every cast, is what makes casting feel free and is staying. The idea only adds to it and never takes the free window away. Revisit when tuning long keyworded words.

## 4b. Roster consolidation (proposed, not built)

- **Sprinter** is a Pursuer with QUICK, a word that already exists: fold it in.
- **Flanker** is a director formation (pursuers sent in as a pincer pair), not its own type.
- **Skirmisher** becomes the spear goblin (harasser). **Built 0.3.4-dev.20** (`encounters.json` `skirmisher.lunge`).
- **Imp** is added (punisher that cannot be escaped). **Built 0.3.4-dev.20** (`encounters.json` `imp.orb`), on placeholder slime art.
- **Juggernaut** gets an attack shape (a belly-bounce shockwave) or is cut.

## 5. Proposed core roster

Each row is one archetype. "Answer" is the best response; everything else still works, slower.

| Archetype | Threat | Answer | What the answer does | Telegraph / read |
|---|---|---|---|---|
| **Pursuer** (fodder) | Walks at you in numbers | Anything | Kills burning → drops a small heal (fodder gives back) | Plain silhouette, the baseline |
| **Flanker** | Comes in **pairs from both sides** at once, a pincer, so you cannot face both | Areas around you (Frost Nova, RINGED, orbits), REPULSING | One cast clears both sides | Arrives as a visible pair; side markers at the screen edge |
| **Skirmisher** | **Hit and run**: winds up, darts in, strikes, retreats out of range | Punish the commit: QUICK, traps where it retreats, chill stops the dart | Caught mid-retreat it is stunned briefly | Crouch before the dart; retreats along a readable arc |
| **Charger** | Telegraphed dash | Sidestep; chill or shock during windup cancels it | Cancelled charge leaves it dazed and open | Existing windup line |
| **Slammer** | Ground slam near you | Keep distance; PULLING into its own slam | Pulled into its slam, it takes its own hit | Existing slam circle |
| **Shieldbearer** | A front shield with its own health; 20% bleeds through; breaks for good with a stagger (built) | HOMING around the shield, areas, traps, flanking | The right answer bypasses the shield entirely | Big shield facing you |
| **Juggernaut** | Armour plates: heavy damage reduction until broken | BIG/MASSIVE or Earth-beating hits strip plates | Stripped, it is an ordinary big target | Plates visibly crack and fall off |
| **Reflector** | Sends your projectiles back | Beams, areas, traps (non-projectiles) | Avoids feeding it; areas break its mirror | Shimmering mirror face |
| **Burrower** | Untargetable underground, surfaces under you | Ground traps and fields (Rune Trap, Cinder Field), PULLING | Trap pops it out stunned | Moving dirt trail; surfacing ring |
| **Splitter** | Splits into smaller copies on death | Burn and areas; EXPLODING finishes the pieces | Burning splitters split into nothing | Visible seam down its body |
| ~~Mender~~ (cut, §7) | Heals or shields nearby enemies | PIERCING or HUNTING through the crowd | Killing it drops every shield it made | Glowing tether lines to the enemies it protects |
| **Flyer** | Ignores ground fields and traps | Projectiles, HOMING | Shot down, it falls and becomes ground fodder | Shadow on the ground beneath it |
| **Shooters** (Marksman, Fan, Mortar) | Ranged fire | Close in, LINED or beams down their lane | Interrupted shot (shock) is lost | Existing aim lines and mortar marks |
| **Element-armoured variants** | Any archetype with an element: takes almost nothing from its own element | Type the element that beats it (type cycle) | Weak element hits double and stagger | Element colour and the word above it, like elites |

Elites remain a layer on top: any archetype plus one word.

## 6. Encounter composition

A good fight mixes three layers: **fodder** (feeds you), **specialists** (each asks its question) and occasionally **one priority target**. Tension comes from conflicting answers: a Shieldbearer wall (wants HOMING) guarding a Mender (wants PIERCING) while Flankers pincer you (want an area). The director's attack-slot limit (doc 20 §3.3) and the three-questions rule keep it readable.

Set pieces keep the run moving between questions:

- **Stampede**: a band of swarmers crosses the screen through the centre, ignoring you; dodge it or blast it for free XP. Early (around 1:00) and repeated later.
- **Flood**: Aditya's favourite Vampire Survivors moment, around ten minutes into the first level, when enemies pour in from every edge of the screen at once, far more than you can imagine. Weak fodder in overwhelming numbers; the answer is areas, rings and orbits, and surviving it feels like power.
- **Ring**: slow enemies spawning in a circle around you and closing in, answered by RINGED, REPULSING or a breakout.

**The flood needs the enemy runtime work first.** Measured 16 October 2026 on Aditya's M4 Pro (headless, swarmers, physics time per frame): 100 enemies 2.6 ms, 200 enemies 11.9 ms, 400 enemies 21.6 ms, 800 enemies 39.1 ms. The frame budget at 60 fps is 16.7 ms, so today's enemies top out around 250 on screen, and the run caps them at 160 (`maximum_enemies`). A real flood is several hundred, which is the batched enemy runtime in [doc 20](20-game-systems-architecture.md) §3.4. The stampede fits within today's limits. Update, 0.3.4-dev.1 (same day): crowd optimizations halved the cost (`tools/probe_enemy_load.gd`, one physics step with enemies closed in: 400 enemies 6.4 ms, 500 enemies 9.1 ms), so about 500 fit in the frame before rendering; a flood of several hundred is now plausible once rendering is measured and `maximum_enemies` is raised for it.

## 7. Decisions so far

- 16 October 2026: the Shieldbearer is not immune from the front; its front reduction becomes stronger than 35% and stays a soft counter. **Superseded the same day (built, 0.3.4-dev.16):** the shield is a block with its own health, not a resistance. Hits inside the front arc (120°) put 80% into the shield and 20% into the body; at zero it shatters, the Shieldbearer staggers for 1.5 s, and the shield never comes back (no regeneration). Back and side hits, area blasts centred behind it, and damage over time (burn, bleed, poison: ticks have no origin) skip it. Numbers: `encounters.json` `shieldbearer.shield`.
- 16 October 2026: element affinity: a monster is immune to its own element's status, not its element (a FIERY elite cannot burn but a fireball still hits it, through the type chart). Built for elites, the only monsters with elements today (`statuses.json` `_rules.own_element_immune`).
- 16 October 2026: no Mender. A monster that only heals is a dull enemy; healing belongs to the LEECHING word on an elite.
- 17 October 2026: the six archetypes of §4a (punisher, telegrapher, rusher, heavy, swarm, harasser) are the roster's roles, judged against the three rules (typing roots you, a fresh slow-motion window every cast, nearest-target). The per-cast slow-motion window stays as it is.
- 16 October 2026: no element-armoured base variants yet. There is one level; element variants wait for more levels and realms.
- 16 October 2026: Flanker (pincer pairs) and Skirmisher (hit and run) are separate archetypes from the Pursuer, each with its own answer.
- 16 October 2026: set pieces are wanted to keep the run moving: the stampede, and a Vampire Survivors–style flood around ten minutes in.

Each archetype becomes a director card (doc 23): a cost, a group size and an unlock time.

## 8. Open questions for Aditya

1. Soft counters (right answer about three times faster, recommended) or some hard counters (only the answer works)?
2. Should the HUD ever name the answer (a hint on first meeting, bestiary entry), or is discovery the point?
3. Which six to eight archetypes come first in 0.5? Proposed: Flanker and Skirmisher reworks, Juggernaut plates, Burrower, plus the stampede event (Shieldbearer shield built; Mender and element variants cut or deferred, §7).
4. Does fodder giving back (burning kills drop heals) belong in 0.5 or with the pickup work?
