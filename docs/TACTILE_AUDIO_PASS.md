# Sample-based gameplay sound pass

## Shipped scope

The actual game uses 23 licensed CC0 samples from rubberduck's **80 CC0 RPG SFX** instead of its former generated keyboard-like SFX. Provenance, source names and conversion settings are in [audio/tactile/CREDITS.md](../audio/tactile/CREDITS.md). This is a first shared sound palette, not bespoke sound design for every spell.

- Bolt and passive Mana Bolt use short blade/air releases; passive fire is quieter.
- Fire spells use fire samples; stone/ice spells use brittle material samples; healing and spirit spells share magic samples. Dedicated ice, lightning and spirit identities remain future polish.
- Enemy health loss, enemy deaths, XP, player damage, typing, menus, level-ups and chests have sample-based cues.
- Successful spell dispatch emits one cast cue for typed, freeform and direct casts. Rejected unlocks and targetless Plague casts remain silent. Existing cast success semantics are preserved.
- Enemy hit sound follows actual health loss. A lethal hit uses its deferred death cue. Zero-damage hits stay silent. Level-up audio comes from the player transition, not a duplicate menu-show event.
- Browser workshop and GIF/video capture remain deliberately silent; this pass changes game audio, not preview controls.

## Mix and safety

Assets are mono 44.1 kHz WAV, normalized with FFmpeg loudnorm I=-20, TP=-3, LRA=7. AudioManager applies conservative per-event gain, 4% pitch variation and wall-clock repetition limits. Repeated hits/deaths allow at most 10 cues per second each, pickups about 11 and passive attacks about 9. Three voices per event and 20 overall bound the mix. Player damage, level-up, chest, button click and typing errors can replace a lower-priority voice at saturation. Pool reuse cannot duplicate a voice in active tracking. Missing files report an error and remain silent instead of making procedural fallback tones.

Placeholder music autoplay is intentionally disabled by `PLACEHOLDER_MUSIC_ENABLED`; its old files/settings remain, pending a proper soundtrack. No replacement music has been composed. Future music playback uses the dedicated music player instead of stranding a looping voice in the SFX pool.

## Verification

Run tests in a copied project whose application name is `SpellCast Survivors Audio Test`; the new scripts refuse the player's normal profile. Godot import/type parsing precedes execution. `tests/tactile_audio_regression.gd` exercises resource loading, real direct/typed/freeform/Seeker/passive casts, rejected casts, actual enemy damage/death, XP, player damage, level-up, horde throttling, priority saturation and repeated pool reuse. Removing the enemy hit hook in the disposable test copy must fail its hit and throttling assertions.

`tests/tactile_audio_demo.gd` records the actual master bus with AudioEffectRecord during Bolt, passive fire, Seeker, enemy impacts/death, XP, damage and chest events. It produces `builds/audio-evidence/gameplay-audio.wav` and a timestamped event log within the isolated project. The recording is for human listening; nonzero PCM and event coverage prove functioning audio, not aesthetic quality. Engine exit resource-cleanup warnings are tracked separately from assertions.

## Follow-up

Listen in a crowded live run and tune volume, repetition, timbre and priority together. Replace shared ice/lightning/spirit placeholders with more distinct samples after that judgment. Add an optional sound toggle to the workshop and sound previews in the gallery later. Choose a soundtrack separately.
