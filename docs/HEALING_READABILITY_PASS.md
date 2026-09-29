# Healing and workshop readability

Approved scope: separate ongoing Regeneration from actual healing, preserve the existing pixel-art direction, and remember sizes per selected spell. No shaders, new enemies, damage changes, or broad art redesign.

Reuse the workshop's existing typography and left-aligned controls, with the live clearing as the main surface. Palette: forest #4f763d, ink #202334, leaf #a9ca79, healing #86ed8a, highlight #e7ffd0. Keep the current stage/control layout; say “This spell” for local settings and keep export feedback explicit. This is an adjustment tool, so no new decorative panels or visual identity.

Regeneration uses four loose, slowly orbiting leaves for its actual remaining duration, even at full health. Healing uses short rising green pluses only after actual health gain. Recasts extend the single visible regeneration indicator to the latest active expiry without multiplying decoration. Life remains a single healing event.

Workshop schema 2 stores spell size, artwork, and particles under effect_settings keyed by effect ID. Selecting another effect restores its own values. Reset clears all overrides. Export retains global world settings separately; legacy schema 1 exports remain review inputs and must not be applied globally.

Verification: isolated workshop profile; full-health and actual-heal checks; overlapping/expired regeneration; per-effect switch/export/reset; positive and deliberately broken controls; native visual evidence and rebuilt Web candidate before integration.

Implementation baseline: Bolt is 0.75 of its prior body and collision radius; the follow-up section below records subsequent individual projectile adjustments. Camera 1.5 → 1.3875 (7.5% farther out), shared by the game and workshop. Exported earlier world settings are not applied.

Validation: 41 engine assertions cover actual cast paths and all four projectile types, healing at full/injured health, chest feedback, overlapping/expired regeneration, per-effect selection/reset, rapid selection during preparation, and shared camera defaults. 11 transport checks cover pause/step/replay/speed. 10 JavaScript checks exercise the actual workshop script, delayed stale state, schema 2 export, and reset. Deliberately broken full-health feedback, selection memory, and stale-event controls fail. Native captures compare the baseline and candidate at 1280×800 and 800×600. Browser interaction verification remains the integration owner's release gate.

## Follow-up: moving projectile readability

User distinguishes decorative particles (keep) from oversized moving spell bodies. Keep earlier generated motifs, compact each family independently: Bolt .75, Magic Missile .8, Life Bolt .8, Lightning Bolt .75, Ember Lance .7, Meteor Lance .85. Lance rendering preserves the source 285:131 crop ratio with its tip aligned to the damaging body's leading edge. Its explosion area remains independent of body scale. Lightning Bolt keeps the mana motif, colored blue-white, with a narrow electrical tail; bounce behavior remains unchanged. No new image generation or procedural sprite replacement.
