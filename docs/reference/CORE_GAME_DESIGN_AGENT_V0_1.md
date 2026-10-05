# SPELLCAST SURVIVORS
## Core Game Design Specification — v0.1

**Status:** Working design  
**Run length:** ~20 minutes  
**Equipped spells:** Maximum 5  
**Primary design goal:** The player should win because they understand their build and manipulate enemy behavior—not because they happened to bring the one spell the game required.

---

# 1. THE GAME FANTASY

You are a spellcaster trapped inside an escalating magical assault.

The game starts almost comfortably. You can read the battlefield, type spells, learn the rhythm, and experiment.

Then the game begins layering problems:

- enemies that chase,
- enemies that intercept,
- enemies that force movement,
- enemies that deny space,
- enemies that attack from range,
- enemies that protect other enemies,
- bosses that combine several of those pressures.

The player's power curve escalates at roughly the same time.

At minute 1, the player is casting a spell.

At minute 10, the player has a **build**.

At minute 18, the player should feel like they have created something borderline ridiculous.

That transformation is a major part of the fantasy.

---

# 2. CORE DESIGN PILLARS

## 2.1 Builds, not counters

Enemies create problems.

Spells create tools.

There should almost never be:

> “This enemy requires Spell X.”

Instead:

> “This enemy makes Spell X particularly useful.”

A five-spell build should have strengths and weaknesses, but the player's movement, targeting, positioning, timing, spell ordering, and typing skill should allow them to work around those weaknesses.

---

## 2.2 Spell behavior matters more than element

Fire, ice, poison, lightning, arcane, etc. define fantasy.

The important mechanical distinctions are:

- projectile
- burst
- piercing
- chaining
- lingering
- damage over time
- knockback
- pulling
- slowing
- shielding
- healing
- delayed attack
- channeling
- mobility

A Fireball and Frost Nova may both solve groups, but they should solve them differently.

---

# 3. COMPLETE RUN STRUCTURE

The run uses escalating **pressure phases**, rather than simply increasing enemy HP every minute.

## Phase 1 — Learn
### 0:00–3:00

Player feeling:

> “Okay. I understand this.”

Enemy composition:

- Pursuer
- occasional Sprinter

Enemy count target:

**6–14 active**

Primary goal:

Teach:

- movement
- typing
- spell cooldowns
- XP collection
- level-up system

First level-up target:

**15–20 seconds**

The existing simulation reaching the first upgrade around 17 seconds is almost exactly where I would want this.

---

# Phase 2 — Position
### 3:00–5:00

Introduce:

- Flanker
- greater Sprinter density

Enemy count:

**12–20**

The battlefield now asks:

> “Where should I move?”

instead of simply:

> “Can I kill enemies?”

---

# Phase 3 — React
### 5:00–8:00

Introduce:

- Charger
- Skirmisher

Boss #1:

**5:00**

Player starts needing:

- quick casts
- emergency control
- target priority

Target active enemies:

**18–28**

---

# Phase 4 — Manage Space
### 8:00–10:00

Introduce:

- Juggernaut
- Shieldbearer
- occasional Slammer

Now large enemies begin creating moving walls.

Player feeling:

> “I can't just walk wherever I want anymore.”

Target:

**22–35 active enemies**

---

# Phase 5 — Battlefield Awareness
### 10:00–12:00

Boss #2:

**10:00**

Introduce ranged family:

- Marksman
- Fan Caster
- Mortar

Never introduce all three simultaneously.

Suggested order:

10:00 — Marksman  
10:45 — Fan Caster  
11:30 — Mortar

Player must now watch:

- nearby melee enemies
- firing lines
- ground indicators
- escape lanes

Target:

**28–42 active enemies**

---

# Phase 6 — Combined Pressure
### 12:00–15:00

The game stops introducing basic concepts.

Instead, it combines them.

Example encounter:

- Juggernaut blocks escape route
- Marksman lines up shot
- Sprinters close distance
- Flankers approach from side

The difficulty now comes from **interactions between enemies**.

Target:

**35–55 active enemies**

Elite chance begins.

---

# Phase 7 — Build Test
### 15:00–18:00

Boss #3:

**15:00**

Player should now have approximately:

- 4–5 spells
- several upgraded spells
- one significant synergy
- potentially one maxed spell

Enemy target:

**45–65**

Elite chance increases.

---

# Phase 8 — Power Fantasy + Chaos
### 18:00–20:00

Enemy combinations become aggressive.

Player should also be extremely powerful.

This is important:

Late game should not simply feel harder.

It should feel:

> **more insane on both sides.**

The screen may contain:

**55–80 enemies**

depending on performance limits.

---

# Final Event
### 20:00

Recommended rule:

**Normal enemy spawning stops.**

The final boss enters.

Enemies already alive remain.

Victory happens when:

**the final boss and remaining elite/boss enemies are defeated.**

This produces a much better ending than simply displaying WIN at 20:00.

---

# 4. DIFFICULTY FORMULA

Do NOT scale every stat equally.

That produces boring difficulty.

Use four independent curves.

## Enemy health

For minute `m`:

`HP Multiplier = 1 + 0.035m + 0.003m²`

Approximate:

| Minute | HP |
|---|---:|
| 0 | 100% |
| 5 | 126% |
| 10 | 165% |
| 15 | 220% |
| 20 | 290% |

---

## Enemy damage

`Damage Multiplier = 1 + 0.025m + 0.0015m²`

| Minute | Damage |
|---|---:|
| 0 | 100% |
| 5 | 116% |
| 10 | 140% |
| 15 | 171% |
| 20 | 210% |

Damage intentionally grows slower than HP.

---

## Enemy movement speed

Movement speed should scale VERY LITTLE.

Suggested:

`Speed Multiplier = 1 + 0.005m`

At minute 20:

**110% speed**

Why?

If movement speed scales aggressively, telegraphed attacks eventually become impossible rather than difficult.

---

# 5. SPAWN BUDGET

Instead of saying:

> spawn 25 enemies

assign enemies a **spawn cost**.

Example:

| Enemy | Cost |
|---|---:|
| Swarmer | 0.35 |
| Pursuer | 1 |
| Sprinter | 1 |
| Flanker | 1.3 |
| Skirmisher | 1.4 |
| Charger | 1.7 |
| Marksman | 2 |
| Fan Caster | 2.2 |
| Mortar | 2.4 |
| Shieldbearer | 3 |
| Slammer | 3.5 |
| Juggernaut | 4 |

Every few seconds the Director receives points.

Example:

### Minute 2

Budget:

**7**

Could spawn:

5 Pursuers + 2 Sprinters.

### Minute 12

Budget:

**22**

Could spawn:

8 Pursuers  
4 Swarmers  
2 Chargers  
1 Juggernaut  
2 Marksmen

That produces vastly more encounter variety than fixed waves.

---

# 6. ENEMY ROSTER

## GRUNT FAMILY

Medium speed.

Medium health.

Primary purpose:

**shape movement.**

---

## Pursuer

**Role:** Baseline enemy

HP: 20  
Move speed: 100%  
Damage: 8  
Spawn cost: 1

Behavior:

Walk directly toward player.

Nothing clever.

It exists so other enemies can be clever.

---

## Flanker

HP: 24  
Speed: 95%  
Damage: 9  
Cost: 1.3

Behavior:

Predicts player movement.

Targets a point approximately:

**1.5 seconds ahead of current movement direction.**

It should NOT perfectly predict movement.

Otherwise it feels psychic.

---

## Skirmisher

HP: 22  
Speed: 115%  
Damage: 8  
Cost: 1.4

Pattern:

1. Approach
2. Stop around medium distance
3. Retreat
4. Re-enter from new angle

Creates distraction.

---

# RUNNER FAMILY

Fast.

Fragile.

Creates urgency.

---

## Sprinter

HP: 10  
Speed: 165%  
Damage: 6  
Cost: 1

Usually dies from one early-game attack.

Main purpose:

interrupt concentration.

---

## Charger

HP: 18  
Speed normally: 80%

Charge speed:

**260%**

Damage:

14

Attack sequence:

1. Stop
2. Face player
3. 0.65 sec warning
4. charge
5. 0.8 sec recovery

Charge should be dodgeable.

Missing creates a punish window.

---

## Swarmer

HP: 6  
Speed: 135%  
Damage: 3  
Spawn cost: 0.35

Spawn groups:

**4–12**

Individual enemy is nearly irrelevant.

The group is the mechanic.

---

# BRUTE FAMILY

Slow.

Large.

Controls space.

---

## Juggernaut

HP: 80  
Speed: 55%  
Damage: 18  
Cost: 4

Large collision body.

The Juggernaut's real weapon is not damage.

It is:

**being in the way.**

---

## Shieldbearer

HP: 60  
Speed: 70%  
Damage: 11

Front damage reduction:

**60%**

Side:

normal

Rear:

normal

Important:

This should never become elemental resistance.

The player can:

- move behind it
- use area damage
- pierce through nearby enemies
- overpower the shield

---

## Slammer

HP: 65

Attack:

1. Raise weapon/body
2. Ground circle appears
3. 0.9 sec delay
4. slam
5. shockwave

Damage:

20 center  
12 outer radius

Cooldown:

4.5 sec

---

# SHOOTER FAMILY

Ranged enemies should generally stay behind melee enemies.

---

## Marksman

HP: 30

Attack range:

long

Sequence:

1. red targeting line
2. 0.85 sec windup
3. projectile

Projectile should be visible enough to dodge.

---

## Fan Caster

HP: 36

Attack:

5 projectiles

Pattern:

wide fan

There MUST be gaps.

Player should think:

> “I can move through this.”

---

## Mortar

HP: 40

Attack:

1. choose predicted player location
2. ground indicator
3. 1.25 sec delay
4. explosion

Mortars punish stationary casting.

---

# 7. ELITE SYSTEM

After minute 12:

Enemies can become Elite.

Elite rate:

12–15 min: 3%  
15–18 min: 6%  
18–20 min: 10%

Elite modifiers include:

## Frenzied

+30% speed  
+20% attack frequency

## Giant

+80% HP  
+25% size  
+20% knockback resistance

## Volatile

Explodes on death.

Clearly indicated visually.

## Arcane

Periodically shields nearby enemies.

## Vampiric

Heals slightly when dealing damage.

Enemies should receive:

**maximum one modifier normally.**

Two-modifier elites can appear after 18:00.

---

# 8. BOSSES

Bosses:

5:00  
10:00  
15:00  
20:00

Bosses should NOT simply be giant enemies.

Each boss should test a concept introduced during that phase.

---

# Boss 1 — The Hunter

Tests:

movement.

Mechanics:

- pursuit
- short charge
- cone attack

Expected TTK:

25–35 sec

---

# Boss 2 — The Warlock

Tests:

battlefield awareness.

Mechanics:

- ranged bolts
- summoning
- ground zones

---

# Boss 3 — The Colossus

Tests:

space management.

Mechanics:

- huge body
- slam
- moving shockwave
- summoned shieldbearers

---

# Final Boss — The Archmage

Tests:

everything.

Three phases.

Phase 1:

projectiles.

Phase 2:

arena zones.

Phase 3:

summons + aggressive attacks.

Target fight:

60–90 seconds.

---

# 9. PLAYER BASE STATISTICS

Example baseline:

HP: 100

Movement speed:

5.0 units/sec

Passive attack damage:

10

Pickup radius:

2.5 units

Crit chance:

5%

Crit multiplier:

150%

Spell power:

100%

Cooldown modifier:

100%

Cast-speed modifier:

100%

---

# 10. BASE CHARACTERS

Characters should influence a build without locking it.

Every character can still acquire every spell.

---

## The Apprentice

Starter:

Magic Missile

Trait:

+8% XP gain

Purpose:

default character.

---

## Ember

Starter:

Firebolt

Trait:

+8% area radius

Supports many builds, not merely Fire.

---

## Tempest

Starter:

Chain Lightning

Trait:

+7% cast speed

---

## Warden

Starter:

Ice Shard

Trait:

+10% status duration

---

## Wanderer

Starter:

random offensive spell

Trait:

+5% movement speed

Starts with one additional reroll.

---

# 11. LEVELING SYSTEM

Enemies drop Essence.

Suggested values:

Swarmer: 0.4  
Pursuer: 1  
Runner: 1.2  
Grunt variant: 1.5  
Shooter: 3  
Brute: 5  
Elite: ×2  
Boss: major XP orb

---

# XP CURVE

Recommended approximate leveling:

Level 2:

15–20 sec

Level 5:

2 min

Level 10:

5–6 min

Level 15:

9–10 min

Level 20:

14–15 min

Level 25:

around 20 min

A typical run therefore produces approximately:

**20–28 level decisions.**

---

# 12. LEVEL-UP SCREEN

Each level:

Player receives **3 choices**.

Choices can include:

- new spell
- upgrade existing spell
- passive modifier
- utility
- rare transformation

If fewer than 5 spells equipped:

At least one offered card should have an elevated chance of being a new spell.

Once five slots are filled:

New spells stop appearing unless the player has a Replace effect.

---

# REROLL

Initial:

1 reroll/run.

Allows completely new choices.

---

# BANISH

Rare upgrade.

Remove one spell/passive from future rolls.

---

# SKIP

Player may skip.

Skipping grants:

**small permanent XP bonus for the run.**

Example:

+3% XP.

Creates an interesting decision.

---

# 13. SPELL DESIGN

Twenty initial spells.

Five spell slots.

Spells are organized by **theme**, not mechanical requirement.

---

# FIRE

## Firebolt

Role:

precision / fast casting

Base:

20 damage

Cooldown:

0.55 sec

Small projectile.

Upgrade ideas:

R2:
+25% damage

R3:
pierces one enemy

R4 specialization:

### Rapid Flame

-25% cooldown  
-15% damage

OR

### Heavy Bolt

+60% damage  
+20% projectile size

R5:

Burn applies for 2 sec.

R6 capstone:

Every fifth Firebolt becomes a triple bolt.

---

## Fireball

Damage:

35 direct

Explosion:

25

Radius:

2.4m

Cooldown:

2.3 sec

R3:

Explosion radius +20%.

R4:

### Cluster

splits into 3 smaller explosions

OR

### Inferno

leaves burning ground

R6:

Kills inside the explosion can trigger secondary mini-explosions.

---

## Flame Wall

Duration:

5 sec

Damage tick:

8 every 0.5 sec

Cooldown:

7 sec

Player places directional wall.

Upgrade routes:

longer/wider

OR

shorter/higher damage.

Capstone:

enemies burning inside wall receive stacking vulnerability to the wall itself.

Not globally.

---

## Meteor Shower

Cast commitment:

long.

Delay:

1.5 sec

Duration:

4 sec

Area:

large

Damage:

22 per meteor

Meteor locations partly random, partly weighted toward enemies.

Specialization:

more small meteors

OR

fewer giant meteors.

---

# FROST

## Ice Shard

Fast projectile.

Damage:

16

Pierce:

2 targets

Applies:

15% slow for 1.5 sec.

Specializations:

greater pierce

OR

shattering damage.

---

## Frost Nova

Centered on player.

Damage:

18

Slow:

50%

Duration:

2 sec

Cooldown:

7 sec

Excellent emergency spell.

Capstone:

enemies already slowed become briefly frozen.

---

## Glacial Spear

Long cast.

High precision.

Damage:

75

Pierces all standard enemies.

Specialization:

boss damage

OR

wide projectile.

---

## Blizzard

Large lingering zone.

Low individual damage.

Strong sustained control.

Duration:

6 sec.

Enemies build Chill while inside.

---

# STORM

## Chain Lightning

Damage:

18

Jumps:

4

Jump range:

3m

Damage loses:

10% per jump.

Upgrade branches:

more jumps

OR

higher first-target damage.

---

## Thunder Spear

Damage:

55

Fast straight piercing projectile.

Longer cooldown than Firebolt.

Rewards lining enemies up.

---

## Static Field

Creates zone around player.

Enemies periodically receive:

8 damage

Small stagger.

Duration:

5 sec.

Excellent against swarm pressure.

---

## Tempest

Large delayed storm zone.

Random targeted lightning.

Prioritizes enemies.

Capstone:

lightning strikes occasionally chain.

---

# ARCANE

## Magic Missile

Reliable auto-targeting projectile.

Damage:

14

Projectiles:

2

Designed as:

easy-to-use baseline spell.

Upgrade:

more missiles

OR

fewer stronger missiles.

---

## Arcane Orb

Slow-moving projectile.

Repeatedly damages nearby enemies.

Acts like a moving area zone.

---

## Gravity Well

Damage:

low.

Pulls enemies inward.

Duration:

3 sec.

Powerful because of synergy.

Not because of raw damage.

---

## Arcane Shield

Absorbs:

25 damage.

Cooldown:

10 sec.

Can eventually gain:

explosion on break

OR

brief cooldown acceleration while active.

---

# NATURE / CORRUPTION

## Thorn Volley

Five-projectile spread.

Excellent close-range burst.

Can specialize into:

narrow piercing cone

OR

wide crowd cone.

---

## Venom Mark

Targeted DoT.

Initial:

6 damage/sec

Duration:

6 sec.

Repeated application stacks to 3.

Specialization:

higher single target stacking

OR

spread one stack on death.

---

## Spore Bloom

Places delayed zone.

After 1 sec:

explodes into lingering spores.

Combines delayed burst + area denial.

---

## Regrowth

Restores:

2 HP/sec

for 5 sec.

Long cooldown.

Specialization:

larger heal

OR

smaller heal plus temporary movement speed.

---

# 14. SPELL RANK PHILOSOPHY

Every spell has six ranks.

Do NOT make six ranks of:

> +10% damage

Use:

## Rank 1

Spell unlocked.

## Rank 2

Numerical improvement.

## Rank 3

Mechanical improvement.

## Rank 4

Choose specialization A or B.

This decision is permanent for the run.

## Rank 5

Strengthen chosen specialization.

## Rank 6

Capstone.

Capstone should visibly change the spell.

The player should be able to look at the screen and know:

> “That spell is maxed.”

---

# 15. SPELL POWER SCALING

Global formula:

`Final Damage = Base Damage × Rank Modifier × Spell Power × Situational Modifier`

Avoid excessive multiplicative bonuses.

Most upgrades should add together before final multiplication.

Otherwise late-game numbers become impossible to balance.

Target damage progression:

Minute 1 player DPS:

**20–35**

Minute 5:

**70–110**

Minute 10:

**180–300**

Minute 15:

**400–650**

Minute 20:

**800–1,200**

Strong optimized builds may exceed this.

---

# 16. SPELL TAG SYSTEM

This should exist internally even if the player never sees every tag.

Examples:

`PROJECTILE`

`BURST`

`LINGERING`

`DOT`

`CONTROL`

`CHAIN`

`PIERCE`

`PULL`

`SHIELD`

`HEAL`

`DELAYED`

`CHANNEL`

Tags power interactions.

This is much more flexible than elemental recipes.

---

# 17. SYNERGY SYSTEM

Synergies should emerge from mechanics.

Example:

Gravity Well + Meteor Shower.

Gravity Well groups enemies.

Meteor Shower hits groups.

There does NOT need to be a special:

> Gravity Meteor Combo

for that interaction to be satisfying.

However, rare upgrades can recognize tag combinations.

---

# 18. RARE SYNERGY MODIFIERS

Example rare relic:

## Convergence

LINGERING spells become 15% smaller.

Enemies inside them are slowly pulled toward the center.

Suddenly:

Flame Wall  
Blizzard  
Spore Bloom  
Tempest

all interact differently.

---

## Detonation

DOT enemies explode for 15% remaining DoT damage when killed.

---

## Echo Casting

Every fifth spell cast repeats at 40% power.

---

## Overchannel

Long-cast spells deal up to +50% damage based on cast time.

---

## Momentum

Casting three different spells within four seconds grants:

+15% movement speed.

This encourages spell sequencing.

---

# 19. SECRET SPELL EVOLUTIONS

These should be rare discoveries rather than mandatory knowledge.

Require:

- Rank 6 spell
- particular tag combination
- rare catalyst/relic

Example:

## FIREBALL → SUPERNOVA

Requirements:

Rank 6 Fireball  
BURST-enhancing relic

Effect:

Huge explosion.

Creates three delayed secondary detonations.

---

## GRAVITY WELL → SINGULARITY

Requirement:

Rank 6 Gravity Well  
LINGERING catalyst

Pull grows stronger over duration.

Enemies killed near center extend it slightly.

---

## CHAIN LIGHTNING → STORM NETWORK

Requirement:

Rank 6 Chain Lightning  
CHAIN relic

Enemies retain a short-lived electric link.

Subsequent lightning can use linked enemies as jump points.

---

## VENOM MARK → PLAGUE

Requirement:

Rank 6 Venom Mark  
spread modifier

Enemies dying at 3 stacks distribute stacks nearby.

---

The player can discover these organically.

They should NOT be required to beat the game.

---

# 20. INTERACTION EXAMPLES

A few interactions that create player cleverness:

### Gravity Well + Fireball

Group enemies.

Explode group.

---

### Frost Nova + Meteor

Freeze/slow long enough for delayed meteor strike.

---

### Flame Wall + movement

Circle around wall.

Force pursuing enemies through it repeatedly.

---

### Charger + player movement

Bait Charger into a predictable line.

Line enemies behind it.

Cast Thunder Spear.

---

### Shieldbearer + Arcane Orb

Orb moves through/around shield rather than requiring frontal damage.

---

### Juggernaut + Swarmers

Juggernaut becomes mobile terrain.

Player can manipulate the swarm around it.

---

# 21. PASSIVE UPGRADES

Not every level should improve a spell.

Example passives:

## Spell Power

+8% global damage.

Maximum 5 ranks.

---

## Quick Mind

+6% cooldown recovery.

---

## Fleet

+5% movement speed.

---

## Reach

+8% spell radius.

---

## Magnetism

+20% pickup radius.

---

## Vitality

+15 max HP.

---

## Precision

+5% crit.

---

## Focus

Long-cast spells receive +8% damage.

---

# 22. ITEM RARITY

Suggested:

Common — 65%

Rare — 25%

Epic — 8%

Legendary — 2%

Legendary upgrades should mainly alter behavior.

Never simply:

+100% damage.

---

# 23. SECRETS

The world should reward curiosity.

Possible secrets:

## Hidden Rune Circles

Stand on a rune for five seconds while enemies attack.

Complete it:

receive rare upgrade.

---

## Cursed Shrine

Player voluntarily increases difficulty.

Example:

+20% enemy HP.

Reward:

+25% XP and improved rare chance.

---

## Spellbook Event

Occasionally a book appears.

Typing the displayed incantation correctly under pressure gives:

temporary or permanent bonus.

---

## Mimic XP Orb

Very rare giant XP crystal.

Approaching it awakens a miniboss.

---

## Perfect Incantation

Casting X spells without a typing mistake temporarily grants:

+10% cast speed.

Potential hidden achievements can come from this.

---

# 24. BALANCE TARGETS

Normal difficulty should aim for:

### First minute

A new player takes little/no damage if moving.

### 5 minutes

A poor build begins showing weaknesses.

### 10 minutes

Build identity is obvious.

### 15 minutes

Player is powerful but mistakes matter.

### 18 minutes

Screen becomes visually chaotic.

### 20 minutes

Player feels dramatically stronger than minute 1.

---

# BOSS TTK

On-curve general build:

25–40 sec.

Strong specialized build:

15–25 sec.

Weak build:

45–60 sec.

If a normal boss routinely takes 90 sec:

HP is too high.

---

# 25. FAILURE SHOULD FEEL FAIR

Avoid:

- projectiles spawned offscreen with no warning
- attacks under other visual effects
- enemies appearing directly on player
- instant attacks
- excessive movement-speed scaling
- unavoidable overlapping AoE
- required elements

Difficulty should come from decisions.

Not surprise.

---

# 26. ART DIRECTION

The game should prioritize **readability before detail**.

Top-down 3/4 perspective.

Recommended runtime character height:

roughly 48–72 pixels depending on enemy.

---

# FAMILY SILHOUETTES

## Grunts

Medium width.

Readable humanoid silhouette.

---

## Runners

Lean forward.

Narrow shape.

Long limbs.

Immediate impression:

FAST.

---

## Brutes

Wide.

Low center of gravity.

Large shoulders.

Occupy visibly more screen area.

---

## Shooters

Tall silhouette.

Weapon/staff clearly extends from body.

Player should identify ranged enemies before seeing them attack.

---

# 27. ENEMY ASSET SPECIFICATION

Do not use chroma-keyed backgrounds if possible.

Use:

**transparent PNG / alpha channel.**

Each enemy should be exported independently.

Recommended source canvas:

**96 × 96 px**

Brutes:

**128 × 128 px**

---

# Required animation states

Every standard enemy:

### Idle

4–6 frames

### Walk/run

6–8 frames

### Attack windup

3–5 frames

### Attack

4–8 frames

### Hit

2 frames

### Death

6–10 frames

Special enemies also require:

### Charger

charge frames

### Shooter

cast/fire frames

### Slammer

large telegraph frame

### Shieldbearer

block/react animation

---

# Naming convention

Example:

`enemy_grunt_pursuer_idle_01.png`

`enemy_grunt_pursuer_idle_02.png`

`enemy_grunt_pursuer_walk_01.png`

etc.

Recommended sheet:

`enemy_grunt_pursuer_sheet.png`

Metadata:

`enemy_grunt_pursuer.json`

---

# 28. SPRITE PIVOTS

All characters:

pivot approximately at feet.

Normalized:

X = 0.5  
Y = 0.80

Do not bake character shadows into sprites.

Use a runtime ellipse beneath characters.

That keeps shadows consistent and allows transparency.

---

# 29. TELEGRAPH VISUAL LANGUAGE

Danger cues need a consistent grammar.

## Line

incoming projectile/charge.

## Circle

area attack.

## Cone

directional fan.

## Pulsing outline

enemy preparing ability.

## Filling area

time remaining before impact.

Color alone should NOT carry the information.

Shape must communicate threat for accessibility.

---

# 30. SPELL VFX ASSET SPEC

Use transparent assets.

Base atlas:

256 × 256 or 512 × 512.

Effects should usually contain:

8–16 frames.

Separate where useful:

### Core

bright magical center.

### Secondary

particles/sparks/smoke.

### Ground decal

persistent zone.

This allows different blending modes.

---

# Example Fireball assets

`spell_fireball_projectile.png`

`spell_fireball_trail.png`

`spell_fireball_impact_sheet.png`

`spell_fireball_ground_burn_sheet.png`

---

# Example Meteor assets

`spell_meteor_projectile.png`

`spell_meteor_shadow.png`

`spell_meteor_impact_sheet.png`

`spell_meteor_crater.png`

---

# 31. AUDIO SYSTEM

Audio should tell the player what is happening even when the screen becomes crowded.

Do NOT give every enemy equal audio priority.

Important sounds should cut through.

---

# Audio Priority 1

Player damage

Boss attacks

Charger telegraph

Mortar impact warning

Level up

Spell ready/failed cast

---

# Priority 2

Spell impacts

Elite appearance

Shield break

Large kills

---

# Priority 3

Normal enemy attacks

Footsteps

Ambient creature noise

---

# 32. FAMILY AUDIO IDENTITIES

## Grunts

dry footsteps

cloth/leather

low vocal sounds

---

## Runners

fast light footsteps

short high-frequency movement cue

---

## Brutes

heavy low-frequency impacts

armor/stone

very little high-frequency content

---

## Shooters

magical charge tone

distinct windup before projectile

---

# 33. SPELL SOUND CONSTRUCTION

Every important spell should contain:

## Cast cue

what the player did.

## Travel loop

optional.

## Impact

what it hit.

## Tail

magic dissipating.

Example Fireball:

Cast:

short ignition.

Travel:

low flame rush.

Impact:

deep explosive hit.

Tail:

embers and crackling.

---

# 34. MUSIC DIFFICULTY LAYERS

Do not necessarily swap songs every phase.

Use layers.

Base track:

0–5 minutes.

At 5 min:

percussion layer.

10 min:

additional rhythmic layer.

15 min:

high-intensity harmonic layer.

Boss:

boss stem fades in.

18 min:

full arrangement.

This makes escalation feel continuous.

---

# 35. SCREEN DENSITY RULE

The player must always be readable.

Maximum VFX opacity should drop as enemy density rises.

Possible dynamic system:

If active enemy count >50:

reduce secondary particle density by 20%.

If >70:

reduce by 35%.

Never reduce:

attack telegraphs.

---

# 36. GAME DIRECTOR

The Director tracks:

- elapsed time
- enemy count
- player DPS
- player HP
- recent damage taken
- boss alive
- number of ranged enemies
- number of brutes
- recent spawn directions

It should NOT heavily rubber-band the player.

But it can prevent terrible combinations.

Example:

If three Mortars currently exist:

do not spawn another Mortar.

If two Slammers are near player:

delay new Slammer.

This protects readability.

---

# 37. DIFFICULTY MODES

## Apprentice

Enemy HP:

85%

Damage:

75%

Spawn budget:

85%

---

## Standard

100%.

Designed experience.

---

## Archmage

HP:

115%

Damage:

120%

Spawn budget:

120%

Elite rate:

+50%

---

# 38. POST-RUN SUMMARY

Show:

Time survived

Enemies killed

Bosses killed

Damage by spell

Total spell casts

Highest single hit

Damage taken

Typing accuracy

Longest perfect streak

Most-used spell

Most effective synergy

This helps the player understand their build.

---

# 39. BUILD ANALYSIS

Example post-run:

**Fireball**

342,420 damage

31% run damage.

**Gravity Well**

28,431 damage

but enemies pulled:

1,482

This avoids undervaluing utility spells.

---

# 40. METRICS TO LOG DURING DEVELOPMENT

For every run capture:

- level times
- spell acquisition
- spell rank progression
- damage by spell
- kills by spell
- enemy damage source
- enemy survival time
- boss TTK
- player HP over time
- elite count
- average active enemies
- typing accuracy
- death minute

This data will make balancing MUCH easier.

---

# 41. BALANCE TEST MATRIX

Every enemy should be tested against at least:

### Build A

single-target heavy.

### Build B

AoE heavy.

### Build C

DoT heavy.

### Build D

control heavy.

### Build E

mostly random spells.

The encounter passes only if:

all five builds can reasonably succeed.

Some can have advantages.

None should become functionally incapable of progressing.

---

# 42. WHAT THE PLAYER SHOULD FEEL

### 0 minutes

“I understand this.”

### 3 minutes

“Okay, they're moving differently.”

### 5 minutes

“I need to start thinking.”

### 8 minutes

“My build is forming.”

### 10 minutes

“Whoa. This is getting serious.”

### 12 minutes

“I need to manage the whole screen.”

### 15 minutes

“My build is awesome.”

### 18 minutes

“This is absolute chaos.”

### 20 minutes

“LOOK WHAT I BUILT.”

That emotional curve is the game.