# Art and feedback specification

Current pass-2 runtime values and complete implemented-spell audit: [SPELL_PASS_2_AUDIT.md](SPELL_PASS_2_AUDIT.md). Earlier proposals below remain historical where superseded.
Status: design proposal, no new art generation or runtime edits. Match the supplied ancient stone/pixel-world art. Read with the [spell catalog](SPELL_AND_UPGRADE_CATALOG.md); visuals must reflect its approved behavior, not invent mechanics.

The [full spell library](SPELL_LIBRARY.md) adds preliminary visual identities for future concepts, including water. The lifecycle tables here cover current content and its proposed migrations; they do not mark future concept art as complete.

## Current art scope — simple placeholders matching supplied art

User direction: match the friend’s supplied artwork as closely as practical while keeping this pass as simple as possible. Existing project assets are the reference for palette, pixel scale, outlines, contrast, silhouettes and stone/forest materials. This is a readable placeholder pass, not final production art or a new art direction.

Reuse existing assets first. For missing effects, prefer small sprite sets, simple frames and clear motion/timing. Shared supporting sparks, fragments and trails are appropriate; each spell still needs a recognisable shape and truthful hit feedback. Do not interpret the lifecycle matrix as a demand for bespoke elaborate animation for every row.

Create only the assets required for the current repaired roster and explicitly selected additions. The full idea library is not an asset-generation queue. Future concepts can keep their written visual descriptions until selected. No shader development, extensive cinematic effects, elaborate new character animation or audio production in this pass.

Acceptance: the wizard, enemies, terrain, keys and new effects look compatible at the actual gameplay scale; player and hostile attacks remain legible; spells communicate their real geometry; effects do not obscure hits or imply nonexistent mechanics. Use restrained motion and brief impact feedback. For Meteor Shower, simple readable falling meteors and impacts come before optional bounded shake.

Before making new art, inspect the actual supplied assets and adjacent in-game visuals. Compare placeholder samples at the same camera scale; do not judge them only as enlarged isolated images. Preserve original art and use it directly wherever it already works.

## Asset audit

Supplied Typecast assets cover the wizard/staff, slimes/kings, wisps, world vegetation/tiles, health UI, keys/branding and mana crystal. They do not constitute complete spell lifecycle sheets.

The frozen combat-effects candidate contains 16 single motifs, four burst strips and six feedback motifs. These are reusable starting assets, not a finished approved effects library. Current gaps include no visible infection transfer, shared wreath presentation for Cinder/Steam, lightning segments standing in for both beams, and a shared spirit silhouette for Orbit/Seeking Spirit. Frame names in spell data are not evidence that artwork exists.

## Base spell art matrix

Every row covers cast → travel/placement → hit → sustained state → ending. Do not invent residual damage to justify an attractive effect. “None” means no persistent effect is needed.

| Identity | Intended visible sequence | Player understanding / feeling |
|---|---|---|
| Mana Bolt | Tiny staff discharge → flat cyan projectile with aligned tail → small spark → none → disappearance. | Dependable automatic support. No tumbling faux-3D rotation. |
| Bolt | Sharp cast snap → compact forward projectile → concentrated contact spark → none → tail collapse. | Immediate, reliable bread-and-butter attack. Distinct from automatic Mana Bolt. |
| Lightning | Charge cue → decisive vertical strike at actual target → branching contact flash → brief residual flicker → dissipation. | Immediate focused force, not a travelling or bouncing bolt. |
| Life, new split | Small restorative pulse on actual immediate healing → quick fade. | Fast modest recovery, about 4 HP; distinct from sustained Regeneration. |
| Regeneration | Restorative bloom → motes drawn inward → pulse on actual healing → restrained repeated restoration → thinning motes. | Recovery that visibly works; distinguish full-health or capped healing. |
| Ice Blast | Ice gathers → forward cone of shards expands → impacts/knockback only inside cone → slow accents on affected survivors → melt/break. | Confirmed directional cone. Clear origin, opening angle and reach; no radial visual suggesting hits behind the wizard. |
| Earth Shield | Proposed earth protection assembles near caster → damage cracks → readable remaining protection/erosion → break or expiry. | Final geometry awaits Shield versus Earth Wall distinction; do not generate a placed-wall asset and assume it defines the shield. |
| Meteor Shower | Strong invocation → separate descending meteors and landing cues → forceful rock/fire impacts → only real lingering effects → settling debris. | Major earned crowd payoff. Optional brief bounded shake on impact. |
| Ember Lance | Narrow ignition → long piercing spear silhouette → sparks at each real hit → none → extinguished tail. | Precise destructive line. Not a recolored small bolt. |
| Plague Seed | Seed forms → visible travel and planting in host → infection onset → persistent plant marker plus travelling host-to-host transfer → withering. | “I am infecting the horde.” Show actual source/destination, never fictional spread. |
| Cinder Field | Ground ignition → irregular low-flame patch → tick embers at actual contacts → burning ground with clear gaps → cooling ash. | Persistent dangerous ground. Not isolated flame icons around a ring. |
| Arcane Orbit | Fragments assemble → satellites circle wizard → flare on actual satellite contact → individually readable orbiting objects → retract/dissolve. | Close protection through motion; distinguish from autonomous creatures. |
| Focus Ray | Focal point gathers → coherent single beam → concentrated target endpoint → stable tracking pulses → contraction/cutoff. | Sustained focused damage. No damaging-looking beam through unaffected targets. |
| Rune Trap | Inscription begins → unmistakable arming progression → armed sustain → trigger burst → removal; cap replacement uses a separate fade. | A prepared tool waiting to work. No ordinary timed expiration under the new design. |
| Seeker, proposed rename | One hunter emerges → readable pursuit → contact strike → retargeting → dissolution. | Short basic summon; count matches mechanics. |
| Seeking Spirit, stronger idea | Several hunters emerge → individually visible pursuit → local contact strikes → retargeting hunters → unravel at end. | Summoned allies doing useful work while the wizard moves. |
| Firewalk, working name for Ember Trail | Trailing origin ignites → tracks follow actual movement → local tick sparks → independently aging patches → cooling. | The player's route becomes a weapon. Distinct from stationary field placement. |
| Cross Blade | Blade assembles → outward flight → cutting contacts → obvious linger → return trail and catch/disappearance. | Deliberate outbound/return opportunity, not a generic spinning crescent. |

## Bonus spell art matrix

| Identity | Intended visible sequence | Distinction / constraint |
|---|---|---|
| Life Bolt | Seed-accented projectile → actual impact plants small healing seed → persistent collectable seed → pickup bloom → brief actual healing pulses. | Physical collection is required. No automatic healing return; distinguish plant seed from XP crystal. |
| Meteor Lance | Dense ignition → molten piercing spear → compact explosion on each qualifying hit → brief debris → cooling. | Composite spear/local explosion, not another full Meteor Shower. |
| Soul Bloom | Seed → planting → flowering infection → visible spread and earned healing motes → wither. | Distinguish infection from its healing reward. |
| Steam Field | Heat/frost meet → low rolling vapor → contact ticks → transparent steam → rapid thinning. | Steam silhouette, not a blue flame field or opaque cloud. |
| Prism Ray | Faceted focus → coherent piercing beam → real contact points → readable aligned targets → facet/beam collapse. | Show the actual affected line, never decorative false branches. |
| Frost Sigil | Frost inscription → slower visible arming → wider trigger shards → slowed-survivor accents → cracked glyph fades. | Persistent until triggered or explicitly replaced under the chosen cap. |
| Reaping Spirit | Reaper hunter emerges → pursuit → contact strike → distinct local burst on qualifying contact kill → normal dissolution. | No burst on ordinary hit or unrelated nearby death; no false chain reaction. |
| Lightning Bolt | Combined cast → travelling bolt → first contact → next visible bounce legs in real hit order → final discharge. | Different from both instant Lightning and simple Bolt. |

## Geometry must read accurately

Use the [geometry contracts](SPELL_AND_UPGRADE_CATALOG.md#spell-geometry-and-targeting-contracts) for silhouettes and motion. Lines, cones, impact circles, moving contact objects and persistent patches must visibly differ. Distinguish projectile travel from impact area, trap trigger from blast radius, and infection spread reach from actual damage locations. Render exact collision/range overlays only in debug; ordinary effects and necessary attack telegraphs convey play-relevant geometry.

## Non-spell event art

| Event | Proposed response | Acceptance boundary |
|---|---|---|
| Enemy hit | Local spark and restrained flash/squash. | No implied knockback or stun unless real. |
| Enemy death | Slime collapse/pop with bounded fragments; wisp dissolution. | Dead silhouette disappears promptly; debris never looks like a surviving threat. |
| Player hurt | Clear local hurt flash and contact/direction cue. | Wizard stays locatable; no opaque full-screen flash. |
| Terrain barrier takes damage | Local segment crack and updated erosion/durability state. | Earth barrier damage is not player HP loss. Preserve separate absorption feedback only for effects that actually absorb hits. |
| XP collection | Crystal disappears into short inward cyan glint. | No unexplained generic explosion; one collection event, no lingering fake pickup. |
| XP crystal | Requested larger crystals; target roughly 1.5× visual size with clear facets/outline. | Size alone does not alter value, magnet or pickup radius. |
| Level-up | Brief readable growth cue followed by choice screen. | Pause transition and choices remain immediate; no extended visual obstruction. |
| Cast accepted | Brief final-word confirmation synchronized with spell release. | Never confirm before ownership/validity acceptance. |
| Backspace | Key removed with short shatter/dissolve. | Fragments cannot obscure the next letter or delay editing. |
| Enemy attacks | Preserve windups, functional shield arcs and hazard telegraphs. | Remove decorative/debug circles, not information needed to dodge. |

## World and typography

Use irregular groves, occasional lone trees, bushes, clearings and traversable corridors. Preserve a clear start. Bushes remain decorative under the current plan; avoid adding surprise collision. Existing map layout must not become a regular obstacle grid.

The frozen forest candidate uses radius 11 instead of 22 and anchors tree variants to visible source-pixel trunk position (39, 120). This corrects a horizontal offset from texture centering and vertical misalignment from differing canvas heights. These are candidate implementation details, not universal dimensions for every future tree. Acceptance is physical contact at the visible narrow trunk from all sides, including the reported left-side sticking case. Canopy coverage must not masquerade as collision.

Keep the floating staff's smooth capped-speed orbit and nearest living visible threat targeting, with visible-boss priority. It indicates intent; it must not snap or spin continuously. Preserve layered wizard assets for future animation.

Increase rendered keycap/glyph readability; do not regenerate higher-resolution assets by default. Verify menu headings, long spell names, typed words, punctuation and wrapping at desktop and narrow geometry. Larger letters need larger layout bounds. Current click/keyboard navigation stays; typed menu selection is deferred.

## Spectacle and accessibility proposal

Long spells earn choreography and meaningful impacts, not screen-filling glare. Meteor impacts may trigger brief bounded shake; simultaneous impacts must not stack without limit. Provide reduced/disabled shake and restrained flash settings. Shape and motion should distinguish important states without relying only on color.

Hostile projectiles, attack warnings and the player stay readable over friendly effects. Reduce decorative debris and secondary sparks first under load; preserve actual hits, infection transfers, expiry states and dangerous areas. Prototype worst-case overlapping spells and late hordes before approving effect density.

Audio production is outside this pass. Moonfall, Yggdrasil and Grasping Hand require approved behavior before final storyboards or asset generation.

## Deferred shader work

Shader development and shader-based polish are later work, not part of the current spell, feedback, art or UX pass. This does not request removing existing rendering behavior. Settle the gameplay/readability baseline first, then scope shader work separately.

### Playtest correction: infection and foliage (2026-09-26)

Tree fading is player-only. Plague Seed uses a 32-pixel plant marker and a brighter four-pixel transfer trail above canopy art. Real host deaths transfer infection once to another living enemy within 130 pixels, including deaths caused by automatic Mana Bolt before the first half-second tick. The existing eight-host cap and five-second effect lifetime remain. Crowded native readability still needs human review; mechanical lifecycle coverage is separate from that judgment.
