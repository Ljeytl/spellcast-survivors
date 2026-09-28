# UI, UX, accessibility and workshop

## Information hierarchy

Combat shows health/shield, a small 20-minute expedition timer, six prepared-page icons with active/inactive state, next activation progress, and temporary relevant objective cues. Derived bonuses live in a compact expandable strip or casting suggestions, not another permanent text wall. No always-on control tutorial, DPS, exact spawn budget, boss countdown or stat essay. Debug overlays remain separate and clearly labeled.

Body text uses a readable font. Readable, angular inscription lettering accents incantations; plain text carries menus and instructions. Retire keycap blocks and keyboard-themed headings. Rune ornament must not become a substitute alphabet or make text hard to read. Spell names fit one line in menus, with sensible font minimum and dedicated width; long typed expressions use a horizontal viewport centered on caret, never wrap unpredictably into combat. A full expression preview remains available on pause/journal. Avoid illegibly shrinking 80 characters to one row.

## Wizard tower: rotary destination chamber

**Recorded 28 September 2026 — user concept, not implemented.** The home between expeditions is a walkable wizard tower. Level selection and spell preparation happen through physical objects in that space.

| Part | Intended experience |
|---|---|
| Circular chamber | A perfectly circular room with roughly twelve stained-glass windows/destination positions around its perimeter. Twelve is a visual concept, not a commitment to twelve playable levels. |
| Central dial | Operate the dais/dial with left or right, like a rotary telephone selector. The whole room rotates to bring the selected destination to the top; this is more than a selection highlight moving between static icons. |
| Departure portal | The selected top position opens or reveals a portal the wizard can walk through to enter that level. Exact opening animation and camera treatment are undecided. |
| Tower exit | One selector position leads back to the rest of the tower. Its relationship to the room's rotating architecture needs a layout experiment. |
| Physical spellbook | A very large book is the preparation interface. Choosing and ordering prepared spells should feel like assembling a deck; page order determines the intended activation order. Four, five or six slots are possibilities, not a settled capacity. |
| Return | At the expedition deadline, the tower automatically summons the player home from wherever they are. No return journey or exit interaction is required at timeout. Twenty minutes remains the current default. |

Book placement is open: outside the chamber, beside a destination doorway, or integrated with/near the central dais. Selection order is also open. A proposed flow is destination → preparation → walk through portal, with free revisiting of destination and book; this recommendation is not a mandatory sequence approved by the user. Click-to-select and drag or explicit controls to reorder are interface experiments, not settled designs.

Different levels may eventually have different durations and difficulty curves. A 25-minute run was discussed but not selected; pacing experiments are deferred. The current default remains 20 minutes. The prior optional guardian route remains a separate part of expedition design; this concept does not resolve death retention or every end-state precedence rule.

**Possible art experiment:** a simple 3D blockout of circular walls, stained-glass recesses, dial, portal and book/lectern. 3D, 2D and mixed presentation remain alternatives; no engine/rendering migration or model production is authorized by recording the idea. Keep the wizard/ancient-inscription direction, not keyboard/keycap theming. Test rotation readability and reduced-motion presentation before polishing.

This is future hub work alongside preparation/connected expeditions. It does not block the next milestone of keyword-modified spells in existing combat.

## Primary surfaces and journeys

| Surface | Main actions | Required states / transitions |
|---|---|---|
|Main menu|Continue expedition, Prepare, Library, Options|No profile, valid profile, suspended run, corrupt-save fallback; keyboard focus stable|
|Preparation|Pick/reorder/remove bases, inspect keywords, choose realm, enter|Empty slots, unknown spells, recipe available, invalid duplicate, warning-only thematic build; summary persists|
|Realm selection|Read terrain/affinity and four discovery silhouettes|Locked, unlocked, partial discovery, completed; next-realm condition truthful|
|Combat HUD|Read health, available pages, next mana|Slot activation without pausing, bonus activation, shield expiry, critical health, deadline warnings|
|Casting editor|Type, edit, commit, cancel|Unknown word, inactive page, incompatible keyword, cooldown, capacity full, valid preview, assist spent, charge cancellation|
|Run Spellbook|Inspect only currently prepared/derived active knowledge|Active, prepared but inactive, recipe waiting; shows ingredients and why unavailable|
|Necronomicon|Search all permanent knowledge and discovered recipes|Known, unseen silhouette, recipe ingredients, modifier compatibility; no spoiler full statistics unless discovery mode|
|Ley preview/reward|Start/decline, read reward, acknowledge|Never started, in progress, waves cleared, ritual failed, completed, repeat mastery; reward grant is idempotent|
|Guardian altar|Summon/leave|Four-ley-line condition, late-timer warning, boss already active, defeated; no second spawn|
|Pause/options|Resume, input/audio/visual/accessibility|Nested menu, restored focus, remapping conflicts, saved settings; no gameplay input leak|
|Death/extraction|Read retained knowledge, prepare again|Distinct win/loss, timeout with unfinished boss, reward settlement, crash recovery|
|Developer workshop|Select spell/enemy, modify geometry, play/export|Running, paused, looping, invalid combination, export pending/success/failure|

## Casting feedback

Before Enter, show canonical spell name and at most one concise message: “Bigger impact area”, “Requires a projectile”, “Spell page not active”, or “Ready in 0.4 s”. Detailed resolved math belongs in expandable preview/debug. Invalid submit keeps text, positions caret usefully, and never produces an effect or consumes mana. Case-insensitive matching should not penalize capitalization. Suggestions do not automatically finish a long spell; that would change the commitment model.

Proposed casting treatment: a letter is inscribed with a brief etched stroke or pulse; backspace fades the last inscription. Successful casting releases the inscription into the effect. No falling keycaps or keyboard-block shatter. The underlying text updates immediately; animation never delays input. Rapid input batches still preserve every character; reduce cosmetic inscription animation under load rather than dropping text. Typing UI ignores camera shake. Input focus and cursor remain visible in high contrast and reduced motion modes.

Charged has a clear rooted progress indicator after submission; it must not resemble continued typing assistance. Delayed shows the pending ground mark/output cue and permits movement. Per-cast assist feedback is a small local ring/underline that ends at 1.25 s; do not show a shared rechargeable tank.

## Accessibility settings and test conditions

- Separate text scale 100/125/150%, inscription animation on/off, reduced motion, shake 0–100%, flash 0–100%, cosmetic density: low/normal, color-assisted shape markers.
- Rebind movement/cast/cancel/menu controls; avoid mandatory simultaneous key chords. Keyboard-only menus, visible focus and predictable Back/Escape behavior.
- Adjustable typing assist duration preset 1.25/2.0/3.0 real seconds and world scale 0.2/0.4/1.0 as accessibility presets, labeled clearly. Leaderboards/challenges, if later added, record assist settings without shaming. Balance tests use specified settings.
- Pause anywhere outside terminal reward transaction; input text can survive pause, but assist does not reset. No time-limited reward reading. Captions/text equivalents for important sound cues.
- No guarantee of photosensitivity safety from settings alone; avoid full-screen flashing and review actual content. Local flashes can be disabled; damage still communicated by health changes and directional cues.
- Test QWERTY/AZERTY input, non-US punctuation, IME composition, paste policy and focus loss. Proposal: paste disabled only in the active combat casting editor, with clear feedback, permitted in journal search; accessibility alternative needs review before release. No anti-cheat justification is assumed.

## Workshop specification

Use the **same effect compiler and runtime effect scenes** as gameplay. Grid includes a wizard reference, enemy shapes, ground palette, damageable targets and collision overlay. Filters: spell family, implemented/proposed only, element, keyword. Only implemented candidates simulate; design-only spells show an honest “Not implemented” card, never a convincing fake preview.

Controls: camera zoom, actor scale, per-spell core scale, area multiplier, cosmetic density, slow motion, loop interval, seed, target count/spacing, moving targets, kill target mid-flight, cast again, player HP. Visual-only scaling is explicitly labeled and cannot be exported as gameplay geometry without the paired collision field. Every imported/exported preset has a schema version, source build SHA and timestamp.

Export GIF/WebM using a deterministic 3–6 second loop with a label and wizard reference. Include anticipation, actual contact, decay and reset. Regeneration shows both damaged and full-health states; a Plague host dies between jumps; Ice Blast shows missed and contacting shards. Exports support art review but do not replace interactive combat tests.

## Copy examples

- Level activation: **“Meteor Shower ready.”**
- Spell row: **“Rain meteors across a marked area.”**
- Discovery: **“Learned Repeating — cast a smaller echo after a short delay.”**
- Incompatibility: **“Seeking needs a travelling spell.”**
- Delayed warning: **“Impact stays at the marked location.”**
- Loss: **“Expedition ended. Your discoveries are kept.”**

Percentages show exact resolved values, not ambiguous ranges. Normal menus hide internal effect IDs, reservation counts and diagnostic state. Debug views expose those fields for investigation.
