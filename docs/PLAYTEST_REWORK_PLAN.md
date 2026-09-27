# Playtest rework — consolidated design and delivery plan

Status: implementation authorized September 26, 2026 by the user: “alright do it. yea keep it simple we can polish later art wise.” Execute the staged plan for the existing roster and approved changes. Preserve unrelated work; keep unresolved product choices explicit. New library ideas, shader work and audio remain outside this pass.

## Latest design acceptance

The user has accepted the overall spell direction and specifically endorsed Frost Nova alongside cone-shaped Ice Blast. The subsequent explicit go-ahead authorizes the implementation plan, not every library idea. Preserve open product decisions; routine tuning stays testable and adjustable.

## Deliverables

1. [Core design v0.4](CORE_GAME_DESIGN.md): reconciled intended rules and superseded decisions.
2. [Full spell library](SPELL_LIBRARY.md): individual current, rework, idea, inactive-data and naming-alternative rows, including user concepts and new water/sun/earth proposals.
3. [Spell and upgrade catalog](SPELL_AND_UPGRADE_CATALOG.md): 15 manual bases, automatic Mana Bolt, eight intended bonus spells, 14 passive families and separate future concepts.
4. [Art and feedback specification](ART_AND_FEEDBACK_PLAN.md): every current spell lifecycle, non-spell events, world layout, collision and readability.
5. This plan: traceable feedback, unresolved decisions, ownership, execution order and evidence requirements.

## Feedback register

All runtime dispositions below remain pending implementation/review unless explicitly identified as historical evidence. Recording a requirement is not completing it.

| ID | User concern / intended outcome | Owner after approval | Required verification |
|---|---|---|---|
| F01 | Fresh finite slowdown per cast; no shared meter. | Casting/progression | Finish, cancel, expire, reopen, duration rank, pause and repeated short casts; typing survives expiry and strength stays fixed. |
| F02 | Start Bolt only; Bolt, Lightning and Lightning Bolt distinct. | Casting/progression + spells | New run, slot 1, owned input aliases, unlock Lightning, then acquire bouncing combination. Check displayed name and actual behavior together. |
| F03 | Bonuses are new slot-free spells; keep ingredients. | Casting/progression | Acquire with six occupied actives; verify originals/ranks remain, bonus casts, no seventh base slot; restart run removes unearned ownership. |
| F04 | Six active and six passive families. | Casting/progression | Fill each category separately, rank existing family, inspect offers when full; no unimplemented map overflow. |
| F05 | Longer spells powerful and unique; basics still useful. | Spell behavior | Compare useful per-cast output and typing exposure across isolated strong target, cluster, surround and moving pack scenarios; human confirmation still needed. |
| F06 | Plague Seed unclear / no visible infection. | Spell behavior + art | Living, dying, absent and offscreen hosts; close versus out-of-range neighbors; visible real transfers, caps and expiry. Diagnose the reported empty cast rather than assuming its cause. |
| F07 | Cross Blade weak; linger and return matter. | Spell behavior + art | Outbound/linger/return, moving caster, misses, multiple targets and recast; compare actual output with Bolt. |
| F08 | Seeker is a short basic hunter; Seeking Spirit is a separately proposed stronger summon. | Spell behavior + art | Visible count equals real hunters; acquisition/retargeting/lifetime and kill attribution work. |
| F09 | Rune Trap permanent until triggered. | Spell behavior | Wait beyond old expiry, trigger, cap overflow, movement, pause and run end; repeat for Frost Sigil. Cap policy remains a proposal. |
| F10 | Clean HUD and concise choices. | UX | All upgrade types, full categories, bonuses, long names, help/pause/endings; exact one-sentence copy, no boss forecast or permanent controls. |
| F11 | Bigger readable keycap letters; text stays in boxes. | UX + art | Desktop and narrow menu/typing journeys; wrapping, repeated backspace, punctuation, long names, focus and next-state transitions. |
| F12 | Complete hit/death/hurt/XP feedback, not only spells. | Art | Actual event-by-event footage plus crowded overlap; terrain-barrier damage and any real absorption distinct from player HP loss. |
| F13 | Mana Bolt animation and enemy circles confusing. | Art + UX | Clean 2D trajectory; debug rings absent normally; necessary enemy attack telegraphs retained. |
| F14 | Bigger XP crystals and understandable pickup. | Art/world | Visual size compared at same zoom, unchanged XP/magnet/radius, readable glint on collection. |
| F15 | Trees thinner and centered on trunks; clustered vegetation. | World | Reported stuck-left case, all-side trunk approaches, tree variants, paths/clearings/start safety; visible canopy versus collision overlay. |
| F16 | Difficulty too passive; inactivity dies around 30–45s. | Pacing | Seeded idle, movement-only, stationary-casting and active runs; report each mode honestly, then human play. No forced timeout damage. |
| F17 | Fair timed tiers, late ranged enemies, bosses and 20-minute win. | Pacing | Boundary checks at 0, 5, 10, 12, 15, 20 minutes; living bosses do not delay tiers or final win. No early shooters. |
| F18 | Projectile speed, Multicast and passive accounting. | Casting/progression + spells | Every applicable spell's mapping, exclusions, caps and exact copy; no recursive multiplier explosions. |
| F19 | Meteor/long-spell impact should feel substantial. | Spell behavior + art | Useful hits first, then bounded shake/flash, mixed hazards and reduced-effects settings. Spectacle does not certify power. |
| F20 | Preserve every named concept with status and provenance; add new ideas without treating them as implementation scope. | Design coordinator | Roadmap distinguishes concepts from approved changes; no accidental new spells, typed menus, audio or pivot. |
| F21 | Life and Regeneration are separate; long healing pays more. | Spell behavior + progression | New IDs/ownership, distinct typing phrases, about-4-HP Life target, stronger Regeneration, heal caps and recipe migration. |
| F22 | Repair Earth Shield; distinguish its protective role from separate Earth Wall terrain. | Spell behavior + world/art | Geometry, caster escape, enemy damage, timed erosion, recast and debris; no invisible blocking or assumed overheal. |
| F23 | No homing on basic Bolt; names fit effects. | Spell behavior + UX | Aim-once path; no steering; Homing Bolt stays a separate idea. Seeker/Firewalk name and behavior changes agree across copy and recipes. |
| F24 | Keep current spells and fix the baseline before selecting expansions. | Design coordinator | No existing spell silently removed or replaced by a library alternative; every new identity has explicit scope status. |
| F25 | Debug and ordinary game should feel substantially different. | UX + diagnostics | Fresh normal run has no diagnostic UI; ordinary spellbook remains sufficient; opt-in debug exposes technical tools and marks gameplay-changing commands. |
| F26 | Ice Blast is a cone; every spell needs explicit hit geometry and aiming. | Spell behavior + art | Inside/outside/behind/boundary and obstacle cases; moving shapes, impact areas, size/Multicast changes, normal visual clarity and debug overlays agree with real hits. |

## Art execution constraint

Match the friend’s supplied asset style and keep new art intentionally simple and placeholder-quality. Reuse available assets and add only the minimal missing sprites/frames needed for the current roster’s truthful geometry and feedback. The lifecycle matrix defines communication requirements, not a production-animation quota. The large idea library does not authorize generating art for every concept. Inspect references and compare at gameplay scale before approving new samples. Shaders and audio remain deferred.

## Deferred rendering scope

User decision: shader work is deferred. No implementation agent should add shader development or shader-based polish to this pass; revisit it separately after the baseline is settled.

## Agent execution plan

Four concurrent slots are available: coordinator plus at most three workers. Agents do not all edit one checkout. Every implementation tranche gets a dedicated branch/worktree, owned files resolved from a read-only code map, and a reviewable PR. Shared files and dependencies are coordinated explicitly. Existing dirty work remains preserved, never absorbed blindly.

### Phase 0 — design, current phase

- Coordinator owns documentation reconciliation and decision status.
- Spell/pacing reviewer audits spell identities, recipes, passive interactions and existing bot evidence.
- UX/progression reviewer audits slots, ownership, slowdown and information hierarchy.
- Art/world reviewer audits available assets, missing feedback, terrain and collision.
- Output: this package and a small set of decisions. No code or art generation.

### Phase 1 — foundations after explicit design approval

- Casting/progression agent owns per-cast slowdown, ownership, six/six limits and additive bonus acquisition. It must define stable data contracts before downstream changes.
- World agent can independently repair visible-trunk collision, grove layout and XP visual scale.
- Art agent can inventory approved assets and storyboard the settled spell/event contracts; runtime VFX integration waits for those contracts.
- Coordinator reviews each diff and keeps shared identifiers, saves and build truth consistent. Exact filenames are assigned before edits, not guessed in this plan.

Merge/review foundation dependencies before rebalancing effects or authoring final copy. Do not count an isolated passing branch as an integrated game.

### Phase 2 — spell behavior and presentation

- Spell agent owns behavior and useful-output tuning for existing bases and eight bonus identities, with approved passive mappings.
- UX agent owns minimal HUD, ordinary spellbook/build access, owned bonus discovery, larger letters and exact upgrade copy.
- Art/VFX agent owns distinct lifecycle effects and non-spell feedback against the approved event contracts.
- If these touch common managers/scenes, changes are serialized or moved behind a reviewed interface; never resolve collisions by overwriting another branch.

Priority identities: Bolt/Lightning/Lightning Bolt; Plague Seed; Cross Blade; Rune Trap; Seeker/Seeking Spirit split; Life/Regeneration split; Earth Shield versus Earth Wall roles; then complete the remaining existing roster and approved migrations. The full library includes future ideas and naming alternatives; those rows require separate scope approval and are not implied implementation work.

### Phase 3 — balance and integrated review

- Pacing agent tunes the final spell/slot/slowdown build, not the old candidate.
- Test agent operates upgrade/casting/persistence journeys and all named playtest concerns, with deterministic scenario coverage and bot telemetry.
- Independent code/UX reviewer checks regressions, effects readability and actual build behavior.
- Coordinator binds all evidence to the exact candidate revision, integrates reviewed PRs in dependency order, and checks one consolidated local build.

Only after verified merges: preserve unique work, clean completed worktrees/branches using the managed lifecycle, list retained worktrees and explain why. Consolidation is an explicit delivery step, not merely a remote merge.

## Balance design and evidence limits

Use density, surround pressure, enemy mixtures and timed surges with recovery before adding large HP/damage multipliers. Keep early fodder readable and fragile; postpone projectiles. More enemies create potential XP growth, so track levels and upgrade opportunity alongside survival.

Previously completed results on frozen candidate `9762359`:

| Mode | Evidence | What it establishes |
|---|---|---|
| Original baseline | All tested modes survived 60 seconds; idle tests stayed full health. | Opening had inadequate pressure in those simulations. |
| Idle candidate | 5/5 deaths at 38.7–42.2 seconds. | Meets idle target on these seeds. |
| Movement-only candidate | 5/5 survived the 60-second limit, with damage. | Does not meet a strict no-casting death target. |
| Active random bot | Five deaths at 398.0, 402.1, 427.7, 748.7 and 787.0 seconds. | Reached first boss; no demonstrated 20-minute victory. |
| Stationary casting | One completed result, death at 49.0 seconds. | Insufficient for a five-run or 30–45-second success claim. |

These are previous fixed-FPS bot measurements reported by the branch owner, not new runs in this design phase. They neither establish human fun nor remain valid after per-cast slowdown, slot and spell changes. Moving intelligently is a legitimate survival skill; deciding whether all non-casting movement must fail by 45 seconds is a product choice, not a reason to add unavoidable damage.

## Current source/build truth

| Location/state | Status at design snapshot |
|---|---|
| Canonical main and local build | `88240e2`; user-owned untracked Typecast files preserved. |
| Remote main | `a653af0`; minimal UI PR27 merged before the pause, not reflected in canonical/current build. |
| `feature/spell-clarity` | Dirty unfinished identity/progression edits; earlier assumptions conflict with newest decisions. Audit before reuse. |
| `feature/combat-effects` | Dirty staged effects/assets; incomplete and not approved as final art. |
| `feature/forest-groves` | `823c0db79a1cc5bb098522383c7f2bfb50e8c0c4`, pushed, clean, no PR or merge. Prior 6,227 geometry/XP and 68 art/world checks are candidate evidence only. |
| `feature/opening-pressure` | `9762359`, frozen/unmerged candidate; previous bot evidence above. |
| `docs/playtest-design` | This documentation-only review branch based on `a653af06fbaaa510f3ed467f37b85d3025689624`. |

No statement here means the user is already playing the intended design. Do not merge frozen branches wholesale: identity assumptions, replacement recipes, shared slowdown and numeric budgets must be reconciled first.

## Decisions to settle before affected implementation

| Decision | Recommendation | Status |
|---|---|---|
| Automatic Mana Bolt and passive slots | Innate attack free; choosing mastery occupies one of six passive slots. | Proposed. |
| Bonus acquisition and ranks | Eligible level-up reward, rank 1, independent upgrades; discovery persists separately. | Proposed; additive/no-slot/keep-ingredients rule already confirmed. |
| Persistent trap cap | Three active traps, oldest replaced on overflow; define shared versus separate Frost Sigil cap. | Proposed, not an agreed cap. |
| Earth Shield / Earth Wall | Personal stone protection now; placed Earth Walls stay on the idea list. | User confirmed during implementation. |
| Plague empty-target handling | Visible bounded living-host selection; explain no-target without silently wasting a cast. | Exact range and input behavior open. |
| Cross Blade input spelling | Display/type “Cross Blade”; retire Returning Blade alias if it bypasses intended identity. | Name direction accepted; exact canonical phrase/alias policy proposed. |
| Slowdown clock | Real elapsed typing seconds; pause/menu time excluded. Negligible debounce, no reserve. | Timing detail proposed; per-cast rule confirmed. |
| Difficulty target | Keep idle 30–45s target; judge moving-only by sustained pressure, not guaranteed unavoidable death. | Needs user judgment on strict no-casting target. |
| New spell concepts | Maintain the full individual library, including Moonfall/Yggdrasil/Hand and water proposals. Choose implementation scope separately; adding a documented row does not approve code. | User requested comprehensive library. |
| Healing recipe migration | Life Bolt = Bolt + Life; impact plants a healing seed which the player physically collects for a brief heal. No automatic life-steal. Regeneration remains a separate stronger self-heal. | Latest user-confirmed Life Bolt fantasy, implemented in this pass. |
| Seeker / Seeking Spirit | Seeker now; Seeking Spirit remains an idea and Reaping Spirit is explicitly deferred. | User confirmed during implementation. |
| Fire trail name | Recommend Firewalk for movement-laid fire; keep Fire Trail and Ember Trail as alternatives/history. | Working proposal. |

Numeric spell ranks, Luck outcomes, crit eligibility, health-on-max-HP increase, Multicast edge cases and exact ranges need authored tables before their implementation. These are not invitations for agents to invent independent policies.

## Release gates after implementation approval

For every feedback ID record reproduction journey, expected behavior, observed behavior, candidate revision, evidence, related-case sweep and fixed/open disposition. Missing runtime or skipped concerns are incomplete, never pass.

Operate new run → first cast → rank/learn → full build → combination → pause/spellbook → death/retry and victory flows. Check visible results immediately, after effects settle, after the next transition, and after reopen/restart where discovery/settings persistence matters. Include desktop and narrow layouts, screenshots/recordings, console/runtime errors, exact start command and revision.

Use discriminating regression controls for shared slowdown, replacement recipes, unowned casting, expired traps, incorrect trunk anchors and clipped text. Report nonzero collected assertions; a clean exit alone is insufficient. Keep mechanical checks, functional journeys, bot evidence and human feel judgment separate. No claim of “ready” based solely on test totals or static screenshots.
