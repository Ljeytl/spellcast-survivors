# Engineering specification and data contracts

This is an implementation specification, **not permission to modify the game during this documentation task**. Build the expedition mode alongside the legacy prototype until its core loop passes testing. Names below are proposed modules, not claims they already exist.

## Boundaries and responsibilities

| Module | Owns | Must not own |
|---|---|---|
|ContentRegistry|Validated immutable spell/keyword/recipe/enemy/realm definitions|Mutable run state or renderer callbacks|
|IncantationParser|Normalized text → spell + keyword IDs or structured diagnostic|Damage, unlock mutation, natural-language guessing|
|SpellCompiler|Capabilities, modifier order, caps, immutable CastPlan|Scene instantiation, UI timers|
|CastController|Typing attempt, assist eligibility, commit/cancel/charge states|Global shared slowdown resource|
|CastScheduler|Reserved output capacity, delayed/repeat release, root lifecycle|Re-parsing text or granting knowledge|
|TargetingService|Spatial candidates, reservations, stable policy choices|Applying damage before collision|
|EffectRuntime|Projectile/area/beam/summon components, actual contacts|Independent per-spell text parsing|
|CombatResolver|Damage, healing, status, absorption, death and hit events|Particles deciding who was hit|
|PresentationDirector|Effect cues, sound, hit flash, bounded shake/hit-stop requests|Changing damage geometry or extending assist|
|EncounterDirector|Budget, cadence, spawn sockets, caps, time bands|Player-level rubber banding or reward persistence|
|RealmGenerator|Versioned seed, authored graph, validated modules and sockets|Unvalidated decoration collision after navigation checks|
|ExpeditionController|Mana activation, objective state, terminal transitions|Permanent stat multiplication|
|KnowledgeStore|Idempotent discovery events, recipes, profile persistence|Temporary active effect serialization as permanent knowledge|
|WorkshopHost|Same compiler/runtime in deterministic scenarios|Fake independent spell behavior for previews|

Prefer data-driven common behavior plus a small number of distinct effect components. “Modular” does not mean every spell must fit a single bloated universal function. Ice fan, infection graph, returning blade and destructible summon merit separate components with shared targeting/damage/geometry contracts. Avoid a new enormous spell-name switch as the composition engine.

## Definition contracts

Fields marked required below must fail content validation if missing. IDs are stable lower_snake_case; display labels can change without losing saves. All collections use explicit order where evaluation matters.

```json
{
  "schema_version": 1,
  "id": "bolt",
  "incantation": "bolt",
  "kind": "projectile",
  "element": "arcane",
  "capabilities": ["damage", "travelling", "geometry", "repeatable"],
  "base": {"damage": 40, "body_radius_wu": 7, "speed_wu_s": 500, "range_wu": 480, "native_count": 1, "recovery_s": 0.45},
  "targeting": {"policy": "nearest_unreserved", "range_wu": 480, "guidance": "none"},
  "geometry_bindings": {"big": ["body_radius_wu"]},
  "limits": {"max_initial_outputs": 2, "max_child_generation": 1},
  "presentation": {"family": "arcane_projectile", "core_geometry": "body_radius_wu", "impact_tier": "ordinary"}
}
```

This is illustrative schema, not a ready-to-load file. Compiler requires: spell ID/incantation/family, numeric base fields needed by its components, capability mask, accepted keyword IDs, targeting policy, geometry bindings, tick/ledger policy, recovery, active family, maximum outputs, presentation binding and acquisition source. Defaulting a missing heal recipient filter to “all entities” is forbidden.

Keyword definition: ID, canonical word, compatibility predicate, field operations with operation types (`add_base_fraction`,`multiply`,`add_count`,`set_category`,`schedule_child`), exclusions, caps, preview text and presentation modifier. Do not store arbitrary executable scripts in save data. Content changes are versioned with migration rules.

Recipe definition: stable ID, two ingredient base IDs, resulting spell ID, enabled flag, discovery rule and activation rule. Validator rejects cycles, unknown references, duplicate canonical spell suffixes and bonus spells as their own ingredients. A combo can use a shared component without inheriting every numeric field from a live mutable ingredient.

Realm definition: ID, map/generator version, anchors, module pools, four objectives with stable IDs, reward bundles, guardian, affinity map, ranged start, threat multiplier, next realm and extraction deadline. Challenge waves reference concrete variants and substitution rules. All reward IDs must resolve to selected campaign content, never an unimplemented idea accidentally exposed.

## CastPlan and lifecycle

Required plan fields: root UUID, owner entity ID, spell/content version, keyword IDs, snapshot potency/geometry/status, target policy/anchor, initial output descriptors, delayed schedule, reserved capacity, generation ceiling, per-root healing limit, active-family assignment and presentation family. Plan immutable after commit; target handles may be resolved at release according to policy but do not change the frozen damage scale.

Events: `CastCommitted`, `ChargeCancelled`, `OutputReleased`, `ContactResolved`, `DamageApplied`, `HealApplied`, `StatusApplied`, `EntityDied`, `OutputExpired`, `RootCompleted`. Every event has run ID, simulation tick, root ID when relevant, entity IDs and typed payload. Presentation consumes authoritative events; an animation cannot emit DamageApplied independently.

Deduplication keys:

- Instant area: `(root,generation,area_instance,target)` once.
- Ice Blast fan: `(root,generation,target)` once across all shards.
- Piercing projectile: `(output,target)` once.
- Cross Blade: `(output,leg,target)` once; linger uses interval gate.
- Field: integrate the union of overlapping same-root patches once per recipient. Each payout has a monotonic settlement event ID and an accumulated-paid cursor; multiple exits/re-entries within one tick interval may legitimately settle different exposure. Replaying a settlement ID must not pay twice.
- Infection: `(root,target)` host admission once; ticks indexed; maximum host counter includes dead hosts.
- Heal pickup: seed ID consumed once; total root heal budget shared among all child seeds.

Owner death cancels pending player output; already active independent effects may finish only if terminal state remains running (e.g. allied summons owned by another actor in future). In current single-player death terminates combat immediately. Scene exit cancels timers and detaches all event subscriptions; no delayed effects leak into menus or next expedition.

## Persistence contract

```json
{
  "schema_version": 1,
  "profile_id": "stable-profile-id",
  "knowledge": {"spells": ["bolt", "life"], "keywords": ["big"], "recipes": ["life_bolt"]},
  "realm_access": ["verdant_ruins"],
  "discovery_event_ids": ["run-id: ley-west: reward-v1"],
  "completed_rewards": ["verdant_ruins: west: v1"],
  "mastery_stamps": [],
  "legacy_profile_reference": "preserved-separate-profile"
}
```

Save mutations write temporary file → flush → atomic replace, retaining last valid backup. Profile and run snapshot include matching last-event sequence. Apply discovery event idempotently before acknowledging success. Unknown content IDs remain preserved in save on content rollback, but are not castable until recognized. Never delete unknown knowledge just because a build's catalog is smaller.

Run snapshot fields: seed/generator version, run clock, player health/shield, prepared order, mana, active index, objective flags/wave progress, crystal totals/positions, director state, known profile sequence. First slice may only suspend at safe preparation/entry; if mid-combat suspension unsupported, UI explicitly ends expedition. Full save/resume of active effects is a later tranche requiring deterministic scheduler serialization, not silently claimed by saving only player position.

## Performance and diagnostics

Spatial hash/cell query for nearby targets and contacts; no full enemy scan per particle. Target service may refresh candidate cache at 10 Hz, but swept collision and damage events resolve at physics tick. Rendering interpolation does not alter authoritative positions. Pool bodies and decorative particles; do not pool stale hit ledgers across casts.

Proposed reference budget:60 Hz physics, 60 FPS at 1280 × 720 on a declared minimum test machine; 90 ambient enemies plus challenge budget, 96 reserved-or-active player projectile/impact bodies, 120 hostile projectiles, 600 cosmetic particles. These caps are design proposals; profile actual cost before choosing shipping minimum hardware. Never quietly drop hostile projectiles or gameplay areas to maintain FPS; lower decoration first, then reject unsupported stress presets in debug.

Debug overlay: source SHA, content version, seed, clocks, remaining assist and assist state, cast root and pending outputs, reservation count, actual hitboxes, damage/heal recipient filters, spawn points per second, banked budget, living enemies by family, encounter phase, mana totals before and after consolidation, objective flags and save-event sequence. Gameplay UI hides these fields. Log structured events with bounded ring buffers and exportable replay scenarios; avoid per-particle log floods.

## Legacy migration and implementation order

1. Add content/compiler tests without changing old spell dispatcher.
2. Build new mode behind an explicit menu option using shared low-level collision/visual components where truthful.
3. Adapt selected existing spells to plans; compare their workshop effect/hit timing before tuning.
4. Add knowledge/preparation and tutorial.
5. Add one realm/director/objectives and terminal states.
6. Playtest and tune; only then expand to full roster/realms.
7. Decide whether to retire legacy mode after user review; never migrate away the only working build first.

No dependency upgrades, engine rewrite, shader pipeline or broad asset regeneration are required merely to compile keywords. Existing Godot architecture should be audited against these contracts before selecting file boundaries.
