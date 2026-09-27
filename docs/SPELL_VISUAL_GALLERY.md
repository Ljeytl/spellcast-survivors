# Spell and particle visual gallery

The local reference page is `builds/current/spell-gallery/index.html`. It contains the 24 currently implemented spells (16 base, seven enabled combinations and Mana Bolt) and one configured example of each of the 28 ParticleManager factories. Legacy disabled spell ideas are excluded.

Every capture uses the real renderer, the same 1280×800 viewport, 1.5× camera, rank-one spells, a wizard and stationary durable targets. Firewalk moves the wizard to lay a trail. Captures include early projectiles, warnings, trap bursts and later persistent effects. Frame times are approximate; playback cycles samples rather than representing a continuous recording.

To regenerate from an isolated task checkout:

1. Add an ignored `override.cfg` setting `[application]` `config/name="SpellCast Survivors Synergy Test"` and `[display]` `window/size/mode=0`. The capture tool refuses the normal user profile.
2. Import with Godot's `--headless --editor --path . --import`.
3. Run Godot with `--fixed-fps 60 --path . --script tools/capture_spell_gallery.gd` using a native renderer.
4. Run `python3 tools/build_spell_gallery.py`.
5. Open `builds/spell-gallery/index.html`, or serve that directory using a loopback HTTP server.

The page supports search, spell/particle filters, sampled playback, and a modal with previous/next buttons and a phase slider. Opening the modal pauses playback. The generated output is local and ignored; the capture and page-building tools are versioned. Gallery-only fixture settings do not change gameplay.
