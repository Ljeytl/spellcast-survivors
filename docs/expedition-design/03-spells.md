Current classification: [consolidated matrix](16-element-family-matrix.md) supersedes historical school/family labels below. Water/Ice and Earth/Metal are merged; Spirit joins Plague/Death; Sun/Moon are combination themes. Nova/Wave and Slice/Whip each share one family. Tsunami and Shrapnel are Blast; Water Jet replaces proposed Frost Ray. Multiple spells per cell are allowed. Runtime unchanged.

Latest idea authority: [29 September element exploration](17-element-spell-ideas.md) and [populated matrix](16-element-family-matrix.md). This preserves proposals and rejections without approving a new runtime roster. Older 36-row campaign recipes below are historical drafts where they conflict with that exploration.

Current Shield rule: [0.1.36 Earth Shield](../releases/0.1.36-earth-shield.md) supersedes earlier absorption-pool proposals. [Element × family matrix](16-element-family-matrix.md) separates implemented spells, user ideas and unselected examples.

Current implementation change: [0.1.35 scaling and combinations](../releases/0.1.35-spell-scaling.md) supersedes older prototype penalties and Soul Bloom leech/carrier proposals. Campaign tuning below remains proposed.

Current roster and behavior are summarized below; numeric 0.1.35 scaling is in its release specification. Earth Shield changes only with the 0.1.36 implementation.

# Spell catalog: current truth, proposed roster, preserved ideas

**Decision precedence:** [Alignment review and open conflicts](13-review-record.md#alignment-review--28-september-2026) supersedes older conflicting proposals below, especially XP/mana, infection/Big and roster counting.

**Development context (28 September):** use [development order](15-development-order.md) for implementation sequencing. Existing gameplay remains the foundation; these target-design tables do not require rebuilding or withholding existing spells. Numeric defaults and unresolved choices remain proposals. Preparation/XP/mana policy and recent spell-identity notes must be reconciled before dependent changes; the first keyword increment retains existing progression.

## Verified prototype baseline

Roster reconciled against `4edb268` and the approved 0.1.36 scope. Historical baseline numeric details below have been replaced by behavior summaries where tuning is maintained in release specs. Source: `data/spells.json`, `scripts/SpellManager.gd`, `scripts/SynergyCatalog.gd`, `scripts/BuildSpellEffect.gd`, `scripts/TacticalSpellEffect.gd`, `scripts/IceBlast.gd`, `scripts/LightningArea.gd`, `scripts/SpellTargeting.gd`, `scripts/SpellGeometry.gd`, `scripts/Player.gd` (paths relative to repository root).

There are 26 JSON entries, but only 16 learnable manual spells, one automatic attack and nine inactive data definitions. Seven enabled combinations live separately; Reaping Spirit is disabled. Old library prose is not runtime evidence. Numbers below are rank 1 before player multipliers; many JSON fields are overridden by runtime code.

| Public name | Current behavior | Status |
|---|---|---|
| Mana Bolt | Automatic homing attack; not the manual Bolt spell | Implemented |
| Bolt | Straight non-homing projectile; visible-target reservations and simultaneous overlapping impacts | Implemented |
| Life | Small immediate heal; global Power scales healing | Implemented |
| Regeneration | Sustained healing; recasts extend one stream; Power and Duration apply | Implemented |
| Ice Blast | Outward cone of contact shards; Size changes bodies/reach and Velocity changes travel | Implemented |
| Earth Shield | Stack one charge per cast; each independently expires after provisional 16 s (Duration scales). One hit consumes one charge, blocks all its damage and preserves combo, then sends a damaging knockback eruption toward that attacker. No overheal, shared lifetime refresh or gameplay charge cap. | Implemented in 0.1.36; see release evidence |
| Lightning | Ground disk, 80 rank-one damage once per enemy; base 0.2 s active window admits late entrants; Duration extends window | Implemented |
| Meteor Shower | Delayed warned impacts; each creates brief damaging aftermath; Duration does not delay impact | Implemented |
| Ember Lance | Piercing projectile; Size changes actual body, Velocity changes travel | Implemented |
| Plague Seed | Spreading infection; visible host transfer and finite orphan spores; no enforced host cap; Size changes spread | Implemented |
| Cinder Field | Persistent damaging area; Size and Duration apply | Implemented |
| Arcane Orbit | Orbiting contact bodies; Size changes bodies/path, Velocity angular speed, Duration lifetime | Implemented |
| Focus Ray | Tracking beam; turns at base 4 radians/s; Velocity improves tracking; Size width, Duration lifetime | Implemented |
| Rune Trap | Persistent until triggered; then brief once-per-target aftermath; Duration does not slow arming | Implemented |
| Seeker | Independent pursuing spirit; distinct target reservations; actual body contacts; max three | Implemented |
| Firewalk | Emits burning ground patches; recast extends emission; Size width, Duration emission and patch lifetime | Implemented |
| Cross Blade | Returning blades; Size and Velocity affect bodies/travel; extra Duration adds stationary afterimage without delaying return | Implemented |
| Lightning Bolt | Bolt + Lightning; rank-one 40 impact plus 80 splash,80 splash radius, 4 bounces; ingredient levels and own rank resolve separately | Enabled bonus |
| Life Bolt | Bolt + Life; 40 impact, 6 healing budget in collectible patch; own ranks alternate added bolts and patch size | Enabled bonus |
| Meteor Lance | Ember Lance + Meteor Shower; 45 impact plus 25 explosion excluding direct victim; ingredient levels scale respective components | Enabled bonus |
| Soul Bloom | Plague Seed + Regeneration; infection kills create finite healing ground patches; spores linger; no leech/player-carrier behavior | Enabled bonus |
| Steam Field | Cinder Field + Ice Blast; damaging slow field; rank-one 12 per tick,5 s,150 radius, 40% slow | Enabled bonus |
| Prism Ray | Focus Ray + Ember Lance; wide piercing beam; base 18 per tick,32 half-width,0.25 radians/s tracking; Velocity does not speed tracking | Enabled bonus |
| Frost Sigil | Rune Trap + Ice Blast; rank-one 60 burst,170 radius,1.2 s arming; own ranks reduce arming to 0.4 s floor | Enabled bonus |

Inactive data: Fire Storm(15 damage/0.2 s, 4 s, radius 350), Time Warp(0.3 × 5 s), Chain Heal(40, 2 chains, 0.7 falloff), Frost Nova(25, radius 300, freeze 2 s), Arcane Missiles(18 × 5), Divine Aura(heal 5/s, 20% reduction, 15 s), Skeleton Warrior(80 HP, 15 damage, 30 s), Arcane Turret(40 HP, 25 damage, 20 s), Flame Elemental(120 HP, 20 damage, 25 s, aura 8). These values are historical drafts, not available spells. Reaping Spirit has draft code but acquisition disabled.

Many base spells use base × (1 + 0.15 × (rank − 1)) × player multiplier; combinations instead use the explicit component coefficients in the 0.1.35 release specification; acquisition does not follow the old JSON unlock-condition drafts. Current Ice Blast range and knockback also scale with rank; its 0.3 slow is a movement multiplier. Plague Seed selects its first host from visible enemies, and its five seconds are per host, not the whole infection chain. Public casting uses Seeker, Firewalk, Cross Blade and Lightning; internal IDs are not free shorter aliases.

## Proposed campaign roster: 36 manual identities

**29 prepared base spells + seven derived slot-free combinations.** This is a full-campaign target, not the first-slice scope. All following numbers are new untested proposals. Source values above remain the baseline evidence. Catalog recovery begins at commit and uses simulation time; effects may outlast recovery. Channels block another channel but permit movement. `r`=radius, `w`=half-width, distances wu. Periodic effects accumulate their stated rate only while a recipient is eligible. Pay accumulated amounts at each interval and a final prorated payment immediately before expiry, exit or interruption. Thus a full 6-second Regeneration pays 24 HP, and 8.4 seconds at 6 HP/s pays 50.4 HP. The final payment cannot target an already dead entity. Discrete attacks such as Earthquake pulses and Cross Blade linger pulses use explicit scheduled counts, including their final scheduled endpoint, with no fractional pulse. See the combat chapter for ordering. Controls are unaffected by damage potency unless specified.

`Geometry family` maps to the composition matrix. Every row includes its player-facing sentence, core numeric contract, visual read and expected use. All spells require active preparation except derived combinations.

| Spell / family / element | Proposed numeric effect and recovery | Fantasy, presentation and tactical purpose |
|---|---|---|
| **Bolt** / projectile / arcane |40 direct; r 7; speed 500; range 480; one contact; recovery 0.45 |“Fire a straight magic bolt.” Bright tapered core, small contact tick. Fast single-target answer; never secretly homes. |
| **Life** / self / life |4 immediate HP; recovery 1.2; cannot exceed maximum HP |“Restore a little health.” One rising green plus only on HP gain. Emergency short heal. |
| **Ice Blast** / fan / ice |9 shards, 90°; 18/unique enemy/generation; r 6; speed 620; range 300; slow 0.5 × 2 s; push 35; recovery 1.8 |“Scatter icy shards to slow nearby enemies.” Visible contacts; pale fan preview never damages. Escape cone. |
| **Lightning** / area / lightning |80 damage once/enemy; r 80; range 360; warning 0.25; active 0.2; recovery 2.5 |“Strike a small area with lightning.” Blue bounded disk then branching flash. Compact immediate cluster deletion. |
| **Regeneration** / personal duration / life |4 HP/s, 0.5 s ticks, 6 s, total 24; recovery 8; refresh-not-stack |“Recover health steadily for a short time.” Loose leaves; green plus only on healing tick. Better total heal than Life, slower rescue. |
| **Earth Shield** / retaliatory protection / earth |Stack one charge per cast; each independently expires after provisional 16 s (Duration scales). One hit consumes one charge, blocks all its damage and preserves combo, then sends a damaging knockback eruption toward that attacker. No overheal, shared lifetime refresh or gameplay charge cap. |“Catch a hit and erupt toward your attacker.” Visible charges and a matching outward cone; see 0.1.36 tuning. |
| **Meteor Shower** / multi-area / fire |4 × 60 damage; impact radius 80; range 420; warnings 0.65 + 0.25 i; area active 0.1; recovery 6 |“Rain meteors across a marked area.” Growing red warnings, descending rocks, ground impact. Formation breaker, not instant panic button. |
| **Ember Lance** / piercing / fire |65 per unique contact; r 9; speed 700; range 650; max 8 contacts; recovery 2.5 |“Pierce a line of enemies with an ember lance.” Long ember tip and restrained trailing sparks. Aimed lane damage. |
| **Plague Seed** / infecting / plague |Seed speed 460, r 7, range 360; 6/0.5 s × 4 s = 48/host; spread 120; max 6 hosts; root lifetime policy under revision; orphan 3 s; recovery 5 |“Infect an enemy and spread spores nearby.” Green-purple seed, lesions, travelling links and visible orphan. Crowded staggered packs. |
| **Cinder Field** / field / fire |12/0.5 s × 5 s = 120/enemy at full dwell; r 95; range 320; warning 0.25; recovery 5 |“Set a patch of ground ablaze.” Connected red-orange ground with bold border. Holds a lane; no candle tiles. |
| **Arcane Orbit** / orbit / arcane |3 bodies r 12, path radius 70; 28 contact, 0.5 s per-target gate; 6 s; angular speed 4 rad/s; recovery 7 |“Orbit with three damaging arcane motes.” Actual motes collide; orbit disk does not. Close defense rewards moving. |
| **Focus Ray** / channel / arcane |16/0.25 s × 2 s = 128; reach 360; w 8; tracking 3 rad/s; first aligned target; recovery 3 |“Track one enemy with a focused beam.” Stable thin bright beam; clear endpoint. Reliable elite damage. |
| **Rune Trap** / trap / arcane |90 once; trigger radius 45/blast radius 90; arm 0.8; placement 140; persistent; max 3 shared; recovery 3 |“Place a lasting rune that bursts on contact.” Visible inscribed ring, armed change. Prepares escape route. |
| **Seeker** / spirit / spirit |22 contact/0.6 s; 6 s; speed 280; body radius 10; leash 400; max 3 bodies; recovery 4 |“Release a spirit that hunts nearby enemies.” Small face silhouette, curling tail and visible target turn. Flexible sustained pursuit. |
| **Firewalk** / trail / fire |10/0.5 s per enemy across all same-root patches; emit 5 s; patch 6 s; r 32; sample interval 0.10 s; recovery 6 |“Leave a lasting trail of burning ground.” Connected burning path; does not damage merely because spell started. Kiting and route control. |
| **Cross Blade** / returning / metal |55 outbound + 55 return per enemy; linger 0.9 with 20/0.3 s; range 280; speed 420; r 14; recovery 3 |“Throw a blade that lingers, then returns.” Readable cross rotates in plane, bright linger hub. Up to 170 on ideal single-target dwell. |
| **Wave** / moving area / water |20 damage; arc 120°; front width 100; travels 180 at 240; push 90; slow 0.7 × 1 s; recovery 2 |“Push enemies back with a wave.” Moving crescent ridge; contact only at advancing front. Creates openings. |
| **Water Jet** / ray / water |Latest user concept: tracking damage/knockback jet; upgrades add jets. Earlier projectile numbers withdrawn pending selected spec. |Ray-family water stream; duration, targeting and exact tuning open. |
| **Frost Nova** / self area / ice |35 damage; r 120; active 0.15; freeze 1 s, bosses slow 0.8 × 1 s; recovery 5 |“Freeze nearby enemies in a sudden burst.” Expanding icy rim over actual disk. Emergency surrounding control. |
| **Fire Bolt** / explosive projectile / fire |35 direct +25 area r 45, direct victim excluded from area; r 8; speed 450; range 450; recovery 1.8 |“Launch a fire bolt that bursts on impact.” Orange core and real local blast. Distinct from Fiery Bolt's 40 direct/no blast. |
| **Firestorm** / field / fire |18/0.5 s × 3 s = 108; r 140; self-centered moving field; warning 0.6; recovery 8 |“Carry a brief firestorm around you.” A moving ring of churning flame surrounds the caster. Broader but shorter and less total damage than the longer stationary Cinder Field; requires staying near threats. |
| **Earthquake** / pulsed self area / earth |4 × 45 at 0.4 s intervals; r 180; first 0.4; push 20 first contact only; recovery 8 |“Shake the ground in four crushing waves.” Cracks and bounded expanding rings, each actual damage beat. Local crowd clear. |
| **Thunderwave** / moving area / lightning |50; arc 160°; front width 160; travels 220 at 320; push 110; recovery 4 |“Blast enemies backward with rolling thunder.” Blue-white advancing ridge; contact flash. Stronger control wave with more commitment. |
| **Frost Ray** / channel / ice |12/0.25 s × 2 s = 96; reach 360; w 10; tracking 2 rad/s; slow 0.5 × 1 s refreshed; first target; recovery 3 |“Chill an enemy with a sustained ray.” Clear icy beam and frost at actual contact. Lower damage than Focus Ray, control utility. |
| **Moonfall** / mixed field / moon |8 damage/0.5 s × 5 s; r 110; range 300; player heal 1/s while inside, max 5/root; warning 0.5; recovery 7 |“Call down a moonlit field that harms foes and gently heals you.” Crescent above purple disk; separate green heal pulses. Weaker healing than Regeneration. |
| **Grasping Hand** / targeted area / spirit |70 burst; r 70; range 300; rootnormal enemies 1.5 s, boss slow 0.8 × 1.5; warning 0.45; recovery 4 |“A spectral hand pins a group of enemies.” Fingers enclose the actual area after warning. Stops a formation, not hidden screen-wide stun. |
| **Mana Storm** / shower / arcane |Latest user concept: moving cloud raining mana or dagger-like magic; earlier stationary pattern numbers unselected. |Shower may use persistent-area components; exact movement and payload open. |
| **Summon Golem** / summon / earth |80 HP; 25 melee/1.2 s; r 18; reach 35; speed 100; acquisition range 240; leash 400; 20 s; max 2 bodies; recovery 15 |“Summon a stone ally to hold nearby enemies.” Heavy stone silhouette and health marker. Blocks foes, not player navigation; enemies may choose golem. |
| **Yggdrasil** / mixed field / life |TreeHP 100; duration 8 s; r 120; player heal 5/s, total 40; rootsdamage 8/s; range 220; warning 0.8; recovery 14 |“Grow a tree of life that heals you and lashes nearby foes.” Tree and visible green boundary; no invulnerable safezone. Major healing commitment; name provisional. |
| **Lightning Bolt** / chain / lightning |60/contact; 2 additional distinct targets; speed 550; r 8; bounce 180; total range 720; recovery 3 |“Send lightning bouncing between enemies.” Visible curved links after contact. Recipe Bolt + Lightning. |
| **Life Bolt** / projectile + pickup / life |30 damage; r 7; speed 450; range 450; impactseed 6 HP over 2 s, expires 10 s, max 6; recovery 2.5 |“Plant a healing seed where your bolt hits.” Seed has plus/leaf marker; approach to collect; no lifesteal. Recipe Bolt + Life. |
| **Meteor Lance** / piercing + burst / fire |45 direct; 25 area r 45 excludes direct victim; max 6 contacts; r 9; speed 650; range 600; recovery 4 |“Pierce enemies with an exploding meteor lance.” Ember point plus distinct contact craters. Recipe Ember Lance + Meteor Shower. |
| **Soul Bloom** / infection + heal / plague-life |4/0.5 s × 4 s; spread 120, max 6 hosts (draft); healing-carrier proposal replaces leech; heal amount, refresh and capacity policies open; recovery 6 (draft) |“Carry a spreading infection that heals you and harms enemies.” Player carrier has distinct healing feedback; enemy infections show damage. Recipe Plague Seed + Regeneration. |
| **Steam Field** / field / water-fire |10/0.5 s × 4 s; r 110; range 320; slow 0.6; warning 0.25; recovery 5 |“Scald and slow enemies in a cloud of steam.” Pale blue-gray boiling boundary; no green pluses. Recipe Cinder Field + Ice Blast. |
| **Prism Ray** / channel / arcane-fire |10/0.25 s × 2 s per target; max 3 aligned; reach 400; w 9; recovery 3.5 |“Burn through a line with a prismatic beam.” Three readable contact nodes; not three arbitrary aim locks. Recipe Focus Ray + Ember Lance. |
| **Frost Sigil** / trap / ice |75 damage; trigger radius 50/blast radius 110; arm 1.2; slow 0.5 × 2 s; persistent; max 3 shared; recovery 4 |“Lay a lasting frost rune that slows a group.” Blue ring, armed center, clear burst. Recipe Rune Trap + Ice Blast. |

## Per-spell mapping exceptions

These complete the generic shape matrix; unsupported combinations must be rejected visibly.

- Lightning Bolt has native guidance and bounces; Seeking is redundant and rejected. Swift applies to travel; Big changes its body, not bounce range. Duplicating adds a second chain with a separate hit ledger.
- Plague Seed and Soul Bloom support Powerful, Swift, Big, Delayed, Lasting, Fiery/Icy/Earthen only. Big mapping is unresolved: prefer an actual visible AoE if the chosen recipe has one; otherwise reject the word. Do not assume spread-radius scaling. Lasting scales host duration; the prior 18 s root ceiling is superseded by the refreshable-host working proposal, with finite host/orphan lifetimes and reinfection/workload policy still to settle. Element conversion changes ticks, not infection identity. No Duplicating/Repeating until spread workload and multiple-root stacking are proven.
- Water Jet now has a user-proposed tracking Ray identity; old projectile-line compatibility must be reconsidered. Wave and Thunderwave support Big, Powerful, Repulsing, Repeating, Delayed, Charged and element conversion, but not Swift until warning/advancing-front timing is tested. Big scales width and travel distance together, unlike Ice Blast.
- Earthquake supports Big, Powerful, Delayed, Charged, element conversion and Repulsing; no Repeat because its native pulses already supply that role in v0.1.
- Mana Storm now has a moving-cloud Shower identity. Earlier Meteor Shower mapping/output caps are withdrawn pending a new component contract.
- Cross Blade supports Big, Powerful, Swift, Delayed, Charged, Duplicating, Repeating, element and Venomous. Duplicating adds a second blade at 0.8 potency; up to 4 bodies with Repeat. Swift shortens flight but not 0.9 s linger. Return expires 4 s after release if owner unavailable; no Seeking.
- Life Bolt supports Bolt's projectile modifiers. Its healing seed is separate secondary budget: potency words scale seed heal, but total seeds heal at most 15 HP/root across all outputs; Repeating/Duplicating share this cap. Big changes projectile, not pickup activation radius. One target cannot receive repeated native immediate contacts from same projectile.
- Meteor Lance supports Ember Lance's mappings; Big changes body and burst; per-projectile contact area excludes direct victim. Added poison is based on actual direct hit only, not burst plus direct double count.
- Moonfall: Lasting increases duration to 7 s, healing still limited to 5 HP/root before potency cap; Powerful scales both damage and heal but max 12.5 HP/root. Repeat shares that root cap. Yggdrasil health does not scale with Powerful; heal cap 100/root, no stacking parallel trees (max 1). Lasting is rejected because its 8-second field is already at the duration ceiling. Its damage ticks and healing use separate recipient filters.
- Focus Ray, Frost Ray and Prism Ray allow Big, Powerful, Lasting, Repulsing, element and Venomous. Lasting 2.8 s channels are intentional extra commitment, first tick 0.25. Venomous applies only on first target contact/root, computed from one tick, not entire future channel. Max one player channel at once.
- Seeker: Big, Powerful, Swift, Lasting, Duplicating and conversion; native seeking makes Seeking redundant. Golem: Big, Powerful, Lasting, Duplicating, conversion; no Swift. Native summons have 20 s duration; the generic 8 s field ceiling does not apply to creatures.

## Player-facing spell naming rule — 2026-09-28

Use magical, evocative words where possible: the name should make the player feel like a wizard, not read like an internal effect identifier. Internal names and mechanical descriptions can be literal. Keep player-facing name, typed incantation and effect description separate; preserve user-supplied names rather than replacing them with geometry labels. **Shillelagh** is confirmed by the user; “moving directional wave of tree roots” describes its behavior. Do not rename it Root Wave. The earlier Shillali/Shalali spellings were voice-transcription artifacts, not deliberate names. This principle does not authorize a bulk rename of existing spells. Spelling reference: [Shillelagh on D&D Beyond](https://www.dndbeyond.com/spells/2249-shillelagh). The user confirmed this reference; the user’s moving-root-wave behavior remains our design, rather than importing the reference spell’s weapon-enchantment mechanic.

### Mystical vocabulary and relic-granted abilities — follow-up

**Source preference confirmed:** names may draw from mythology, folklore or popular fantasy media. Trace a candidate to its earlier source where possible and record the word’s origin separately from a franchise’s specific mechanics. Shillelagh names a traditional Irish cudgel and derives from the place Shillelagh in County Wicklow ([Collins dictionary](https://www.collinsdictionary.com/dictionary/english/shillelagh)); D&D uses that older word for its spell. Yggdrasil comes from Norse mythology. These source notes guide naming, not automatic adoption of another work’s spell rules.


- Prefer a memorable mystical word over a literal effect label when both fit. Mythology and words familiar from other media can inspire the vocabulary; the preference is not limited to wholly invented terms. Meteor Shower is a candidate for a future more evocative name, with no replacement selected or current incantation changed.
- Short reaction actions are an intentional exception. **Dash** should remain quick to invoke; do not force a long elaborate phrase onto an urgent movement action just to satisfy the naming style.
- **Boots of Hermes** is a proposed relic that unlocks Dash. This separates the magical item's identity from the quick ability it grants. “Cast Dash freely” expresses availability after unlocking, not an approved rule for unlimited charges, no cooldown, invulnerability, free spell slots or saved dash charges. Acquisition, relic slots, activation, limits and run persistence remain undecided. Relics granting abilities are a new design possibility, not an implemented equipment system.
- **Yggdrasil / the World Tree** is the player's preferred kind of ultimate-healing fantasy: an evocative, unfamiliar word paired with a powerful visible tree of life. [World Tree spelling reference](https://www.worldhistory.org/image/7513/yggdrasil/). The existing Yggdrasil proposal stays in the catalog; no new healing numbers or duplicate spell are authorized by this naming discussion. Yggdrasil has nine letters; unfamiliar spelling can add typing difficulty even without a longer name. Incantation difficulty supplements length when judging payoff; it does not remove the established expectation that longer spells earn their commitment.
- Keep effect descriptions plain and informative beneath the magical name. Internal identifiers may remain functional. This is a direction for future naming review, not authorization for a bulk rename or aliases that bypass typing commitment.

## Storm aura, roots and wizard movement — 2026-09-28 ideas

**Status: design exploration only; no new spells implemented.** Preserve these as individual spell ideas rather than silently collapsing them into elemental modifiers. The user wants names whose typing commitment fits their utility.

| Idea / working names | Fantasy, geometry and targeting | Intended effect / scaling | Open decisions |
|---|---|---|---|
| Personal storm aura — Static Field, Lightning Shield, Static Shield, Lightning Tower, Channel Lightning, Channel the Storm; suggested name Lightning Crown | A circle around the wizard. Proposed following aura; whether it follows or stays where cast is not explicitly settled. The circle itself does no contact damage. Track each enemy's continuous time inside; after about 1–1.5 seconds that enemy is individually struck by lightning, with no travelling projectile. Both defensive deterrence and offensive area control. | Fixed lifetime per cast, extended by spell level-ups; kills do not extend duration. Area upgrades grow the visible circle and eligibility radius together; damage upgrades strengthen individual strikes. Each enemy needs its own exposure timer, not one shared global tick. Suggested visual: readable circle plus charge cue on eligible enemies, then a clear direct zap exactly when damage occurs. No shield absorption, stun or chaining implied by the name. | Select name, following versus stationary field, exact dwell time, whether strikes repeat, how exit/re-entry affects exposure, and the duration gained at each upgrade. The user clarified that level-ups extend the spell duration, not kills. Stationary lightning-tower fantasy is an analogy, not approval to immobilize the player or add a tower object. Suggested rule for testing: leaving resets exposure; staying begins another exposure interval after each strike. These are proposals, not decisions. |
| **Shillelagh** — confirmed player-facing name; internal effect label: directional root wave | A directional moving wave of tree roots, with a finite lifetime. Plants physically erupt/move along the ground; visible root front defines where contact damage occurs. | Damage and size/range/duration are potential tuning axes. A physical/nature fantasy; it does not automatically heal, poison, immobilize or make impassable terrain. | School, width/speed/reach, hit frequency, and whether roots leave a damaging trail or only the moving front hurts. Do not automatically interpret “roots” as an immobilizing status. |
| Dash | Spell acts on the wizard: either casting immediately dashes, or casting grants a charge that can be spent later. | Distinct mobility tool. | Explicitly a separate control-design discussion: immediate versus stored activation, direction, activation key, charge capacity/expiry, invulnerability and collision rules are all undecided. |
| Swiftness | Temporary movement-speed enhancement on the wizard. | Increase movement speed for a period; amount and duration not specified. | Refresh versus stacking, magnitude, duration and upgrade progression. Keep distinct from permanent movement-speed passive upgrades. |

Naming counts include spaces as typed keystrokes: **Lightning Crown = 15**, **Tempest Mantle = 14** (additional suggestion), **Lightning Tower = 15**, **Channel Lightning = 17**, **Channel the Storm = 17** (15 letters plus two spaces). The user is aiming roughly at a 14–15-character commitment; retain longer candidates for comparison rather than silently shortening them. “Shield” may imply absorption, which this aura does not currently promise.

Category context: the current design reference separates Life, Plague, Earth and Metal; the game already has healing, infection and earth protection. A broader Life/Nature fantasy could contain healing, poisonous growth and physical roots, but this is a proposed thematic grouping, not a decision to merge damage types or impose elemental counters. Earth remains useful for stone, terrain and earthquake identities. See [school versus damage/status distinction](14-spell-system-reference.md#4-element-and-timing-keyword-families).

### Accumulated mana as progression

The user proposes mana as **accumulated magical power, not a consumable casting pool**: gathering it reaches thresholds that unlock the next tier or upgrade the wizard. It can mechanically serve the role of XP while expressing the wizard fantasy. Casting should not subtract this resource under this proposal. A level-up need not narratively “spend” acquired power; total accumulated mana and progress toward the next threshold can be shown separately if useful.

Do not implement a second mana bar, cast costs, or remove random level-up choices on the basis of this idea. Naming, threshold behavior, tiers versus ordinary upgrades, whether any resource carries between runs, and reconciliation with the future expedition/preparation proposal remain open. This refines the earlier XP/mana conflict without changing the current roguelike game.

## Preserved spell ideas and naming inventory

Reserved entries are real recorded ideas, **not fully balanced release content**. For ideas without an agreed identity, inventing precise damage would create false completeness; the prototype requirement is instead a defined experiment before promotion. Their missing numbers are an explicit gate, not an implementation placeholder to silently choose.

| Name(s) | Proposed identity / relation | Status and next decision |
|---|---|---|
| Mana Bolt |Current automatic homing attack | Baseline; D04 decides new-mode presence |
| Homing Bolt |Seeking Bolt expression | Prefer composition, no separate slot identity |
| Magic Missile |Possible starter alternative | Resolve overlap with Bolt/Seeker before numbers |
| Arcane Orb |Slow travelling impact body | Reserve if distinct from Fire Bolt via persistence |
| Arcane Shield |Historical reserved proposal | Unselected; no agreed behavior; outside current matrix |
| Pulse |Short radial push | Compare Wave and Frost Nova; reserve cheapest radial emergency |
| Gravity Well |Pulling field | Reserve: test navigation/stacking before damage |
| Arcane Missiles |Native multi-bolt volley | Inactive JSON; compare Duplicating Bolt |
| Time Warp |Area/world time spell | Inactive; conflicts with finite per-cast assist; no prototype adoption |
| Arcane Turret |Stationary ranged summon | Inactive; define health/placement/cap then promote |
| Plague / Plague Nut |Plague was a small area-infection alternative; Plague Nut was a naming idea | Reserved area experiment; consolidation with Plague Seed is a new proposal, not deletion of the original idea |
| Tree of Life |Yggdrasil alternative display/incantation | Choose one canonical name before shipping |
| Thorn Volley |Piercing plant fan | Reserve; distinguish from Ice Blast's control |
| Venom Mark |Delayed poison mark | Reserve; compare Venomous modifier |
| Spore Bloom |Stationary infection nursery | Reserve; distinguish source location from travelling Seed |
| Regrowth / Heal |Historical healing names | No short aliases for Regeneration; Life already short |
| Chain Heal |Bouncing allied heal | Inactive; needs multiple allied recipients first |
| Seeking Spirit |Stronger persistent spirit concept, old Seeker internal identity | Reserve distinct long summon; no free alias |
| Reaping Spirit |Seeker + Plague Seed draft bonus | Disabled; explicitly deferred by user |
| Skeleton Warrior |Melee summon | Inactive; future summon variety, distinguish from golem |
| Fire |Standalone base/element word idea | Reserved grammar decision; Fiery handles conversion now |
| Fire Trail / Ember Trail |Firewalk alternatives | Legacy/name candidates, not extra spells |
| Fireball |Large explosive projectile | Reserve until its role differs from Fire Bolt |
| Fire Wall / Flame Wall |Line of burning ground | Reserve line geometry; differs from circular Cinder Field |
| Flame Elemental |Mobile fire summon | Inactive; future specialized creature |
| Ice Lance / Glacial Lance |Piercing ice attack / heavier version | Reserve two-tier identity experiment; avoid just recolored Ember Lance |
| Splash |Short local water hit | Reserve versus Wave; no automatic inclusion |
| Undertow |Returning/pulling water band | Reserve controlled displacement experiment |
| Tidal Wave |Long wide moving wall | Reserve major wave after Thunderwave utility tested |
| Maelstrom |Rotating water pull field | Reserve versus Gravity Well |
| Ice Shard |Short ice projectile | Prefer Icy Bolt unless distinct slow is worth identity |
| Blizzard |Large sustained slowing storm | Reserve longer field with visibility limits |
| Lightning Arc / Thunder |Historical Lightning names | Not current public aliases |
| Lightning Rain / Rain of Lightning |Distributed lightning impacts | Reserve; compare Mana Storm elemental conversion |
| Chain Lightning |Immediate chain vs travelling Lightning Bolt | Reserve only if arrival distinction earns a spell |
| Thunder Spear |Delayed piercing discharge | Reserve; distinguish from converted lance |
| Static Field |Stationary lightning zone; also a naming candidate for the newer personal storm aura | Reserve; see [storm aura idea](#storm-aura-roots-and-wizard-movement--2026-09-28-ideas) before treating these as the same spell |
| Tempest |Large moving weather effect | Reserve major combined control/damage identity |
| Earth Bolt |Earth projectile | Prefer Earthen Bolt unless distinct terrain interaction |
| Stone |Short thrown stone | Reserve starter alternative |
| Earth Wall / Earth Walls / Stonewall |Temporary destructible terrain, one wall vs formation | Reserved separate from personal Earth Shield |
| Returning Blade / Boomerang |Cross Blade naming alternatives | Legacy/candidate, not extra current spell |
| Slash / Whip |Alternate short starters / character weapons | Deferred characters; no forced inclusion now |
| Crescent |Short moon blade | Reserve ingredient identity |
| Moon Slash / Crescent Slash |Directional fan of three purple slashes | Reserve combination; one identity until naming chosen |
| Sunbeam |Narrow solar ray | Reserve versus Focus Ray; thematic distinction insufficient alone |
| Daybreak |Radiant damaging burst; cleansing is a new optional proposal | Reserve until status cleansing relevant |
| Solar Flare |Directional fan of solar energy | Reserve vs Frost Nova role |
| Divine Aura |Healing/protection aura | Inactive; avoid invalidating Earth Shield and Regen |
| Explosion — ritual incantation |Long multi-stage chant followed by a final release word and a screen-wide blast | New deferred concept; [ritual casting design](../CASTING_FANTASY_NOTES.md#multi-stage-ritual-casting--2026-09-28-idea); no incantation text, interrupt rules or damage selected |
| Super Extreme Meteor Shower Deluxe |Aspirational elaborate incantation | Expression/mastery fantasy; not a short-name balance bypass |

Any selected campaign spells need a complete effect definition, preview, icon, readable one-sentence description, damage/heal/filter tests and modifier compatibility tests before shipping. Reserved entries need identity selection first; no implementation team is authorized to fill gaps ad hoc.
