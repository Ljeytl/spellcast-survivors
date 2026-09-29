Art decision: retain the friend’s art for this iteration. Later compare 2D, 3D and hybrid treatments of the same casting/combo sequence; none is selected, and this release commissions or generates no new art.

Current Shield rule: [0.1.36 Earth Shield](../releases/0.1.36-earth-shield.md) supersedes earlier absorption-pool proposals. [Element × family matrix](16-element-family-matrix.md) separates implemented spells, user ideas and unselected examples.

# Art direction, VFX, impact and audio specification

**Confirmed direction:** wizard fantasy and readable ancient inscriptions, replacing keycap/typing-game identity. Norse-inspired angular rune carving is a reference for form, not a requirement to copy a particular game or replace readable letters. Palette, environment treatment and animation timing below remain proposals. Explore a user sketch and a simple flat-color ground before commissioning broad replacement art; shaders remain later.

**Direction options and all timing/size values are proposals. No art is generated or replaced by this package.** Existing friend-made art is reference material, not a requirement to preserve the current look unchanged.

## Direction decision

| Option | Visual promise | Low-cost production approach | Risk |
|---|---|---|---|
|**Lantern and Lichen — recommended**|Travelling wizard, mossy observatories, warm camp lights, luminous inscriptions|Simple silhouettes, small shared palette, modular stone/wood/foliage, brief shape-based magic|Foliage can conceal threats; keep combat floor quiet|
|Ink and Ember|Charcoal world, parchment highlights, woodcut silhouettes, colored spells|Few neutral values, two-frame idles, broken-line impacts, sparse texture|May feel flat or grim; retain warm player/camp accents|
|Wandering Star Atlas|Cobalt ruins, brass rings, constellation landmarks, mineral glow|Geometric architecture, quiet terrain blocks, reusable star/rune motifs|Celestial effects may all look alike; reserve brightest values|

Recommend Lantern and Lichen for the first validation board because it can reuse the friend’s wizard/slime/forest language while shifting from a flat survival field toward magical places. Approval needs an actual side-by-side board at gameplay scale before production. No shader dependency. Do not commission or replace all assets before one representative combat scene reads well.

## Art bible v0.1 proposal

- 640 × 360 logical composition; nearest-neighbor integer scaling where possible, letterbox option. Camera framing evaluated at 1280 × 720 and 1920 × 1080 plus narrow 1280 × 800 window; UI uses readable independent sizing. World units define simulation; set camera mapping explicitly in the first board instead of assuming 1 sprite pixel = 1 wu.
- Reference wizard artwork footprint 24 × 32 asset pixels; enemies silhouette sizes relative to wizard height: Swarmer 0.65, Grunt 0.85, Dart 0.75, Pursuer 1.05, Brute 1.35, Caster 1.0, guardian 2.2–2.8. These are visual ratios, not copied collision sizes. Compare all in one board at real zoom.
- 16 × 16 ground modules, larger assembled landmarks; shared palette target 24–32 colors across a realm, two/three values per material, darkest contour on actors. Warm upper-left light direction; grounded elliptical contact shadow. Avoid mixing painted perspective with flat pixel outlines.
- Floor has 3–5 restrained variants per material, sparse larger motifs and clustered foliage. No high-contrast tile seam grid. Background saturation/value contrast lower than actors and active hazards.
- Wizard hat/cloak/staff remain unmistakable. Use the layered wizard asset for future animation; initial whole-body sprite is acceptable. Staff floats smoothly around nearest threat/boss direction at bounded angular speed 3 rad/s; staff's visual target is not the spell targeting authority.
- Trees: broad canopy, narrow trunk collision. Bushes decorative unless explicitly dense/solid; solid bush silhouette differs. Visual cluster scale 0.88–1.12. Canopy fade around player/hazards, never enemy transparency.
- Enemy roles must survive grayscale/silhouette tests: round grunt, pointed runner, heavy wide brute, elevated caster. Tint is supplemental. Red damage flash only after confirmed damage, 80 ms; no permanent ghostly alpha during ordinary damage.

## Visual language is a gameplay contract

| Information | Visual treatment | Must not imply |
|---|---|---|
|Future area impact|Translucent matching-color fill, bold same-hue brighter outline; progress grows toward actual radius/impact|A harmless disk is already damaging|
|Active damaging ground|Stable boundary and connected animated interior; cadence synchronized with ticks|Individual candle sprites are the whole hitbox|
|Projectile|Solid directional core matching collision, tapering tail, modest glow|Tail/glow damages when it does not|
|Healing|Green plus/leaf rising on actual gain; potential healing zone outlined with leaf markers|Green flashes on enemies are hostile damage|
|Protection|Stone shell/segments and absorption break reaction|Protection is regenerating health|
|Infection|Persistent lesion marker, travelling spore, explicit orphan lifetime fade|Damage spreads instantly without a carrier|
|Hard control|Ice enclosure or grasp outline, timed release cue|Boss is fully frozen when only slowed|
|Ritual objective|Landmark glyph + interaction ring, distinct from damage ring|All circles on screen are interchangeable|
|Enemy warning|Warm danger edge plus directional/pattern shape, independent of player school palette|Blue always means safe|

Geometry is driven by the compiled effect plan. Changing Big changes the solid geometry and damage bounds together. Powerful changes contact emphasis, not apparent coverage. Delayed uses a waiting mark before native anticipation; Charged shows the wizard rooted and accumulating energy. Repeating is a visibly smaller second beat. Element conversion changes material/color but retains native shape/status markers; Icy Cinder Field still needs its field identity, not an invisible frozen projectile.

Color proposal: arcane violet, fire orange-red, lightning blue-white, ice pale cyan, water deep blue, plague yellow-green/purple, life leaf green, earth ochre, spirit mint-white, moon lavender, metal silver. Always pair color with shape and motion. For example, plague motes are irregular and cling; life motes are plus/leaf forms and rise.

## Impact timeline contract

Milliseconds are duration units, not fixed render frames. At 60 Hz, 33 ms ≈ 2 frames. These are **our proposed values**, not numbers validated by the cited talks.

| Event | Contact / reaction / decay | Global interruption |
|---|---|---|
|Ordinary Bolt|Immediate 33 ms local accent; 80 ms target sprite recoil; 120 ms tiny directional fragments|None|
|Heavy lance or blade|33 ms sharp contact; 100 ms recoil; 180 ms thin debris|Optional 25 ms, root's first qualifying hit only|
|Charged major area|50 ms local silhouette/rim; 100 ms expanding impact shape; 250 ms thinning aftermath|50 ms once/root|
|Repeated follow-up|20 ms small accent; 80 ms local reaction; 120 ms decay|None|
|Damage-over-time tick|Brief lesion/fire pulse synchronized with damage; no burst cloud|None|
|Player hit|80 ms local red flash, directional cue, clear hurt-state marker|35 ms; globally rate-limited|
|Guardian defeat|Authoritative death → 80 ms impact pause → 400 ms collapse → knowledge reward|80 ms once|

Global hit-stop: `remaining=max(remaining,request)`; never sum per target. Refractory 250 ms; rolling one-second interruption budget 120 ms. Exceeding requests become local reactions. Freeze combat simulation only; input, UI, assist expiry, extraction deadline and impact animation stay on their defined clocks. One meteor hitting 30 enemies cannot pause 30 times. DoT and repeat children cannot retrigger a full-camera event.

Camera trauma 0–1, quadratic amplitude, linear decay 2.5/s; heavy impact adds 0.2, major 0.45, guardian 0.6. Maximum translation 3 logical pixels; zero rotation initially to avoid pixel shimmer. HUD and typed text never shake. Offset is applied around stable camera base, not integrated as a random walk. No full-screen white/red inversion in v0.1. Options separately control shake and local flash intensity including zero; essential boundaries remain.

## Representative spell timelines

| Effect | Sequence and exact gameplay link |
|---|---|
|Meteor Shower|At commit, select centers. Each warning grows for 0.65 + 0.25i seconds before impact. The red outline reaches final radius at impact; the rock appears during the last 180 ms. Damage occurs once on contact; harmless dust persists for 250 ms.|
|Lightning|250 ms blue warning, then a 200 ms active region. Each enemy is hit once, including enemies entering during that interval. Harmless fade lasts 120 ms.|
|Ice Blast|Optional fan guide for 100 ms at release. Each shard travels and collides; the enemy flashes red only on contact. Ice chips decay over 120 ms; no cone-wide pre-hit flash.|
|Cinder Field/Firewalk|Boundary appears at activation. Ground flames connect; damage and brightness pulses coincide every 500 ms, with partial exposure settled on exit. After expiry, 150 ms of dim ash is harmless.|
|Plague Seed|Seed arrives, lesion appears, periodic damage starts. Spreading spores visibly travel. Host death leaves a 3-second orphan; successful arrival consumes it, expiry dissolves it.|
|Regeneration|Leaves persist for 6 seconds. Emit a small plus only when HP increases. Full health shows quiet leaves without false healing numbers.|
|Earth Shield|Distinct floating stone charges; a blocked hit consumes one and launches a visible attacker-directed earth front. Damage and knockback follow the front; expiration visibly removes a charge. No HP-pool presentation.|
|Rune Trap|800 ms arming fill, then steady glyph. Trigger, bright ring, actual blast, 180 ms decay. Armed trap persists until triggered or replaced.|
|Seeker|120 ms summon. Face/tail orient toward the actual target; contact accent follows damage. Turns remain visible; expired spirit dissolves over 150 ms.|
|Cross Blade|Spinning outbound cross; 900 ms linger with three damaging pulses; distinct return direction; dissolve on catch. No damage after catch.|
|Focus/Prism/Frost Ray|Beam extends to the actual first contact or pierced line. Contact nodes pulse every 250 ms. Solid beam width remains visible; harmless fade lasts 80 ms.|
|Life Bolt|Impact plants a leaf/plus seed. Collecting it activates 2 seconds of healing; full health prevents consumption. Seed expires after 10 seconds, dimming during its last second.|
|Moonfall/Yggdrasil|Marked area becomes moon/tree. Damage and healing use distinct pulses. Tree health is shown only when damaged; no healing outside the boundary.|

Every other spell inherits its geometry-family timeline with its catalog timing values. Exceptions must be explicit in data; no effect artist may invent a damaging phase because it looks good.

## Asset manifest and production budget

This is the art list the spell list depends on. Each campaign spell gets a 36 × 36 journal icon, one 96 × 64 preview composition, and an animated runtime preview generated from actual effect logic. GIF/WebM previews are exports, not hand-maintained alternate gameplay simulations.

| Family | Required source assets | Used by |
|---|---|---|
|Projectile|Arcane core, ember point, ice shard, water head, spore, lightning knot, leaf seed; 4 frames each maximum initially|Bolt, Fire Bolt, Ice Blast, lances, Water Jet, Plague, Lightning Bolt, Life Bolt|
|Ground|Rune ring, irregular flame fill, steam roll, crack mask, ice fracture, moon rune; 4–6 frames or parameterized shapes|All fields, traps, Lightning, Earthquake, Moonfall|
|Large strike|Meteor rock 3 frames + shadow, impact rim 3 frames, arcane lightning star 3 frames|Meteor Shower, Mana Storm, Lightning|
|Persistent body|Spirit face/tail 4 frames, cross blade 4, orbit mote 4, stone piece 3, leaf 4|Seeker, Cross Blade, Arcane Orbit, Earth Shield, Regen|
|Beam|Start cap, repeatable body, contact cap, prism node, ice contact; 2–4 frames|Focus Ray, Prism Ray, Frost Ray|
|Creature/special|Golem idle 2/walk 4/attack 4/hurt 1/death 4; tree growth 4/idle 2/collapse 4; spectral hand 4|Summon Golem, Yggdrasil, Grasping Hand|
|Shared feedback|Damage accent 3, death puff 4, pickup spark 3, knowledge burst 4, plus 3, poison lesion 3|All relevant actors/effects|
|Enemies|12 variant silhouettes; family motion sets; 4 guardian poses/attack sets; elite overlay|Enemy catalog; no 12 bespoke animation systems initially|
|Environment|Per realm 3–5 floor variants, 6 edge pieces, 4 obstacles, 4 landmark kits, ley altar 4 states, entry portal 4 frames|Module layouts; reuse structural assets|
|UI|Plain body font, readable inscription letters and restrained rune ornaments, focus highlight, spell shape icons, page activation|HUD, casting, journals, preparation|

Use particle systems for transient sparks, dust, motes and count scaling; sprite animation for identifiable bodies, contact silhouettes and growth; procedural simple shapes for exact rings and beam geometry. Do not flatten every effect into a generated sheet that cannot scale or match collision. Current generated assets may serve as temporary texture inputs, with provenance recorded.

## Audio direction (later production, specified now)

Avoid a MIDI note for every action. Distinguish material: dry key-stone thud, sharp airy release, wet infection pop, brittle ice contact, low stone impact, soft leaf heal. Base casts have short sounds; major casts add a low body and airy tail without becoming louder by default. Type sounds vary subtly across 3 samples; Backspace has lighter crumble. Avoid one unique loud sample per particle.

Mix limits: at most eight spell voices, four enemy voices and two UI voices. Major impacts duck minor impacts by 3 dB for 150 ms; music ducks by 2 dB during ritual and reward cues. Critical health information never relies solely on audio. All volumes are independently adjustable, with a moderate master default. A source and licensing manifest tracks artist, license, original path, processing and replacement status. Document approval does not authorize new generation or paid commissions.

## Art acceptance

Review one wizard, all 12 enemy variants, one guardian, all 36 spell previews and two encounter densities at actual gameplay zoom. Include dark and bright floors, Big + Repeat variants, red hit flashes, reduced effects, grayscale and a paused geometry overlay. Use drift within 10% of the intended dimension as an initial art-review tolerance; authoritative gameplay bounds remain exact. Reject any area whose active edge disappears under cosmetic load. Do not claim readability until the effects have been operated in motion.
