# Preparation, discovery, mana and extraction

**Decision precedence:** [Alignment review and open conflicts](13-review-record.md#alignment-review--28-september-2026) supersedes older conflicting proposals below, especially XP/mana, infection/Big and roster counting.

**Development context (28 September):** use [development order](15-development-order.md) for implementation sequencing. Existing gameplay remains the foundation; these target-design tables do not require rebuilding or withholding existing spells. Numeric defaults and unresolved choices remain proposals. Preparation/XP/mana policy and recent spell-identity notes must be reconciled before dependent changes; the first keyword increment retains existing progression.

**Proposed defaults resolve open decisions D01–D10; see decision register.**

## Permanent library versus expedition state

Permanent profile: completed tutorial steps, known base spell IDs, known keyword IDs, discovered recipe IDs, realm access, ley reward flags, guardian rewards, mastery stamps and settings. Expedition state: ordered prepared pages, cumulative mana, active page index, health, encounter time, seed/generation version, objectives and current effects. Never store temporary damage multipliers as permanent upgrades.

Tutorial grants Bolt, Life, Ice Blast, Lightning and Big. Learning Bolt + Life discovers Life Bolt; learning Bolt + Lightning discovers Lightning Bolt. These bonuses become usable only once both ingredient pages are active in a particular run. Tutorial completion therefore knows four bases, two recipes and one keyword, not six prepared pages.

## Preparation screen contract

- Six slots is the proposed cap. Empty slots are allowed; duplicates are not. First expedition fixes Bolt in slot 1. After one extraction or guardian clear, starter eligibility expands to Bolt, Ice Blast, Lightning, Wave, Water Jet, Seeker and Fire Bolt if known. Slot 1 must be damage-capable because mana activation requires kills; Life and other non-damaging openers are disabled with that explanation. This is a proposed preparation constraint, not a hidden combat penalty.
- Reorder with drag or keyboard move controls. Each slot shows activation mana and a small role glyph. Show the derived bonuses their ingredients will enable, in a separate free-bonus strip.
- All learned keywords are available. A searchable journal previews compatibility for the selected spell; this is not another six-slot passive inventory.
- Starting health 100; movement 180 wu/s; collisionr 12. No persistent stat leveling, equipment rarity or XP purchase system in v0.1.
- Prepared spells activate in order; no random upgrade card interrupts combat. Activation grants a short page-open cue and a one-line name, never forced pause while endangered. The page is immediately usable.

## Mana curve

Mana is collected progression, **never consumed by casting**. Enemy kills emit value-preserving crystals. Thresholds are cumulative, not costs.

| Slot | Cumulative mana | Increment | Intended ordinary-route activation |
|---|---:|---:|---|
|1|0|0|Entry|
|2|40|40|0:45–1:30|
|3|110|70|2:00–3:30|
|4|230|120|4:00–6:00|
|5|420|190|7:00–10:00|
|6|700|280|10:00–14:00|

These time bands are **measurement targets**, not guaranteed timer unlocks. A missed crystal does not disappear. Realm challenges award 30 mana each and guardians 120. Their knowledge rewards are separate. No level-up enemy stat scaling; encounter clock controls baseline threat. Collecting faster creates a real advantage without secretly increasing HP to cancel it.

AoE-enabled or bonus-assisted reference economy target (not a universal Bolt opening): first 2 min about 60 collected mana/min; 2–5 min about 45/min; 5–10 min about 60/min; 10–14 min about 75/min, including challenge rewards when earned. This reaches roughly 855 by 14 min. Different routes may activate all pages earlier or later; tune kill yield, not arbitrary hidden catch-up grants. At full preparation, mana continues score accumulation but grants no passive power.

### Opening economy feasibility gate

The slot-2 timing band is not yet feasible for every order or typing speed. At 40 WPM, an optimistic Bolt-only route can fire 50 shots/minute. With 80% two-hit grunts and 20% one-hit swarmers, that yields at most 27.8 mana/minute before movement, errors and misses: 40 mana takes at least 1:26. At 20 WPM it takes at least 2:53. Bolt → Life does not immediately improve kill rate. The initial 60/min reference therefore requires AoE access or challenge bonuses; it must not be presented as ordinary guaranteed progress.

Before implementing a production curve, simulate Bolt → Life and Bolt → Lightning at 20/40/60 WPM with realistic overhead. Compare lower first thresholds (20 rather than 40) and authored noncombat mana pickups as explicit alternatives. This is an unresolved tuning gate, not permission to secretly grant catch-up mana. Keep the table as the v0.1 experimental input until that comparison chooses a curve.

## Crystal rules

Each drop stores integer `mana_value`. Display tier: blue 1–4, green 5–19, violet 20+. Size grows by tier only:6/8/10 wu reference diameter; no constant throbbing. Shape detail distinguishes tiers if colors are indistinguishable. Pickup radius 32 wu; collect animation attracts only already-in-range crystals, never grants value twice.

When crystals are farther than one viewport diagonal from the player for 3 s, group within 120 wu cells into one crystal at a reachable ground point; sum exact value. Do not pull crystals across impassable walls, merge a chest, despawn value, or relocate it to the player. Store clustered drops in the current expedition snapshot. Returning to that region reveals the consolidated reward. Budget 400 visible/drop records before consolidation; never discard XP to meet a render budget.

## Discovery and combinations

A ley site has an authored reward bundle and challenge. Completing it atomically adds its unknown spells/keyword to the permanent library and updates the site flag. Reward names appear briefly; full explanations wait in the journal. Newly learned keywords are immediately available in that expedition. Newly learned base spells are library discoveries for future preparation; they do not replace or secretly append active pages mid-run. This asymmetry must be explicit in the reward card: “Word ready now” versus “Spell learned for your next preparation.”

Recipe discovery is permanent once both bases are known. In a run it activates when both ingredients activate. No level-up selection, no slot consumption, no removal of ingredients. Base-only loadout eligibility prevents putting a derived combination in slot 1 to bypass its ingredients. This is a proposed adaptation of the old slot-free bonus rule.

| Recipe | Ingredients | Availability |
|---|---|---|
|Life Bolt|Bolt + Life|Both ingredient pages active|
|Lightning Bolt|Bolt + Lightning|Same|
|Steam Field|Cinder Field + Ice Blast|Same|
|Frost Sigil|Rune Trap + Ice Blast|Same|
|Meteor Lance|Ember Lance + Meteor Shower|Same|
|Prism Ray|Focus Ray + Ember Lance|Same|
|Soul Bloom|Plague Seed + Regeneration|Same|

Fire Bolt is currently proposed as a discovered base spell because `Fiery Bolt` already has a clear compositional meaning. If standalone Fire becomes a base later, its relationship to Fire Bolt must be reviewed rather than silently adding another recipe. Reaping Spirit remains deferred.

## Repeat expeditions and realm access

The tutorial unlocks Verdant Ruins. Extracting from a realm at 20:00 **or** defeating its guardian unlocks the next realm. Death keeps discoveries but does not unlock the next realm. A player can unlock all four ley rewards across several attempts, but each new attempt must activate all four sites again to summon that attempt's guardian. Permanent reward completion and per-run objective activation are separate fields.

Repeated sites grant 30 mana and progress the current guardian condition even when their knowledge bundle is already known. They also award a non-power mastery stamp for completing an optional condition; duplicates add score only. No endless currency grind is introduced. Realm selection allows replay at any point. Challenge variants are opt-in after a first extraction: fewer assist seconds, denser patrols or no-heal preparation, each clearly labeled and initially score-only.

## Exit and loss state machine

`running → dead` when health reaches 0 before extraction. `running → extracting` at 20:00, or `guardian_defeated → reward_settlement → extracting`. Only one terminal transition wins. Process simulation events chronologically; if death and timeout share the same authoritative tick, death wins unless guardian defeat was committed on an earlier tick. Document and test this boundary so clients do not invent divergent outcomes.

At 19:00 show “Extraction in 1:00”; at 19:50 use an unobtrusive countdown. No permanent “boss in 5 minutes” HUD. Summoning a guardian after 18:00 warns that extraction remains 20:00. The player may proceed; there is no hidden extra combat time. At timeout, stop damage and input commitment, settle earned rewards, then play a 1.5 s portal/extract animation on presentation time. Effects cannot kill the player during that sequence.

Guardian defeat locks damage immediately and settles its knowledge bundle once. A visible chest/seed of knowledge lands; auto-open after 0.8 s or interact earlier. It is a discovery reward replacing the legacy upgrade chest, not a passive-stat card. Extraction follows reward acknowledgement (self-paced, no timer). Never teleport away before the player can read what they earned.

Death shows discovered knowledge retained, activated pages and a single “Prepare again” action. Do not call death a successful extraction. Quitting to menu suspends one expedition with seed/state if supported by milestone; an earlier slice may explicitly offer “End expedition” with discoveries retained. Force-close recovery must never duplicate a reward.

## Save/retention proposal

Knowledge is written atomically at discovery with a monotonic event ID. A interrupted save uses last valid file plus pending journal event; verify checksum/schema and preserve a backup. Offline single-player does not need an anti-cheat economy. Tests must cover crash after grant-before-summary and reload after boss death. Profile reset is a separate explicit destructive action. Existing legacy progression remains in a separate namespace; migration offers a fresh expedition profile and never overwrites the old run or unlocks.
