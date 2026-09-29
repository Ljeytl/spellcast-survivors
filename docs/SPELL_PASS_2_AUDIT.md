Current playtest balance note (2026-09-28): Earth Shield protection and visuals now last 16 seconds; Cross Blade radius is 33.6 (20% smaller). These replace the older runtime values below; proposed future expedition mechanics are unchanged.

# Implemented spell audit — playtest pass 2

This is the runtime behavior reference for pass 2. Historical proposals in the full spell library remain ideas unless listed here. Values below are rank-one base values before damage/passive upgrades. Sixteen primary spells, seven enabled bonus spells, and one passive attack are covered. Data-only entries (Fire Storm, Time Warp, Chain Heal, Frost Nova, Arcane Missiles, Divine Aura, Skeleton Warrior, Arcane Turret, Flame Elemental) are unavailable; Reaping Spirit remains disabled. No library expansion occurred.

## Shared contracts and tuning

`AreaArt` renders authoritative world-space circle/cone/path geometry. Firewalk fills the exact round segment capsules used by gameplay; polygon offsets draw only exterior/hole contours. Closed paths retain unburned holes. Cosmetic particles do not expand hitboxes. Circle warnings show the final affected boundary plus growing inner fill; warnings themselves do no damage. Ground fill and border persist while the area is active. Normal and reduced-effects modes keep gameplay boundaries.

| Tuning | Baseline | Candidate |
|---|---|---|
| Lightning | One direct target, 80 | Group-centered radius160, 80 per enemy once during a0.2s window |
| Meteor Shower | Radius hardcoded180 despite data220; first meteor zero delay | Data radius220; first warning0.65s, next impacts spaced0.3s; 4 meteors,20 damage each unchanged; planned damage spreads likely-lethal hits to other groups |
| Arcane Orbit | Orbit65, small24px stamps, hit radius38 sampled every0.5s,16 damage,5s | Orbit130, bodies42radius/84diameter, continuous substep contacts capped at one28damage hit per enemy per0.5s,6s |
| Cross Blade | Radius24,38damage each leg,0.4s linger with no repeat payoff | Radius42,60damage each leg,0.9s linger with30damage every0.3s;350travel preserved,4s hard expiry |
| Firewalk | 40radius,2s patches,15damage/0.5s,5s emission | 65radius,6s patches,24damage/0.5s,5s emission/11s total; connected ground; one hit per enemy per trail tick |
| Cinder/Steam Field | Invisible150radius beneath scattered flame/smoke stamps | Same damage/radius/lifetime, continuous translucent area and bright outline; fire region visibly filled |
| Rune Trap/Frost Sigil | Armed visual radius32 versus70 trigger | Visible70 trigger circle; activation shows130/170 damage circle |
| Plague/Soul Bloom |32px plant at-32offset |40px plant at-58offset, retained bright transfers above canopies, fitted to1.75x bodies |

No Focus Ray numerical, targeting, cadence, or tracking changes. Exact visual scale remains a candidate for player judgment, not a claim of final polish. Lightning reuses the existing electrical cast sound via the current-name alias; new audio production remains deferred.

## Library inventory

All entries below are implemented and available through their existing ownership rules. “Self” uses the caster as origin; “target” uses the selected enemy/group location. Hit tests use enemy centers unless projectile HurtBox contact is stated. Primary incantations remain typed only when owned. Bonus spells preserve ingredients and use no primary slot.

| Spell / status | Role and targeting | Shape / origin / reach | Duration and hit cadence | Visible lifecycle and disposition | Evidence |
|---|---|---|---|---|---|
| Magic Missile / passive | Automatic support, useful target per launch, homing reacquisition | Traveling projectile from self;450speed; HurtBox contact |15base damage,1.5s baseline cadence; rank volleys | Enlarged cosmetic projectile; incoming commitment releases on impact/miss/expiry. Preserve passive power | shared_targeting |
| bolt / primary | Quick direct attack; shared useful launch target | Straight projectile from self;600speed; HurtBox |40base per shot; rank adds shots capped5;3s projectile life | Keeps straight trajectory, no accidental homing | shared_targeting, foundations |
| life / primary | Small emergency heal; self | Personal feedback, no damaging area |4HP immediate | Brief heal particles; distinct from stronger sustained heal | foundations |
| regeneration / primary | Sustained recovery; self | Personal feedback |8HP/sec for5s,40total base | Heal feedback coalesced; no misleading damage circle | foundations |
| ice blast / primary | Directional escape/control, nearest living aim |90-degree cone from self,400base reach |18damage once, knockback and2s slow | Full cone fill/outline plus directional particles; exact angular/range boundary preserved | foundations, visual |
| earth shield / primary | Personal protection; self | Orbiting protective stones, no terrain |60overheal,8s | Stones disappear when protection depleted; no walls added | foundations, simple_art |
| lightning / primary | Immediate group burst; shared group coverage | Circle at selected enemy,160radius |80once per enemy in0.2s window | Blue fill/bold border and electrical strikes; data owns radius/lifetime; current sound alias fixed | spell_areas, foundations, visual |
| meteor shower / primary | Delayed crowd bombardment; shared group selection | Target circles,220radius |4base impacts,20each;0.65s initial warning,+0.3s each | Final border plus growing red fill, then impact; no warning damage; timers receiver-bound | spell_areas, delayed, visual |
| ember lance / primary | Pierce an aligned group; living target aim | Straight swept lane,24halfwidth,700speed from self |45once per enemy,1.5s travel | Directional lance; entry hit deduplication | spell_build |
| plague seed / primary | Infection propagation; nearest visible live host | Host markers;130neighbor spread;8hosts total |9every0.5s,5s lifetime | Plant markers/bright links above canopy; external and own deaths transfer once. Death-ground idea deferred | plague_visibility, visual |
| cinder field / primary | Sustained zone denial; group center | Stationary150radius target circle |12every0.5s for5s | Entire ground region burns with bright border; no candle-only representation | spell_build, visual |
| arcane orbit / primary | Protect moving caster with satellites |3moving42radius bodies on130orbit; self |28per contact,0.5s per-target cooldown,6s | Actual satellite regions drawn; empty center/gaps do not damage; bounded substep sweep | spell_areas, spell_build, visual |
| focus ray / primary | Reliable focused tracking; retained target/reacquire450 |20halfwidth beam from self,450reach,first target |12every0.25s for2s,8ticks;one active | Beam endpoint stops at hit target. **Preserved benchmark** | magic_variety |
| rune trap / primary | Prepare a delayed proximity burst | Forward placement up to160;70trigger/130burst |60once;0.8s arming; persists until trigger;max3 | Visible trigger circle fills while arming, activation shows burst radius | spell_areas, magic_variety, visual |
| seeker / primary | Mobile hunter; retained/reacquired target within600 of caster | Spirit from self,320speed,24contact |22every0.5s on contact,5s;max3 | Traveling spirit, no invisible remote hit | magic_variety |
| firewalk / primary | Damage pursuers while repositioning | Connected path from movement,65radius |24every0.5s once per enemy per trail;5s laying/6s patches;max3 | Continuous burning ground; each effect ages independently, no per-sample damage multiplication | spell_areas real boss chase, magic_variety, visual |
| cross blade / primary | Outbound/linger/return crowd cutting |42radius moving body from self,350outbound,500speed |60each leg;30each0.3s during0.9s linger;4s hard expiry;max3 | Bigger rotating blade, stationary linger, return tracks moving caster; speed upgrades preserve distance | spell_areas, magic_variety, simple_art |
| lightning bolt / bonus | Traveling bounce chain; useful target and living next target | HurtBox projectile,550speed;240bounce reach |60per hit,2extra targets,no repeats | Distinct from instant Lightning circle; reservations only next impact | shared_targeting, simple_art |
| life bolt / bonus | Attack plants recoverable healing | Straight Bolt behavior; seed at damaging impact | Seed6HP/2s,10s expiry,max6;fullHP does not consume | Visible healing seed, physical pickup; no remote lifesteal | foundations, simple_art |
| meteor lance / bonus | Piercing lane plus packed-group splash | Ember Lance lane;90radius per hit |27direct plus13.5splash excluding direct target | New brief bordered splash at each actual impact; shared hit geometry | spell_build, area renderer |
| soul bloom / bonus | Infection with small sustain | Plague host/spread geometry |6.75/0.5s,5s;10%actual damage healing capped2HP/tick | Same visible infection; stronger dedicated Regeneration remains useful | spell_build, plague_visibility |
| steam field / bonus | Area damage and slow | Group-centered150circle |12/0.5s for3s;40%slow | Cool-colored filled region/bold border; shorter than Cinder | spell_build, shared renderer |
| prism ray / bonus | Aligned crowd piercing | Focus Ray geometry,up to3aligned targets |7.2each/0.25s for2s;sharesone-beam cap | Endpoint follows last hit target. Focus remains stronger single-target | magic_variety |
| frost sigil / bonus | Larger slowing prepared burst |70trigger/170burst;forward placement |60once,1.4s arming,40%slow2s;sharesmax3traps | Shared persistent circle language; longer setup than Rune Trap | magic_variety, shared renderer |

## Verification and limits

`spell_areas_regression.gd` uses real EncounterEnemy instances, an owned typed Lightning cast, an actual boss instance following a controlled chase path, and explicit geometry/time stepping. Negative controls restore a small Orbit and short-lived Firewalk; both must fail their specific useful-coverage assertions. Controlled boss movement isolates trail timing; it is not a full autonomous boss-fight balance claim.

Existing foundation, magic-variety, spell-build, simple-art, Plague, and delayed-cast suites cover sibling contracts. Legacy expectations changed only where the approved geometry/lifetime changed. `spell_areas_visual.gd` captures a crowded native-rendered fixture at1280x720 and800x600 with reduced cosmetic effects. It verifies that areas and markers render at candidate scale; the final integrated player-input/long-run review belongs to the integration gate. Native fixtures are not reported as completed human game-feel testing.

A native pixel test compares a closed Firewalk loop center with unburned ground; the old polygon-fill implementation is a discriminating failing control.

Final exact revision, assertion counts, logs and captures are recorded in the handoff to the integration owner. The pass2 spec remains the controlling requirement register.
