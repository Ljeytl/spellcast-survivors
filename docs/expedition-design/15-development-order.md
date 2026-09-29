## Implemented keyword increment

MEGA is now the first keyword: +50% Spell Power and +50% Spell Size for owned manual spells, immediately available in numbered/Space casting. It is explained in the run spellbook. The next step is playtesting its visible impact, then tutorial discovery; additional keywords and permanent unlocks remain future work. See [current composition contract](04-composition.md#current-prototype-mega).

# Development order: evolve the game we have

> **Current development slate:** preserve the playable roguelike and style system. Earth Shield 0.1.36 is implemented and merged. Next build a tutorial introducing meaningful, visibly multiplicative keywords, then preparation/tower/ley-line expeditions. MEGA is implemented as described above; further keyword selection and stacking remain proposals. Keep the friend’s art; 2D, 3D and hybrid art direction are a later exploration.

**28 September 2026 · documentation only · current direction**

The existing game is fun according to the user's playtest. Preserve that foundation and expand it toward **Should Have Joined a Party**: a wizard expressing complex magic through language. It is not a schedule for when a player unlocks vocabulary. Milestones describe changes to the current game, not a fresh build or a requirement to reimplement every spell.

## Current baseline and required change

Source inspected at gameplay baseline `5955a876059af06e571c3861f306072afb881d16`; documentation branch descends from `edc34dcc`. These are implementation observations, not a new operated gameplay pass.

| System today | Evidence | Disposition and next change |
|---|---|---|
| Movement, combat, death and run flow | scripts/Player.gd, scripts/Game.gd | Keep; verify they remain enjoyable after each increment |
| Typed casting and finite per-cast assistance | scripts/SpellManager.gd | Adapt parser to vocabulary and resolved properties; retain input and assistance behavior until an explicit change is tested |
| 16 learnable manual spells and seven enabled combinations | 03-spells.md baseline audit; SpellManager and effect scripts | Keep available in the comparison/current game; migrate shared properties incrementally, not recreate spell content |
| Projectiles, Ice Blast, lightning areas, fields, spirits and infection | scripts/SpellProjectile.gd, scripts/IceBlast.gd, scripts/LightningArea.gd, scripts/BuildSpellEffect.gd | Reuse behavior; expose shared geometry/payload parameters and authoritative events as needed |
| Encounters, enemies and boss rewards | scripts/EncounterDirector.gd, scripts/EncounterEnemy.gd, scripts/BossReward.gd | Configure normal-slime Level 1; adapt guardian trigger/reward when objectives arrive |
| XP, upgrades and run spellbook | scripts/LevelUpScreen.gd, scripts/RunSpellbook.gd | Transition to preparation and vocabulary; progression policy must be reconciled before replacing existing upgrades |
| Collection and interface tooling | scripts/SpellCollection.gd; docs/VISUAL_WORKSHOP.md | Reuse inventory/workshop paths where suitable; inspect persistence before extending permanent knowledge |
| Keycap presentation, existing forest and effects | docs/UI_UX_PASS.md; docs/ART_AND_FEEDBACK_PLAN.md | Replace keyboard-themed presentation with readable inscriptions; retain useful art and effects while direction is explored |
| Tests, bot and exports | tests/; docs/BASELINE_BOT.md | Reuse regression evidence and tooling, rerun relevant checks on each exact candidate; existence is not a current pass |
| General modifier composition, prepared expeditions and ley-line progression | Proposed contracts in this package | New/adapted capabilities; not claimed implemented by these documents |

## Ordered playable increments

| Milestone | Change from today | Concrete scope | Completion evidence |
|---|---|---|---|
| Complete — Earth Shield 0.1.36 | Replace overheal with an active defensive decision | Stack one-hit stone charges; blocked hit preserves combo and sends damaging knockback toward the attacker | Source-aware melee/projectile hits, one charge per hit, visible collision, no combo loss |
| M1 — tutorial and keywords in the current game | Add expression to existing combat | MEGA is implemented across owned manual spells at 1.5× power and size. Next add the short tutorial; Bolt, Ice Blast and Meteor Shower exercise projectile, fan and multi-impact geometry. Existing spells remain available; unsupported words fail clearly | Play current encounters with modified and ordinary casts; size matches collision, no unavailable casts, short spells retain utility, workshop agrees |
| M2 — prepare your spellbook | Add selection/order before entry and activation during a run | Use the existing spell catalog; persistent known vocabulary, prepared bases and derived spells; settle capacity and XP/mana/upgrade roles before replacing old progression | Prepare → enter → activate → cast → return; locked/inactive spells reject; existing combat remains playable |
| M3 — exploration earns knowledge | Add purpose to the existing world | Four ley-line sites with readable challenges and spell/keyword rewards; reuse terrain, enemies and encounter machinery; authored anchors with restrained variation | Travel, attempt, fail/retry, complete, grant once; readable threats and worthwhile rewards |
| M4 — connected expeditions | Connect progression into a complete loop | Permanent knowledge, return to preparation, guardian after four sites, 20-minute extraction, death and save handling | Discover → extract or die under selected retention policy → reopen → prepare new vocabulary → reenter; reward and save integrity |
| M5 — levels and vocabulary expansion | Shape and expand the working loop | Normal-slime first level; introduce later enemy patterns and compatible keywords in tested batches; add genuinely new spells separately from migrating existing ones | Distinct preparations and spell choices matter; no compulsory elemental hard counter; complete level journeys |
| M6 — production and release | Polish a proven expanding game | Accessibility, performance, readable art/audio, packaging and provenance work; add content justified by playtests | Operated packages and representative player evidence, not document/test counts alone |

Earth Shield 0.1.36 is complete. M1 is next with a short playable introduction that teaches Bolt, spell choice and a visibly stronger modified cast. There is no M0 rebuild gate. Inspect relevant existing code as part of M1, then adapt the minimum shared behavior needed. A complete compiler/scheduler/module hierarchy is not a prerequisite to trying Mega Bolt in the actual game. Architecture names in document 10 describe responsibilities, not mandatory new files.

## First level and retained content

**Level 1 starts with normal slimes.** Configure existing grunt and fragile runner behaviors first, then normal bruisers and King Slime as the objective loop arrives. No early fire slimes, elemental resistance puzzle or ranged barrage. This constrains encounters, not the entire development spell inventory.

The small M1 modifier test set is not the shipping starting loadout and does not delete current spells. Existing bases: Bolt, Life, Regeneration, Ice Blast, Earth Shield, Lightning, Meteor Shower, Ember Lance, Plague Seed, Cinder Field, Arcane Orbit, Focus Ray, Rune Trap, Seeker, Firewalk, Cross Blade. Existing enabled combinations: Lightning Bolt, Life Bolt, Meteor Lance, Soul Bloom, Steam Field, Prism Ray, Frost Sigil. Exact current behavior and proposed changes remain separate in document 3.

## Vocabulary expansion and dependencies

| Batch | Candidate words/content | Dependency |
|---|---|---|
| First playable composition | MEGA implemented | Playtest 1.5× power and size, then teach it in the tutorial; further words remain proposals |
| Duration, force and movement | Lasting, Repulsing, Swift, Seeking | Explicit compatible properties; reuse existing duration, knockback and targeting rather than claim they are absent |
| Release structure | Delayed, Charged, Repeating, Duplicating | Clock, cancellation, output ownership and retargeting contracts; duplicating differs from a delayed smaller echo |
| Elements | Fiery, Icy, Venomous, Earthen | Damage type versus status distinction, readable conversion, no useless accepted words |
| New content | Water Jet, Wave, Frost Nova, Thunderwave, Frost Ray, Fire Bolt, Firestorm, Earthquake, Grasping Hand, Moonfall, Mana Storm, Summon Golem (castable word Golem), Yggdrasil | Introduce by play value and compatible components after the loop works; do not delay existing infection or Seeker until these are built |
| Later experiments | Ice Lance/Glacial Lance paired family, base Wall plus elemental synonyms, Super/Omega beyond MEGA, Orbiting/Rotating, Wide/Piercing, Quick Cast, numeric Delay, Earth Wall, Reaping Spirit, alternate characters | Preserve ideas; none is a requirement for the next playable milestone |

Catalog coverage (design entries, not a final independent-base count): Bolt, Life, Ice Blast, Lightning, Regeneration, Earth Shield, Meteor Shower, Ember Lance, Plague Seed, Cinder Field, Arcane Orbit, Focus Ray, Rune Trap, Seeker, Firewalk, Cross Blade, Wave, Water Jet, Frost Nova, Fire Bolt, Firestorm, Earthquake, Thunderwave, Frost Ray, Moonfall, Grasping Hand, Mana Storm, Summon Golem (castable word Golem), Yggdrasil, Lightning Bolt, Life Bolt, Meteor Lance, Soul Bloom, Steam Field, Prism Ray, Frost Sigil. The existing table has 29 base rows plus seven derived rows; desired independent-spell count and family tiers still require reconciliation.

## Presentation track alongside gameplay

The approved direction is wizardry and readable ancient inscriptions, moving away from keycaps and typing-game branding. Norse-inspired angular carving is a visual reference, not a substitute alphabet players must decode. Prototype one casting line over the existing game: inscription appears on input, intensifies with meaningful commitment, releases on cast and fades on correction. Animation details are proposals; text updates immediately and remains readable.

Use plain readable menu text with restrained grimoire/stone ornament. Ordinary controls remain in tutorial/settings; menus need not require typing. The user may supply a layout sketch. A flat-color floor with subtle patches and existing obstacles is a candidate to evaluate from it, not an approved new environment or mandatory asset-generation job. Keep shaders and broad asset replacement later; readability fixes can happen immediately.

## Delivery and decision gates

Track each feature as existing, adapting, new, deferred or needs verification, separately from player acquisition. Retain a reproducible comparison build and grow the actual game in reviewable increments. Do not implement parallel replacement systems by default or remove a working system before its replacement is playable.

Open decisions include XP versus mana terminology and upgrade roles, preparation capacity, automatic Magic Missile, discovery retention, Big infection geometry/kill-through, Soul Bloom healing carrier, Meteor Lance identity and final roster counting. Preserve local working notes; unresolved proposals must not become silent implementation defaults. Existing game fun is user-reported; the expanded loop remains to be validated.

[Validation](11-validation.md) defines evidence obligations, [components](14-spell-system-reference.md) defines property contracts, and [levels](06-levels.md) proposes player-facing content. Those tables do not supersede this incremental development order. Documentation approval does not itself implement gameplay or replace art.

### Tower concept for the preparation and expedition milestones

See the [rotary destination chamber](09-ui-accessibility.md#wizard-tower-rotary-destination-chamber): walkable circular tower room, rotating stained-glass destinations, top-position portal and a large preparation book. Explore a simple blockout when hub work begins; book placement, capacity and 3D versus 2D remain open. Recall returns the wizard automatically at the level deadline (20 minutes by default); level-specific pacing is later tuning. This does not move hub construction ahead of keyword gameplay.
