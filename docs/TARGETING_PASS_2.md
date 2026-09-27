# Shared spell targeting — pass 2

Projectile damage is a short-lived estimate owned by each live projectile, not permanent enemy state. `SpellTargeting.select` prefers the nearest living enemy with health remaining after estimated incoming damage, then falls back to the nearest living enemy. Estimates last expected travel time plus 0.25 seconds, bounded by projectile lifetime. Straight shots release their estimate when the target falls behind or moves more than 60 units off their trajectory. Hits, despawn, expiry and pool reset release it. This avoids promising that a moving target will certainly be hit.

Homing shots reacquire within 600 world units if their target dies. Reacquisition excludes already-hit targets, and updates reservations before another projectile selects. With no target they continue flying and may acquire one later until normal expiry. Straight shots never steer. Delayed volleys select when each shot actually launches, so they do not retain dead queued targets.

`SpellTargeting.select_area(tree, origin, radius, maximum_range)` selects an enemy-centered circle with the most useful coverage: live enemies score 1, enemies whose current incoming damage is likely lethal score 0.1, and ties prefer nearby centers. It is a selection helper, not an area damage implementation; effects own their timing and geometry. No speculative full-duration ground/beam damage is reserved.

## Implemented library selection policies

| Spell | Selection and commitment policy |
|---|---|
| Passive Mana Bolt | Shared useful target at every launch; homing reacquisition; one-impact reservation. |
| Bolt | Shared useful target for each delayed or rapid cast; straight trajectory; one-impact reservation. With no enemies, existing spread/facing fallback remains. |
| Lightning Bolt | Shared launch and bounce selection; excludes previously hit enemies; reserves only next impact, not hypothetical future bounces. |
| Life Bolt | Shared useful launch target; straight projectile; one-impact reservation; healing seed unchanged. |
| Lightning | Current direct strike nearest living target; downstream AoE work consumes group helper and owns radius. Immediate damage needs no projectile reservation. |
| Meteor Shower | Existing delayed group placement is assigned to effects integration using area helper; no reservation of speculative delayed impacts. |
| Cinder Field / Steam Field | Ground area uses group helper in effects integration; no full-duration damage reservation. |
| Ember Lance / Meteor Lance | Piercing lane retains direction toward living target, then hits along path; lane policy belongs to effects integration, no single-impact reservation pretending the whole line is guaranteed. |
| Plague Seed / Soul Bloom | Visible living host and bounded neighbor propagation; no speculative infection-chain reservations. |
| Focus Ray / Prism Ray | Preserve retained living beam target and reacquisition within beam reach; cadence and tracking unchanged. |
| Seeker | Preserve living target tracking/reacquisition in its own range; repeated contact damage does not reserve future lifetime damage. |
| Cross Blade | Outbound direction toward living target, linger, return; no guaranteed outbound/return damage reservation. |
| Ice Blast | Cone aimed toward nearest living enemy; no projectile reservation. |
| Rune Trap / Frost Sigil | Forward placement, then proximity trigger; no reservation before an enemy enters. |
| Firewalk | Player movement lays trail; no enemy target. |
| Arcane Orbit | Player-centered moving contact geometry; no enemy target. |
| Life / Regeneration / Earth Shield | Self-directed healing/protection; no enemy target. |

Data-only, unavailable ideas are not implemented casting contracts. Reaping Spirit remains disabled.

## Evidence

`tests/shared_targeting_regression.gd`: 18 assertions using actual EncounterEnemy nodes and owned typed Bolt casts. Covers rapid casts, weak-target passive distribution, healthy-target concentration, all-reserved fallback, host death, area coverage, straight-shot miss, expiry, impact, no-live-target state and reset/reuse. Disabling `reserved_damage` produces four targeted failures (rapid distribution, death redistribution, passive distribution, reuse) rather than a false pass. Native visual readability is not established by this mechanical test.
