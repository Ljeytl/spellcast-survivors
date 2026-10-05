# Spell pixel art pass

The current 24 implemented attacks and heals share a single 4 × 4 transparent motif atlas at `assets/effects/spell-motifs.png`. Each cell is read through the opaque crop recorded in `EffectArt.gd`, so transparent gutters do not enlarge a visible spell body. The atlas is generated placeholder art informed by the supplied Typecast wizard robes, slime, forest spirit, stone and forest assets. It does not replace those original assets.

| Row | Column 1 | Column 2 | Column 3 | Column 4 |
|---|---|---|---|---|
| 1 | Mana projectile | Bolt | Ember Spear | Ice Blast shard |
| 2 | Plague sprout | Seeker ghost | Arcane Orbit crystal | Cross Blade |
| 3 | Flame | Steam | Meteor | Earth Shield stone |
| 4 | Healing leaf | Frost fragment | Ember fleck | Prism crystal |

The image was generated with the built-in image generation tool. Source output: `/Users/ljeytl/.codex/generated_images/01a0da91-2f92-7783-9673-187188f092c1/exec-fe295f56-aec6-4d93-815e-3d1d1f61f668.png`. Prompt specification: one transparent 4 × 4 atlas, 16 centered sprites with generous gutters, no labels, chunky simple pixel art, limited palette, muted outlines, two or three tones plus a highlight, no gradients or 3D rendering. Row-major subjects are those in the table. The art references were the supplied Typecast wizard robes v2, slime boi 1 and forest spirit. The first two source projectiles face left; the renderer flips them to face their direction of travel.

Spell bodies use these motifs; gameplay circles, cones, paths, beams, warnings, armed runes and lightning remain code drawn from the same dimensions and timing used by combat. Magic Missile and Bolt have separate colors and silhouettes; Life Bolt adds a leaf cue and plants its existing collectable seed. Plague transfers and death spores remain visible until their real arrival or expiry. Firewalk and Cinder Field retain continuous damage ground while Steam Field uses a low pale vapor. Meteor descent is visible during its warning and its impact keeps the data radius. Focus Ray has one restrained coherent core; Prism Ray adds aligned crystals to its wider multi-target line. Rune Trap keeps its arming boundary, and Frost Sigil adds an ice fragment. No spell rules, audio, hostile art or new spells changed in this pass.

`tests/spell_motif_contract.gd` checks every opaque atlas region and the link between body dimensions and Spell Size. Gameplay geometry and infection timing remain covered by `tests/spell_geometry_spores_regression.gd`.
