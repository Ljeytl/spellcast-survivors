# Damage, effects and keywords

**Status:** decided with the user, 14 October 2026 · rev 1 · amends [doc 18](18-spell-system-rewrite.md) §6.1–6.4 and the keyword tables in §9. Where this doc and doc 18 disagree, this doc wins. Engine and data ownership stay as in [doc 19](19-engine-architecture.md) and [doc 20](20-game-systems-architecture.md).

## 1. Every hit has three parts

Every damaging spell answers three questions, from the spell's fantasy (what it is physically made of, and what it does):

| Part | Meaning | Data |
|---|---|---|
| **Physical** (`raw`) | the force of a body: weight, edge, impact | share of each hit |
| **Magical** | the element itself | share of each hit, by element |
| **Effect** | a status or behaviour the hit leaves | optional; most spells have none or one |

Every spell has a split (physical + magical = 100%). Not every spell has an effect. An effect belongs to a spell only when it is that spell's identity.

**The effect takes the shape of the hit.** Whatever an effect is, it follows the part that carries it: a projectile hit leaves it on the enemy or at that point, an area impact leaves it over the area, a field or trail carries it for as long as it lasts. This holds for spells and keywords alike (section 4).

## 2. Effects by element

| Element | Damage over time | Control | Movement | Debuff | Build-up → payoff | Friendly |
|---|---|---|---|---|---|---|
| Arcane | — | transformed (idea) | gravity (idea) | **vulnerable**, in stacks | — | invulnerable, reflect (ideas) |
| Fire | **burn** | — | — | — | — | — |
| Water/Ice | — | **chill**, slow; frozen | push, pull | — | 5 chill → freeze | — |
| Storm | — | **shock** (mark + stagger); stun | — | — | shock → chain / conduct / grounded | — |
| Earth/Steel | **bleed** | root, stun | knockback | — | bleed → hemorrhage | — |
| Plague/Death | **poison**, infection | — | — | weakened | — | — |
| Life | — | **entangled** → root | pull (idea) | — | — | **healing** (shape follows the hit) |
| No element | bleed via SANGUINE | taunted | Force words | marked | **Overload** (section 3) | ward, leech |

Element reactions stay elemental: Thaw (fire on chill), Shatter (earth on frozen), Toxic Flare (fire on poison), Cleanse (life on poison or weakened), and shock's chain / conduct / grounded.

### 2.1 Arcane: vulnerable stacks

Arcane's one effect is **vulnerable**, built in stacks like chill: each stack +4% damage taken (proposed), up to 5, fading when not refreshed. Arcane is otherwise neutral on the type chart and partly pierces armour.

## 3. Overload is a keyword, not arcane

**Changed:** arcane damage no longer pops damage over time. Overload is an elementless payoff keyword that any spell can carry.

- A hit carrying it lands all the damage over time pending on the enemy (bleed, poison, burn) at once, at a multiplier, and clears them.
- Pending means what has already built up; ramp not yet reached does not count.
- With nothing pending, the hit just deals its own damage.
- Big swing by design. Strength by word length: **RUPTURING 2×, DETONATING 2.5×, OVERLOADING 3×** (starting numbers; bots tune).

## 4. Keywords

### 4.1 Two kinds

1. **Modifiers** add to the shape the spell already has and apply to every damaging part: element words, effect words, healing, Overload, power, size, leech.
2. **Makers** add a new part with its own shape and its own split: EXPLODING (a physical blast on hit), SPLITTING, CHAINING, CASCADING. Each is unique.

They combine on their own: a part a maker adds is a damaging part, so every modifier applies to it. BURNING EXPLODING BOLT burns with both the bolt and the blast; OVERLOADING EXPLODING BOLT pops damage over time across the blast.

A word means the same thing on every spell, so its card can say it in one line. The only per-spell difference is systematic: repeating parts (fields, trails, beams, orbits) apply effects at reduced strength, and healing follows the shape of the hit.

### 4.2 Element words: a spectrum

A word that names what the spell **is made of** adds damage; a word that names what it **does to the target** adds the effect; some do both. Each word carries two numbers in data: damage share and effect strength. Word length scales both.

| Tier | Per letter (proposed) |
|---|---|
| Damage | 5% damage, no effect |
| Both | about 3% damage + effect at half strength |
| Effect | about 1% damage + effect at full strength |

| Element | Damage | Both | Effect |
|---|---|---|---|
| Arcane | ARCANE, MAGICAL | MYSTIC, ELDRITCH, ESOTERIC | RUNIC (vulnerable) |
| Fire | INFERNAL, FIERY | FLAMING, BLAZING, EMBER | BURNING *(new)*, SCORCHING (burn) |
| Water | GLACIAL, ICY | FROSTY | CHILLING *(new)*, FROZEN (chill) |
| Storm | ELECTRIC, STORMY | THUNDERING | SHOCKING (shock) |
| Earth | IRON, EARTHEN | BLADED | SERRATED (bleed) |
| Plague | NECROTIC, DEATHLY | TOXIC | VENOMOUS, POISONOUS (poison) |
| Life | LIVING, VERDANT | — | HEALING *(new)*, BLOOMING (healing); THORNED, OVERGROWN (entangle) |

A word of the spell's own element strengthens that element's effect (BURNING CINDER FIELD burns harder).

### 4.3 Healing follows the hit

HEALING and BLOOMING leave healing in the shape of the hit:

| The hit | The healing |
|---|---|
| projectile | a seed where the enemy was, walked over to collect |
| area impact | a healing circle the size of the impact, for a few seconds |
| field or trail | the ground heals you while you stand in it |
| beam or orbit | small seeds, heavily capped |

Balance is a **healing budget per cast** (word length × spell power), spread over whatever the spell makes. An area spell heals more conveniently, not more in total.

### 4.4 Payoff and effect-on-you words

| Group | Word | Does |
|---|---|---|
| Payoff (no element) | RUPTURING, DETONATING, OVERLOADING | Overload (section 3) |
| Effect on you | WARDING *(was planned)* | a ward absorbs damage for a few seconds; refreshes, does not stack |
| Effect on you | LEECHING *(new)* | heals a share of damage dealt, capped per cast below SANGUINE's cost |
| Sacrifice | SANGUINE | unchanged: −10% health, 2.5× power, half the damage becomes bleed |

Blood magic is a loop: SANGUINE spends health for damage, LEECHING earns it back, OVERLOADING cashes the bleed.

## 5. Spells

Decided so far:

| Spell | Physical / magical | Effect |
|---|---|---|
| Magic Missile | **100 / 0** (balance: the auto-attack is resisted by armour, which pushes typed spells) | none |
| Bolt | 0 / 100 arcane | none (plain mana bolt) |
| Infestation | its infection ticks become **poison** stacks | poison, spreading host to host |

Kept from doc 18 §6.1b: burn on Ember Spear's trail, Cinder Field, Fire Walk and Steam Field; bleed on Cross Blade and Earth Shield; chill on Ice Blast (with its old slow); shock on Lightning.

Open, to go through spell by spell: Meteor Shower (big rock with a short stun, or fiery crater), Focus Ray and Rune Trap (build vulnerable?), Seeker (weakened?), Arcane Orbit, and every combination.
