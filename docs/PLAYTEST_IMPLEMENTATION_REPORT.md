# September 26 playtest repair — implementation and evidence

This is a playable baseline repair, not production balance certification. The full idea library remains in `SPELL_LIBRARY.md`; recording an idea does not make it an implemented spell.

## Delivered behavior

- Start with Bolt. Lightning is a separate direct strike; Lightning Bolt is an additional bouncing combination.
- Six primary spell slots and six passive-family slots. Bonus spells retain both ingredients and occupy no primary slot; discoveries do not grant ownership in later runs.
- Each cast starts a fresh finite slowdown window at fixed strength. Duration upgrades extend it; pause does not consume it. Exhaustion restores normal speed while typing continues.
- Life is a small immediate heal, Regeneration heals more over time, and Life Bolt plants a physically collected healing seed. Earth Shield is personal stone protection; absorption and health loss have different feedback.
- Ice Blast uses a forward cone. Plague Seed shows actual infection transfers; a missing visible living host produces a retryable failure with no false success or fresh slowdown. Cross Blade travels out, lingers and returns. Rune traps persist until triggered, subject to their active cap. Seeker remains available; Reaping Spirit is deferred.
- Simple outlined pixel effects communicate casts, hits, deaths, infection, healing and XP. Projectile-speed upgrades affect supported moving spells without extending their authored path length. Reduced effects persists across runs and disables shake while reducing cosmetic density.
- Ordinary HUD/cards stay concise. The pause spellbook exposes owned primary/bonus casts, passive ranks and discoveries. Larger keycaps fit short windows; the short-window casting panel temporarily replaces the spell bar and restores it afterward.
- Trees and bushes form irregular groves with routes and a clear start. Tree collision is centered on the trunk with radius 11; XP crystals render at 1.5 times their previous size.
- Opening pressure uses timed surges and recovery. Tiers remain time-driven, ranged enemies stay gated, bosses occur at five-minute milestones before the immediate 20:00 win.

## Scope limits

There are seven working passive families: spell damage, movement speed, maximum health, pickup radius, projectile speed, slowdown duration, and bundled Magic Missile mastery. A build can hold six. Area, Multicast, XP gain, Luck, critical stats and enemy population still require authored contracts and implementation; none is offered as an inert upgrade.

Earth Walls, stronger Seeking Spirit/Reaping Spirit, Frost Nova and the larger water/moon/tree/hand library remain separate selection work. Typed menu navigation, shaders and audio polish remain deferred. Native audio shutdown was repaired as a lifecycle defect, without redesigning sounds.

## Evidence and limits

The consolidated launcher’s `builds/current/manifest.json` records the delivered revision, pack digest and review reference. Supporting logs, candidate-bound bot reports, screenshots and component evidence are retained under `builds/current/evidence/playtest-rework/` after integration.

The integrated sweep covers ownership/acquisition, additive combinations, caps, timing, healing, targeting, spell geometry, effect behavior, text containment, pause/navigation, preferences, encounter milestones, forest collision and endings. Known-bad controls include displaced labels, excessive beam ticks, omitted damage costs and removed timer-boundary updates; these produce the expected failures. Tests use isolated profiles. The real-time 15 FPS timing test must run without `--fixed-fps`, because accelerated fixed-frame execution is not a wall-clock timing test.

Candidate `fd7521f` passed 25 suites with 12,318 assertions and no runtime errors, plus six real-time timing assertions and eight Python report tests. Later audio shutdown changes receive their own menu/window-close smoke and integrated revalidation. The final manifest/results identify the exact tested revisions rather than transferring old evidence silently.

At `fd7521f`, accelerated seeds 11/22/33 died idle at 32.7–35.3 seconds and stationary-casting at 37.1–42.4 seconds; movement-only survived each 60-second limit. Active seed 44 died at 526 seconds, level 16, after 154 casts. Earlier real-time validation on the same pressure model produced idle death at 34 seconds and an active first-minute survival. These are weak-bot samples, not a promised player survival rate or proof of boss balance.

Native operation covered title → play → Bolt input/cast → pause → owned spellbook → back → title. Rendered desktop/short-window captures cover HUD, typing, choices, debug choices, endings, help, discoveries and spellbook. A user run was left undisturbed during final packaging; the exact final reduced-effects menu and crowded-combat feel still need a human visual pass. Mechanical preference persistence/containment and both native quit routes are tested separately. Do not describe this as a complete production UX sign-off.

## Feedback disposition

| Feedback IDs | Disposition |
| --- | --- |
| F01–F04 | Implemented and regression-tested: per-cast slowdown, identities, bonus ownership and slot caps. |
| F05 | Useful long-spell mechanics and trade-offs tested; overall payoff and fun remain human judgments. |
| F06–F09 | Implemented: valid Plague host/failure feedback, blade phases, selected spirit identity and persistent traps. |
| F10–F11 | Implemented with operated and rendered UI evidence; final human visual pass remains explicitly open. |
| F12–F13 | Event effects, shield distinction and projectile/ring cleanup implemented; dense combat readability remains a playtest judgment. |
| F14–F15 | Groves, trunk collision and crystal sizing implemented and tested. |
| F16–F17 | Pressure candidate, behavioral bot controls, timed tiers/bosses and 20-minute ending verified; production balance remains open. |
| F18 | Projectile speed and six-family accounting implemented; remaining seven passive families are explicitly deferred. |
| F19 | Bounded impact effects and persisted reduction implemented; perceived spectacle remains human review. |
| F20–F24 | Library preserved; accepted healing/protection/name decisions applied; unselected expansions deferred. |
| F25–F26 | Normal/debug separation and explicit cone geometry implemented; future area/Multicast obstruction interactions are not claimed. |
