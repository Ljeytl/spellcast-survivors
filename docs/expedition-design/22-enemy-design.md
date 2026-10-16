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
| Shieldbearer | 35% less damage from the front | Flank it | Right idea, too weak to be a question |
| Marksman, Fan Caster, Mortar | Shoot from range | Move, close the distance | **Good** |

About four real asks today (move, dodge, hit a crowd, kite), and every answer is movement or more damage. **No enemy asks for a specific word.** That is the gap this document closes.

## 5. Proposed core roster

Each row is one archetype. "Answer" is the best response; everything else still works, slower.

| Archetype | Threat | Answer | What the answer does | Telegraph / read |
|---|---|---|---|---|
| **Pursuer** (fodder) | Walks at you in numbers | Anything | Kills burning → drops a small heal (fodder gives back) | Plain silhouette, the baseline |
| **Flanker** | Comes in **pairs from both sides** at once, a pincer, so you cannot face both | Areas around you (Frost Nova, RINGED, orbits), REPULSING | One cast clears both sides | Arrives as a visible pair; side markers at the screen edge |
| **Skirmisher** | **Hit and run**: winds up, darts in, strikes, retreats out of range | Punish the commit: QUICK, traps where it retreats, chill stops the dart | Caught mid-retreat it is stunned briefly | Crouch before the dart; retreats along a readable arc |
| **Charger** | Telegraphed dash | Sidestep; chill or shock during windup cancels it | Cancelled charge leaves it dazed and open | Existing windup line |
| **Slammer** | Ground slam near you | Keep distance; PULLING into its own slam | Pulled into its slam, it takes its own hit | Existing slam circle |
| **Shieldbearer** | Heavy damage reduction from the front (stronger than today's 35%, not immunity; tunable) | HOMING around the shield, areas, traps, flanking | The right answer bypasses the shield entirely | Big shield facing you |
| **Juggernaut** | Armour plates: heavy damage reduction until broken | BIG/MASSIVE or Earth-beating hits strip plates | Stripped, it is an ordinary big target | Plates visibly crack and fall off |
| **Reflector** | Sends your projectiles back | Beams, areas, traps (non-projectiles) | Avoids feeding it; areas break its mirror | Shimmering mirror face |
| **Burrower** | Untargetable underground, surfaces under you | Ground traps and fields (Rune Trap, Cinder Field), PULLING | Trap pops it out stunned | Moving dirt trail; surfacing ring |
| **Splitter** | Splits into smaller copies on death | Burn and areas; EXPLODING finishes the pieces | Burning splitters split into nothing | Visible seam down its body |
| **Mender** (priority) | Heals or shields nearby enemies | PIERCING or HUNTING through the crowd | Killing it drops every shield it made | Glowing tether lines to the enemies it protects |
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

**The flood needs the enemy runtime work first.** Measured 16 October 2026 on Aditya's M4 Pro (headless, swarmers, physics time per frame): 100 enemies 2.6 ms, 200 enemies 11.9 ms, 400 enemies 21.6 ms, 800 enemies 39.1 ms. The frame budget at 60 fps is 16.7 ms, so today's enemies top out around 250 on screen, and the run caps them at 160 (`maximum_enemies`). A real flood is several hundred, which is the batched enemy runtime in [doc 20](20-game-systems-architecture.md) §3.4. The stampede fits within today's limits.

## 7. Decisions so far

- 16 October 2026: the Shieldbearer is not immune from the front; its front reduction becomes stronger than 35% and stays a soft counter.
- 16 October 2026: Flanker (pincer pairs) and Skirmisher (hit and run) are separate archetypes from the Pursuer, each with its own answer.
- 16 October 2026: set pieces are wanted to keep the run moving: the stampede, and a Vampire Survivors–style flood around ten minutes in.

## 8. Open questions for Aditya

1. Soft counters (right answer about three times faster, recommended) or some hard counters (only the answer works)?
2. Should the HUD ever name the answer (a hint on first meeting, bestiary entry), or is discovery the point?
3. Which six to eight archetypes come first in 0.5? Proposed: Flanker and Skirmisher reworks, Shieldbearer immune front, Juggernaut plates, Mender, Burrower, element-armoured variants, plus the stampede event.
4. Does fodder giving back (burning kills drop heals) belong in 0.5 or with the pickup work?
