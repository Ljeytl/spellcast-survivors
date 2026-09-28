# Spell catalog: current truth, proposed roster, preserved ideas

## Verified prototype baseline

Audited at `0cb22e90f4d4a2e8416c1d3e2dfe5c73d1c1ca6c`. Source: `data/spells.json`, `scripts/SpellManager.gd`, `scripts/SynergyCatalog.gd`, `scripts/BuildSpellEffect.gd`, `scripts/TacticalSpellEffect.gd`, `scripts/IceBlast.gd`, `scripts/LightningArea.gd`, `scripts/SpellTargeting.gd`, `scripts/SpellGeometry.gd`, `scripts/Player.gd` (paths relative to repository root).

There are 26 JSON entries, but only 16 learnable manual spells, one automatic attack and nine inactive data definitions. Seven enabled combinations live separately; Reaping Spirit is disabled. Old library prose is not runtime evidence. Numbers below are rank 1 before player multipliers; many JSON fields are overridden by runtime code.

| Public name | Current behavior | Status |
|---|---|---|
| Mana Bolt | Automatic 15 damage/1.5 s, homing, 450 + 25 × projectile-index speed; count increases at ranks 3/6/10 | Automatic; new-mode policy open |
| Bolt |40 damage; straight 500 + 30 × index speed; count = min(rank, 5), 0.12 s stagger | Active |
| Life |4 instant HP | Active |
| Regeneration |8 HP/s × 5 s; current multiple effects stack | Active; proposed stack policy differs |
| Ice Blast |13 contact shards across 90°; 18 per unique enemy/cast; 400 reach; 620 speed; radius 12; slow 0.3 × 2 s | Active |
| Earth Shield |60 overheal; runtime 5 s | Active |
| Lightning |80 damage; radius 160; 0.2 s active, each enemy once; internal ID lightning_arc | Active |
| Meteor Shower |4 impacts; actual 20 each; radius 220; warnings 0.65 + 0.3 × index | Active |
| Ember Lance |45 per unique enemy; 700 speed; 1.5 s; piercing; nominal radius 24 with visual-default factor | Active |
| Plague Seed |9/tick every 0.5 s; 5 s/host; spread 130; spore 460 speed; 8 hosts; orphan spore 3 s | Active |
| Cinder Field |12/0.5 s for 5 s; radius 150 | Active |
| Arcane Orbit |3 bodies radius 42 on orbit 130; 28/contact/0.5 s; 6 s | Active |
| Focus Ray |12/0.25 s for 2 s; 450 reach; half-width 20; tracks first aligned target | Active |
| Rune Trap |60; arms 0.8 s; trigger 70/explosion 130; placement 160; persists; shared max 3 | Active |
| Seeker |22/contact/0.5 s; 5 s; 320 speed; radius 24; reacquire 600 from caster; max 3 | Active; ID seeking_spirit |
| Firewalk |24/0.5 s; emits 5 s, patches 6 s; radius 65 | Active; ID ember_trail |
| Cross Blade |60 per leg; 350 outbound; 0.9 s linger 30/0.3 s; 500 speed; radius 42; 4 s lifetime | Active; ID returning_blade |
| Lightning Bolt |Bolt + Lightning; 60 damage; 550 speed; 2 extra bounces within 240 | Enabled bonus |
| Life Bolt |Bolt + Life; 40 damage; seed 6 HP/2 s, lasts 10 s; max 6 | Enabled bonus |
| Meteor Lance |Ember Lance + Meteor Shower; 27 direct +13.5 area excluding direct victim, radius 90 | Enabled bonus |
| Soul Bloom |Plague Seed + Regeneration; 6.75 infection/tick; actual damage leech 10%, cap 2 HP/0.5 s | Enabled bonus |
| Steam Field |Cinder Field + Ice Blast; 12/0.5 s, 3 s, radius 150; 40% slow | Enabled bonus |
| Prism Ray |Focus Ray + Ember Lance; 7.2/0.25 s for 2 s; up to 3 aligned targets; shares beam cap | Enabled bonus |
| Frost Sigil |Rune Trap + Ice Blast; 60 burst, radius 170; arm 1.4 s; 40% slow 2 s; persistent | Enabled bonus |

Inactive data: Fire Storm(15 damage/0.2 s, 4 s, radius 350), Time Warp(0.3 × 5 s), Chain Heal(40, 2 chains, 0.7 falloff), Frost Nova(25, radius 300, freeze 2 s), Arcane Missiles(18 × 5), Divine Aura(heal 5/s, 20% reduction, 15 s), Skeleton Warrior(80 HP, 15 damage, 30 s), Arcane Turret(40 HP, 25 damage, 20 s), Flame Elemental(120 HP, 20 damage, 25 s, aura 8). These values are historical drafts, not available spells. Reaping Spirit has draft code but acquisition disabled.

Current general rank scaling is base × (1 + 0.15 × (rank − 1)) × player multiplier; acquisition does not follow the old JSON unlock-condition drafts. Current Ice Blast range and knockback also scale with rank; its 0.3 slow is a movement multiplier. Plague Seed selects its first host from visible enemies, and its five seconds are per host, not the whole infection chain. Public casting uses Seeker, Firewalk, Cross Blade and Lightning; internal IDs are not free shorter aliases.

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
| **Earth Shield** / personal protection / earth |50 absorption, 6 s; recovery 8; replace only if incoming absorption ≥ remaining absorption; otherwise reject; no addition |“Surround yourself with protective stone.” Five stone segments break with absorbed damage. No impassable terrain. |
| **Meteor Shower** / multi-area / fire |4 × 60 damage; impact radius 80; range 420; warnings 0.65 + 0.25 i; area active 0.1; recovery 6 |“Rain meteors across a marked area.” Growing red warnings, descending rocks, ground impact. Formation breaker, not instant panic button. |
| **Ember Lance** / piercing / fire |65 per unique contact; r 9; speed 700; range 650; max 8 contacts; recovery 2.5 |“Pierce a line of enemies with an ember lance.” Long ember tip and restrained trailing sparks. Aimed lane damage. |
| **Plague Seed** / infecting / plague |Seed speed 460, r 7, range 360; 6/0.5 s × 4 s = 48/host; spread 120; max 6 hosts; max 18 s root; orphan 3 s; recovery 5 |“Infect an enemy and spread spores nearby.” Green-purple seed, lesions, travelling links and visible orphan. Crowded staggered packs. |
| **Cinder Field** / field / fire |12/0.5 s × 5 s = 120/enemy at full dwell; r 95; range 320; warning 0.25; recovery 5 |“Set a patch of ground ablaze.” Connected red-orange ground with bold border. Holds a lane; no candle tiles. |
| **Arcane Orbit** / orbit / arcane |3 bodies r 12, path radius 70; 28 contact, 0.5 s per-target gate; 6 s; angular speed 4 rad/s; recovery 7 |“Orbit with three damaging arcane motes.” Actual motes collide; orbit disk does not. Close defense rewards moving. |
| **Focus Ray** / channel / arcane |16/0.25 s × 2 s = 128; reach 360; w 8; tracking 3 rad/s; first aligned target; recovery 3 |“Track one enemy with a focused beam.” Stable thin bright beam; clear endpoint. Reliable elite damage. |
| **Rune Trap** / trap / arcane |90 once; trigger radius 45/blast radius 90; arm 0.8; placement 140; persistent; max 3 shared; recovery 3 |“Place a lasting rune that bursts on contact.” Visible inscribed ring, armed change. Prepares escape route. |
| **Seeker** / spirit / spirit |22 contact/0.6 s; 6 s; speed 280; body radius 10; leash 400; max 3 bodies; recovery 4 |“Release a spirit that hunts nearby enemies.” Small face silhouette, curling tail and visible target turn. Flexible sustained pursuit. |
| **Firewalk** / trail / fire |10/0.5 s per enemy across all same-root patches; emit 5 s; patch 6 s; r 32; sample interval 0.10 s; recovery 6 |“Leave a lasting trail of burning ground.” Connected burning path; does not damage merely because spell started. Kiting and route control. |
| **Cross Blade** / returning / metal |55 outbound + 55 return per enemy; linger 0.9 with 20/0.3 s; range 280; speed 420; r 14; recovery 3 |“Throw a blade that lingers, then returns.” Readable cross rotates in plane, bright linger hub. Up to 170 on ideal single-target dwell. |
| **Wave** / moving area / water |20 damage; arc 120°; front width 100; travels 180 at 240; push 90; slow 0.7 × 1 s; recovery 2 |“Push enemies back with a wave.” Moving crescent ridge; contact only at advancing front. Creates openings. |
| **Water Jet** / piercing / water |45 damage; w 8; speed 600; range 500; max 3 contacts; push 25; recovery 2 |“Drive a narrow jet through enemies.” Coherent blue stream head with droplets behind. Faster cheaper line option. |
| **Frost Nova** / self area / ice |35 damage; r 120; active 0.15; freeze 1 s, bosses slow 0.8 × 1 s; recovery 5 |“Freeze nearby enemies in a sudden burst.” Expanding icy rim over actual disk. Emergency surrounding control. |
| **Fire Bolt** / explosive projectile / fire |35 direct +25 area r 45, direct victim excluded from area; r 8; speed 450; range 450; recovery 1.8 |“Launch a fire bolt that bursts on impact.” Orange core and real local blast. Distinct from Fiery Bolt's 40 direct/no blast. |
| **Firestorm** / field / fire |18/0.5 s × 3 s = 108; r 140; self-centered moving field; warning 0.6; recovery 8 |“Carry a brief firestorm around you.” A moving ring of churning flame surrounds the caster. Broader but shorter and less total damage than the longer stationary Cinder Field; requires staying near threats. |
| **Earthquake** / pulsed self area / earth |4 × 45 at 0.4 s intervals; r 180; first 0.4; push 20 first contact only; recovery 8 |“Shake the ground in four crushing waves.” Cracks and bounded expanding rings, each actual damage beat. Local crowd clear. |
| **Thunderwave** / moving area / lightning |50; arc 160°; front width 160; travels 220 at 320; push 110; recovery 4 |“Blast enemies backward with rolling thunder.” Blue-white advancing ridge; contact flash. Stronger control wave with more commitment. |
| **Frost Ray** / channel / ice |12/0.25 s × 2 s = 96; reach 360; w 10; tracking 2 rad/s; slow 0.5 × 1 s refreshed; first target; recovery 3 |“Chill an enemy with a sustained ray.” Clear icy beam and frost at actual contact. Lower damage than Focus Ray, control utility. |
| **Moonfall** / mixed field / moon |8 damage/0.5 s × 5 s; r 110; range 300; player heal 1/s while inside, max 5/root; warning 0.5; recovery 7 |“Call down a moonlit field that harms foes and gently heals you.” Crescent above purple disk; separate green heal pulses. Weaker healing than Regeneration. |
| **Grasping Hand** / targeted area / spirit |70 burst; r 70; range 300; rootnormal enemies 1.5 s, boss slow 0.8 × 1.5; warning 0.45; recovery 4 |“A spectral hand pins a group of enemies.” Fingers enclose the actual area after warning. Stops a formation, not hidden screen-wide stun. |
| **Mana Storm** / distributed multi-area / arcane |8 × 45 strikes; r 55; centers within 180 oftarget; warning 0.55 + 0.12 i; range 400; recovery 9 |“Unleash an arcane storm across a large formation.” Violet marked stars and coherent impact pulses. Cap 8 unique bodies initial, 9 duplicated. |
| **Summon Golem** / summon / earth |80 HP; 25 melee/1.2 s; r 18; reach 35; speed 100; acquisition range 240; leash 400; 20 s; max 2 bodies; recovery 15 |“Summon a stone ally to hold nearby enemies.” Heavy stone silhouette and health marker. Blocks foes, not player navigation; enemies may choose golem. |
| **Yggdrasil** / mixed field / life |TreeHP 100; duration 8 s; r 120; player heal 5/s, total 40; rootsdamage 8/s; range 220; warning 0.8; recovery 14 |“Grow a tree of life that heals you and lashes nearby foes.” Tree and visible green boundary; no invulnerable safezone. Major healing commitment; name provisional. |
| **Lightning Bolt** / chain / lightning |60/contact; 2 additional distinct targets; speed 550; r 8; bounce 180; total range 720; recovery 3 |“Send lightning bouncing between enemies.” Visible curved links after contact. Recipe Bolt + Lightning. |
| **Life Bolt** / projectile + pickup / life |30 damage; r 7; speed 450; range 450; impactseed 6 HP over 2 s, expires 10 s, max 6; recovery 2.5 |“Plant a healing seed where your bolt hits.” Seed has plus/leaf marker; approach to collect; no lifesteal. Recipe Bolt + Life. |
| **Meteor Lance** / piercing + burst / fire |45 direct; 25 area r 45 excludes direct victim; max 6 contacts; r 9; speed 650; range 600; recovery 4 |“Pierce enemies with an exploding meteor lance.” Ember point plus distinct contact craters. Recipe Ember Lance + Meteor Shower. |
| **Soul Bloom** / infection + heal / plague-life |4/0.5 s × 4 s; spread 120, max 6 hosts, 18 s root lifetime; actual damage healed 10%, max 6 HP/root; recovery 6 |“Spread a life-draining infection through a group.” Plague links plus thin return motes only on actual healing. Recipe Plague Seed + Regeneration. |
| **Steam Field** / field / water-fire |10/0.5 s × 4 s; r 110; range 320; slow 0.6; warning 0.25; recovery 5 |“Scald and slow enemies in a cloud of steam.” Pale blue-gray boiling boundary; no green pluses. Recipe Cinder Field + Ice Blast. |
| **Prism Ray** / channel / arcane-fire |10/0.25 s × 2 s per target; max 3 aligned; reach 400; w 9; recovery 3.5 |“Burn through a line with a prismatic beam.” Three readable contact nodes; not three arbitrary aim locks. Recipe Focus Ray + Ember Lance. |
| **Frost Sigil** / trap / ice |75 damage; trigger radius 50/blast radius 110; arm 1.2; slow 0.5 × 2 s; persistent; max 3 shared; recovery 4 |“Lay a lasting frost rune that slows a group.” Blue ring, armed center, clear burst. Recipe Rune Trap + Ice Blast. |

## Per-spell mapping exceptions

These complete the generic shape matrix; unsupported combinations must be rejected visibly.

- Lightning Bolt has native guidance and bounces; Seeking is redundant and rejected. Swift applies to travel; Big changes its body, not bounce range. Duplicating adds a second chain with a separate hit ledger.
- Plague Seed and Soul Bloom support Powerful, Swift, Big, Delayed, Lasting, Fiery/Icy/Earthen only. Big changes spore collision and visible spread radius together. Lasting increases host infection duration to 5.6 s but root ceiling remains 18 s. Element conversion changes ticks, not infection identity. No Duplicating/Repeating until spread workload and multiple-root stacking are proven.
- Water Jet uses projectile-line behavior. Wave and Thunderwave support Big, Powerful, Repulsing, Repeating, Delayed, Charged and element conversion, but not Swift until warning/advancing-front timing is tested. Big scales width and travel distance together, unlike Ice Blast.
- Earthquake supports Big, Powerful, Delayed, Charged, element conversion and Repulsing; no Repeat because its native pulses already supply that role in v0.1.
- Mana Storm uses Meteor Shower mapping; Duplicating adds one strike. Its repeated strike pattern reserves 18 bodies maximum.
- Cross Blade supports Big, Powerful, Swift, Delayed, Charged, Duplicating, Repeating, element and Venomous. Duplicating adds a second blade at 0.8 potency; up to 4 bodies with Repeat. Swift shortens flight but not 0.9 s linger. Return expires 4 s after release if owner unavailable; no Seeking.
- Life Bolt supports Bolt's projectile modifiers. Its healing seed is separate secondary budget: potency words scale seed heal, but total seeds heal at most 15 HP/root across all outputs; Repeating/Duplicating share this cap. Big changes projectile, not pickup activation radius. One target cannot receive repeated native immediate contacts from same projectile.
- Meteor Lance supports Ember Lance's mappings; Big changes body and burst; per-projectile contact area excludes direct victim. Added poison is based on actual direct hit only, not burst plus direct double count.
- Moonfall: Lasting increases duration to 7 s, healing still limited to 5 HP/root before potency cap; Powerful scales both damage and heal but max 12.5 HP/root. Repeat shares that root cap. Yggdrasil health does not scale with Powerful; heal cap 100/root, no stacking parallel trees (max 1). Lasting is rejected because its 8-second field is already at the duration ceiling. Its damage ticks and healing use separate recipient filters.
- Focus Ray, Frost Ray and Prism Ray allow Big, Powerful, Lasting, Repulsing, element and Venomous. Lasting 2.8 s channels are intentional extra commitment, first tick 0.25. Venomous applies only on first target contact/root, computed from one tick, not entire future channel. Max one player channel at once.
- Seeker: Big, Powerful, Swift, Lasting, Duplicating and conversion; native seeking makes Seeking redundant. Golem: Big, Powerful, Lasting, Duplicating, conversion; no Swift. Native summons have 20 s duration; the generic 8 s field ceiling does not apply to creatures.

## Preserved spell ideas and naming inventory

Reserved entries are real recorded ideas, **not fully balanced release content**. For ideas without an agreed identity, inventing precise damage would create false completeness; the prototype requirement is instead a defined experiment before promotion. Their missing numbers are an explicit gate, not an implementation placeholder to silently choose.

| Name(s) | Proposed identity / relation | Status and next decision |
|---|---|---|
| Mana Bolt |Current automatic homing attack | Baseline; D04 decides new-mode presence |
| Homing Bolt |Seeking Bolt expression | Prefer composition, no separate slot identity |
| Magic Missile |Possible starter alternative | Resolve overlap with Bolt/Seeker before numbers |
| Arcane Orb |Slow travelling impact body | Reserve if distinct from Fire Bolt via persistence |
| Arcane Shield |Arcane protection | Earth Shield overlaps; reserve reflect experiment |
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
| Static Field |Stationary lightning zone | Reserve; native proximity behavior needed |
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
| Super Extreme Meteor Shower Deluxe |Aspirational elaborate incantation | Expression/mastery fantasy; not a short-name balance bypass |

All 36 campaign spells need a complete effect definition, preview, icon, readable one-sentence description, damage/heal/filter tests and modifier compatibility tests before shipping. Reserved entries need identity selection first; no implementation team is authorized to fill gaps ad hoc.
