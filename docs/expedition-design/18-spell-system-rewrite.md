# Spell feel specification and shared mechanics

Updated 15 October 2026. The rewrite foundations and existing spell migration are part of 0.3.0. This page now owns the complete spell-feel sequences, presentation review contract and dependency checklist; the full catalog is in [doc 3](03-spells.md), engine architecture in [doc 19](19-engine-architecture.md), game systems in [doc 20](20-game-systems-architecture.md), and damage/status/keyword rules in [doc 21](21-damage-effects-keywords.md). The older rewrite specification is [historical](archive/2026-10-14/18-spell-system-rewrite.md).

## Reading guide

- [Shared sequence and material language](#spell-feel-design-brief)
- [Current audit and provisional grades](#current-spell-audit--15-october-2026)
- [Current manual spells](#current-manual-spell-sequences)
- [Existing combinations](#existing-combination-sequences)
- [Automatic and special attacks](#automatic-and-special-attack-sequences)
- [Bare forms and modifiers](#bare-forms-and-modifier-presentation)
- [Spirit behavior candidates](#spirit-behavior-candidates)
- [Future catalog sequences](#authored-future-spell-sequences)

## Presentation contract

Spell identity must remain readable through anticipation, release, travel, contact, sustained effects and expiry. Silhouette, motion and timing all matter. Visible damaging boundaries must agree with gameplay geometry; glow may extend beyond them only when the actual boundary remains clear. Spell fantasy and contact timing take precedence over a uniform animation template.

| Area | Review obligation |
|---|---|
| Casting | Immediate readable input; accepted/rejected words and cancellation; windup proportional to intended commitment. |
| Projectile and wave | Speed, acceleration, arc, copy spacing, target changes and size upgrades communicate the hit. |
| Beam and chain | Start/stop, tracking, target allocation, tick rhythm and branching remain readable. |
| Field, trail and wall | Edge, occupancy, crossing/tick timing, following/fixed behavior and expiry are clear. Flame Wall follows the circular-band design in doc 3. |
| Trap and seed | Distinguishable inscription, armed/growing, triggered/mature and expired states. Frost Sigil must read differently from Rune Trap before detonation. |
| Summon and barrier | Spawn, idle, attack, damaged, broken/death states; ownership, target and collision are understandable. |
| Impact | Damage, contact flash, enemy reaction, sound and shake align; strength fits the spell and does not obscure the next threat. |
| Status and reaction | Coexisting statuses remain distinguishable; buildup, actual reaction and expiry have truthful cues. Frozen differs from chilled. |
| Healing and pickups | Friendly benefit and collection are legible; avoid visuals that imply healing where only enemy damage exists. |
| Keywords | A meaningful change has meaningful feedback; word order must not accidentally hide an effect. Preserve clarity under multiple modifiers. |
| Accessibility and performance | Reduced effects propagates through all renderers and shake; visible enemies take priority under budgets; evaluate native and web frame time. |

The existing VFX layer and art are inputs for refinement, not proof of good feel and not a requirement to replace every asset. The historical grey-value asset pipeline is an option, not a new mandatory rewrite of the current renderer. Element palettes, shapes, stamps, outlines and audio should be shared where useful while preserving authored identity.

## Spell feel design brief

Draft for design review, 15 October 2026. This is the canonical sequence specification for spell feel: what the player sees, hears and feels from the caster's first gesture to the final residue. It proposes a target experience, not a claim that the current game already delivers it. The catalog in [doc 3](03-spells.md) still owns identities and selection status; [doc 21](21-damage-effects-keywords.md) still owns damage and status rules. No gameplay change or new acquisition is approved merely by appearing here.

**The target is a consistent B in actual play.** A B spell has a recognizable fantasy, convincing motion, responsive release, satisfying contact and a deliberate ending. Its strength and reach are understandable in a moving fight. A technically correct effect, attractive still image or loud impact does not earn that grade. The working assessment is that our best spells are around B and many others are C or below; individual grades remain unassigned until reviewed in motion and with sound.

### How to read and use these scripts

Read the full sequence aloud before choosing an emitter, sprite or shader. Prototype the connected sequence, then compare it with the intended experience. The [particle sandbox](../../tools/vfx-reference/spell_vfx_sandbox.html) is a strong motion/material reference, not a perfect target or a replacement for combat review. Preserve its successful flow, density, trailing motion and release of energy where they serve the spell. Particle systems are the preferred approach. The rejected painted Bolt and Slash treatments must not return as the default. The ghost and wisp art remains a separate approved visual experiment whose movement still needs work.

Each current-spell script covers intention, caster/staff, release and motion, contact, sound/camera, ending/readability, and any gameplay decision. Future scripts inherit the shared rules below and explicitly leave unresolved mechanics open. No phase has to be lengthy: a quick bolt can gather, release and recover in one compact gesture. A lasting field needs a sustained phase; an instant slash does not need a forced travel phase.

### Simplicity and contrast

**Simple can be the finished design.** Every spell needs a clear identity; it does not need equal ceremony or complexity. The phases below are questions to consider, not a mandatory effects checklist. Combine them into an instant or omit them when they do not serve the spell. A B-quality spell feels complete, not crowded with particles, gestures, sounds or shake.

- **Magic Missile:** a small automatic release, clean seeking trail and satisfying little contact. Quiet and unobtrusive enough to repeat constantly; no elaborate charge or camera shake.
- **Bolt:** a quick deliberate staff flick and crisp projectile impact. More presence than the passive attack because the player chose to cast it, while staying immediate.
- **Lightning:** gather, slam, warning, strike and aftershock. Its larger sequence earns its place through the spell's fantasy and impact.
- **Meteor Shower:** separate heavy arrivals, preserving the enjoyed stagger and repeated impacts.

Keep this contrast across the roster. Light, frequent spells give heavier casts room to feel powerful. Improve a weak spell by clarifying its essential gesture, motion or contact before adding more layers. Simplicity is not an unfinished state or a lower quality grade.

### Shared casting sequence

1. **Preparing the word:** the staff gathers the spell's material while the player types or uses an existing preparation window. A small responsive cue starts immediately. A recognizable head of fire, rising stone chips or snapping arcs identifies the coming spell without becoming a second UI. Preparation strength follows real readiness, not keystroke count alone.
2. **Commit:** accepted input produces a clear release gesture and sound. Staff direction, hand/body pose and muzzle position agree. A stab, sweep, plant or upward call should feel physically connected to the result. Quick casting never acquires an arbitrary new windup merely to fit an animation. Added delay, movement lock or vulnerability is a gameplay proposal requiring a separate decision.
3. **Delivery:** motion has material and intent. Trails remember the path; particles detach and continue living. Turning must not rotate an entire rigid trail around its head. Core motion remains consistent with targeting and collision.
4. **Contact:** the real hit drives the contact flash, sound, material response and any enemy reaction. A miss does not receive a successful-hit payoff. Actual shield blocks, immunity and resisted damage need distinct feedback. Cosmetic recoil does not silently add stagger or displacement.
5. **Sustain:** show the real pulse, dwell, crossing or rehit rhythm. Avoid making every damage tick a new explosion. The player should understand whether the spell remains dangerous, is charging again, or is spent.
6. **End:** give material a believable release: embers cool, water runs out, ice fractures or thaws, energy collapses, souls unravel. Stop damage cues when gameplay stops. Harmless residue is dimmer, broken and retreating rather than an active rim.
7. **Cancel or invalid cast:** gathered material falls back into the staff or dissipates locally with a short soft failure cue. No target strike, hit sound or strong shake. Rejected modifiers do not create the visual promise of an effect that was rejected.

Staff movement is local to the caster; the world effect is not a texture glued to the staff. Recoil and recovery can overlap normal movement and the next allowed action. During rapid recasts, articulate the new release without snapping the pose back to idle every time. A persistent field or summon does not keep the wizard stuck in its casting pose.

### Motion and material rules

- **Fire:** a compact hot source feeds rising tongues, stretched travel flames and detached embers. Short tongues turn, split and die at different ages. Large fire has a heavier body, not just more screen-filling sparks.
- **Steam and water:** steam expands, rolls and partially hides what it passes over; water has momentum, a coherent leading mass, spray and falling droplets. A steam cloud is not a grey ground circle. Water does not use plague goo.
- **Ice and earth:** ice has sharp cold surfaces, chips and brittle fracture; earth carries mass, launches grit and settles. Thin frost and deep cracks have different weight. Neither needs persistent glitter to remain visible.
- **Lightning:** unstable gathering arcs collapse into decisive contacts, then smaller branches search and die. Keep individual leaders and branches legible; random flashing everywhere loses force.
- **Arcane:** controlled geometry and precise pulses, with material that gathers and releases deliberately. Glyphs mark meaningful actions; decorative runes should not compete with every target.
- **Life and plague:** life grows, reaches and recoils; plague swells, creeps and transmits between hosts. Healing has an inward, restorative resolution. Infection has a connected, uneasy rhythm rather than generic green confetti.
- **Spirits:** a head or core leads, the body yields, the tail lags and shed wisps drift independently. Acceleration stretches; deceleration curls. A breeze may disturb loose material, while pursuit remains purposeful. Hovering, circling and repeated attacks must be designed as behavior when they affect contact, not disguised by rotating a PNG.

### Sound camera and intensity

Use a connected sound phrase: gathering texture, release transient, material sustain if needed, contact, then a decay. Do not play a full contact sound per particle or a full release sound on every tick. Repeated copies vary subtly without changing their identity. Prioritize the player's important cast/contact and immediate threats; bound overlapping tails and loops. On pause, interruption, scene change or host deletion, loops stop or suspend with their owner. Sound cues have a visible equivalent.

Camera terms below are relative design targets, not approved numeric amplitudes: **none** for automatic attacks, healing, light contact and continuous ticks; **light** for a restrained short contact kick; **firm** for a deliberate heavy strike; **heavy** for rare major payoff. Shake occurs on impact, not every anticipation spark. Overlapping shakes must be bounded and respect the player's zero-shake setting. Preserve the enjoyed staggered meteor impacts and multiple kicks instead of synchronizing them or replacing the cascade with one shake. The HUD and typing stay stable.

Flash, sound, camera and enemy reaction should agree on the same event without all reaching maximum intensity. Reduced effects preserves the core, direction, real boundary and contact cue while reducing secondary particles, long tails and rapid brightness changes. A large spell is not permission to hide the next threat. Full-screen flashes and camera zoom changes are not the default; any special treatment must retain accessible alternatives.

### Timing and gameplay boundary

These scripts specify relationships and rhythms rather than inventing frame counts for every spell. Record actual runtime timing when a prototype is built. Fit the presentation to existing cast, warning, travel, hit, tick and expiry events unless a behavior proposal is explicitly accepted. There must be no invisible damage while a visual implies the spell is still winding up, nor a convincing impact before the actual hit.

User directions to preserve: Lightning's staff charge → ground slam → blue warning circle → descending strike → shock response → charged aftermath; staggered Meteor Shower falls and repeated shakes; Flame Wall's large passable ring with proportional radius/band growth and a low-direct/strong-DoT intent; Arcane Slash's additional slashes by level and final-rank glyph/explosion; separate enemy-aimed Scorching Ray beams provisionally; one Shillelagh with a rooting trail and a pull. These directions are not claims that all mechanics are implemented.

Circling wisps that damage their host and ghosts that make heavier repeated passes are **candidate behavior designs**, not selected changes to Seeker or Soul Bloom. Balance follows the chosen attack rhythm: measure actual contacts, time on target, target switching, overkill, travel downtime, survivability and crowd utility before choosing damage per hit. No unapproved cooldowns, enemy stuns or invulnerability are introduced by this brief.

## Current manual spell sequences

All sequences below are proposed presentation targets for current spells. Runtime identifiers bind them to the real spells; the current catalog and data retain authority over mechanics and progression.

### Bolt

**Runtime:** `bolt`. **Intent:** a quick, dependable packet of directed magic; the elementary cast should still be enjoyable.

**Caster and staff:** a small concentrated bead gathers at the tip; the wizard points and snaps it forward. Release has a tiny staff recoil, with recovery immediately available for movement and recasting.

**Motion and contact:** the head stays distinct from a short particle wake. The wake follows the travelled path and breaks into motes rather than rotating as one object. Actual contact compresses the head into a crisp spark and short outward flecks; a miss dwindles without a hit burst.

**Sound and camera:** a brief resonant gathering note, a clean release flick and a compact contact tap. Camera none at ordinary strength. Copies form one audible release phrase rather than a deafening stack.

**End and readability:** sparks die quickly; no damaging ground is implied. Size affects the readable core, not just the glow. Fire-modified Bolt inherits fire tongues and embers while retaining a clear projectile head. **Decision:** a standalone Fire Bolt is a catalog design, not a new current spell ID.

### Life

**Runtime:** `life`. **Intent:** a decisive breath of renewal focused on the wizard.

**Caster and staff:** the staff draws a small green-gold seed of light inward; the caster gathers rather than throws it. A brief opening of leaves or soft roots connects the staff and body.

**Motion and contact:** the healing pulse resolves into the recipient, followed by a subtle lift through the silhouette. The visible resolution coincides with actual healing. Leaf fragments drift out and settle; the player is not engulfed in a permanent bright ring.

**Sound and camera:** a warm intake and clear rounded healing note, with a soft leafy exhale. Camera none; no hostile hit flash or recoil.

**End and readability:** the body glow recedes from extremities toward the core. At full health or when no benefit occurs, do not fake a large successful heal. **Decision:** no extra ally recipients or regeneration payload are implied.

### Regeneration

**Runtime:** `regeneration`. **Intent:** living magic quietly repairs over time.

**Caster and staff:** a bud opens at the staff, then sends a gentle ribbon into the wizard. The initial gesture is distinct from Life's immediate resolution.

**Motion and contact:** small growth pulses appear on actual healing ticks. Between them a restrained leafy orbit or breathing glow communicates that the effect remains active. The motion follows the caster without leaving a false healing field behind.

**Sound and camera:** soft activation, quiet tick accents and a final settling tone. Avoid a continuous loud healing loop. Camera none.

**End and readability:** the final leaf closes or drifts away when the effect ends; refresh uses a small renewal cue rather than replaying a huge cast. **Decision:** tick cadence and refresh stay authoritative to the existing effect.

### Ice Blast

**Runtime:** `ice_blast`. **Intent:** throw a biting fan of cold that breaks against a crowd.

**Caster and staff:** frost condenses along the tip; a short outward flick cracks it into the launched shards. The caster's gesture opens toward the actual fan.

**Motion and contact:** distinct pointed shards carry sparse ice dust and short cold streaks. Impacts produce brittle chips and a small rime flash on each real recipient. A chilled enemy shows cold buildup; a genuine freeze gets the stronger lock-up treatment.

**Sound and camera:** a crystalline intake, a sharp fan release and restrained brittle contacts. One light kick may accompany the main grouped impact; not one shake per shard.

**End and readability:** missed shards chip away; frost residue thins. Keep spread lanes readable and distinguish hit ice from existing frozen status. **Decision:** no new fan width, freeze guarantee or knockback is specified.

### Earth Shield

**Runtime:** `earth_shield`. **Intent:** take shelter inside heavy, protective stone.

**Caster and staff:** the staff plants or presses down; grit lifts and stones assemble around the caster with staggered weight. The pose releases as soon as protection is established.

**Motion and contact:** pieces orbit or hold according to the actual shield state. Consumption of the current one-hit shield charge drives a localized crack, chips and a heavy response at the incoming direction. Any actual retaliatory eruption originates from the protection rather than an unrelated flash.

**Sound and camera:** stone scraping at assembly, a compact low block knock, a larger fracture on break. Light kick on an important block; firm only for the final heavy break/eruption, not idle orbit.

**End and readability:** protection loss is obvious: surviving pieces drop or crumble. Voluntary expiry is quieter than a violent break. **Decision:** do not imply physical enemy collision or invulnerability beyond the real shield rules.

### Lightning

**Runtime:** `lightning`. **Intent:** command a violent strike from above through a deliberate staff action.

**Caster and staff:** small arcs gather between the staff head and hand; charge tightens and the wizard drives the staff into the ground. A short conductive pulse answers at the target as the large blue warning circle appears. Fit the slam into existing preparation/release timing; an added action lock is not assumed.

**Motion and contact:** the circle gathers charge inward, its edge communicating the actual impact footprint. A faint leader seeks down from above; the main bolt arrives at the damage event. On impact, a brief flash and enemy reaction coincide with branching arcs racing outward across the ground.

**Sound and camera:** rising electrical tension, staff ground-thump, then a sharp crack over a short low blast and sizzling decay. A firm camera kick belongs to the main strike. Secondary crawling sparks do not trigger more full shakes or blasts.

**End and readability:** ground charge becomes smaller, irregular and broken, then goes dark. Unless a real damaging aftermath exists, this is visibly spent residue, not a continuing hazard. Show the transition from warning to active hit clearly. **Decision:** adding damaging ground charge would change the payload and needs a separate choice; the requested charged look can be cosmetic.

### Meteor Shower

**Runtime:** `meteor_shower`. **Intent:** call a sequence of separate heavy arrivals, each satisfying in its own right.

**Caster and staff:** an upward call draws hot cinders above the staff; the gesture opens the skyward attack. Each warning mark promises one actual landing.

**Motion and contact:** rocks become readable before impact, accelerate into their marks and drag burning wakes. Falls remain staggered. Every landing delivers its own crushing flash, debris kick and crater response; the next meteor can already be descending while the previous impact settles.

**Sound and camera:** approaching rush, separate deep impacts, skittering debris and fire tails. Preserve repeated firm kicks with bounded overlap. Do not synchronize the falls or flatten them into a single impact to reduce noise.

**End and readability:** craters glow while their real burning phase is active, then cool into broken char. Marks and live craters differ. **Decision:** orbit-and-release meteors belong to the later signature idea, not this base behavior.

### Ember Spear

**Runtime:** `ember_spear`. **Intent:** drive a concentrated burning lance through a line of enemies.

**Caster and staff:** sparks pull into a long narrow spear at the tip; the wizard thrusts directly along the shot. A brief pressure release makes the spear feel launched rather than spawned.

**Motion and contact:** an unbroken leading shape pulls a thin flame tail. Piercing contacts snap sideways in short ember cuts, then the spear continues; it must not appear to explode and die on every pierced enemy.

**Sound and camera:** a compressed fiery thrust, sharp muted punctures and a fading hiss. Light kick only on a substantial contact, with repetition bounded.

**End and readability:** the remaining lance breaks into a few embers at range expiry; no successful-hit blast on a miss. Keep its narrow damaging path distinct from the decorative wake. **Decision:** the existing burning line trail is part of this spell: a thin hot seam forms behind the spear, ticks with the real damage cadence, then cools. Keep this ground burn separate from the airborne decorative wake; do not add extra damage events.

### Infection

**Runtime:** `infestation`. **Intent:** introduce a living sickness that visibly takes hold and spreads.

**Caster and staff:** a swollen spore gathers at the tip and is flicked toward the host with an uneasy organic release.

**Motion and contact:** the spore travels as a coherent seed with sparse drips. On attachment it sinks into the enemy silhouette; restrained bubbles and internal pulses communicate infection. Real spread events send a distinct travelling transfer toward another host, followed by that host's own attachment cue.

**Sound and camera:** soft wet release, a small attachment tick and quiet irregular host pulses. Camera none. Infection should be unsettling, not an explosion every tick.

**End and readability:** cure or expiry drains the host effect; death resolves into a collapse rather than leaving a floating status marker. Keep host identity readable under stacked ailments. **Decision:** extra transmission events, death blooms and slowing are not inferred from the particles.

### Cinder Field

**Runtime:** `cinder_field`. **Intent:** establish a bed of persistent, scalding embers.

**Caster and staff:** the caster casts a low scatter of coals or presses heat into the chosen area. The field ignites from several connected patches into its true footprint.

**Motion and contact:** low flames crawl over coals, with occasional upward embers. Enemy contact/ticks produce restrained heat responses at the affected enemy; the whole field does not detonate repeatedly.

**Sound and camera:** a short ignition whoosh followed by quiet crackling; ticks use light local sizzles. Camera none during sustain, at most a light ignition response if warranted by scale.

**End and readability:** hot edges collapse inward, coals dim and ash lifts. The active ground boundary remains distinguishable from residual char. **Decision:** keep this low ember bed distinct from Flame Wall's upright barrier and Steam's airborne volume.

### Arcane Orbit

**Runtime:** `arcane_orbit`. **Intent:** maintain controlled magical bodies that sweep around the wizard and make deliberate contacts.

**Caster and staff:** condensed motes lift from the staff and find their orbital lanes. The caster releases control into a stable rhythm rather than repeatedly recasting each orb.

**Motion and contact:** each orb has a readable head and short curved wake following its actual route. Contact briefly compresses/pulses the orb and sends a small outward spark before it continues. Crossing behind and in front of the wizard should feel spatially coherent.

**Sound and camera:** a rounded establishment tone, restrained orbit texture and separate contact taps. No continuous camera shake or impact sound per rendered revolution.

**End and readability:** orbiting bodies thin and unravel in their direction of travel. Effective radius and orb size are visible; trails do not imply a solid damaging disk. **Decision:** no enemy-centered orbit behavior is added here.

### Focus Ray

**Runtime:** `focus_ray`. **Intent:** focus sustained force down deliberate lanes.

**Caster and staff:** a bright point tightens inside a focusing ring at the staff; the caster braces or aims as the ray opens. The source visibly supplies the beam.

**Motion and contact:** a clear narrow core carries flowing internal energy. Contact at enemies or termination produces localized pressure sparks, not a giant decorative orb. Actual tracking and copies have distinct lanes; pulse emphasis follows real damage ticks.

**Sound and camera:** a short locking tone, controlled continuous hum and small contact crackle. At most one light initial kick; no vibration on every tick. Stop the loop when the beam stops.

**End and readability:** the beam pinches off at the source and its remaining energy clears promptly. Nonpiercing termination must match what blocks it. **Decision:** do not invent free tracking or longer duration to support a looping animation.

### Rune Trap

**Runtime:** `rune_trap`. **Intent:** inscribe a quiet promise of force that snaps shut on intrusion.

**Caster and staff:** a precise staff tracing sends an inscription to the placed location. Lines draw into a recognizably arcane shape during arming.

**Motion and contact:** armed state is quiet and complete; an approaching trigger is not itself a hit. The real trigger pulls the inscription inward, then releases its burst over the actual area, with a clear recipient response.

**Sound and camera:** scratch/chime while inscribing, a restrained armed cue, then a concise magical crack. Light or firm impact kick according to actual payoff; no armed-state shaking.

**End and readability:** triggered lines fracture and disappear; removal/reset of an untriggered trap erases the inscription quietly. The current named trap waits indefinitely after arming, so do not animate a countdown to an invented natural expiry. Armed, triggered and spent states must differ in shape/motion as well as color. **Decision:** no decorative lingering damaging field after the burst.

### Seeker

**Runtime:** `seeker`. **Intent:** send a purposeful supernatural presence after an enemy.

**Caster and staff:** gather a small presence at the staff; it stretches toward the selected direction, peels away and gains confidence as it pursues.

**Motion and contact:** the core leads while the body and tail lag through turns. Detached wisps continue drifting. Contact pulls the body into a brief concentrated strike, with a readable response at the target; the current persistent chasing spirit can contact repeatedly and continues until its actual end condition, rather than being consumed on the first hit. Avoid a goo burst that hides the spirit.

**Sound and camera:** a breathy gathering whisper, a restrained travelling tone and a short spectral contact accent. Camera none for ordinary contact; stronger rare impacts may justify light feedback.

**End and readability:** the presence unravels into its direction of motion, or quietly loses coherence on a miss. Target death and retargeting should produce a purposeful turn, not a teleport. **Decision:** ghost repeated passes and wisp target-orbiting are separate candidate behaviors below; neither is selected by this visual script.

### Fire Walk

**Runtime:** `firewalk`. **Intent:** leave a hot, dangerous wake through the route the wizard chooses.

**Caster and staff:** fire travels from the staff toward the caster's feet, establishing the empowered state with a quick low flare.

**Motion and contact:** new footprints or patches ignite behind actual movement. Patches have low rising tongues and local embers. Damage ticks respond at affected enemies, while the trail itself stays continuous enough to read the route.

**Sound and camera:** a quick ignition, subdued movement-linked crackle and local burn contact. Camera none; footsteps do not become explosions.

**End and readability:** each patch cools on its own lifetime, leaving a darkening broken trail. Stopping the caster must not imply new patches where none exist. **Decision:** do not change patch spacing, damage stacking or stationary emission in the presentation pass.

### Cross Blade

**Runtime:** `cross_blade`. **Intent:** throw a substantial spinning cutting shape with repeated edge contacts.

**Caster and staff:** a brief metallic gathering around the tip resolves into the blade; a throwing flick gives it direction and angular motion.

**Motion and contact:** the cross remains recognizable beneath a restrained rotational blur. Sparks come from real edge contacts; turns and any return behavior follow the actual trajectory. Do not bury the blade in a generic orb glow.

**Sound and camera:** metallic release, airy rotational swish and sharp clipped hits. Camera none or a small light contact cue for a major hit, not every rotation.

**End and readability:** fragments or residual light spin away when the blade really ends. The blade's visible reach matches its effective body. **Decision:** outward, hold and return are existing behavior. A new catching mechanic or extra passes would be a change; the staff may visually receive the spent blade without creating one.

## Existing combination sequences

These seven recipes remain unchanged. Their identity should feel like a specific synthesis, not two complete base effects drawn over one another.

### Lightning Bolt

**Runtime:** `lightning_bolt`. **Intent:** a travelling electrical attack ricochets between enemies and discharges at each contact.

**Caster and staff:** compact charge forms at the tip and is thrust outward. This has a directed release, unlike Lightning's grounded call to the sky.

**Motion and contact:** a bright moving head and broken conductive wake reveal the current target. Each real collision gives an immediate projectile contact cue and starts its actual local warning; the delayed sky strike lands after that warning. Meanwhile the next travelling segment commits to the next enemy. Keep contact, warning and area strike as three distinct events rather than collapsing them into an instant splash.

**Sound and camera:** short launch crack, separate crisp contact zaps and a thinning electrical tail. Light bounded kicks for meaningful contacts; no full Lightning blast mix at every bounce.

**End and readability:** the final contact spends the charge. A dead/missing next target leads to natural dissipation, not a false connected beam. **Decision:** keep this bouncing recipe distinct from both the base sky strike and future channeled Static Shock.

### Life Bolt

**Runtime:** `life_bolt`. **Intent:** offensive life magic turns a struck enemy into an opportunity for recovery.

**Caster and staff:** a seedlike core forms inside a projectile; a gentle thrust releases it without losing the bolt's responsiveness.

**Motion and contact:** a compact living head carries short leaf motes. Real enemy contact has a clear damage cue, followed by the actual healing-seed or recovery object. Its appearance and collection are separate beats; no heal sound plays merely because an enemy was hit.

**Sound and camera:** a soft wooden release, a small strike tick, then a warmer collection note when recovery occurs. Camera none.

**End and readability:** remaining recovery objects follow their actual lifetime, collection radius and target rules. Friendly recovery must not resemble a hostile seed hazard. **Decision:** remote automatic healing is not substituted for the existing collection behavior.

### Meteor Spear

**Runtime:** `meteor_spear`. **Intent:** a penetrating spear marks its route with heavier consequences from above.

**Caster and staff:** form the narrow Ember Spear with a denser ember core and a brief upward pull in its sparks.

**Motion and contact:** the spear stays fast and narrow; its real meteor-trigger events create distinct warnings/descending bodies. Separate the spear's piercing cut from each meteor's crushing arrival so the player understands both sources.

**Sound and camera:** a fiery thrust with small punctures, followed by weightier meteor rushes and impacts. Preserve staggered heavier kicks at the actual landings; spear contacts should not duplicate them.

**End and readability:** the spear can disappear while already-created meteors finish their legitimate lifecycle. Cooling impact residue follows the actual aftermath. **Decision:** no extra meteors per decorative ember; actual trigger events own every arrival.

### Soul Bloom

**Runtime:** `soul_bloom`. **Intent:** life escapes an infected death and seeks a new purpose.

**Caster and staff:** the initial cast carries a restrained mixture of infection and renewal. The signature moment belongs at a real infected host's death, not as an unrelated flourish at the caster.

**Motion and contact:** a soul gathers out of the collapsing host, separates, and follows its real healing or hunting destination. The body yields around turns; the tail retains its route. Healing resolves inward into the wizard; hunting concentrates into a target strike.

**Sound and camera:** soft emergence breath; a warm resolving note for an actual heal and a sharper hollow accent for an actual hostile contact. Camera none for healing and ordinary soul contacts.

**End and readability:** healing and hunting differ by destination, motion resolution and tint, not tint alone. Unspent expiry dissipates without a hit or heal cue. **Decision:** the current one-delivery soul is the baseline. Persistent orbiting or repeated ghost passes would require new lifetime, target, rehit and damage decisions.

### Steam Field

**Runtime:** `steam_field`. **Intent:** a volume of scalding vapor occupies the battlefield.

**Caster and staff:** heat and cold condense into a pressurized breath around the tip; release feeds rising jets at the field location. The initial source should explain the cloud's growth.

**Motion and contact:** overlapping puffs rise, swell and roll into connected masses, with moving gaps and denser streams beneath. Steam partly obscures the space without erasing important threats. Real damage has local scald reactions; frost/fire keywords do not turn the whole cloud back into Cinder Field.

**Sound and camera:** a pressurized initial hiss, a lower rolling vent sound and restrained local scald accents. Camera none during sustain; no repeated explosion noise.

**End and readability:** emission ceases, existing vapor stretches and thins, and the ground becomes visible again. Show a spent cloud as dissipating rather than a still-active damage boundary. **Decision:** volume appearance does not authorize blindness, projectile blocking or additional damage after expiry.

### Prism Ray

**Runtime:** `prism_ray`. **Intent:** a focused ray splits into distinct elemental directions at meaningful contact.

**Caster and staff:** a small ordered prism-like focus gathers at the tip; the main ray releases with a clean braced gesture.

**Motion and contact:** the primary lane stays clear. Actual refraction events create separate departing beams with their own material accents, rather than a rainbow fog around the whole cast. Each real contact receives a compact elemental response.

**Sound and camera:** a focused hum, crystalline splitting accents and restrained element contacts. Light feedback on the initial release or major split at most; no camera rattle for every beam tick.

**End and readability:** beams stop and decay according to their own lifetime; disconnected leftovers do not continue implying damage. Shapes, direction and source distinguish lanes alongside color. **Decision:** preserve the actual elemental beam recipe rather than inventing additional targets or unlimited branches.

### Frost Sigil

**Runtime:** `frost_sigil`. **Intent:** lay a cold inscription that springs into a freezing strike.

**Caster and staff:** rime draws inward along the staff, then traces a crystalline ground glyph with pointed ice geometry, distinct from Rune Trap's arcane inscription.

**Motion and contact:** arming grows fine frost into a complete sigil. Trigger snaps the structure outward into a cold burst or expanding frost response matching actual propagation. Genuine freeze is a separate enemy-state event, not guaranteed by every blue flash.

**Sound and camera:** brittle inscription, quiet ready cue, then a sharp ice crack and falling chips. Light or firm kick on the real detonation, never on arming.

**End and readability:** an untriggered sigil remains armed until removed by gameplay or reset; on removal its frost quietly thaws. Triggered frost breaks and recedes. Preserve the real trigger and damage radii, which need not be the same. **Decision:** lingering decorative snow does not extend the trap's damage or freeze duration.

## Automatic and special attack sequences

### Magic Missile

**Runtime:** `mana_bolt`. **Intent:** a dependable background attack that feels crisp without exhausting the player's attention.

**Caster and staff:** a tiny ready glint at the automatic source, followed by a quick flick or pulse. Do not interrupt a manual casting pose with a competing full-body animation.

**Motion and contact:** a small directed dart leaves a short sparse wake, turns according to real guidance, and breaks into a compact contact spark. Multiple missiles remain individually readable.

**Sound and camera:** quiet release and soft contact taps with bounded voices. Camera none. Manual casts and threats take audible priority.

**End and readability:** rapid unobtrusive decay; misses do not explode. **Decision:** no new charge time, camera effect or manual commitment is added to the automatic attack.

### Atomic

**Runtime:** `atomic` (special ability). **Intent:** a rare earned release with overwhelming scale and a clear consequence.

**Caster and staff:** once legitimately available and committed, energy contracts toward the wizard/staff into an unnaturally tense focus. Preserve the actual warning window and the distinction between ready and committed.

**Motion and contact:** the existing affected scope is telegraphed before the real damage event. A decisive expansion and impact response carries the payoff; the central shape remains readable beneath secondary debris and light.

**Sound and camera:** gathering tension, a short controlled drop in ambience, then a dominant blast with a decaying low tail. Heavy bounded kick with reduced/zero-shake alternatives; do not rely on a long white screen or deafening mix.

**End and readability:** afterglow withdraws and ordinary combat cues regain priority quickly. Boss response follows the actual special damage rule. **Decision:** combo gating, scope, boss damage, survival and interruption remain governed by current ability rules; no new time freeze or invulnerability is implied.

## Bare forms and modifier presentation

Bare forms are intentionally weak foundations, not unfinished previews of a stronger named spell. Use a modest arcane treatment when no element supplies a material. An elemental modifier changes material expression while the underlying geometry and real payload remain legible. These forms do not create extra named acquisition slots.

### Spear

**Runtime:** `spear`. A brief staff thrust launches a narrow directed body with a thin path-following wake. Each real piercing hit gives a clipped puncture and small sideways flecks; expiry dissolves the remaining point. Camera none ordinarily. Preserve the line of attack and contacts through a crowd. Element accents change the puncture material without turning every contact into a full explosion.

### Slash

**Runtime:** `slash`. The staff or casting hand draws a short cutting gesture toward the target. A fast particle-supported crescent sweeps through the real cone; a crisp edge and taper communicate direction. Contact has a short cutting tick and local enemy flash; the tail disappears promptly. Camera none or light for stronger variants. This is the bare short slash, not the full future Arcane Slash progression or an implicit sword-equipped character.

### Nova

**Runtime:** `nova`. The staff gathers a small central pulse and opens it into the actual expanding front. A clear moving rim carries contact, with restrained particles left behind. Sound expands from a compact release to a short airy tail; light kick only if the real impact merits it. The interior must not look continuously damaging when only the front hits. End by breaking the rim and letting the last particles drift outward.

### Field

**Runtime:** `field`. A placement gesture establishes the actual disk, whose material settles into a readable sustained state. Local tick cues and a quiet sustain sound communicate ongoing activity; camera none. Arming/growth, active edge and collapse differ. Element changes choose ember bed, water, growth or other appropriate material, not a permanent opaque circle. Expiry retires the damaging boundary before residue finishes.

### Trap

**Runtime:** `trap`. A quick trace inscribes an armed shape, then waits quietly. The actual trigger provides the burst, contact sound and optional light kick. Empty expiry erases the inscription with no successful-hit sound. Distinguish trigger radius from damage extent and armed state from decorative residue. Named Rune Trap and Frost Sigil can add stronger authored identity while retaining this readable lifecycle.

### Orbit

**Runtime:** `orbit`. A small body leaves the staff and finds its real orbital route. Its wake remembers the curve; individual contacts get compact ticks and sparks, without a constant camera pulse. Bodies lose coherence at expiry. The lane is not a solid wall and the whole interior is not a damaging disk. Elements modify the material; target-centered orbits are a separate behavior proposal.

### Keywords status reactions and copies

The detailed semantics remain in [doc 21](21-damage-effects-keywords.md). Presentation follows accepted effects, never rejected words. Size must scale the damaging core and boundaries; speed changes stretch wakes but keep a clear head; extra copies require separated releases/lanes rather than one unreadable bloom. Delayed/charged variants visibly hold real stored energy; homing changes reveal the turn; bounce/chain show the chosen next target; return effects retain ownership and route. Longer duration extends sustain rather than replaying ignition indefinitely.

Burn grips and flickers; poison pulses within/around the host; bleed produces brief directional drops; chill gathers rime; frozen locks into a stronger coherent shell; shock snaps locally; roots physically connect to the ground. Vulnerability and other marks remain small enough to coexist. Apply, tick, reaction and expiry are separate beats. A genuine reaction may earn a stronger accent, but stacked statuses do not each demand full flashes, sound loops and camera kicks. Enemy stagger, knockback and freeze only occur when the gameplay applies them.

## Spirit behavior candidates

These alternatives are not yet assigned to a spell. Ghost and wisp can still be compared on both Seeker and Soul Bloom.

**Haunting wisp:** circle a selected enemy at a visible offset, leading with the core while the tail trails around the orbit. A close pass or directed tendril/pulse makes each actual damage event understandable. Its hover includes acceleration, small corrections and independent shed vapor. Soft circling sound gives way to short contact accents; camera none. On host death it visibly seeks or dissolves according to a selected rule. Decide orbit radius, damaging path versus attached-host damage, cadence, target transfer, lifetime and caps before implementation. Orbiting a host does not automatically hit every nearby enemy.

**Passing ghost:** orient toward a victim, gather its body, rush through, then curve around for another committed pass. The face/core remains legible while the tail stretches and catches up. Each real crossing gets a heavier spectral strike; turns and recovery are quieter. Decide whether these are actual body collisions, whether other crossed enemies are hit, the rehit interval, target-death rule, lifetime and damage per pass. Fewer heavier hits are a balancing candidate, not a numerical commitment.

**Current behavior with richer motion:** retain Seeker's persistent chase/contact behavior and Soul Bloom's single-delivery heal-or-hunt behavior but animate a yielding body, lagging trail, independent wisps and meaningful arrival. This is the lowest gameplay-change option. Do not label it a haunting/orbiting spirit unless its actual movement supports that description.

## Authored future spell sequences

These are proposed feel scripts for the selected or open catalog identities, not an implementation queue or new recipes. Catalog statuses remain authoritative. Shared casting, contact, audio, reduced-effects and lifecycle rules above apply to every entry. An unresolved delivery or target rule is a decision to make before implementation; the script must adapt to that decision. No invented numeric balance accompanies these proposals.

### Arcane Slash

**Experience:** conjure a magical cutting action that visibly writes through the fight. The staff draws back, condenses a sharp arcane edge and cuts across the actual target direction. Each additional slash receives a distinct alternating or stepped gesture and particle sweep, rather than all copies overlapping into one flash.

**Contact and end:** the leading edge owns the hit; sparks and a short fading cut trace follow. At the final rank, the completed cut pattern resolves into the small glyph/explosion payoff. Ordinary ranks must not imply that payoff already exists.

**Sound and camera:** gathering ring, clean blade-like swishes, clipped hit accents; light kick on substantial cuts and a firmer final payoff if warranted. **Open:** exact targeting, slash spacing, glyph location and final-rank timing. The rejected striped shader is not the visual target; the existing bare Slash is only a starting implementation.

### Mana Storm

The staff lifts a loose cluster of condensed magic into a moving cloud; it forms a readable overhead source before raining distinct darts downward. Each arrival has a small precise hit and vanishing mote trail. A soft high gathering sound becomes irregular dart releases and compact contacts; camera none except a deliberately stronger terminal event, if one is selected. The cloud thins and the last already-released darts finish. **Open:** follows the caster or wanders independently; this choice determines drift, warning distribution and recast behavior.

### Arcane Nova

The staff draws energy inward, then opens a powerful expanding front around the wizard. A bright thin leading edge and streaming particles communicate outward force; contact responses progress with the ring rather than all firing at cast time. Use a compact resonant release, expanding airy tail and light/firm single kick. The rim breaks into escaping motes at its real extent; the cleared interior should not look active. **Open:** propagation speed, contact timing and how this authored spell differs from the weak bare Nova.

### Black Hole / Eye of [unnamed]

The staff compresses light into a dense dark seed, then places a gravity center whose surrounding debris reveals inward motion. Material curves and accelerates toward it; a legible boundary separates influence from decorative distortion. Enemy motion must follow actual allowed force, not cosmetic teleporting. Sound is a low gathering pressure with sparse inward tearing accents; camera none during sustain, potentially firm on a selected final collapse. The well releases/collapses without falsely hitting the whole screen. **Open:** force limits, affected entities, end payload and combo-earned threshold; no global camera warp is assumed.

### Prism Wall

A deliberate staff trace raises a fragile faceted barrier along the selected boundary. Segments assemble into a clear obstructing surface; incoming eligible attacks create localized refractive stress and a visible response toward the attacker if actual reflection occurs. Glassy assembly and clipped contacts precede a brittle break; camera none or light on destruction. Fragments lose collision appearance as they disperse. **Open:** reflect damage versus physical projectiles, eligibility, fraction and collision rules. Do not depict a projectile bouncing if only damage is returned.

### Prismatic Shield

The staff closes a small faceted envelope around the wizard. Its protected state has a clear shell and restrained internal light; eligible incoming hits ripple at their point of contact. A bright clean seal and soft deflections communicate protection; camera none so the shield does not feel like repeated damage. Near the actual end, facets loosen, then open and vanish. **Open:** duration, exact invulnerability and reflection; this cannot inherit Earth Shield's charge rules by visual similarity.

### XP Magnet / Arcane Restoration

A drawing gesture gathers a small attractor at the staff. Eligible experience objects bend inward along readable paths, accelerate toward the player and resolve with individual but voice-limited collection cues. Soft gathering hum and light pickup notes; camera none. The attractor fades when collection/activation ends, without a healing bloom. **Open:** a castable action versus always-available utility, attraction scope and excluded pickups. Do not imply health restoration from the historical name.

### Time Stop

The staff pinches a regular moving rhythm into stillness. A clear activation cue marks the moment enemies actually stop; affected actors hold a restrained frozen-time treatment while the wizard remains readable and active. Sound narrows into a suspended texture, then releases cleanly as time resumes; camera none during the hold, optional light activation cue. Resume motion and queued impacts deliberately, without an uncontrolled stack of audio peaks. **Open:** whether new casts wait, projectile handling, boss eligibility and combo-earned threshold. Do not freeze the game merely to produce the visual.

### Mirror Image

The staff sweeps through the caster's silhouette, leaving decoys that separate into readable places with a brief imperfect shimmer. Decoy movement and enemy attention should reveal actual distraction; a hit makes an image fracture rather than imitate a real player death. Use soft displaced footsteps/echoes and a glassy dispersal, with camera none. Images fade individually at end; ownership remains clear. **Open:** target rules, count, lifetimes and whether decoys reproduce harmless cast gestures.

### Polymorph

A compact twisting symbol forms at the staff and reaches the chosen target. The real transformation pulls the old silhouette inward and lets the new creature emerge in one readable transition, preserving the target's location. A short elastic warble and soft pop replace heavy impact audio; camera none. Reversion unwinds the treatment rather than looking like a new kill. **Open:** delivery, eligible creatures/bosses, new behavior and duration. An immune target needs a truthful failed transformation cue.

### Ward

A protective staff gesture traces a personal boundary that settles into a quiet, readable ready state. Actual prevented or reduced harm resolves locally against that boundary, then it reseals or breaks according to the chosen rule. Use a low clean activation and muted deflection notes; camera none except possibly a light final break. Expiry opens the boundary and removes the protection cue. **Open:** independent spell versus WARDING keyword, protection mechanism and cost; do not specify both as separate acquired spells without a decision.

### Fire Bolt

The staff kindles a compact flame, draws it into a hot head and throws it with a short forward snap. Flame tongues stretch backward, curl, detach and die; the core remains readable through the wake. Contact flares sharply at the victim, sheds embers and ends without Fireball's broad detonation. A quick breath of ignition, fiery release and short sizzle; camera none or light for a stronger hit. Misses lose heat quietly. **Open:** standalone acquisition and differentiation from a fire-modified Bolt. Use particle-driven material, not the rejected striped stroke.

### Fireball

A heavier mass of fire gathers at the staff with visible pressure, then launches as a substantial coherent body. Flames roll around the core and drag behind it. Actual impact opens the mass into a broad explosion, with outward embers and a short smoke response; the body clearly ceases to exist. Gathering roar, launch whoosh, sharp blast over a low thump; firm kick at detonation. Residue cools and clears. **Open:** blast extent/timing and recast balance; no persistent burning field unless selected.

### Scorching Ray

Heat collects into separate bright points around the staff head, then each releases a coherent beam toward an assigned enemy. Flame flow stays directional inside the lanes; contacts sear locally and track actual targeting. Use a sharp ignition and controlled sustained hiss with restrained tick contacts; camera none after release. Beams taper and cut off, leaving small cooling scorches where appropriate. **Open:** targeting allocation and duration. Separate enemy-aimed beams are the provisional direction; a V arrangement is an alternative, not an extra simultaneous mode.

### Flame Wall / Fire Wall

The staff plants heat into a large ring around the wizard; ignition runs around the circumference and erects strong upward tongues in the band. The center remains readable and traversable space. Real crossings and ongoing burns produce local reactions rather than explosive direct hits. A surrounding ignition whoosh gives way to a low sustained roar; one light establishment kick at most, none per tick. Flames shorten and die around the ring at expiry. **Open:** following versus fixed placement and rehit rules. Radius and band thickness scale proportionally; low direct damage and strong DoT remain the intended balance direction.

### Volcano

A heavy staff plant cracks the chosen ground and builds pressure beneath a vent. The initial eruption has a clear warning and heavy release; later lava lumps have distinct launch arcs, landing cues and material splashes. Sound shifts from subterranean rumble to eruption and intermittent lob/land phrases; firm initial kick, restrained later impacts. The vent dwindles to cooling rock. **Open:** its role beside Meteor Shower, projectile targeting and active lava aftermath. A persistent vent should not borrow Meteor's falling-from-the-sky identity.

### Fire Shield

Flame gathers from the staff into a compact protective mantle around the caster. Idle heat stays restrained; an actual qualifying hit concentrates it toward the attacker and releases the retaliatory blast. Use a quick ignition, muted protected contact and a distinct outward retaliation roar; light/firm kick only on the meaningful blast. The mantle dims or breaks as protection ends. **Open:** protection amount, eligible trigger, retaliation area and charges; no free retaliation from cosmetic near misses.

### Fire Orbit

The staff separates a flame cluster into orbiting bodies, each feeding a curved wake. Real contacts flare locally and leave only the actual burn status on the victim. A low establishment whoosh and sparse contact sizzles; camera none during repeated orbit. At expiry the bodies unravel tangentially into dying embers. **Open:** contact cadence and whether this is distinct enough from a fire-modified Orbit to warrant an authored identity. The lane must not appear to be an impassable wall.

### Flame Seed

The staff lowers a glowing ember into the ground. A readable dormant seed swells, sprouts and opens into a fire-flower turret only when maturation is real. Each actual attack gathers at the flower, launches and produces its own contact. Sounds move from a small plant hiss to opening crackle and compact firing bursts; camera none outside any selected major destruction. Withering/trampling and natural expiry have distinct endings. **Open:** growth time, trample, attacks, maturity, ownership and recast limits.

### Fire Golem

The staff draws nearby fire into an allied silhouette; limbs gain shape before the ally begins acting. Movement sheds low flames while an attack visibly gathers in its hands or mouth and commits toward the real target. Use a heavy ignition, restrained burning footsteps and a clear attack phrase; no constant camera shake. Death releases the bound fire and leaves cooling fragments. **Open:** copied kit spells, their ranks, ownership and target rules. A copied Ember Spear must retain its own contact sequence without looking like an extra player cast.

### Flaming Restoration

The staff draws controlled warmth toward the recipient, where it settles as an inward restorative pulse or an outward empowering mantle according to the selected benefit. Keep the release and ending gentle; use a warm ignition note and quiet heat texture, camera none. A healing resolution belongs only to a real heal, while a buff needs a distinct sustained cue. **Open:** whether it heals, buffs, or both, and what benefit it grants. No hostile burn aura is implied.

### Snowball

Cold compacts into a small dense ball at the staff, then is tossed or thrust along the chosen projectile path. Powder trails behind the solid center. Contact compresses and breaks it into icy fragments with a short chill cue. Soft icy release, crisp compact crunch; camera none. Unspent travel ends in a powdery breakup. **Open:** hit/chill tuning and distinct identity from Ice Blast's fan; no giant explosion or automatic freeze.

### Ice Spear / Glacial Spear / Glacial Lance

**Paused.** Preserve the possible brittle penetrating body and heavy cold-contact fantasy without selecting impale versus lateral shove. Either would need a clear staff thrust, travel wake, authoritative contact and fracture/expiry, with a narrow icy sound and restrained impact kick. The shove version must show actual sideways displacement; the impale version must show actual restraint. No implementation, acquisition, numeric balance or variant choice proceeds until this family is revisited.

### Water Jet

Water coils around the staff head, pressurizes, then releases as a connected stream with a strong leading flow. The caster aims while the water bends only as much as real tracking permits. Actual contact splashes and pushes according to the payload; spray falls away from the main stream. Pressurized release and sustained rush with heavier splash contacts; camera none after any light opening kick. The flow thins and droplets finish independently. **Open:** target allocation for extra jets and push limits.

### Water Whip

A hanging ribbon of water gathers from the staff, then the gesture sends a wave down its length into the lash tip. The tip's snap owns contact; detached droplets continue past the sweep. Use a wet swish, tight snap and falling splash, camera none or light at a strong contact. The ribbon breaks or retracts after the attack. **Open:** collision path, displacement and repeat rhythm. Do not render a rigid rotating line as a flexible whip.

### Tsunami

The staff pulls a broad body of water up behind the wizard, then drives it forward as a rectangular advancing wave. A clear crest carries momentum, with rolling water behind it and spray peeling off. Contact progresses across the front and applies real displacement; never depict a simultaneous radial hit. Deep gathering rush, broad breaking-water impact and receding wash; firm kick at the meaningful collision/release, not constant rumble. Water drains at the end. **Open:** propagation, push and trailing damage.

### Frost Nova

The staff draws heat inward, then releases cold in every direction. A thin advancing frost front is followed by branching rime and scattered chips; actual contact drives chill, with a stronger shell only on genuine freeze. A sharp cold intake, radial crystalline crack and fine settling ice; light/firm single kick. The front breaks at range and harmless rime thaws. **Open:** exact propagation and control profile; this authored design is distinct from the inactive legacy draft.

### Frost Strike / falling icicle

The staff lifts a cold point toward the target; a clear ground warning appears as an icicle forms above. Its visible descent resolves into the real impact, shattering outward with local cold feedback. A thin rising tone, falling whistle and brittle heavy crack; firm contact kick. Fragments settle and cold residue fades. **Open:** final name, warning duration, impact geometry and any aftermath; decorative fragments are not extra hits by default.

### Blizzard

The staff releases a gust that gathers a storm volume. Snow has a prevailing direction with turbulent eddies and changing density, rather than uniformly scattered screen noise. Local enemy cold responses follow actual exposure. Use a soft storm onset, controlled wind bed and sparse ice contacts; camera none during sustain. The wind loses density and remaining flakes drift out. **Open:** following versus independent motion and slow/freeze rules. Preserve threat silhouettes through the storm.

### Whirlpool / Maelstrom

A circular staff gesture establishes water rotation at the chosen center. Water accelerates inward along curved paths and creates a readable rotating rim. Enemy displacement and damage pulses follow actual forces; splashes come from real interactions. Use low circulating water and occasional intake splashes, camera none. Rotation slows and drains at expiry rather than exploding by default. **Open:** name, force limits, center behavior and escape/collision rules.

### Lightning Spear / Lightning Rod

**Paused.** Preserve the idea of a thrown conductive spear establishing a rod on a host or ground. A future script would distinguish launch, attachment, charge gathering, discharge and rod removal, with a sharp launch crack and discrete zaps rather than a constant full strike. No active damage ring or host-death behavior is selected. The paused status takes precedence over the existence of a data-only prototype.

### Static Shock

The staff maintains a live electrical source that commits its first arc to a real recipient. Each hop forms a legible conductive connection before the next contact resolves, with quick irregular branches confined near that path. Use a controlled electrical sustain and distinct short hop zaps; camera none for the chain rhythm. Arcs break in order when the channel ends or no next target exists. **Open:** channel rules, hop/retarget cadence and target exclusions; distinct from bouncing Lightning Bolt.

### Lightning Whip

Arcs gather along a flexible lash from the staff; a sweep sends charge toward the snapping tip. The actual contact gets a concentrated zap and short branching discharge on the victim. Electric gathering, airy lash and sharp tip crack; light contact kick at most. Remaining branches extinguish rapidly rather than leaving a solid beam. **Open:** contact geometry, timing and status payload; the electrical lash should preserve whip motion.

### Thunderwave

The caster braces and drives a pressure pulse outward from the staff/body. A surrounding radial front carries the actual push, with brief dust and air distortion that do not hide the enemy trajectories. A compact low gathering sound gives way to a broad thunder crack and short bass tail; firm single kick. The wave expands and breaks, leaving no persistent hazard. **Open:** displacement limits and propagation. This is radial, not the superseded travelling directional wave.

### Rain of Lightning / Lightning Rain

The raised staff calls a distributed set of charges into an area. Each chosen location gets a proportionate warning and distinct descending strike, with staggered branches and small ground aftershocks. Sound forms a sequence of sharp cracks at varied emphasis rather than one continuous overloaded roar. Bounded light/firm impact kicks preserve readable cadence. Ground sparks spend themselves between arrivals and stop when the spell ends. **Open:** warning rhythm, target selection and whether any live aftermath exists.

### Static Field

The staff deposits a charged ground source that settles into a clear boundary. Fine branches search inside it; actual ticks or selected enemy-to-enemy arcs become brighter, directional events. A restrained electrical bed and local zaps; camera none during sustain. The boundary breaks and residual charge becomes sparse before fading. **Open:** a meaningful mechanic beyond generic ticking damage. This must remain separate from the personal exposure-based storm aura.

### Tesla Wall

The staff establishes two solid coils, one after the other, and charge connects them into a passable electrical boundary. Coil solidity and the dangerous connecting line have different shapes. Crossing contacts produce local arcs; coil hits produce structural stress. Rising coil charge, steady restrained electrical tone and discrete crossing zaps; camera none except light destruction. When a coil breaks, its link visibly disconnects. **Open:** coil health, pathing, linked lifetime and damage behavior after one end is lost.

### Spike

The staff punches force into the chosen ground; a small earth warning cracks before a spike erupts into the actual target. Grit and fragments travel outward from the emergence, while bleed appears only on affected enemies. A short subterranean scrape and hard upward crack; light/firm contact kick. The spike collapses or retreats without implying permanent collision. **Open:** warning, persistence and exact hit timing.

### Bullet / Spray

Metal condenses into small hard projectiles at the staff tip; repeated releases have a stable firing rhythm and modest recoil. Thin travel streaks make direction clear without hiding individual shots. Real hits make clipped metal sparks and enemy responses; misses end quietly. Dry release snaps and compact metallic ticks, camera none for normal repeated shots. **Open:** one identity versus variants, cadence, spread and penetration; do not assume an actual firearm model.

### Boulder

Stone fragments gather into a weighty mass, then the staff heaves it along the real path. Rotation and grit communicate momentum. Contact has a dense crunch, actual push and chips thrown along the impact direction; the boulder does not become a fiery explosion. Low assembly rumble, heavy launch and firm contact kick. The remaining mass settles or breaks according to chosen lifetime/collision. **Open:** travel/collision response and knockback limits.

### Earth Spear

The staff draws grit into a rigid pointed shaft and thrusts it forward. The primary contact cracks the shaft into visibly smaller secondary spears that scatter along the selected trajectories; those have lighter contacts. Stone scrape, sharp primary fracture and small secondary ticks; light/firm primary kick, none per fragment. Dust and missed fragments settle promptly. **Open:** fragment targeting, count and eligible triggering contacts.

### Lance

**Reserved.** Preserve a close-range piercing thrust: a compact ready pose, decisive extension along a narrow line, hard contact and prompt recovery. A short thrust swish and clipped puncture with no routine shake would suit it. Reach, weapon manifestation, target selection and acquisition are not selected. Do not implement the reservation as another renamed Spear.

### Earth Blast

The staff compacts fragments, then releases a broad fan with weight in each piece. Actual contacts deliver debris, bleeding and the selected knockback; the fan must read as rough physical material rather than cold shards. A gravelly release and staggered crunches, with a light grouped kick. Fragments fall and dust clears. **Open:** spread and push limits; distinguish its force and abrasion from Ice Blast's cold control.

### Shrapnel

The chosen source releases a dense burst of small metal fragments with legible outward paths. Contact is sharp and brief, with sparks at actual victims and quieter fragments that miss. Use a concise metallic burst and scattered ticks; light or firm primary kick according to the selected source, no shake per fragment. End with settling debris. **Open:** delivery first—throw, placed charge, direct burst or another form. A grenade, fuse and explosion are not automatically selected.

### Earth Nova

The staff plants a forceful command into the ground and a radial sequence of spikes erupts outward. Each emergence carries local grit and contact, making progression understandable. Deep ground crack followed by expanding stone breaks; firm initial/major impact response, not an unbounded shake for every spike. Spikes lose their threatening posture as the damage phase ends. **Open:** propagation, persistence and collision; bleed follows the actual payload.

### Earth Wall / Earth Walls / Stonewall

A deliberate staff trace raises a physical barrier, with heavy chunks locking together along the chosen boundary. Local hits chip that location and progressively expose damage; a breach opens visible traversable space. Stone grinding and weighty hit knocks, light/firm response on substantial collapse. Broken fragments settle without retaining false collision. **Open:** single wall versus enclosure, placement, health, pathing and whether collapse damages anything.

### Earth Trap

The staff lays a rough buried pattern, then the ground becomes a quiet armed patch. Trigger drives spikes upward around real victims, with a visible brief immobilizing connection and actual bleed cues. Low placement scrape, sharp springing crack and restrained chips; light contact kick. Once spent, spikes break/retract and the restraint visibly releases. **Open:** arming, activation limits and persistence after triggering.

### Muck

A low staff sweep lays thick slowing ground along the selected route. The surface stretches and settles around footsteps; actual slowed enemies show drag without being secretly rooted. Wet earth release and subdued sticky movement accents; camera none. The patch dries or sinks as slowing ends, leaving a clearly spent stain. **Open:** placement, duration and later fire/oil interaction; no ignition behavior until selected.

### Earth Golem / Summon Golem / Golem

Stone rises around a core at the staff's command and assembles into a visible ally. Heavy footsteps settle weight locally; an attack draws back before committing, then scatters grit on contact. Deep assembly knocks, bounded footsteps and distinct attack crunches; light/firm attack camera feedback only if the ally deserves that screen priority, never every step. Death collapses the body into inactive rubble. **Open:** taunt, attacks, kit access, ownership and limits.

### Earthquake

**Reserved.** A staff plant could send uneven ground stress through an area, with local cracks leading actual eruptions and displacement. Low rumble should support discrete heavy moments instead of constant nausea-inducing shake; accessible motion alternatives are essential. Ground settles as danger ends. Decide a distinct mechanic against Earth Nova before selecting timing, damage, force or a large persistent camera treatment.

### Carcass (unnamed)

The staff gathers or lifts infected remains, then hurls them on a readable lob with a clear destination. Landing breaks the mass into a diseased ground zone; actual exposure drives local host effects. Heavy wet release, dense landing and subdued unhealthy bubbling, light/firm landing kick. The dead zone loses active secretion before its residue decays. **Open:** final name, source, arc, warning and infection payload. Do not assume corpse consumption unless selected.

### Ray of Sickness

An unhealthy pressure gathers at the staff and releases as a coherent searching ray. A sweep or pivot across the crowd visibly reaches each recipient; debuff application is separate from the ray's decorative haze. Use an uneasy low sustain and short wet contact accents; camera none. The beam pinches off and the final vapor dissipates, while actual statuses retain their own durations. **Open:** sweep versus tracking, DoT, slow and weakened payload.

### Grasping Hand

A contracting gesture at the staff calls a spectral hand from the chosen area. Fingers approach and close around actual recipients; a hold, pull or crush must be visibly distinct if selected. Sound moves from a low breath to a concentrated grip accent; light/firm kick only for an actual crush, none for holding. Release opens the fingers and lets them unravel. **Open:** which phases exist, timing, target limits and force; a decorative hand cannot imply restraint on a free enemy.

### Raise Dead

The staff reaches toward eligible corpses; energy enters each source before an ally visibly rises from it. Formation ends before independent movement and attacks begin. Use a restrained summoning whisper, rising-body material sounds and the ally's own attack cues; camera none for ordinary raising. A failed/invalid corpse gets no false ally emergence. Allies collapse or unbind at their actual end. **Open:** corpse eligibility/consumption, ally types, caps and ownership.

### Hex

A small deliberate gesture knots a mark at the staff and delivers it to the chosen victim. Application makes the mark grip the silhouette; vulnerability remains restrained and identifiable beside other statuses. A short binding whisper/click and quiet expiry; camera none. The mark loosens and disappears when the effect ends. **Open:** delivery, eligibility, duration and recast behavior. A curse cue must not pretend to be direct damage when there is none.

### Plague Spear, Nova, Shower, Field, Wall, Trail, Trap

**Open exploration slots, not seven selected spells.** Preserve a shared material hypothesis—swollen sources, creeping transfer, wet contact and unhealthy residue—but do not invent names, acquisition or seven payloads to fill the matrix. Once a distinct identity is selected, specify its staff gesture, delivery, application, sustain, sound and ending using the matching geometry contract above. Camera should ordinarily remain quiet, reserving weight for a real major release. **Decision required:** one actual purpose and complete behavior per selected identity.

### Vine Ball (unnamed)

A living knot gathers at the staff and is sent to the target area. On actual arrival it unfurls into reaching vines; visible ground connections explain immobilization. A woody release, unfurling rustle and tightening grip accents; light impact cue at most. The vines relax, dry and withdraw when restraint ends. **Open:** name, delivery details and bleeding. Do not add a damaging explosion merely because the source is ball-shaped.

### Shillelagh / Life Spear

A staff thrust sends living growth along a line, leaving a readable rooting trail. Vines reach from that trail toward eligible enemies and visibly draw them into it; the pull and the rooted connection are distinct steps. Use a woody thrust, travelling root cracks and short tightening creaks; light contact feedback, no constant shaking during restraint. Roots release and wither when their actual effect ends. **Open:** line/travel geometry, pull limits and rehit timing. This is one spell, not separate Life Spear and Shillelagh acquisitions.

### Vine Whip

A growing vine extends from the staff, then transmits the casting gesture along a flexible length to its tip. A real lash has a visible snap and local plant/impact response; thorns and leaves follow the motion rather than forming a rigid green beam. Woody swish, sharp fibrous contact and soft leaf fall; camera none or light on a heavy hit. Retraction or withering ends the attack. **Open:** contact path, timing and status payload.

### Crushing Vines / expanding vine circle / Life Nova

The staff calls roots into a circular front that grows outward through the ground. Vines reach and tighten on real recipients, with separate growth, restraint and crushing accents if those phases are selected. Root creaks and a firm tightening sound support the strongest actual hit; camera light/firm at that moment, none during ordinary growth. Plants relax and wither as control ends. **Open:** root versus slow, propagation and whether the names describe one identity.

### Exploding Flowers / poisonous flowers

The staff scatters buds toward selected locations; each becomes readable before its actual bloom or burst. A poisonous opening would release controlled drifting pollen; an explosive flower would visibly tense and snap outward. Planting rustle and either soft pollen release or a compact organic pop; camera none for poison ticks, light for a substantial burst. Petals settle and danger visibly ends. **Open:** strike versus shower, poison versus burst, and triggering conditions. Alternatives are not separate confirmed spells.

### Flower Trail / vine trail

A staff gesture sends growth toward the wizard's route. New plants emerge behind real movement; each patch matures and expires independently. Flowers release pollen where poison is real; vines visibly writhe where they control. Soft travelling growth sounds and restrained local contacts, camera none. Spent plants droop and withdraw so old paths stop looking dangerous. **Open:** flower poison versus roiling-vine behavior, spacing and duration; choose the identity before building both.

### Yggdrasil / Tree of Life / World Tree

The staff plants a powerful seed and roots spread before the trunk rises into a visible tree. Growth communicates increasing presence; healing reaches the wizard with inward restorative cues while harmful roots or other selected attacks clearly connect to enemies. Deep woody growth, leaf movement, warm healing and distinct hostile contacts; firm establishment cue at most, no continuous camera shaking. Destruction and natural withering need different endings. **Open:** growth stages, maturity, destructibility, hostile mechanism and combo threshold if ultimate. Preserve one identity across these names.

### Dash

A short directional preparation draws the caster's silhouette toward the intended route, then releases into a decisive movement burst. A brief path-following wake marks where the wizard travelled; arrival has a controlled settling cue rather than an automatic damage blast. Sharp displacement swish and soft landing; camera none by default so aim remains readable. Cancel/blocked movement must not show a completed dash. **Open:** immediate versus stored charge, direction, collision, invulnerability, damage and limits.

### Swiftness

The staff loosens a small windlike ribbon around the caster's movement. Activation opens the posture; actual faster travel stretches a restrained wake that relaxes at rest. Soft rising release and sparse motion accents; camera none. The ribbon slackens when the speed benefit ends, without implying a stun. **Open:** magnitude, duration and refresh. Do not use a constant screen blur to communicate speed.

### Personal storm aura

The staff gathers a small storm around the wizard or selected location. A readable exposure region is present, but it does not look like instant contact damage. Each enemy's real dwell progress gathers charge toward that enemy; completed exposure produces its own strike and response. Quiet charged ambience, then discrete cracks; bounded light/firm kicks on significant strikes, none for merely entering. Expiry releases remaining unspent charge harmlessly. **Open:** name, following versus fixed, exposure reset and repeat rules. Level-ups extend duration; kills do not. Keep this distinct from Static Field.

## Signature and deferred combination sequences

### Homing Bolt

The staff launches a clear leading bolt whose wake remembers the turns. Guidance is purposeful: turn toward the actual target rather than wobbling randomly, and keep any spiral readable around a forward path. Contact is compact; misses or lost targets dissipate according to the real rule. Focused release note and small hit accent, camera none. **Open:** special HOMING expression, smaller guided copies and signature distinction. This is not automatically an extra base acquisition.

### Ring of Meteors

A skyward staff call establishes distinct heavy rocks in orbit, each with its own burning wake. A release command or selected automatic rule then sends individual rocks toward real enemies; their warnings and impacts retain separate heavy beats. Orbital rumble gives way to descending rushes and impacts, with bounded repeated firm kicks. Unreleased rocks need an explicit end rule. **Open:** release trigger, targets and whether this upgrades Meteor Shower or is separately acquired.

### Sunbeam

A solar focus builds above the staff, then releases a powerful clean ray with visible source, direction and contact pressure. The center is bright but bounded; heat and light spill away from actual hits without washing out the whole arena. A rising clear tone, strong release and controlled sustained roar; firm initial/major contact kick, not constant shaking. End by narrowing the beam and releasing residual warmth. **Open:** recipe, acquisition, duration and payload. Sun remains a combination theme; no ingredients are selected here.

### Moon Slash / Crescent Slash

The staff draws a cool crescent and releases multiple purple cutting forms with deliberate spacing. Each has a crisp advancing edge, a softer trailing wake and its own actual contact. Use airy glasslike swishes and clipped cool impacts; light bounded feedback on significant hits. Crescents thin into drifting particles after their range or contact limit. **Open:** recipe, targeting, copy rhythm and acquisition. Do not treat this as a recolor automatically approved by the Arcane Slash script.

### Moonfall

The staff calls a cool descending mass toward a marked location. Its arrival creates a clearly bounded aftermath whose enemy harm and friendly healing resolve differently at their recipients. A distant gathering tone, weighty soft-edged impact and quieter pulsing aftermath; firm initial kick, none for healing or regular ticks. The area loses active structure before moonlit residue fades. **Open:** recipe, scope, timing and payload; falling magic and the dual aftermath must share one readable identity.

## Parked identities and unselected alternatives

The following entries remain preserved in [doc 3](03-spells.md), but do not yet have enough selected behavior for an implementation script. This is a deliberate unresolved-design list, not a missing set of secretly approved spells. Start a sequence only after the identity is selected; apply the shared staff, contact, sound and ending contract then.

| Preserved names | Decision before a complete script |
|---|---|
| Arcane Orb | What a slow impact body contributes beside Bolt, Orbit and Fireball. |
| Pulse; Wave; Splash | Separate identities versus local/radial geometry expressions. |
| Gravity Well | Relationship to Black Hole and whether it is the same spell. |
| Arcane Missiles; Time Warp; Arcane Turret | Select a distinct volley, time mechanic or stationary summon; old inactive drafts are not approval. |
| Plague / Plague Nut | Select the small infection identity and its relationship to Infection. |
| Thorn Volley; Venom Mark; Spore Bloom | Choose fan, delayed mark or nursery behaviors and acquisition individually. |
| Chain Heal | Allied recipients and traversal must exist before a connected healing sequence is designed. |
| Seeking Spirit; Reaping Spirit | Distinguish from Seeker/Soul Bloom; Reaping Spirit remains disabled, not an eighth current combination. |
| Skeleton Warrior; Flame Elemental | Select allied behaviors and distinguish from Raise Dead and Fire Golem. |
| Fire | Grammar/base-word decision; not another implementation implied by FIERY. |
| Undertow; Tidal Wave; Ice Shard | Select return-band, large-wave or small-projectile identities without silently aliasing them to Tsunami/Snowball. |
| Chain Lightning; Thunder Spear; Tempest | Select immediate chain, delayed spear or weather roles; do not bypass the paused Lightning Spear family. |
| Earth Bolt; Stone | Resolve projectile identity and distinction from Boulder/Bullet. |
| Slash / Whip starters; Crescent | Character weapon/acquisition and possible moon ingredient identity. |
| Daybreak; Solar Flare | Resolve solar burst/fan identities; Sun remains a combination theme. |
| Explosion — ritual incantation | Full chant, interruption, release word, scope and damage must be selected before a multi-stage ritual script. |
| Super Extreme Meteor Shower Deluxe | Decide mastery expression and parser behavior; not a free alias or an automatic larger meteor cast. |
| Boots of Hermes | Equipment/charges/persistence and its relationship to Dash. |
| Regrowth / Heal; Lightning Arc / Thunder; Returning Blade / Boomerang; Fire Trail / Ember Trail | Historical names, not extra spells or approved short incantations. |

Frost Ray / Ice Ray, Tidal Push and Divine Aura remain removed/dropped; Firestorm remains questioned beside Meteor Shower; Arcane Shield remains unselected. Generic matrix-fill examples (including Arcane Ball, Mana Spear/Strike/Seed/Golem, Water Spear, Lightning Ball, Earth Wave, elemental slices, Fire Cone/Blast/Wave/Nova/Sigil, Ice/Water Wall, plain Rain/Water Field, Life Seed, Frostball and Plague Ball) do not gain design approval from this brief. The catalog owns their full disposition.

## Enemy spell readability

Enemy spells use the same material quality but a distinct threat presentation. Player spell beauty cannot erase hostile warnings. Do not make every elite cast borrow the player's staff pose; animate the actual enemy's body/source and preserve its own silhouette. Enemy warnings must remain distinguishable by shape/motion and source, not only hue.

- **Elite meteor (`elite_meteor`):** the enemy calls down a hot mass and marks the actual target with a clear hostile warning for its real 1.1-second window. Descent, blast and player-hit feedback coincide with impact; the remaining burning ground retains a distinct active boundary until its damage ends. Gathering pressure, falling rush, heavy local impact and quieter ground burn form separate beats. Nearby impact can have bounded weight without confusing it with a player cast or obscuring the next warning.
- **Elite frost burst (`elite_frost_burst`):** the enemy gathers cold inside its actual 0.8-second warning, then sends the expanding ring outward. A distinct hostile leading edge communicates when it will reach the player; chips settle behind it. Cold gathering and expanding crack, with player-contact feedback only on a real hit. The safe interior must not falsely look active.
- **Elite lightning (`elite_lightning`):** the enemy source visibly charges and places the actual warning at the target. Preserve the longer hostile warning window; the descending strike and player response coincide with real damage. The crack and ground aftershock are local; spent ground does not remain a false hazard. This does not shorten enemy reaction time to match the faster player Lightning.

Other enemy attacks retain their own design owners. This brief adds quality requirements to shared spell presentations, not new elite words or attacks.

## Prototype order and acceptance

### First playable batches

1. **Lightning sequence:** staff charge/ground gesture, truthful target warning, descending strike, contact, sound, camera and spent charge. This tests the whole sequence in one high-contrast example.
2. **Continuous material and spirits:** Steam volume and dissipation; Seeker/Soul Bloom yielding bodies, independent trails and actual arrival/contact. Evaluate the existing behavior first, then compare selected spirit-behavior prototypes separately.
3. **Quick attacks:** Bolt, Magic Missile, Ember Spear, Ice Blast and Cross Blade. Protect responsiveness, distinct contact rhythms and heavy-versus-light contrast.
4. **Sustained and defensive:** Cinder Field, Fire Walk, Orbit, Focus Ray, healing, Earth Shield and traps. Focus on actual state changes, local tick feedback and clean endings.
5. **Combinations and stress:** all seven recipes, ranked/copy variants, accepted modifiers, stacked statuses and simultaneous enemy attacks. Preserve the meteor cascade throughout; refine its weak phases without flattening its enjoyed rhythm.

This order covers the current roster before promoting the future catalog into implementation. It does not replace the agreed release roadmap or select a smaller future spell catalog. Existing strong phases can be retained; each spell still receives a full-sequence review.

### A B requires evidence in play

For each current spell, grade six columns: **fantasy**, **visual quality**, **motion and behavior**, **casting and impact**, **sound and camera**, and **readability**. Ending/cleanup belongs in motion and readability; enemy response belongs in casting/impact. Every column must be in the C band or higher (C− is acceptable), and the arithmetic mean must reach B (3.0). Use A+=4.3, A=4.0, A−=3.7, B+=3.3, B=3.0, B−=2.7, C+=2.3, C=2.0, C−=1.7, D+=1.3, D=1.0, D−=0.7 and F=0. A missing observation is untested, never zero or an invented grade. An incomplete row cannot pass; a mean of observed columns may be shown only as a clearly labeled partial mean. These are working artistic judgments, not objective measurements.

**Fantasy leads the recommendations.** Preserve an exceptional identity even when its readability is merely C−; improve comprehension around the essential effect instead of stripping away its character. For example, an Ember Spear with A+ fantasy and C− readability is not automatically a redesign candidate. The average remains unweighted as requested; fantasy priority governs what to preserve and which improvements to pursue. Simplicity can earn an A.

Capture the complete candidate in motion with sound and a real moving enemy, then a crowded encounter with another player spell and an enemy threat. Compare normal size, meaningful rank/copy upgrades, rapid recasts, target death, expiry, pause, reduced effects and narrow geometry. Observe miss, block/resist, heal-at-full-health and cancellation when applicable. Use the actual release/damage events to verify alignment. A tiny fast spell should be sampled well enough that its full life is not skipped between screenshots.

Keep technical correctness, subjective feel, audio and performance findings separate. Record exact revision, test path, capture conditions, known limitations and the user's acceptance/disposition. Headless validation can establish behavior; sampled screenshots cannot certify motion or sound. Do not open visible Godot windows without an explicit request. A beautiful isolated frame does not certify crowded combat, and a clean test run does not certify a B.

Show each artistic batch for judgment before treating it as accepted or integrating it as the new default. User feedback can reject a treatment without rejecting the spell's fantasy. Iterate the deficient phase, or change the approach when the approach is the problem; do not increase particle count, shake and loudness everywhere to manufacture a higher grade.

### Decisions to settle before behavior changes

Keep a short decision record for target ownership/retargeting, damaging geometry versus decorative trails, attack cadence, lifetime, recast/cap rules, rank changes and compatible modifiers. For spirit alternatives, explicitly choose orbit-host damage versus collision damage and one-pass versus persistent attacks. For Lightning, decide whether ground charge is harmless residue or a new payload. For Flame Wall, settle placement/movement and contact cadence. Paused spear families remain paused; undefined catalog cells remain undefined. Sound assets and their licenses must be tracked when assets are selected; no specific external sound or paid acquisition is mandated here.


## Current spell audit — 15 October 2026

**Status: provisional visual audit; full spell-feel gate INCOMPLETE.** Candidate `a96ddd56c42e8759371ef7918dc564d016cbdbf0`. All 31 current player spell/form/special sequences were captured in a background Chromium Web build using the real Game scene and spell engine. This is a dated assessment, not an approval of the current effects or a claim that the game meets the target. Future catalog spells have no running implementation to grade here; their design scripts remain proposals.

The six-column rubric above applies. **U means untested.** The final six-column average is withheld for every row because sound was not audibly reviewed. The numeric partial mean uses the five observed columns only; B corresponds to 3.00. Do not treat it as a passing overall grade. All visible grades are provisional judgments from recorded frame sequences: casting/impact describes the observed release and contact, not a certified typing-response test, and motion describes path/material changes, not a frame-time benchmark. Fantasy remains the priority when choosing what to preserve or improve.

### Evidence and coverage

The preserved evidence bundle is located at `/Users/ljeytl/.codex/visualizations/2026/10/15/spell-feel-audit-a96ddd5/index.html`. Its absolute location, case count and manifest checksum are recorded in the [audit data](spell-feel-audit-2026-10-15.json); the bundle manifest inventories fixture and recording hashes. It contains per-spell WebM recordings, full frames, chronological frame sheets, console logs, test results and the fixture overlays/runners. Base captures use 1280×800 geometry, fourteen slowly moving enemies, an invincible wizard following the showcase path, and two to five repeated casts. Automatic Magic Missile is disabled in other cases so it cannot be mistaken for the reviewed spell; its own case invokes its actual firing method at showcase cadence. Atomic uses its actual blast directly, bypassing acquisition. Earth Shield's block is deliberately triggered by the showcase. These fixture differences limit the verdict.

| Obligation | Observed evidence and disposition |
|---|---|
| Current roster and combinations | 31 base recordings; real spell engine and game scene. Visual sequences reviewed, including dense opening samples for fast attacks. Provisional artistic grades below. |
| Material, movement, contact and ending | Recorded sequences plus source audit. Short shots need dense samples; four-frame-per-second summary sheets alone are insufficient. No native performance certification. |
| Sound and camera as a complete experience | Recordings have no audio track. Source mappings inspected; camera effects remain enabled. Audible mix, fatigue, synchronization and full combined feel are UNTESTED; column U. |
| Player typing, responsiveness and cancellation | Showcase invokes casts. Full manual input, cancellation and recovery journeys are UNTESTED; release/contact observations do not discharge them. |
| Spirit comparison | Seeker ghost and wisp; Soul Bloom normal and quarter-speed cases, including full-health and explicitly wounded fixtures. Slow motion reveals appearance but does not establish normal-speed feel. |
| Expiry and quiet waiting | Corrected empty-enemy fixtures: Steam clears after the cast stops; Rune Trap remains visibly armed; bare Trap disappears after its finite lifetime. Initial empty cases retained one setup enemy and are superseded by `_verified` cases. |
| Recasts, size and modifiers | Repeated base casts across roster; larger Steam at 640×800; FIERY DOUBLE Bolt. Complete rank progression and modifier combinations remain UNTESTED. |
| Crowded combat | Fourteen moving enemies expose overlap, but they are slow and the caster is invincible. Mixed late-run enemy attacks, multiple simultaneous spell families and survival-pressure response remain UNTESTED. |
| Narrow layout | Larger Steam reviewed at 640×800. Cloud retains its identity; the bottom active-spell text overlaps the minimap area. Layout issue OPEN, separate from the cloud's artistic grade. Other narrow spell/layout cases UNTESTED. |
| Reduced effects and pause | Reduced Lightning captured. Showcase-cycle pause used to observe expiry; it is not game pause. Full reduced-effects sibling sweep, actual pause/resume, save/reopen and lifecycle interruption remain UNTESTED. |
| Misses, blocks and recipient states | Empty cases and synthetic shield block observed; wounded healing fixtures log health=30 at cast. Full resist/immunity, blocked-damage and all healing-at-full-health cases remain UNTESTED. |
| Review controls | Runtime error collector deliberately challenged by a known error; grading controls reject a D despite a high average, reject B− average, accept a C− floor with a high enough average, and keep U incomplete. These controls validate the mechanism, not aesthetic quality. |

No runtime/art changes were made during this audit. The working showcase copy uses an isolated save identity and compatibility renderer, with explicit fixture controls for the above cases. Normal-speed captures and slow-motion diagnostic captures are separate. Apparent capture stalls must not be reported as a measured game-performance defect.

### Provisional scorecard

Columns are fantasy, visuals, motion/behavior, casting/impact, sound/camera and readability. The last numeric column is **partial**, not the requested final average. Every final verdict is INCOMPLETE until the missing evidence is reviewed. Cross Blade and Atomic additionally have observed columns below the allowed C band.

| Runtime | Spell | Fantasy | Visuals | Motion | Cast/impact | Sound/camera | Readability | Partial mean / 4.3 |
|---|---|---|---|---|---|---|---|---|
| `bolt` | Bolt | B- | B- | B | C+ | U | B | 2.74 |
| `life` | Life | C+ | C+ | C+ | C | U | B- | 2.32 |
| `regeneration` | Regeneration | C | C+ | C | C | U | C+ | 2.12 |
| `ice_blast` | Ice Blast | B- | C+ | B- | C+ | U | B- | 2.54 |
| `earth_shield` | Earth Shield | B- | B- | B- | B | U | C+ | 2.68 |
| `lightning` | Lightning | B | B- | B- | B | U | B | 2.88 |
| `meteor_shower` | Meteor Shower | B+ | B | B+ | B+ | U | B- | 3.12 |
| `ember_spear` | Ember Spear | B+ | B- | B | B | U | C+ | 2.86 |
| `infestation` | Infestation | C+ | C | C+ | C | U | C+ | 2.18 |
| `cinder_field` | Cinder Field | B- | B- | C+ | C+ | U | B- | 2.54 |
| `arcane_orbit` | Arcane Orbit | C+ | C | B- | C+ | U | B | 2.46 |
| `focus_ray` | Focus Ray | B- | C+ | B- | C+ | U | B | 2.60 |
| `rune_trap` | Rune Trap | B | B- | B- | B | U | C+ | 2.74 |
| `seeker` | Seeker | B- | B | C+ | C | U | C+ | 2.46 |
| `firewalk` | Fire Walk | B- | C+ | B- | C | U | C+ | 2.40 |
| `cross_blade` | Cross Blade | C- | D+ | C+ | D+ | U | C- | 1.66 |
| `lightning_bolt` | Lightning Bolt | B | C+ | B | B | U | C+ | 2.72 |
| `life_bolt` | Life Bolt | C+ | C+ | B- | C | U | C- | 2.20 |
| `meteor_spear` | Meteor Spear | B+ | B- | B | B+ | U | C | 2.86 |
| `soul_bloom` | Soul Bloom | C+ | B- | C | C | U | C- | 2.14 |
| `steam_field` | Steam Field | B+ | B+ | B | C+ | U | C+ | 2.84 |
| `prism_ray` | Prism Ray | B | C+ | B- | C+ | U | C- | 2.40 |
| `frost_sigil` | Frost Sigil | C+ | C+ | B- | B | U | C+ | 2.52 |
| `mana_bolt` | Magic Missile | B | B | B | C+ | U | B | 2.86 |
| `spear` | Bare Spear | B- | B- | B | C+ | U | B- | 2.68 |
| `slash` | Bare Slash | C+ | C | C+ | C+ | U | C+ | 2.24 |
| `nova` | Bare Nova | B- | B- | B | C+ | U | B | 2.74 |
| `field` | Bare Field | C+ | C+ | C+ | C | U | C+ | 2.24 |
| `orbit` | Bare Orbit | B- | B- | B | C+ | U | B | 2.74 |
| `trap` | Bare Trap | C+ | C+ | C+ | C+ | U | C+ | 2.30 |
| `atomic` | Atomic | D+ | C- | C | C+ | U | B- | 2.00 |

### Findings and strongest improvement per spell

Each proposal below is OPEN. It describes a direction for a prototype, not permission to change damage, timing, targeting or acquisition. Preserve the strong identity before polishing its weaker dimensions.

**Bolt — observed:** A compact white-purple head and short trail communicate a quick directed shot. The contact is much less memorable than the launch; the staff does not visibly author a distinct flick.

**Strongest idea:** Preserve the fast minimal projectile. Tighten the staff-tip release and give the real contact one clean directional spark rather than a larger explosion.

**Life — observed:** The green-gold cross ring clearly signals healing, but floats around the caster like a buff badge rather than a decisive breath of recovery.

**Strongest idea:** Pull a compact pulse into the body on the actual heal, then let a few warm motes rise. Keep it instant and distinguish it from the sustained Regeneration ring.

**Regeneration — observed:** The sustained yellow-green crosses and ring remain visible, but look very similar to Life. Continuous decoration communicates an active buff more than living repair.

**Strongest idea:** Make a quiet breathing rhythm with sparse leaves gathering inward on recovery. Preserve a low steady aura and avoid repeated full Life bursts.

**Ice Blast — observed:** The cold fan, scattered chips and icy contact read as frost. Large outlined shards and scattered white marks dominate the release without a particularly brittle material transition.

**Strongest idea:** Preserve the fan. Give the advancing shards a crisp edge and make contacts fracture into smaller directional chips, with fewer persistent white marks around the caster.

**Earth Shield — observed:** The triggered eruption has recognizable stone chunks and a convincing outward breakup. The brief protection and its consumption are less explicit than the eruption itself; this fixture triggers the block directly.

**Strongest idea:** Make one protective stone shell assemble, visibly take the incoming hit, then break into the existing eruption. The single charge should look spent afterward.

**Lightning — observed:** A blue warning ring, descending white bolt, bright impact and dark residue form a recognizable strike. The caster stays visually detached and the aftermath is mostly a ring/scorch rather than branching charge.

**Strongest idea:** Build the staff gather/slam connection, then let a few ground arcs spread from the actual strike and die away. Preserve the strong bolt; do not add new damage or casting delay by implication.

**Meteor Shower — observed:** Separate hot arrivals, bright contacts and cooling patches give this a strong repeated-impact identity. The fire has weight and color; the coarse dark residue is less convincing than the arrivals.

**Strongest idea:** Keep the stagger and repeated impacts. Refine descending trails and crater cooling so each arrival becomes hot debris and spent ground without synchronizing the shower.

**Ember Spear — observed:** The long hot lance and persistent fiery route strongly communicate burning penetration. The straight black strip with orange outline looks mechanically drawn compared with the lively flames above it.

**Strongest idea:** Preserve heat, reach and force. Break up the strip into an irregular scorched path with moving low flame, keeping the spear head distinct from its damaging wake.

**Infestation — observed:** Green black-outlined blobs travel and collect around enemies. They suggest poison, but host infection and transmission look like similar loose particles rather than a sickness taking hold.

**Strongest idea:** Anchor a compact crawling/pulsing growth to the infected host, then let a visibly released spore travel to the next host. Give application and spread different motion.

**Cinder Field — observed:** Orange fire over dark ground convincingly occupies an area. A hard circular border and repeated tall flames read more as a generic fire patch than a bed of cinders.

**Strongest idea:** Keep the heat and saturated color. Emphasize glowing coal pockets, low licking flame and hot ash stirred at real damage contacts; let the edge cool unevenly.

**Arcane Orbit — observed:** Two large purple-white bodies visibly orbit and touch enemies, but their solid outlined, simply shaded surfaces resemble physical balls more than controlled magical energy.

**Strongest idea:** Keep two clear bodies and their orbit. Let light circulate within each shell and leave a short curved particle wake; concentrate the contact accent on the leading edge.

**Focus Ray — observed:** A clear white-purple beam connects caster and target, tracks and stops. Its uniform striped body and modest endpoint response communicate a line better than sustained pressure.

**Strongest idea:** Keep the clean beam. Add subtle forward flow and a concentrated contact point that responds to real ticks, plus a brief narrowing shutdown rather than extra screen effects.

**Rune Trap — observed:** The glyph circle and triggered burst communicate authored magic. Similar rings in the armed, warning and aftermath phases make the state transition less distinct than it could be.

**Strongest idea:** Keep the runic geometry. Draw the inscription once, wait quietly, then snap its symbols inward during the actual trigger warning before the blast opens outward.

**Seeker — observed:** The painted ghost is a clear centerpiece and turns while pursuing. Close pursuit tends to stack bodies over the victim, with weak separation between gliding, touching and dealing damage.

**Strongest idea:** Preserve the body. Add a genuinely lagging trail and a distinct real-contact contraction/release. Compare deliberate passing attacks only as a separately approved behavior prototype.

**Fire Walk — observed:** A low fiery wake visibly follows the caster path. Small isolated flame clumps and checker-like scorch make the trail feel intermittent rather than a continuous hot wake.

**Strongest idea:** Keep the ground-hugging scale. Connect neighboring flames through short-lived heat and embers, show ignition directly behind each step, and let older patches cool in path order.

**Cross Blade — observed:** At gameplay scale the blade is a thin dark rotating cross accompanied by white flecks. Its body and contacts have too little presence for a substantial spinning cutter, and the stronger return is not visually obvious.

**Strongest idea:** Give the existing blade a solid readable edge and short curved cutting wake without expanding its hitbox. Accent the reversal and actual return contacts; keep the three-phase behavior.

**Lightning Bolt — observed:** Repeated local lightning impacts and expanding rings give a strong electrical payoff. The traveling cause is easily lost among the later bright blasts and dark residue.

**Strongest idea:** Make each projectile contact leave a compact electrical mark that visibly becomes its delayed sky strike. Preserve the cascade while shortening distracting spent-ring emphasis.

**Life Bolt — observed:** A shot is followed by green-gold rings and crosses among enemies and around the wizard. The shared healing motif makes the enemy hit, available recovery and received healing difficult to distinguish.

**Strongest idea:** Use a small planted sprout for available recovery and reserve the inward warm pulse for actual healing. Preserve the offensive projectile; do not make damaging contact look like healing the enemy.

**Meteor Spear — observed:** The burning line followed by separate falling fireballs gives the combination a substantial escalating payoff. Hard trail rectangles and overlapping contact bursts make its causal sequence less elegant than its force.

**Strongest idea:** Keep penetration and staggered follow-up impacts. Mark the pierced contacts briefly, then make each descending meteor visibly answer a mark; refine the same artificial trail edge as Ember Spear.

**Soul Bloom — observed:** The slow-motion wisp comparison reveals an appealing luminous soul traveling toward the wizard. At normal speed, infection particles and arrival flashes dominate; short nearby deliveries do not consistently establish the spirit as the centerpiece. The full-health ghost delivery is especially brief.

**Strongest idea:** Keep the approved spirit body and immediate gameplay delivery. Let a visible emergence and absorption remnant complete independently, and render an actual path-following trail. Do not slow healing or add orbit behavior without a separate decision.

**Steam Field — observed:** Soft blue-white connected vapor has volume and shifting lobes; it is unmistakably different from Cinder Field. It convincingly obscures the occupied area, but local scalding consequences are less tangible than the cloud itself.

**Strongest idea:** Preserve the obscuring cloud and color depth. Give its base a few directional vent streams and let genuine scald contacts briefly disturb the vapor locally; do not replace it with a transparent circle.

**Prism Ray — observed:** A broad central ray fans into many colored beams, strongly communicating a combination spectacle. Similar-strength branches and a busy intersection weaken the sense of one ray being refracted at a deliberate focal point.

**Strongest idea:** Make a bright compact refraction knot at the real split, maintain a confident primary ray and give branches lighter material tails. Keep the rainbow fan rather than sanitizing away the fantasy.

**Frost Sigil — observed:** The cold glyph distinguishes the waiting trap, but its large white detonation and dark checker-like aftermath resemble the generic explosion family more than a cold fracture.

**Strongest idea:** Preserve the forceful trigger. Make frost race along the inscription and burst into brittle fragments; fade into cold rime rather than a burnt-looking patch.

**Magic Missile — observed:** Dense opening frames show a small guided dart, sparse wake and compact contact. It stays subordinate to the fight, as a passive cast should; its endpoint could be a little more tactile.

**Strongest idea:** Keep the current scale and simplicity. Refine the tiny contact accent and evaluate repeated sound fatigue at the real automatic cadence; do not add a charge sequence.

**Bare Spear — observed:** A narrow pointed white-purple body establishes a direct thrust and piercing line. The general casting ring is more conspicuous than the spear in some frames.

**Strongest idea:** Keep one sharp point, short wake and local puncture. Reduce competing generic cast decoration before adding anything to the projectile.

**Bare Slash — observed:** A short white-purple filled sector appears at the caster. It conveys affected direction but reads more as a flashing wedge than an edge carving through space.

**Strongest idea:** Keep the quick cone. Concentrate light at an advancing curved edge and taper the tail, with clipped contact particles; do not reintroduce the rejected painted treatment.

**Bare Nova — observed:** An expanding bright rim and sparse runes communicate outward force with a clear ending. The generic cast ring overlaps its identity and weakens the sense of one meaningful front.

**Strongest idea:** Let the damaging front own the release, with a compact central compression and localized edge contacts. Keep the inside quiet after the wave passes.

**Bare Field — observed:** A dark purple disk filled with bright moving glyphs clearly marks active magic, but resembles a decorated bubble more than a low persistent influence on the ground.

**Strongest idea:** Preserve the compact rune field. Ground the glyphs and let real ticks produce a restrained outward pulse instead of constant equally bright decoration.

**Bare Orbit — observed:** Small white-purple moving bodies and curved wakes make the orbit legible with less bulk than Arcane Orbit. Contacts are light and the pattern does not demand the whole screen.

**Strongest idea:** Keep this restrained scale and readable orbit. Give actual contacts a tiny leading-edge spark and retire each wake naturally when its body expires.

**Bare Trap — observed:** A quiet broken ring waits, then becomes a compact runic burst. It is serviceable but the arming and waiting distinction is subtle, and nearby cast-circle decoration competes with the trap.

**Strongest idea:** Use one short closing inscription to signal armed, a quiet waiting state, and one snap on trigger. Empty expiry should erase it without a blast.

**Atomic — observed:** The effect clears enemies after expanding gold lines and a screen tint, but the thin rectangular frame and pale overlay feel like a screen treatment rather than an overwhelming magical release. The fixture directly triggers the blast, not its earning/input flow.

**Strongest idea:** Give the release one strong central collapse-and-expansion and a coherent dissipating shock front. Preserve a brief readable recovery; build exceptional weight through contrast instead of a longer opaque flash.

### Shared findings and next review priorities

1. **Restore missing identity where it matters most.** Cross Blade needs a tangible cutting body/contact; Atomic needs an exceptional release rather than a frame overlay; Soul Bloom needs its spirit to remain perceptible through delivery. These are stronger fantasy gains than adding another generic burst to every spell.
2. **Connect the caster selectively.** [OrbitingStaff](../../scripts/OrbitingStaff.gd) currently follows targets and hovers; [VfxPresenter](../../scripts/vfx/VfxPresenter.gd) supplies a shared cast flash. Lightning is a good first authored gesture; Magic Missile should remain tiny and automatic.
3. **Separate healing, sickness and spirit events.** Life/Regeneration/Life Bolt share much of their visible vocabulary. Infestation's launch, host attachment and spread need clearer organic behavior. [AudioManager](../../scripts/AudioManager.gd) also shares samples among life, spirit and plague; listening is required before selecting replacements.
4. **Preserve the strongest material fantasies.** Meteor Shower's stagger, Ember Spear's burning penetration and Steam's connected obscuring vapor deserve refinement, not normalization. Correct artificial ground edges and weak contact consequences while retaining their presence.
5. **Finish the untested experience before any passing verdict.** Review sound with real automatic cadence, typed casting and cancellation, mixed hostile combat, ranks, reduced effects and actual pause/resume. Regrade against the same columns and compute the complete mean only then.

A concrete Soul Bloom lifecycle issue supports priority 1: [SoulGhost](../../scripts/SoulGhost.gd) moves immediately at 320px/s and delivers inside 24px; [SpiritVisual](../../scripts/vfx/SpiritVisual.gd) takes 0.18s to emerge. A stationary recipient 60px away can consume it in roughly 0.11s. SoulGhost stores trail positions, but that path is not drawn by its body renderer. A visual arrival remnant and independently fading trail could improve the fantasy without delaying healing. Changing travel speed or adding orbit/pass damage remains a separate design decision.

## Shared mechanics dependency checklist

These are capabilities to verify when implementing the catalog, not an assertion that they are absent in 0.3.0.

| Capability | Catalog uses |
|---|---|
| Phases and event-driven transitions | Arcane Slash payoff, Flame Seed growth, Grasping Hand, Sunbeam, Yggdrasil, meteor ring. |
| Owner, afflicted and death events | Fire Shield, Firewalk, Infestation, Soul Bloom, Raise Dead and paused lightning rod. |
| Barrier health and collision | Earth Wall, Prism Wall, Tesla coils, Yggdrasil. |
| Chains and target traversal | Static Shock, Lightning Bolt and later chain concepts. |
| Aim and target assignment | Scorching Ray, Water Jet, Ray of Sickness and Prism Ray. |
| Displacement | Pull into Shillelagh's rooting trail, Water Jet push, Whirlpool swirl, Dash. |
| Lob, fall and moving fields | Carcass, Volcano, falling icicle, Mana Storm, Blizzard, Moonfall. |
| Spell references and allied actors | Golems casting from the kit, Raise Dead, Mirror Image. |
| Additional statuses and recipient filters | Polymorph, Time Stop, reflection, taunt, corpses, pickups, allies. Current damage/status contract stays in doc 21. |
| Contact and per-target rehit timing | Flame Wall crossings, orbiting bodies, whips and persistent contact. |
| Linked parts and per-copy variation | Tesla Wall and elemental ray copies. |
| Global scope | Time Stop and ultimate concepts. |

## Review evidence

Use fresh comparison cases and real moving encounters. Inspect the full timeline, ranks, keyword variants, combined statuses, crowded scenes, supported display sizes, reduced effects, sound and frame time. Record candidate revision and any working-file hashes. Input/menus/progression need actual operated journeys, including settled state, next transition and persistence where relevant.

Keep mechanical checks, visual judgment, audio judgment and performance evidence separate. A registered presenter, successful cast or saved screenshot is not a quality pass. Missing journeys are incomplete. Preserve before/after evidence; use known-bad controls for automated invariants, such as disconnected settings or missing catalog entries, rather than treating an exit code as proof.

## Interface and accessibility direction

Use readable inscriptions for magic, plain readable menu text and restrained ornament. Do not require a substitute alphabet. Keycaps are the existing implementation, not the target identity. Spell names need sufficient width and a readable minimum text size; long typed expressions use a horizontal viewport around the caret rather than wrapping into combat or shrinking illegibly.

Input text updates immediately. Cosmetic animation never delays input or loses rapid characters; reduce animation under load. Typing UI and HUD do not shake with the camera. Accepted/rejected words, current focus and cursor stay legible. Keep canonical spell/availability feedback concise; detailed math belongs in expandable inspection/debug. Current parser behavior is not changed by this design consolidation.

The tower concept rotates the **whole circular room**, not merely a selection highlight. Roughly twelve stained-glass positions are a visual concept, not twelve committed levels. A top-position portal opens for departure; the physical book assembles the prepared order. Existing six-slot preparation is the baseline. Book placement and 2D/3D/hybrid treatment remain open. At recall the wizard returns automatically from wherever they are, **without a return journey or exit interaction**. Test rotation with reduced motion before polishing.

### Required journey inventory

| Surface | Actions and states to review |
|---|---|
| Main menu and saves | No profile, existing profile, interrupted run, corrupt-save recovery, stable keyboard focus. |
| Preparation and realm selection | Pick/reorder/remove, locked/known spells, available recipes, empty slots, invalid duplicates, persisted order, enter/back. |
| Combat and casting | Slot activation, expiry, unknown/inactive/incompatible words, edit/commit/cancel, assist exhaustion, charge and delay, focus loss. |
| Spellbook and knowledge | Active versus prepared-but-inactive, known versus unseen, recipe requirements, honest availability. |
| Ley sites and guardian | Preview/start/decline, attempt/fail/retry, completion, grant once, four-site condition, late timer, already-active/defeated boss. |
| Pause and options | Nested back navigation, retained focus, settings persistence, no gameplay input leakage. |
| Death and extraction | Distinct outcomes, unfinished boss at timeout, reward settlement, crash/reopen and prepare again. |
| Developer workshop | Actual gameplay compiler/runtime, moving targets, player health, mid-flight target death, recast, invalid data, export success/failure. Design-only entries must say not implemented. |

Accessibility review includes independent text scale, cosmetic animation/density, reduced motion, shake and flash controls down to zero, shape-assisted color cues, keyboard-only navigation, remapping, readable focus and predictable Escape/Back. Exact presets remain open. Important sound cues need text/visual equivalents; reward reading must not be timed. Pause must not provide an accidental assist reset. Test non-US layouts, punctuation, IME composition and focus loss; the earlier paste restriction is a proposal requiring review, not an adopted policy.

Combat information prioritizes health/protection, available spells, activation progress, relevant objectives and the expedition timer. Keep developer statistics and permanent control tutorials out of the normal HUD. Telegraphs, healing, harmful fields and interaction rings must be distinguishable without relying only on color.

### Sound and production

Use material-specific release/contact sounds and bounded voice priorities, not a loud sound for every particle. Align audio with authoritative contact, distinguish friendly healing from hostile effects, and keep important information visible. Historical millisecond timelines, voice counts and palette recipes are starting experiments, not accepted quality measurements. Record source/license provenance and preserve supplied art; this plan does not authorize paid commissions or mandate replacing assets.


### Accepted spirit model — 16 October 2026

The ghost/wisp hybrid at browser commit `2b0bee3` is accepted at **B-**. Preserve its rounded expressive center, tracking eyes, 1.65-width advected trail and broad soft rear transition. The solid sculpted ghost and separate fabric/strap variants were rejected. Acceptance is for the browser model, not automatic approval of every engine rendering or spell behavior.

Seeker and Soul Bloom now share `scripts/vfx/SpiritVisual.gd`, with native advection and hybrid material shaders. The initial visual port retained gameplay behavior; Seeker’s subsequent leech behavior is specified below. Auto selects the hybrid for both; Soul Bloom retains its healing/hunting tint. The runtime fields remain in world space while the source moves. No illustration is used as the complete spirit.

Translation gates: actual GPU history (including a deliberately reset-history failure), pause/resume, hide/show reset, form and size changes, host cleanup, native-game captures and the existing spell regressions. Use `tools/capture_hybrid_spirit.gd` for the controlled motion fixture and `tools/capture_hybrid_gameplay.gd` for actual spell hosts, with isolated test saves. Both hide the window and capture offscreen SubViewports. The normal headless renderer cannot establish visual quality. The native capture uses Forward+/Metal and HDR fields; Compatibility/Web does not provide equivalent HDR 2D storage in Godot 4.4.

Each spirit has roughly 4 MiB of HDR color-field storage before other renderer overhead. Eight spirits held an approximately 16.7 ms median and 16.9 ms p95 frame interval in the isolated M4 Pro capture; this is not a full-game performance guarantee. Further work should preserve this accepted identity, measure heavier gameplay combinations and test additional GPUs before changing precision/resolution or appearance.


### Seeker hunt and leech behavior — 16 October 2026

The accepted hybrid is the identity for these little life-stealing helpers. Preserve Seeker’s original sustained hunt: pursue nearby visible enemies, move around prey at close range, and deal repeated contact hits with the original one-second per-enemy interval. The hunt lasts the existing scaled duration: 12 seconds at base and 24 at rank eight, before duration modifiers. A killed or invalid target is replaced during the remaining hunt. The one-touch return introduced in dev.4 was rejected and is superseded by this behavior.

When the hunt ends, return collected healing if the caster is hurt. If full, turn red and dive into a fresh enemy never pursued or hit by that spirit during this trip. Track that history even when pursuit did not land damage; split/chain children inherit parent history. A full heal during return switches to the same fresh-target finish. No fresh visible enemy means search briefly then dissipate. The whole ending has a four-second timeout. The finishing burst is a single-target hit with an arrival effect, not extra area damage.

Initial recovery balance stays at 15% of health actually removed, with a fixed 2 HP budget shared by all spirits spawned by one cast, including split/chain copies. A basic Life cast immediately heals 4 HP and grows with rank. Leeching adds drain share within the same cap and delivery requirement. Incidental explosion/reaping damage cannot trigger immediate Leeching recovery on a Seeker cast; explicit healing-word mechanics remain separate. Healing is accumulated during hunting regardless of current health, but paid only when returning to a hurt living caster. No return-path damage, revival, or payment on expiry/removal.

Three visible phases: cool aqua hunting; luminous mint-green material and soft pale-green center on healing return; saturated red/coral material and pink-red center on the fresh-target finish. Gold/yellow was rejected as aggressive; the healing palette must feel restorative. These are material palette changes, not a subtle multiply tint. Set healing-return speed to 80% of outbound motion, including speed modifiers; the prior faster return felt aggressive. Keep the red finishing dive quick. Preserve the approved hybrid geometry and trail. Soul Bloom retains its own infection/death-triggered heal-or-hunt release.

Validate with `tests/seeker_leech_regression.gd` and the full-duration `tools/capture_seeker_leech.gd`. Continue judging hunt pacing, high-rank crowd readability and sustained damage/recovery at real cast cadence. Code tests do not confer an aesthetic grade.


### Lightning refinement — 0.3.4-dev.10

The dev.9 rebuild is rejected in full except for its blue target circle. Restore the pre-rebuild bolt, particle effects, impact audio, staff behavior and 0.32-second warning. The circle uses the actual damage radius and ends on impact. There is no custom ground discharge or gather/slam choreography. Future work must refine the original Lightning rather than treat the rejected version as a baseline. Passing tests does not establish aesthetic acceptance.


### Shared spell-feel refinement — 0.3.4-dev.12

Lightning's circle, bolt, explosion and effect sequence are accepted at A tier. Preserve them. The main refinement priorities are screen shake and lighting, applied around existing effects rather than replacing them. Small shake requests should differ in strength; a small simultaneous hit should not erase a heavy impact. The first colored local-light samples are Bolt and Ice Blast contacts, with bounded brightness, short fade and overlap suppression. No new lighting is attached to Lightning, Meteor, Seeker or automatic Magic Missile.

Staff work is a smaller later layer: reusable cast time where appropriate and colored particles gathering at the staff, followed by release. Bespoke staff gestures are not required. Spell persistence does not by itself determine cast time. Keep quick spells quick; make explicit timing choices separately from visual polish.
