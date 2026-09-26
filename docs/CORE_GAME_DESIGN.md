# SpellCast Survivors — Core Game Design v0.2

Status: revised working design for user review. This document reconciles the supplied agent draft with the conversation through the immediate twenty-minute victory decision. It does not approve all proposed systems or change game behavior.

The original draft is preserved in [the reference copy](reference/CORE_GAME_DESIGN_AGENT_V0_1.md). Current encounter implementation is described in [ENCOUNTER_DESIGN.md](ENCOUNTER_DESIGN.md). Older proposals, including [combined-spells-design.md](../combined-spells-design.md), remain sources of ideas rather than binding requirements.

## 1. What this game should feel like

You begin as a spellcaster with enough breathing room to understand movement, typing, passive attacks and leveling. During the run, your spell choices and upgrades form a recognizable playstyle. By the end, your build should feel almost absurdly powerful while you manage more interesting enemy combinations. Escalation should increase the spectacle on both sides while preserving readable danger.

The player succeeds through a combination of build decisions, positioning, targeting, timing and typing. The game should reward a chosen playstyle without unexpectedly invalidating it because the player omitted one particular spell or element.

The narrative reason for the assault and victory can be designed later. A twenty-minute timer currently provides a complete mechanical objective.

## 2. Decision status

| Topic | Status and direction |
|---|---|
| Run ending | Agreed: reaching 20:00 immediately wins. Zero health before completion loses. No final fight after the timer. |
| Boss timing | Agreed under the current ending: 5:00, 10:00 and 15:00. |
| Tier advancement | Agreed: elapsed game time advances tiers even if earlier bosses remain alive. |
| Opening | Agreed: err toward easy, with consistent melee fodder and time to earn upgrades. |
| Early durability | Agreed target: ordinary enemies take 2–3 starting passive hits; fast fragile enemies take one. |
| Runner trade-off | Agreed target: approximately 2–3 times ordinary melee speed in exchange for fragility. Not every runner behavior must use the same movement speed. |
| Enemy roster | Agreed structure: Grunts, Runners, Brutes and Shooters, with multiple variants each. The current roster has three per family. Skirmisher belongs to Grunts, Swarmer to Runners. |
| Ranged introductions | Agreed: later pressure, roughly 10–12 minutes; clear hostile projectiles. |
| Elemental identity | Agreed: primarily theme. Multiple approaches must remain viable; ordinary enemies must not require an element or named spell. Special late elemental interactions are undecided. |
| Progression | Desired: acquire spells, choose meaningful upgrades and explore combinations during runs. Exact rules remain proposals. |
| Spell count and slots | Open: twenty spells/five slots began as an example. The prototype has six numbered slots; neither count is immutable. |
| Production direction | Agreed: aim for publication, build the gameplay loop first, tackle art direction afterward. |

Current numeric values are a baseline for experiments, not a veto on better design proposals.

## 3. Run structure

The following pacing goals organize the run. Exact introductions within these windows are tuning proposals, not additional hard milestones.

| Game time | Intended experience | Encounter direction |
|---|---|---|
| 0–3 minutes | Learn and get stronger without immediate panic | Consistent Pursuers, then occasional fragile Sprinters; gradually introduce positional pressure. |
| 3–5 minutes | Position deliberately | Flankers, Skirmishers and small swarms diversify movement. |
| 5–10 minutes | React and manage space | First boss; introduce durable Brutes, charge warnings and ground attacks progressively. |
| 10–12 minutes | Read ranged threats | Second boss; Marksman, Fan Caster and Mortar arrive separately. |
| 12–15 minutes | Handle combinations | Mix familiar behaviors while preserving understandable escape opportunities. |
| 15–20 minutes | Express the build under pressure | Third boss and more demanding combinations; upgrades should make the player visibly stronger too. |
| 20:00 | Immediate victory | Stop combat, spawning and the clock. Show results and allow another run. Living enemies do not block victory. |

The current introduction schedule is Pursuer 0:00, Sprinter 0:45, Flanker 2:00, Skirmisher 3:00, Swarmer 4:00, Juggernaut 5:00, Charger 6:00, Shieldbearer 7:00, Slammer 8:00, Marksman 10:00, Fan Caster 11:00 and Mortar 12:00. The original draft's later Brute introductions and tighter ranged spacing remain alternatives to test.

First-upgrade target: roughly 15–20 seconds under ordinary competent opening play. Three seeded passive-attack simulations previously reached it around seventeen seconds; that is supporting evidence, not proof across players and typing abilities.

## 4. Typing is a core combat system

### Current prototype behavior, not a final input specification

- Numbered slots enter a spelling prompt; a freeform casting path also exists.
- Correct completion automatically casts. Backspace edits, Escape cancels, and Enter submits; an incorrect submission cancels.
- Typing applies engine time scaling, initially 0.2. Simulation time, including the run clock, therefore advances more slowly than wall time.
- Player movement still reads its movement actions while typing. WASD is also letter input, so movement and spelling can interfere.
- The cast-speed multiplier both accelerates passive firing and increases the time scale during typing. The latter reduces the slowdown and gives the player less wall-clock thinking time per unit of enemy movement. That is a potentially adverse upgrade effect, not an endorsed design feature.

### Proposed direction for review

Keep the move → choose spell → type → resolve → reposition rhythm. Keep typing assistance explicit and predictable. A typing mistake should normally cost time and require correction, rather than silently choosing another spell or imposing an additional health penalty.

Resolve movement and aiming before promising complex placement spells. Each spell needs a targeting contract: automatic target, direction, player-centered, placed area or selected enemy. A wall cannot be balanced until its orientation and placement controls are known.

Separate three concepts in both design and UI:

1. Human entry time: incantation length, readability, corrections and player fluency.
2. Spell timing: release delay, cooldown and duration after input succeeds.
3. Typing assistance: how the battlefield slows while the player enters text.

Recommended starting position: keep typing slowdown consistent as power increases; make cast-speed upgrades improve clearly beneficial spell/passive timing. Test dedicated movement inputs during typing rather than allowing incantation letters to steer the character. These are recommendations requiring input-design review, not changes authorized by this document.

Twenty minutes currently means simulation time. A heavily typing-focused run can take longer in real time. Whether the product promises twenty minutes of wall time is an open decision.

## 5. Enemy design

| Family | Variant | Tactical role |
|---|---|---|
| Grunt | Pursuer | Readable baseline pursuit and dependable early XP. |
| Grunt | Flanker | Angled approaches that encourage repositioning; prediction should be imperfect if added. |
| Grunt | Skirmisher | Approach, retreat and re-entry rather than simple pursuit. |
| Runner | Sprinter | Fast, fragile urgency; early versions die to one passive hit. |
| Runner | Charger | Announce a committed direction, charge, then leave a recovery window. |
| Runner | Swarmer | Small enemies whose group formation creates the threat. |
| Brute | Juggernaut | Slow durable body that shapes movement. |
| Brute | Shieldbearer | Readable frontal protection with positional alternatives. |
| Brute | Slammer | Delayed area attack with clear timing and an escape opportunity. |
| Shooter | Marksman | Aimed shot with a visible warning and projectile. |
| Shooter | Fan Caster | Spread with gaps a player can actually traverse. |
| Shooter | Mortar | Marked delayed area attack; prediction must leave room to react. |

Enemy behaviors should create several possible responses. A positional shield may reward flanking, area attacks, sustained damage or overpowering it. Do not claim that piercing bypasses a shield unless that interaction is explicitly implemented and communicated.

The current shield reduces frontal projectile damage by 35%; the source draft proposes 60%. Both are tuning candidates, but stronger mitigation must be tested with projectile-focused builds. Current regeneration heals forty HP over five seconds; the proposed Regrowth heals ten. Compare these within the chosen damage and casting economy rather than automatically adopting either value.

Bosses are currently enlarged, marked variants. Bespoke Hunter, Warlock and Colossus concepts remain good expansion candidates: each should combine familiar threats with readable new behavior. A fourth Archmage fight is deferred because it conflicts with immediate victory at 20:00. Its mechanics could later be reused in another encounter.

## 6. Difficulty and encounter composition

Keep health, damage, movement speed and spawn pressure independently tunable. Maintain ordinary fodder in later pools so builds retain satisfying targets. Avoid aggressive movement-speed scaling that removes the ability to dodge.

Current baseline: health stays flat for three minutes, then grows by 1.16 per two minutes; movement speed is fixed; opening spawns occur every three seconds before pressure rises. These values remain editable.

The source draft's polynomial health/damage curves, modest speed growth, phase density ranges and spawn costs are candidate experiments. Do not combine them wholesale with existing scaling: that could unintentionally multiply difficulty. Compare complete configurations against player progression.

A budget-based director is a useful proposal. Define budget accrual interval, carryover, burst limit, composition limits and whether swarmer cost is per unit or group. Prioritize time and composition constraints initially. Player damage output can be logged without automatically increasing pressure to compensate for a strong build.

Active enemy count is an observation and safety limit, not a quota the director must refill whenever the player kills efficiently. High kill rate should be allowed to earn breathing room. Limits on simultaneous ranged attacks, large bodies and overlapping warnings should protect readability.

Elite modifiers remain expansion ideas. Start with one readable modifier if introduced. Frenzied, Giant, Volatile, Arcane and Vampiric need individual behavior tests; combinations come later. Avoid death explosions that punish unavoidable close-range kills without warning or an escape window.

## 7. Building the wizard during a run

Desired progression: early choices establish useful tools; later choices develop their identity and interactions. A player should experience a build well before the last few minutes.

Working proposal: offer three choices per level, drawn from eligible new spells, owned-spell upgrades and passives. Improve the chance of seeing a new spell while slots remain open. Define that probability or guarantee explicitly; do not describe a probabilistic offer as guaranteed.

Keep the passive attack available as basic coverage while manual spells provide meaningful advantages. Whether it occupies an equipped slot is still open.

### Loadout and replacement

Five slots is a candidate, six is the current numbered interface. Choose based on meaningful choices and typing usability, not just precedent. At capacity, stopping new-spell offers is simple but can trap a player in an early commitment. Recommended proposal: permit an explicit replacement choice with clear consequences, and decide how invested ranks transfer or are lost before implementation.

### Upgrade budget

Six ranks with a branch at rank four is a candidate structure, not a requirement for every spell. The objective is a noticeable change in use, not completing a uniform rank checklist.

If a player starts with one spell and ends with five, acquiring the other four and upgrading all five from rank one to six takes 29 level choices. At level 25, only 24 level-up choices have occurred. Passives consume more of that budget.

Recommended proposal: a typical run completes one or two signature spells while supporting spells remain useful at lower ranks. Acquisitions, branches and passive choices all need to be included in the same progression budget. If the intended fantasy requires every slot maxed, change ranks, rewards or leveling instead.

Reroll, skip and banish are useful candidate tools. A skip reward must be explicitly run-local or persistent; the source phrase “permanent XP bonus for the run” is ambiguous. A repeatedly stacking XP bonus can make skipping into the dominant growth strategy. No skip reward or reroll count is approved yet.

## 8. Candidate spell library

The following twenty concepts are a library to develop, not a committed launch count. Existing spells can be adapted rather than automatically replaced. Names are theme and UX choices; incantation aliases need separate review if names change.

| Theme | Spell | Behavior and possible development |
|---|---|---|
| Fire | Firebolt | Quick precision projectile; develop firing rate, piercing or heavier hits. |
| Fire | Fireball | Direct hit plus local explosion; branch toward clusters or lingering fire. |
| Fire | Flame Wall | Directional damage zone; trade area and duration against intensity. |
| Fire | Meteor Shower | Delayed sustained bombardment; many small impacts or fewer large ones. |
| Frost | Ice Shard | Piercing projectile with light slow; more coverage or shattering damage. |
| Frost | Frost Nova | Player-centered burst and brief control; emergency breathing room. |
| Frost | Glacial Lance | Committed high-damage line; precision or wider coverage. |
| Frost | Blizzard | Lingering area control with sustained damage. |
| Storm | Chain Lightning | Connected-target coverage; more jumps or stronger initial impact. |
| Storm | Thunder Spear | Straight piercing attack that rewards lining up enemies. |
| Storm | Static Field | Temporary nearby damage and interruption. |
| Storm | Tempest | Delayed enemy-targeted storm with optional chaining. |
| Arcane | Magic Missile | Reliable automatic targeting; more missiles or concentrated hits. |
| Arcane | Arcane Orb | Moving area damage that rewards its path through enemies. |
| Arcane | Gravity Well | Grouping and displacement with modest direct damage. |
| Arcane | Arcane Shield | Temporary protection; optional break effect or another behavior change. |
| Nature / Corruption | Thorn Volley | Spread burst; narrow piercing cone or wider coverage. |
| Nature / Corruption | Venom Mark | Sustained single-target damage; stacking or spread on death. |
| Nature / Corruption | Spore Bloom | Delayed burst followed by a lingering zone. |
| Nature / Corruption | Regrowth | Healing over time; stronger recovery or a recovery/mobility trade-off. |

The numeric spell values in the original draft are retained in the reference document for experiments. They are not synchronized with the prototype and should not be imported as a balance patch.

Each implemented spell needs: target selection, input commitment, timing units, hit rules, repeat-hit limits, status stacking, upgrade eligibility, readable effects and contribution to the progression budget. Compare single-target output separately from aggregate damage across crowds.

A fire-themed build must be able to handle normal encounters through several fire behaviors and general player skills. “Theme is not a counter” should not quietly become “every theme needs an identical spell in every role.”

## 9. Interactions, combinations and evolutions

Preserve both natural interactions and the possibility of authored combined spells. They serve different purposes:

- Natural interaction: group enemies with Gravity Well and hit them with Fireball; slow targets before a meteor; lead enemies through a wall.
- Authored combination: a named ability deliberately changes behavior when ingredients or conditions are met.
- Evolution: an owned spell transforms into a stronger or different version.

The newer draft favors natural interactions plus rare evolutions. The older combination design proposes named fusions and special incantations. The user has asked for combinations; that does not yet select either implementation.

Recommended proposal: establish natural interactions, then add a small set of visible, optional authored combinations. Players should be able to discover the requirements in the game rather than needing an external recipe guide. A normal coherent build should win without finding an evolution.

Still open: does a fusion replace one spell, consume two slots, add a special cast, or create a modifier? What happens to its ingredients and upgrades? These choices affect slot count and progression together.

Internal behavior tags can help select eligible modifiers, but tags do not define outcomes by themselves. Convergence, Detonation, Echo Casting, Overchannel and Momentum remain candidate modifiers. Specify stacking, recursion prevention, damage attribution and timing before adding them. Echoed casts must not create an unintended infinite echo chain; damage-over-time explosions need a clear definition of remaining damage and overkill.

## 10. Characters, rewards and optional content

Apprentice, Ember, Tempest, Warden and Wanderer are proposed character concepts. Characters may influence a starting build while retaining access to the wider spell library. The names, starting spells and trait percentages are not an approved roster.

Passive damage, timing, movement, area, pickup and health upgrades remain useful. Use additive stacking within a category where appropriate, then clearly defined category multipliers. The source DPS targets are experimental because input speed, targeting, enemy density and uptime are not yet specified.

Rarities, relics, rune circles, shrines, spellbook events and secret evolutions belong in an expansion backlog. Typing-based events are especially relevant, but they need the same fair-input and readability rules as combat. Avoid requiring hidden content to compensate for a weak ordinary progression system.

Difficulty modes are a proposal. First tune a forgiving default; additional modes should not delay understanding whether the default is enjoyable.

## 11. Readability, art and audio

Keep enemy silhouettes distinct, the player identifiable, and danger signals visible above player spell effects. Line, circle and cone indicators should communicate shape and direction; color alone must not carry the warning. Filling or pulsing cues can communicate time to impact.

Transparent source assets, consistent pivots and reusable metadata are sound production practices. The proposed 96/128-pixel canvases, 48–72-pixel runtime heights and animation frame counts are placeholders until camera scale and art direction are reviewed. A per-enemy six-animation checklist is not yet a required asset order.

Prioritize audio for player damage, incoming danger, spell success/failure and level-up feedback. Secondary impacts should not mask warnings. Layered music and density-dependent secondary VFX reduction are later options. Never reduce telegraph clarity to make room for decorative effects; more late-game spectacle must still be readable.

## 12. Validation and development sequence

Next playable slice: earn new spells, make meaningful upgrade choices, and experience several useful interactions within the existing timed encounter structure. Select a small representative subset of spells for that slice; the full proposed library remains available for later expansion.

Then evaluate progression across single-target, area, damage-over-time, control and mixed builds. These categories should describe coherent builds, not imply that every arbitrary collection of non-damaging or conflicting choices must be equally powerful. The fairness requirement is multiple viable approaches without mandatory named spells or elemental keys.

Capture level/acquisition times, rank choices, damage and utility by spell, damage sources, boss time-to-kill, enemy counts, typing corrections, pauses and both simulation and wall-clock duration. Use aggregate multi-target damage carefully; it is not interchangeable with boss DPS. Keep initial logging local during development.

Post-run presentation can start with outcome, survival time, levels, kills and casts, then add spell damage and utility contribution as reliable attribution becomes available. “Most effective synergy” requires a defensible measurement and should not be invented from coincidental casts.

Before publication: test normal and narrow layouts, input correction/cancellation, settings and saves, restart/menu transitions, performance under overlapping effects, asset licensing, exported builds and the chosen platform. These are release requirements, not claims that the current prototype already passes.

## 13. Remaining choices to review

| Choice | Recommendation for discussion | Why it matters |
|---|---|---|
| Five or six equipped spells; does the passive count? | Keep six during the next playable iteration, then compare five once acquisition exists. Keep passive coverage separate unless there is a clear reason to spend a slot on it. | Limits build breadth and determines UI and acquisition rules. Current six is a testing baseline, not a commitment. |
| Movement, slowdown and cast-speed meaning while typing | Prevent spelling keys from steering movement; keep slowdown consistent; make speed upgrades clearly beneficial. | Defines the moment-to-moment skill and whether an upgrade can make typing harder. |
| Twenty minutes of game time or wall time? | Preserve simulation time for now and measure actual session length. | Typing slowdown makes the two different. A future promise of a twenty-minute real session needs a deliberate change. |
| Natural interactions versus named combinations | Support both, starting with natural interactions and a few visible optional recipes. | Keeps clever play and the requested discovery/transformation fantasy. Fusion slot and ingredient rules remain undecided. |
| Upgrade depth and loadout flexibility | Aim for one or two signature spells with useful lower-rank support; permit deliberate replacement rather than trapping the player. | Resolves the rank/choice budget and reduces dependence on lucky early offers. Rank refunds or transfers still need a rule. |
| How much of the proposed library belongs in the first milestone? | A small representative set first; keep twenty spells and the extra systems as a candidate release direction. | Proves the complete loop without committing every concept before it is played. |

Already resolved, not questions to reopen: immediate victory at 20:00; no final fight; timer-based progression; easy opening; delayed ranged enemies; no required element or named spell.
