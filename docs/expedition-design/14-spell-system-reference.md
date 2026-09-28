# Spell system reference: components, properties, words and recipes

**Design reference v0.2 · 28 September 2026 · no gameplay implementation**

This document defines the reusable vocabulary from which spells are built. Its first tables deliberately contain **no named spells**. A spell is a graph of components with parameter values and connections. A player keyword changes explicitly exposed properties or adds a supported component. The game implements those behaviors once; spell definitions configure and combine them.

This is the proposed structural successor to the descriptive classifications in [the spell catalog](03-spells.md) and the first [composition draft](04-composition.md). It does not silently ratify their compatibility exclusions or tuning. **The user has not decided whether every keyword must work with every spell.** Here, “candidate” means a meaningful mapping exists, “conditional” means an additional mechanic or decision is required, and “not applicable” means no honest operation is currently defined. No-op words must never be accepted silently.

Some user-owned working notes in the local catalog differ from the committed draft: infection can refresh recipients without an arbitrary whole-chain deadline; Soul Bloom may make the player a healing infection carrier; Meteor Lance has several identity options; a rotating laser is a separate idea. Those alternatives are recorded here as **working design notes**, not verified runtime behavior. The existing documents and local edits are preserved. This reference does not decide XP, loadout or progression policy.

## 1. Three kinds of vocabulary

| Vocabulary | Purpose | Who uses it? |
|---|---|---|
| Component identifier | Defines reusable behavior such as projectile movement or periodic healing | Spell data and implementation |
| Parameter identifier | Specifies a value such as radius, speed, count or duration | Spell data, modifier operations, debugging |
| Incantation word | A player-facing instruction such as Big or Repeating | Player and parser |

A school label is not itself an implementation. A fire projectile and a fire field share an element, but use different geometry and delivery. A spell can have several payloads, such as hostile damage and friendly healing, with separate recipient rules. Internal identifiers need not be words the player can type.

## 2. Foundational component table — no spell names

| Slot | Reusable type | Required properties | Shared behavior |
|---|---|---|---|
| Origin | Self | source, local offset, position-lock policy | Starts at caster; following is a separate choice |
| Origin | Ground point | position, selection range, commit/release lock | Starts at a selected world position |
| Origin | Entity | entity handle, offset, lost-owner policy | Starts at or attaches to an entity |
| Geometry | Disk | radius | Filled circular region; can be instant, expanding or persistent |
| Geometry | Cone sector | length, angle, facing | Angular sector; propagation determines when each part becomes active |
| Geometry | Line/capsule | length, half-width, facing | Finite thick line, not automatically instant or travelling |
| Geometry | Ring/front | outer radius, thickness | Only the visible band is active; a filled expansion uses a disk with changing extent instead |
| Geometry | Body | radius or half-extents, orientation | Shape used by a moving body and its visible solid core |
| Geometry | Trail | patch shape, sample interval, sample limit | Union of visible active patches; expired patches leave the damaging union |
| Delivery | Projectile | body, motion, contact policy, expiry | Moves a body; contact creates effects through an event connection |
| Delivery | Volume | shape, propagation, recipient filter | Queries targets inside the currently active visible region |
| Delivery | Beam | line shape, facing policy, occlusion, contact limit | Continuous visible line; applies payload only where it actually intersects |
| Delivery | Field | shape, anchor-follow policy, lifetime | Maintains an area; exposure supplies periodic or entry events |
| Delivery | Trap | trigger shape, arming duration, trigger filter, charges | Waits for an actual trigger, then executes its connected effect |
| Delivery | Creature | health, body, movement, perception, attack recipe | Creates an autonomous actor; attacks reuse ordinary effect components |
| Delivery | Collectible | body, pickup filter, expiry, consume policy | Waits for valid collection, grants a payload once |
| Motion | Straight | heading, speed, range, lifetime | Advances without target correction |
| Motion | Guided | homing enabled, turn rate, acquisition range, retarget policy | Turns within defined limits; reacquiring does not reset range or lifetime |
| Motion | Orbit | center, path radius, angular speed, phase | Moves a body around a center; orbital path is not a filled damaging disk |
| Motion | Return path | outbound limit, dwell duration, return target, expiry | Sequences outbound, dwell and return phases with explicit contact ledgers |
| Propagation | Instant | activation time | All eligible points in the shape activate together |
| Propagation | Expanding front | initial extent, maximum extent, front speed, thickness | Near locations activate before distant locations as a visible front passes |
| Propagation | Travelling | motion reference | Active region follows the actual moving body |
| Propagation | Sweep | start angle, angular speed, sweep arc | Active line/sector rotates continuously; no snapping between endpoints |
| Timing | One-shot | activation delay, active window, hit ledger | Applies once to each eligible target in its stated scope |
| Timing | Periodic exposure | rate, interval, duration, settlement policy | Accumulates eligible exposure and settles it at intervals/exit/expiry |
| Timing | Discrete pulses | count, interval, start delay | Executes a specified number of distinct pulses; no fractional extra pulse |
| Timing | Channel | maximum duration, interruption rule, aim update | Runs while channel state permits; movement permission is explicit |
| Payload | Damage | amount/rate, element, recipient filter | Reduces health after protection/resistance rules |
| Payload | Healing | amount/rate, recipient filter, overheal rule | Restores health; never damages hostile entities by accidental sign inversion |
| Payload | Absorption | capacity, duration, replacement policy | Intercepts damage to an entity; not terrain or automatic regeneration |
| Payload | Displacement | direction, distance/force, collision rule | Moves valid recipients through collision-safe gameplay movement |
| Payload | Status | kind, strength, duration, reapplication policy | Applies slow, root, poison or another explicitly defined status |
| Payload | Infection | host filter, host duration, spread range, transfer timing, reapplication | Maintains hosts and sends visible transfers; lifecycle below |
| Payload | Destructible structure | health, body, collision masks, attached effects | Creates a damageable world entity; blocking and healing are separate components |
| Scheduler | Volley | output count, spread angle/pattern, spacing | Emits a pattern of outputs, with an explicit target-sharing rule |
| Scheduler | Target traversal / chain | recipient filter, hop count/range, visited-target policy, transition mode, termination | Visits valid targets with instant or travelling transitions; stops when budget or candidates are exhausted |
| Scheduler | Repeat | child count, delay, coefficient, inheritance mask | Schedules bounded echoes without re-running the incantation parser |
| Scheduler | Charge | duration, root/cancel policy, release event | Holds a committed action before release; rooting is actual gameplay state |
| Lifecycle | Event connection | source event, condition, destination recipe, generation budget | Connects contact, death, expiry, collection or scheduled events to effects |

**Self does not imply expanding. Cone does not imply projectile. Circle does not imply simultaneous damage.** These are independent slots. A recommended authoring preset can combine self + disk + expanding front, while remaining inspectable as those three choices.

## 3. Property dictionary and the component/property matrix

Units: distance in world units (wu), simulation time in seconds, angle in radians internally/degrees in editor, health in HP. Typing assistance has its own real-time clock and is not an effect-duration property. Numeric values below are schema constraints or examples, not a new balance pass.

| Property | Type / constraints | Exposed by | Meaning and important non-effects |
|---|---|---|---|
| `count` | Integer ≥1, family maximum | Volley, orbit, summon formation | Outputs/actors, not damage events per output |
| `body_radius` / `half_extents` | Positive distance/vector | Projectile, creature, collectible | Physical coverage; does not automatically add pierce or blast |
| `area_radius` | Positive distance | Disk, field, explosion | Active effect radius; distinct from projectile body |
| `length` | Positive distance | Cone, line, wave | Reach of the shape, not necessarily projectile travel range |
| `half_width` | Positive distance | Line, beam | Half the solid damaging width |
| `cone_angle` | Angle >0 and ≤360° | Cone distribution/volume | Angular coverage; widening need not increase reach |
| `front_thickness` | Positive distance ≤maximum extent | Expanding/sweeping front | Width of currently active band |
| `front_speed` | Positive distance/second | Expanding front | Determines contact delay with distance |
| `travel_speed` | Positive distance/second | Projectile, moving spirit | Motion rate; fixed range means reduced travel time when faster |
| `travel_range` | Positive distance | Projectile | Total path-length budget, not reacquisition radius |
| `homing_enabled` | Boolean | Guided-capable body | Enables steering; does not itself define turn speed |
| `turn_rate` | Nonnegative radians/second | Guidance, tracking beam | Maximum steering speed; zero means no correction |
| `acquisition_range` | Positive distance | Guidance, creature perception | Search range, not hit geometry |
| `retarget_policy` | Enumerated policy | Guided body, creature, beam | What happens when a target dies or leaves eligibility |
| `max_unique_contacts` | Integer ≥1 or explicit unlimited | Projectile | Lifetime/leg contact budget; one is an ordinary stopping projectile |
| `max_targets_per_sample` | Integer ≥1 | Beam | Maximum ordered intersections during one contact sample; new targets can enter later |
| `occlusion_policy` | Explicit terrain and actor rules | Beam/line | Decide whether solid scenery blocks and whether enemies stop the beam; unresolved policy cannot ship |
| `bounce_count` / `bounce_range` | Integer ≥0 / distance | Chain scheduler | Additional contacts and search range between them |
| `damage` / `damage_rate` | Nonnegative HP / HP per second | Damage | Direct amount or rate; never both implicitly applied |
| `heal` / `heal_rate` | Nonnegative HP / HP per second | Healing | Separate from damage potency and from pickup radius |
| `damage_element` | Element ID | Damage payload | Affinity only; conversion does not invent burn/freeze |
| `status_kind` / `strength` | Status ID / kind-specific value | Status | Slow, root, poison etc.; different from elemental color |
| `duration` / `tick_interval` | Nonnegative / positive time | Timed effect | Lifespan and settlement cadence; not assistance time |
| `release_delay` / `charge_duration` | Nonnegative time | Scheduler | Free waiting versus rooted commitment are distinct |
| `orbit_radius` / `angular_speed` | Distance / radians per second | Orbit | Body path; enlarging body alone does not enlarge orbit radius |
| `trigger_radius` / `blast_radius` | Positive distance | Trap plus impact | Detection area and damage area must both be represented visibly |
| `host_duration` / `spread_radius` | Time / distance | Infection | How long one host remains infected and how far a transfer can search |
| `transfer_speed` / `orphan_duration` | Distance per second / time | Infection carrier | Visible movement and survival without a host |
| `reapplication` | Ignore / refresh / replace / stack | Status/infection | Explicit duration/potency ownership; no accidental recursive refresh |
| `health` / `attack_interval` | Positive HP / time | Creature/structure | Durability and behavior; not implicitly changed by Big |
| `attack_reach` / `leash_range` | Positive distance | Creature | Contact reach and owner tether; distinct from body size |
| `recipient_filter` | Team/type mask + predicate | Every payload/trigger | Damage enemies, heal player, ignore scenery etc. |
| `hit_scope` | Root/generation/output/phase/pulse | Contact payload | Defines whether a target can be hit again |
| `max_active` / `max_pending` | Positive integer | Runtime family/scheduler | Workload/concurrency controls, not arbitrary invisible expiry |

Read this matrix as capability ownership, not as one enormous parameter object every spell must fill:

| Component | Size/shape | Motion/guidance | Count | Potency | Duration/ticks | Element/status | Target/filter |
|---|---|---|---|---|---|---|---|
| Projectile | Body | Speed, range, optional guidance | Via volley | Contact payload | Expiry | Contact payload | Aim and contact filters |
| Cone volume | Length, angle, front | Propagation | Via pulses | Volume payload | Window/pulses | Volume payload | Volume recipients |
| Field | Area | Anchor-follow only | Instances | Exposure payload | Duration/interval | Exposure payload | Area recipients |
| Beam | Length/width | Facing/turning | Via explicit split recipe | Contact payload | Channel/ticks | Contact payload | Occlusion/contact limits |
| Self healing | None | None | Payments are not projectiles | Healing | Instant or periodic | Life theme, no damage element | Self/friendly only |
| Shield | No independent area by default | Follows protected entity | None | Absorption | Duration | Optional material theme | Protected entity |
| Infection | Spread radius; optional carrier body | Carrier speed | Transfer concurrency | Per-host payload | Host/orphan lifetime | Infection payload | Hosts, transfers |
| Creature | Body/attack reach | Movement/perception | Formation | Attack payload | Lifetime/attack cadence | Attack payload | AI targeting |
| Trap | Trigger plus blast | Placement only | Instances | Triggered payload | Arming/persistence | Triggered payload | Trigger filter |
| Collectible | Body/pickup area | Optional attraction | Instances | On-collect payload | Expiry | Usually non-damaging | Pickup eligibility |

## 4. Element and timing keyword families

A **school** describes fantasy; a **damage element** participates in damage resolution; a **status** is an additional behavior. They can agree without becoming the same field.

| Element ID | Suggested typed conversion | Intrinsic operation | Separate optional status |
|---|---|---|---|
| Arcane | Arcane | Change eligible damage to arcane | No mandatory status |
| Fire | Fiery | Change damage to fire | Burning is separate |
| Ice | Icy | Change damage to ice | Slow/freeze are separate |
| Water | Watery or Tidal — name open | Change damage to water | Push/pull are separate |
| Lightning | Electric — name open | Change damage to lightning | Chain/stun are separate |
| Earth | Earthen | Change damage to earth | Protection/terrain are separate |
| Plague | Pestilent — name open | Change damage to plague | Infection/poison are separate |
| Spirit | Spectral — name open | Change damage to spirit | Seeking behavior is separate |
| Life | No universal conversion yet | Healing is a recipient-aware payload, not negative damage | Regeneration is healing plus periodic timing |
| Moon | Lunar — name open | Change eligible damage to moon | Mixed healing is a separate payload |
| Sun | Solar — name open | Reserved affinity candidate | Cleansing/blinding require explicit mechanics |
| Metal | Metallic — name open | Change eligible damage to metal | Piercing is separate |

Only Fiery, Icy and Earthen were selected conversion words in the earlier draft. The other names above are **candidates**, not newly approved unlocks. One conversion per damage payload by default; mixed spells declare which payloads are convertible. Converting an infection's damage must not remove its spread behavior.

| Timing/status word family | Slot affected | Proposed interpretation |
|---|---|---|
| Delayed | Release scheduler | Wait a fixed time, allow movement, then release; small potency bonus |
| Charged | Commitment scheduler | Root during an explicit charge, then release stronger effect |
| Repeating | Root schedule | Execute a smaller echo later; children cannot echo recursively |
| Lasting | Selected duration | Extend a declared host/field/summon/channel duration, not every timer in the graph |
| Venomous | Added periodic damage status | Add a bounded poison payload to eligible direct contact; not elemental conversion |
| Burning | Added periodic damage status | Candidate fire DoT; numbers/stack policy open |
| Freezing / Chilling | Control status | Candidate freeze/slow; boss behavior and stacking explicit |
| Pulsing | Discrete scheduler | Candidate repeated waves within one effect; distinct from repeating the whole cast |
| Regenerating | Healing over time | Candidate modifier only on valid friendly-healing/protection recipes; not universal |

## 5. Modifier operation table

Earlier coefficients are retained below only as **worked tuning candidates**. Compatibility is reconsiderable. Every accepted word must change a declared gameplay field and give the player an understandable result.

| Word | Required capability | Candidate operation | Must not silently do |
|---|---|---|---|
| Big | Recipe exposes `size` binding | Multiply named dimensions by 1.35 | Scale only sprites; enlarge every radius in the graph; add piercing |
| Powerful | Recipe exposes potency binding | Add 50% of base potency to selected payloads | Multiply health, duration and damage indiscriminately |
| Swift / Fast | Exposes movement speed | Multiply selected travel speed by 1.35 | Increase range, beam tick rate or player speed without saying so |
| Seeking / Following | Guidable movement | Enable homing; set bounded turn/acquisition parameters | Bend a beam by pretending it is a projectile; refresh lifetime |
| Repulsing | Exposes hostile contact/volume payload | Add collision-safe displacement | Push once per decorative particle or every frame |
| Duplicating / Replicating | Exposes logical output unit | Add an output with an explicit coefficient | Guess whether “output” means one meteor or an entire shower |
| Repeating | Repeatable root graph | One echo after 0.60 s, 40% potency, 75% dimensions | Repeat itself, double rewards, create another assist window |
| Delayed | Schedulable release | +0.80 s release delay,+15% base potency | Invisibly move a locked ground target |
| Charged | Supported commitment state | Root 1.20 s,+150% base potency | Grant invulnerability or extend typing slowdown |
| Lasting | Exposes semantic duration binding | ×1.40 selected duration | Add time to arming, release delay and recovery as well |
| Element conversion | Convertible damage payload | Replace element ID | Add an unlisted status or change ally/enemy filters |
| Venomous / Poison — name open | Eligible direct hit | Add defined poison status | Poison healing recipients or compound on every poison tick |
| Orbiting / Rotating | Orbit path or rotating facing available | Candidate orbit/sweep behavior | Treat moving bodies and rotating beams as identical |
| Piercing | Scoped contact-limit property | Candidate additional unique contacts | Add a damage area unrelated to visible body |
| Wide | Angular/lateral size binding | Candidate wider cone/beam at fixed reach | Duplicate Big without a distinct decision |
| Mega / Super / Omega / Giant | Mastery/size/potency tier open | Preserve as vocabulary ideas until distinct behavior is selected | Accept arbitrary adjectives as free compounded multipliers |
| Quick Cast | Alternative input contract | Candidate shorter input with weaker output | Become a free alias for full-strength long incantations |
| Numeric Delay | Parameterized parser | Deferred | Accept arbitrary numbers before queue/lifecycle design exists |

Alias choices above are naming candidates, not simultaneous valid incantations. `Fast` and `Swift` need one canonical rule before shipping. Internal component identifiers such as `expanding_front` are not automatically unlocked player words.

## 6. What “size” actually does

### Projectile body size

A projectile does have a gameplay body even when its artwork is tiny or its current size field is hidden. For a circular approximation, contact occurs when the swept projectile core comes within projectile radius + target radius. Larger bodies therefore tolerate more aim error and can contact targets near their path.

That does **not** imply more damage or multiple hits. A first-contact Bolt still stops at one target. A piercing lance can intersect more enemies because its wider body reaches more bodies along its lane. An explosive projectile has two independent sizes: travelling body and impact area. Each recipe must name whether Big changes one or both.

A halo, tail or glow is cosmetic, not another collision radius. If the user decides ordinary projectiles should not support Big, reject it clearly; do not pretend a decorative enlargement is a meaningful upgrade.

### Big on infection

Plague Seed's defining mechanic is infection; an initial travelling seed is optional delivery. ****Recommended mapping: Big targets infection spread radius****, regardless of whether we retain that initial projectile. With a proposed 120 wu spread radius, Big gives 162 wu. A target 150 wu away becomes a valid spread candidate, whereas one 170 wu away does not. That is measurable utility without adding damage, hosts or lifespan.

Recommendation: leave initial seed body unchanged for this meaning of Big. Show the enlarged spread reach in inspection/target selection and a brief pulse when a transfer is sought; do not clutter every infected enemy with a permanent circle. A target within range does not necessarily receive infection instantly: the transfer still follows its declared carrier/contact rule.

Alternative decisions remain visible: Big could instead enlarge an on-death spore cloud if we choose that recipe. It cannot enlarge a cloud that does not exist. Do not invent projectile-only eligibility that excludes infection from meaningful modifiers.

### Common size bindings

| Recipe exposes | Candidate Big mapping | Deliberately unchanged |
|---|---|---|
| Ordinary projectile | Body radius | Damage, range, pierce count |
| Explosive projectile | Body and impact radius, if explicitly bound | Target selection range, damage |
| Projectile fan | Individual shard bodies | Fan angle and maximum range unless separately bound |
| Continuous cone front | Length and front thickness | Angle and per-target damage; longer travel takes longer at same speed |
| Ground field | Active area radius | Tick rate, duration, damage |
| Beam | Half-width | Length, aim turn rate, tick rate |
| Infection | Spread radius | Host duration, potency, concurrency |
| Orbit | Body radius and orbital path radius | Angular speed, number of bodies |
| Trap | Trigger and blast radius | Arming duration, charges |
| Creature | Body and melee reach | Health, movement speed, target search range |
| Healing area | Recipient area radius | Healing amount and duration |
| Single-recipient healing | No meaningful spatial binding | Candidate not applicable; area-heal conversion would be a new mechanic |
| Personal absorption | No spatial binding without interception geometry | Candidate not applicable; do not enlarge player hurtbox |

## 7. Time, geometry and events: shared operational rules

For an expanding front with constant speed, a stationary point at distance `d` is reached at `start_time + max(0, d - initial_extent) / front_speed`, provided it lies in the geometry. Moving targets require actual swept intersection, not precomputed damage timers. Cone angle selects where the front exists; the expansion component selects when it gets there.

A self-centered disk can be instant or outward-moving. A line can appear simultaneously along its full length, grow outward, or sweep in angle. A ground AoE can expand from its center. No geometry name alone promises an arrival order.

Projectile cones have individual contacts and gaps; continuous cone fronts cover the visible sector band. Never run both damage paths unless a deliberately combined spell explicitly has both payloads. The existing Ice Blast contact behavior stays the reference for the projectile recipe; the non-projectile alternative is a separate design option.

Each event edge declares its trigger, destination, recipient filter and hit scope. Useful edges: `on_release`, `on_contact`, `on_nth_contact`, `on_host_death`, `on_expire`, `on_collect`, `after_delay`, `while_exposed`, `on_return`. This supports unusual spells without a spell-name switch in the generic projectile code.

Periodic damage/healing integrate actual eligible exposure; interval payments and final fractional settlement preserve the rate. Discrete pulses stay discrete. Replace/refresh policies specify whose rate, remaining budget, duration and tick phase survive. Generation IDs and settlement IDs prevent double application. Presentation follows these authoritative events and the same geometry; it does not decide contact independently.

Repeat's geometry coefficient uses the recipe's explicit `repeat_geometry` bindings. It never scans all distance fields: acquisition range, leash, bounce search range and pickup reach remain unchanged unless individually bound. The default candidate copies the recipe's effect-size binding, but a recipe may name a different supported subset. Potency inheritance and geometry inheritance are separate operations.

Beam occlusion is an explicit pending policy: candidate A blocks on solid scenery and the first hostile body; candidate B blocks on scenery but pierces up to its simultaneous target limit. A third no-terrain-occlusion choice needs deliberate review. Each beam recipe must select one before implementation; visual length stops at the same authoritative endpoint. The prototype is not asserted to already follow any of these new policies.

### Infection lifecycle decision

The earlier draft used six total hosts and an 18-second root ceiling. Working catalog notes propose refreshable host durations and no arbitrary whole-chain timeout. Keep these as different policies, not contradictory constants hidden in two tables.

Recommended candidate for the refreshed design: finite duration per host; reapplication refreshes duration without stacking tick damage; finite orphan lifetime; finite transfer speed; no fixed whole-chain deadline. A chain can continue only through successful transfers/refreshes. Concurrency limits, per-frame transfer budgets and no same-tick ping-pong protect runtime load. **Whether previously visited hosts can reinfect one another, and what transfer cooldown prevents effortless permanent loops, remains a product decision.** Expose these parameters rather than restoring an invisible hard expiry as a technical shortcut.

Reinfection also needs a tick-phase contract. Recommended candidate: preserve the next scheduled payment and unpaid exposure accumulator while resetting the host expiry; refreshing cannot postpone ticks indefinitely or pay accumulated exposure twice. A potency/owner replacement settles the prior descriptor once and installs the new one under explicit ownership. This is a proposed operational rule, not a claim that current infection code already behaves that way.

Soul Bloom's proposed player-carrier variant uses the same infection state with a recipient-dependent payload: enemies take DoT, the player receives healing over time and can carry transfers. This is not lifesteal. Healing rate/cap and self-reinfection policy are unresolved; do not reuse the older damage-leech numbers automatically.

## 8. Named spell recipes and exposed properties

The following table applies the component vocabulary to named spell recipes. Rows below cover all 36 identities in the earlier campaign proposal. Values are **candidate starting parameters from that proposal**, not current runtime statistics. They are included here so a recipe is inspectable without guessing its dimensions. Recovery values are copied from the earlier catalog as candidate context; recovery and unlock policies belong to cast/progression metadata, not every effect component. These are design snapshots until a shared data source generates both references.

Abbreviations in the parameter column: `r` = radius, `w` = half-width; distances are wu, speeds wu/s, angles degrees and time seconds. “On contact” means actual collision, not a cosmetic projectile preceding invisible damage. Damage/healing values refer to the appropriate payload, not every component in a graph.

Powerful modifies the listed primary damage/healing/absorption payload by default, not creature health. Element words modify eligible damaging payloads only. Repeating, Duplicating and Lasting still need the per-recipe semantic binding described below; they do not blindly visit every numeric field.

| Spell | Component recipe | Starting properties | Big binding and boundary | Other keyword bindings / open decisions |
|---|---|---|---|---|
|**Bolt**|Self → straight projectile → contact damage|40 direct; r 7; speed 500; range 480; one contact; recovery 0.45|Body radius; still stops at first hit|Swift: travel; Seeking: guidance; Duplicating: one extra body|
|**Life**|Self recipient → one-shot heal|4 immediate HP; recovery 1.2; cannot exceed maximum HP|Not applicable without a new area-heal mechanic|Powerful: healing; Delayed/Charged: scheduled heal; other geometry words undecided|
|**Ice Blast**|Self → cone-distributed volley → shard contact → damage + slow + push|9 shards, 90°; 18/unique enemy/generation; r 6; speed 620; range 300; slow 0.5 × 2 s; push 35; recovery 1.8|Shard bodies; cone-volume alternative would bind cone reach/front|Duplicating: one shard; Swift: shard travel; continuous-front alternative must be a different recipe|
|**Lightning**|Ground point → disk warning → brief volume → one-hit damage|80 damage once/enemy; r 80; range 360; warning 0.25; active 0.2; recovery 2.5|Active disk radius|Repeating: another warned disk; no travelling-projectile guidance|
|**Regeneration**|Self recipient → periodic healing → finite expiry|4 HP/s, 0.5 s ticks, 6 s, total 24; recovery 8; refresh-not-stack|Not applicable to single-recipient healing|Lasting: healing duration; Powerful: healing rate; no automatic parallel stack|
|**Earth Shield**|Self recipient → absorption pool → depletion/expiry|50 absorption, 6 s; recovery 8; replace only if incoming absorption ≥ remaining absorption; otherwise reject; no addition|Not applicable without an interception area|Powerful: capacity; Lasting: duration; no enlarged player hurtbox|
|**Meteor Shower**|Ground pattern → scheduled warnings → falling impacts → damage disks|4 × 60 damage; impact radius 80; range 420; warnings 0.65 + 0.25 i; area active 0.1; recovery 6|Impact disks, plus matching falling-rock visual; falling carrier is not a second hit|Duplicating: one meteor; Repeating: another whole pattern; Swift on descent is conditional on honest warnings|
|**Ember Lance**|Self → straight piercing body → unique-contact damage|65 per unique contact; r 9; speed 700; range 650; max 8 contacts; recovery 2.5|Body width|Swift: travel; Seeking: guided lance candidate; pierce count unchanged by Big|
|**Plague Seed**|Selected host → optional travelling seed → infection → transfers/orphans|Candidate: seed speed 460/r 7/range 360 if carrier retained; infection 6 HP/0.5 s; host 4 s; spread 120; orphan 3 s. Refresh/concurrency policy open; no whole-chain deadline in working alternative.|Infection spread radius; initial carrier size unchanged in recommended mapping|Lasting: host duration; Swift: transfer speed if visible carriers retained; repeat/duplicate infection policies open|
|**Cinder Field**|Ground point → stationary disk field → periodic hostile damage|12/0.5 s × 5 s = 120/enemy at full dwell; r 95; range 320; warning 0.25; recovery 5|Active disk radius|Lasting: field duration; Repeating: second field; overlapping-generation damage must be explicit|
|**Arcane Orbit**|Self-following center → orbiting bodies → contact damage|3 bodies r 12, path radius 70; 28 contact, 0.5 s per-target gate; 6 s; angular speed 4 rad/s; recovery 7|Body radius and orbit radius|Duplicating: one mote; Lasting: orbit lifetime; Swift on orbital motion is a separate mapping decision|
|**Focus Ray**|Self → tracking line beam → first intersected hostile → periodic damage|16/0.25 s × 2 s = 128; reach 360; w 8; tracking 3 rad/s; first aligned target; recovery 3|Beam half-width|Lasting: channel duration; tracking uses turn rate, not projectile homing|
|**Rune Trap**|Ground point → armed trigger volume → disk blast|90 once; trigger radius 45/blast radius 90; arm 0.8; placement 140; persistent; max 3 shared; recovery 3|Trigger and blast radii|Lasting has no meaning on persistent armed trap; Repeating/Duplicating require an explicit trap-count recipe|
|**Seeker**|Create autonomous spirit → acquire/pursue → contact attack|22 contact/0.6 s; 6 s; speed 280; body radius 10; leash 400; max 3 bodies; recovery 4|Spirit body and contact reach|Swift: movement; Duplicating: one spirit; Lasting: lifetime; Seeking redundant unless it improves native guidance|
|**Firewalk**|Self moving emitter → sampled ground patches → periodic hostile damage|10/0.5 s per enemy across all same-root patches; emit 5 s; patch 6 s; r 32; sample interval 0.10 s; recovery 6|Patch radius/width|Lasting: emitter and patch durations explicitly bound; no speed increase from Swift by default|
|**Cross Blade**|Body → outbound phase → dwell pulses → return phase → catch|55 outbound + 55 return per enemy; linger 0.9 with 20/0.3 s; range 280; speed 420; r 14; recovery 3|Blade body, including dwell contact region|Swift: outbound/return movement; Duplicating: one blade; Repeating: whole trajectory; does not shorten dwell|
|**Wave**|Self → cone/ridge front → outward travel → damage + displacement|20 damage; arc 120°; front width 100; travels 180 at 240; push 90; slow 0.7 × 1 s; recovery 2|Front width/reach; shape definition must reconcile width and angle|Swift could modify front speed, conditional; Repeating makes another wave|
|**Water Jet**|Self → narrow piercing projectile → damage + push|45 damage; w 8; speed 600; range 500; max 3 contacts; push 25; recovery 2|Jet body width|Swift: travel; Seeking conditional guided jet; Duplicating: one jet|
|**Frost Nova**|Self → instant disk OR outward ring/front → damage + control; propagation choice open|35 damage; r 120; active 0.15; freeze 1 s, bosses slow 0.8 × 1 s; recovery 5|Maximum radius; front thickness only if a front is selected|Propagation timing needs explicit choice; visible expansion must govern contact if chosen; Repeating creates another front|
|**Fire Bolt**|Projectile → contact damage + separate impact disk|35 direct +25 area r 45, direct victim excluded from area; r 8; speed 450; range 450; recovery 1.8|Projectile body and blast radius|Direct victim excluded from secondary blast in prior proposal; Duplicating creates another complete projectile recipe|
|**Firestorm**|Self-following disk field → periodic hostile damage|18/0.5 s × 3 s = 108; r 140; self-centered moving field; warning 0.6; recovery 8|Moving field radius|Lasting: duration; keep field following caster, unlike stationary Cinder Field|
|**Earthquake**|Self → discrete pulse scheduler → ground disk/front → damage|4 × 45 at 0.4 s intervals; r 180; first 0.4; push 20 first contact only; recovery 8|Pulse radius; if fronts expand, front thickness too|Pulse propagation choice open; Lasting must define extra pulses or be rejected, not create fractional pulses|
|**Thunderwave**|Self → advancing cone/ridge front → damage + strong displacement|50; arc 160°; front width 160; travels 220 at 320; push 110; recovery 4|Front width/reach|Same front component as Wave, different parameters/payload; no bespoke lightning-wave collision|
|**Frost Ray**|Self → tracking beam → damage + slow|12/0.25 s × 2 s = 96; reach 360; w 10; tracking 2 rad/s; slow 0.5 × 1 s refreshed; first target; recovery 3|Beam half-width|Lasting: channel duration; Powerful does not automatically deepen slow|
|**Moonfall**|Ground point → field → hostile damage + friendly healing|8 damage/0.5 s × 5 s; r 110; range 300; player heal 1/s while inside, max 5/root; warning 0.5; recovery 7|Shared field radius for both recipient masks|Powerful binds both payloads with separate budgets; Lasting: field duration|
|**Grasping Hand**|Ground point → warned disk → damage + root|70 burst; r 70; range 300; root normal enemies 1.5 s, boss slow 0.8 × 1.5; warning 0.45; recovery 4|Active disk radius|Repeating: second grasp; Powerful changes damage, not root duration; hand animation follows activation|
|**Mana Storm**|Ground distribution → strike scheduler → warned disks|8 × 45 strikes; r 55; centers within 180 of target; warning 0.55 + 0.12 i; range 400; recovery 9|Individual strike radius, not pattern spread by default|Duplicating: one strike; Repeating: full pattern; pattern-spread modifier is a separate capability|
|**Summon Golem**|Create creature → perception/movement → melee attack recipe|80 HP; 25 melee/1.2 s; r 18; reach 35; speed 100; acquisition range 240; leash 400; 20 s; max 2 bodies; recovery 15|Creature body and melee reach, not health|Powerful: attack; Duplicating: another golem; Lasting: lifetime; element changes attack material|
|**Yggdrasil**|Create destructible tree → friendly-heal field + hostile root damage|Tree HP 100; duration 8 s; r 120; player heal 5/s, total 40; root damage 8/s; range 220; warning 0.8; recovery 14|Effect area; tree artwork may grow but collision only if bound|Powerful: heal/damage; durability separate; duration is a meaningful Lasting binding, while the earlier eight-second ceiling remains undecided|
|**Lightning Bolt**|Projectile contact → damage → next-target chain movement|60/contact; 2 additional distinct targets; speed 550; r 8; bounce 180; total range 720; recovery 3|Projectile body, not bounce search radius|Swift: travel; Duplicating: another chain; Seeking redundant with native chain steering|
|**Life Bolt**|Projectile → contact damage + spawn collectible → collect → healing|30 damage; r 7; speed 450; range 450; impact seed 6 HP over 2 s, expires 10 s, max 6; recovery 2.5|Projectile body only by default; collection radius is a separate candidate|Powerful: declared damage/heal budgets; Duplicating/Repeating share root healing cap|
|**Meteor Lance**|Piercing projectile → contact event → impact disk; alternatives below|45 direct; 25 area r 45 excludes direct victim; max 6 contacts; r 9; speed 650; range 600; recovery 4|Lance width and secondary impact radius|Second-contact predicate or recorded-path meteor follow-up can replace event edge; choice open|
|**Soul Bloom**|Infection → recipient routing: enemy DoT / player HoT → transfers|Working alternative: enemy infection + player healing carrier; spread 120 as starting reference; per-host duration, heal rate, transfer cooldown and concurrency open. Older leech numbers are not reused.|Infection spread radius|Player-carrier working proposal replaces leech; Lasting: host duration; healing scaling/reinfection budget open|
|**Steam Field**|Ground disk field → hostile damage + slow|10/0.5 s × 4 s; r 110; range 320; slow 0.6; warning 0.25; recovery 5|Active disk radius|Lasting: duration; Powerful: damage only; never heal an enemy because steam uses soft-colored VFX|
|**Prism Ray**|Self → beam → limited piercing intersections → periodic damage|10/0.25 s × 2 s per target; max 3 aligned; reach 400; w 9; recovery 3.5|Beam half-width|Powerful: damage; Lasting: channel; more contacts is a contact-limit modifier, not Big|
|**Frost Sigil**|Persistent armed trigger → disk damage + slow|75 damage; trigger radius 50/blast radius 110; arm 1.2; slow 0.5 × 2 s; persistent; max 3 shared; recovery 4|Trigger and blast radii|Same trap component as Rune Trap; slow is separate payload; Lasting on persistence is not applicable|

### Explicit geometry decisions still needed

- **Ice Blast:** current contact-shard recipe versus a continuous expanding cone are alternatives, not two simultaneous damage systems. Both can share cone distribution parameters; they do not share identical coverage or hit probability.
- **Wave/Thunderwave:** the old proposal lists angle, front width and reach without declaring which dimension derives from which. Recommend authoring angle + maximum reach + front thickness, deriving endpoint width; alternatively use a fixed-width travelling strip. Do not independently set incompatible cone dimensions.
- **Frost Nova/Earthquake:** the old catalog describes expanding visuals while also listing instant-area/pulse damage. Decide instant full-area activation with honest simultaneous visuals, or travelling front with explicit speed and near-to-far contact. Recommend travelling fronts for the stated outward fantasy; exact speeds remain tuning inputs.
- **Meteor Lance:** contact explosion, second-contact explosion and delayed meteorites along a recorded path are three alternative graphs. They need event predicates or trajectory history, not three unrelated projectile implementations.
- **Big shield/heal:** no spatial meaning exists by default. An area healing aura or intercepting shield could be designed, but accepting Big must not silently transform the spell into a new type without an approved rule.

## 9. Cross-spell keyword binding families

This is the practical lookup layer between generic words and spell recipes. A spell declares which family binding it exposes; exceptions are visible in its row above. “Conditional” is a pending design choice, not a runtime coin flip.

| Recipe family | Big | Swift | Duplicating | Repeating | Lasting | Element words |
|---|---|---|---|---|---|---|
| Stopping/piercing projectile | Body | Travel speed | Another body | Whole recipe echo | Usually not: range and life interact | Contact damage |
| Explosive projectile | Body + impact, explicitly | Travel | Another complete output | Whole recipe echo | Usually not | Declared direct and blast damage |
| Shard fan | Shard bodies | Shard speed | One shard, or authored volley policy | Another fan | Not applicable without lingering shards | Shard damage |
| Continuous front | Reach/thickness | Front speed, conditional | Multiple fronts needs direction policy | Another front | Not a vague substitute for range | Front payload |
| Instant area | Active area | Not applicable | Separate locations required | Another activation | Active-window extension conditional | Area damage |
| Stationary/moving field | Active area | Motion only if field has it | Another field requires placement policy | Another field, explicit overlap policy | Active duration | Periodic damage |
| Beam | Width | Aim speed or tick speed would be a new explicit meaning | Split beam requires targeting policy | Second channel requires ownership policy | Channel duration | Beam damage |
| Infection | Spread range | Transfer speed if travelling | More carriers requires propagation policy | Reinfection behavior undecided | Host duration, not all timers | Host damage only |
| Personal healing | No size binding | Not applicable | Extra heal means total heal, not projectile count; undecided | Extra heal requires budget | HoT duration if present | No damage conversion |
| Absorption | No size binding | Not applicable | Multiple pools not defined | Refresh semantics required | Shield lifetime | Theme only unless damage exists |
| Spirit/creature | Body + reach | Movement where appropriate | Another actor | New summon requires cap semantics | Lifetime | Attack damage |
| Orbit | Body + path | Angular speed conditional | Another orbiting body | Second orbit requires family cap | Orbit duration | Contact damage |
| Trap | Trigger + blast | Not applicable | Another placed trap, conditional | Another trap, conditional | Armed persistence has no finite duration to extend | Blast damage |
| Trail | Patch width | No implied player speed | Parallel path needs geometry rule | New emitter requires ownership rule | Emission/patch duration explicitly | Ground damage |

Powerful applies to selected payload potency across these families. Repulsing applies only where a meaningful hostile-contact/area event exists. Charged and Delayed operate on cast scheduling, but a heal, channel or summon still needs a deliberate acceptance decision; technical schedulability alone is not proof of a good design.

## 10. All remaining spell concepts and reusable recipes

These rows preserve the unselected ideas. They do not claim every idea is implemented or fully tuned. Each names the reusable pieces needed and the candidate size binding, so no concept disappears merely because it has no final number yet. Historical aliases are listed separately to avoid pretending a name change is a new mechanic.

| Concept | Candidate reusable recipe | Big / key modifier implications | Status |
|---|---|---|---|
| Mana Bolt | Automatic emitter → guided projectile → damage | Body; emission cadence belongs to automatic controller, not every spell | Existing automatic attack; expedition presence open |
| Homing Bolt | Projectile + guidance | Body; Seeking may already express this | Separate identity versus expression open |
| Magic Missile | Projectile/volley + optional guidance | Body or volley coverage must be selected | Starter identity open |
| Arcane Orb | Slow moving body + repeat-contact gate/expiry | Body; Lasting must preserve range/lifetime tradeoff | Reserved |
| Arcane Shield | Absorption; optional projectile-interception/reflect component | No size until interception geometry exists | Reserved; reflection unselected |
| Pulse | Self disk front + push | Radius/thickness; Repulsing modifies force | Reserved |
| Gravity Well | Field + radial inward flow | Area; Powerful meaning may be force rather than damage | Reserved; displacement bounds needed |
| Arcane Missiles | Authored projectile volley | Bodies; Duplicating unit must be explicit | Inactive data concept |
| Time Warp | Clock-influence volume/controller | Area only if local; no spatial binding if global | Inactive; clock interaction deferred |
| Arcane Turret | Stationary creature + ranged attack recipe | Actor/body and attack size need separate bindings | Inactive |
| Plague | Area volume → apply infection | Application area versus spread radius must be explicit | Distinct area-infection idea, not merely an alias |
| Thorn Volley | Piercing projectile fan | Shard bodies; pierce remains separate | Reserved |
| Venom Mark | Entity-bound mark → delayed/triggered poison | No size without splash/transfer | Reserved |
| Spore Bloom | Stationary structure/field → infection carriers | Nursery area and spread range require bindings | Reserved |
| Chain Heal | Friendly target chain → healing | Chain search range could be a meaningful size-like mapping, but not automatic | Inactive; allied-recipient design needed |
| Seeking Spirit | Longer autonomous spirit recipe | Body/reach; distinguish from Seeker through behavior | Reserved stronger summon |
| Reaping Spirit | Spirit attack → qualifying kill → area burst | Body and kill-burst radius | Disabled/deferred |
| Skeleton Warrior | Melee creature + health/lifetime | Body and reach, not automatic durability | Inactive |
| Fire | Base effect identity not chosen | Cannot define meaningful parameters until delivery selected | Standalone spell/element grammar open |
| Fireball | Projectile → larger impact area | Body + impact; must distinguish from Fire Bolt | Reserved |
| Fire Wall / Flame Wall | Placed strip field → fire damage | Strip length/width; no terrain blocking unless added | Reserved |
| Flame Elemental | Mobile creature + melee/aura effects | Actor/reach/aura bindings explicitly separate | Inactive |
| Ice Lance / Glacial Lance | Piercing projectile + ice/control | Body; heavier variant needs meaningful distinction | Reserved |
| Splash | Local volume + water payload | Shape/radius after selection | Reserved; exact geometry open |
| Undertow | Travelling/returning front + pull | Width/reach; flow respects collision | Reserved |
| Tidal Wave | Large advancing front | Width/reach; front speed explicit | Reserved |
| Maelstrom | Field + rotational/inward flow | Area; turn force not implied by Big | Reserved |
| Ice Shard | Projectile + optional native slow | Body; Icy Bolt alone does not add slow | Separate identity versus expression open |
| Blizzard | Persistent field + damage/slow | Area; Lasting duration | Reserved |
| Lightning Rain / Rain of Lightning | Distributed warnings → lightning impacts | Impact radius; pattern spread separate | Reserved |
| Chain Lightning | Immediate ordered target traversal → damage | Chain acquisition range needs explicit binding | Reserved distinct from travelling Lightning Bolt |
| Thunder Spear | Piercing body + delayed discharge | Body and discharge area if present | Reserved |
| Static Field | Field + proximity trigger/electric payload | Area/trigger radius | Reserved |
| Tempest | Moving weather field + scheduled payloads | Weather footprint | Reserved; motion pattern open |
| Earth Bolt | Projectile + earth payload | Body; Earthen Bolt may express it | Separate identity open |
| Stone | Projectile + impact response | Body; mass/knockback separate from size | Starter idea |
| Earth Wall / Earth Walls / Stonewall | Destructible barrier segment/formation | Segment width/height; collision/navigation must match | Reserved terrain, separate from Earth Shield |
| Slash | Short swept arc → contact damage | Arc reach/thickness | Deferred starter/character |
| Whip | Articulated curve/sweep → contact payload | Reach/thickness; requires curve collider | Deferred starter/character |
| Crescent | Travelling curved body/cutting front | Body/reach depending chosen recipe | Reserved |
| Moon Slash / Crescent Slash | Fan of three visible cutting fronts | Front size; Duplicating means another cut | Reserved combination/name choice |
| Sunbeam | Solar beam + selected distinguishing behavior | Beam width | Reserved; avoid pure recolor identity |
| Daybreak | Radiant area burst; optional cleansing | Area; cleansing is separate recipient/status removal | Reserved |
| Solar Flare | Directional solar fan | Cone/front dimensions | Reserved |
| Divine Aura | Self-following friendly field → heal + protection | Area; separate payload budgets | Inactive |
| Full-circle rotating laser | Beam + sweep controller with 360° cycle | Width; rotation speed independent | Unnamed working-note idea, separate from Focus Ray |

Naming references retained: Tree of Life → Yggdrasil candidate; Heal/Regrowth → healing names; Plague Nut → plant/infection name; Ember Trail/Fire Trail → Firewalk; Lightning Arc/Thunder → Lightning; Returning Blade/Boomerang → Cross Blade. Super Extreme Meteor Shower Deluxe, Mega Bolt, Mega Lightning Bolt, Giant Bolt, Giant Lightning Bolt, Wide Bolt and Piercing Bolt remain expression/name ideas, not free parser aliases.

### Additional reusable components needed by reserved ideas

| Component | Needed for | Parameters/contract to define before implementation |
|---|---|---|
| Curve/strip geometry | Walls, Whip, curved cuts | Control points, width, swept contact and visible tessellation |
| Flow/displacement field | Gravity Well, Maelstrom, Undertow | Force vector, speed cap, collision behavior, boss response |
| Trajectory history | Path-following Meteor Lance alternative | Sampling, maximum stored path, event positions/times, owner death |
| Reflection/interception | Arcane Shield experiment | Collision shape, eligible projectiles, new ownership, reflection limit |
| Navigation obstacle | Earth Wall | Blocking masks, placement validity, destructibility, expiry, escape safety |
| Clock influence | Time Warp | Affected clock domains, overlap rule, assist/deadline exclusion |
| Status removal | Daybreak cleansing alternative | Removable tags, recipient filter, timing, immunity exclusions |

These are the honest boundaries of reuse: a new behavior may require new code, but it should become a reusable component rather than a special case hidden inside a named spell.

## 11. Data-authoring contract and sustainable implementation

The design table should eventually be a human-readable view of validated spell data. Do not hand-maintain a documentation table, a separate spell switch and a third workshop implementation indefinitely.

A recipe definition needs:

1. Stable spell ID and player incantation, distinct from component IDs.
2. Named component instances with typed parameters and schema versions.
3. Event connections, recipient routing and hit/settlement scopes.
4. Exposed modifier bindings such as `size → infection.spread_radius`.
5. Per-keyword disposition: meaningful mapping, explicit rejection reason, or unresolved design state. Unresolved content cannot enter the shipping catalog.
6. Visual bindings to the same geometry, arrival timing and authoritative combat events.
7. Lifecycle and concurrency policy, including death, cancellation, pause and scene exit.
8. A reproducible preview/test scenario exercising the defining behavior.

Illustrative data shape, **not a new runtime file or approved numeric schema**:

```json
{
  "spell_id": "plague_seed",
  "components": {
    "infection": {
      "type": "infection",
      "host_duration_s": 4,
      "spread_radius_wu": 120,
      "reapplication": "refresh_without_stacking"
    }
  },
  "modifier_bindings": {
    "big": [{"target": "infection.spread_radius_wu", "operation": "multiply", "value": 1.35}],
    "lasting": [{"target": "infection.host_duration_s", "operation": "multiply", "value": 1.4}]
  },
  "design_state": "transfer_and_reinfection_policy_unresolved"
}
```

This excerpt intentionally omits carrier selection and damage components to illustrate bindings; it is not loadable complete spell data. A real content validator must reject incomplete shipping recipes. No unnamed “size” field should force renderer code to guess whether it means body, area, spread or reach.

Compiler sequence: parse known words → find active recipe → validate capabilities → apply explicit bindings in defined order → resolve bounds and reserve capacity → freeze cast plan → execute shared components → emit authoritative events → present. The shared renderer/preview reads the resolved plan. A keyword never runs the parser recursively or modifies the global spell definition for subsequent casts.

Maintainability rules:

- Adding a new parameter-only spell should require data, assets/presentation bindings and behavior tests—not a new projectile class.
- Adding a genuinely new mechanic requires one component with a clear contract and tests; do not force it into a misleading generic component.
- Design-time capability validation prevents accepted words with zero meaningful operation. Exceptions remain data with a reason.
- Derive documentation and workshop controls from parameter metadata once implemented. Keep original design intent alongside generated values; a data dump is not a design explanation.
- Version definitions and preserve old IDs in saves. Renaming an incantation must not silently grant a shorter alias with identical commitment power.
- Keep numeric tuning separate from behavior semantics. Changing spread 120→140 is tuning; replacing a carrier with instant application changes behavior and requires review.

## 12. Acceptance examples and decisions to make

These are future gameplay tests, not claims that the reference has been implemented.

| Scenario | Expected observable result |
|---|---|
| Big ordinary projectile passes near two enemies | Wider body may contact sooner; first-contact policy still limits it to one victim |
| Big piercing lance passes beside a line | Wider visible lance contacts the extra intersected enemies; pierce count unchanged |
| Big infection with target 150 wu away, base range 120 | Modified 162 wu search can reach it; original cannot; transfer remains visible |
| Self + disk + instant versus self + disk + expanding | First hits eligible points together; second hits by actual front arrival |
| Cone projectile variant misses between shards | Enemy in the gap is not hit by an invisible cone |
| Continuous cone front reaches a distant enemy | Damage occurs when the visible front arrives, after nearer points |
| Big Life with no area-heal definition | Clear incompatibility or unresolved-design label; no cosmetic-only success |
| Soul Bloom player-carrier candidate | Player receives healing, enemies damage; no enemy healing or implicit leech |
| Infection host dies | Finite orphan remains; transfer can continue; no host means eventual quiescence |
| Repeated effect | One bounded echo, no recursive repeat or fresh typing assist |
| Same recipe in workshop and combat | Same size, arrival time, contacts and payloads |

Review priorities:

- Is Big's infection mapping **spread radius** the desired default?
- Should ordinary projectile Big improve contact tolerance only, or should some recipes additionally expose blast/pierce changes through different words?
- Which unsupported pairings should reject versus gain a deliberately designed new behavior? Single-target heal and absorption are the clearest examples.
- Which cone/nova/wave spells use projectiles, a continuous front, or instantaneous coverage?
- Which durations and output units does each long-lived/multi-output recipe expose?
- Which infection refresh/reinfection policy and Meteor Lance identity should become the next authoritative design?

Those decisions can be made against explicit tables now. They are not prerequisites to documenting the system, and they must not be silently answered by whichever component is easiest to code.
