# Research register and limits

Reviewed 27 September 2026. Primary developer talks/articles inform principles; **all tuning numbers, realm designs and keyword coefficients in this package are our proposals**. No cited source proves this game will be fun, sell well, or suit a particular typing speed. We did not watch unavailable talk videos or treat search snippets as full documents.

## Inspected primary sources

| Source | Inspected evidence | Application / limitation |
|---|---|---|
|[David Pittman — Procedural Level Design in Eldritch, GDC 2015](https://media.gdcvault.com/gdc2015/presentations/Pittman_David_Procedural%20Level%20Design.pdf)|Full 68-page PDF text with notes. Pages 38, 44, 51–54, 57–62 describe prescribed rooms, guaranteed module connections, themed selection and purposeful population sockets.|Reserve objectives before filling connections. Validate routes after decoration. Measure repeated module frequency to prioritize production. Eldritch's desired disorientation is not our desired timed navigation.|
|[Michael Booth — The AI Systems of Left 4 Dead, Valve 2009](https://cdn.fastly.steamstatic.com/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf)|Full 95-page PDF text. Population uses categories and spatial constraints; pacing separates buildup, peak, fade and recovery. Slides distinguish difficulty amplitude from pacing frequency.|Separate rising threat from local cadence; do not dump ambient peaks into an authored ritual. Its cooperative shooter timings and counts are not copied.|
|[Johan Pilestedt — Magicka postmortem](https://www.gamedeveloper.com/business/postmortem-arrowhead-game-studios-i-magicka-i-)|Director's account discusses combinations, elemental meaning and returning to what made the prototype enjoyable.|Preserve the act of composing and performing magic. Test whether increasing system complexity improves actual play. Magicka's friendly fire and immediate element availability are not universal requirements.|
|[Noita official site](https://noitagame.com/)|Developer description of crafted spells interacting with a simulated world.|Inspiration for consistent compositional rules; not documentation of its internal evaluator or proof that a similar complexity level fits typing.|
|[Noita official release notes](https://www.noitagame.com/release_notes/)|December 1, 2020 entries include damage/explosion-radius caps and fixes to modifier interactions.|Bound extreme combinations and test explicit exceptions. Noita's actual values are not transferable.|
|[Riot — Clarity in League](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/)|Article discusses effect/hitbox correspondence, visual hierarchy and readable projectile direction.|Match visible core to gameplay, emphasize consequential actions and suppress decorative noise. This is a clarity reference, not balance research for horde survival.|
|[Riot — VALORANT Shaders and Gameplay Clarity](https://www.riotgames.com/en/news/valorant-shaders-and-gameplay-clarity)|Engineer article describes preserving relevant effect edges across quality settings and testing expensive abilities.|Low-effects mode must keep boundaries and player visibility. No shader implementation is required now.|
|[Squirrel Eiserloh — Juicing Your Cameras with Math, GDC 2016](https://media.gdcvault.com/gdc2016/Presentations/Eiserloh_Squirrel_JuicingYourCameras.pdf)|62-page PDF text; pages 11–19 cover bounded trauma, nonlinear amplitude and smooth noise; later sections address framing. Static PDF does not play its embedded GIFs.|Use a stable camera plus bounded event offsets. Our pixel displacement/decay values are experimental. Rotation recommendations need separate pixel-art judgment.|
|[Mihir Sheth — Evolving Combat in God of War for a New Perspective, GDC 2019](https://media.gdcvault.com/gdc2019/presentations/Sheth_Mihir_EvolvingCombat.pdf)|182-page PDF with notes. Pages 130–147 discuss hit reactions moving enemies out of view and adjusted trajectories; 155–159 discuss interruption of aggression.|Feedback should leave a readable next action. No searchable hit-stop/freeze section was found; this source does not substantiate our millisecond timings.|
|[Game Accessibility Guidelines — Avoid flickering images and repetitive patterns](https://gameaccessibilityguidelines.com/avoid-flickering-images-and-repetitive-patterns/)|Accessible guideline text describes flash/pattern risks and effect-intensity options.|Prefer local restrained accents and adjustable flashes; never market a toggle as a guarantee of safety. An actual release needs review of actual footage/settings, not just numeric limits.|
|[Game Accessibility Guidelines — Full list](https://gameaccessibilityguidelines.com/full-list/)|Guideline collection covering readable text, input, pace and alternatives.|Use self-paced explanations, scalable text, remapping and independent effect settings. Apply relevant items and test them; listing settings is not proof of accessibility.|

## Located but not fully inspected: further viewing only

- [Petri Purho — Exploring the Tech and Design of Noita](https://www.gdcvault.com/play/1025695/Exploring-the-Tech-and-Design): session abstract inspected; video not inspected. Do not attribute compiler details to it.
- [Magicka publisher manual](https://cdn.akamai.steamstatic.com/steam/apps/42910/manuals/Magicka%20manual%20body%20--%20English.pdf): indexed text on elements/casting found; direct PDF retrieval failed. It is not a fully reviewed foundation.
- [Derek Yu — Speaking about Spelunky](https://devmag.org.za/2009/04/02/speaking-about-spelunky/): primary interview located; full-page retrieval failed. Room-generation excerpt is a research lead only.
- [Riot original VFX guide announcement](https://nexus.leagueoflegends.com/en-us/2017/10/dev-leagues-vfx-style-guide/): original linked PDF redirected to homepage. Do not claim its full timing chapter was reviewed.
- [Masahiro Sakurai — Eight Hit Stop Techniques](https://www.youtube.com/watch?v=tycbMSjDDLg) and [Stop for Big Moments!](https://www.youtube.com/watch?v=OdVkEOzdCPw): titles/URLs verified; usable video/transcript unavailable. Timing proposals in this package do not pretend otherwise.

No exact Risk of Rain or Vampire Survivors scaling formula is imported. The new prepared expedition loop changes its economy, agency and threat needs. Historical user references establish inspiration, not an instruction to clone a current commercial game's hidden parameters.

## Research-to-design hypotheses to disprove

| Hypothesis | What would disprove it | Response |
|---|---|---|
|Authored objective graph makes procedural routes understandable|Players repeatedly lose sites or traversal consumes the run|Strengthen landmarks, shorten routes, reduce generator variation|
|Cadence creates opportunities for long incantations|Players only cast during near-total emptiness or never find openings|Adjust control tools, recovery windows and local spawn budgets|
|Shared properties make words predictable|Players cannot transfer Big/Repeat understanding between spells|Reduce exceptions or rename words; do not add more help text first|
|Visible geometry makes damage trustworthy|Recorded contacts disagree with player explanations|Fix timing/bounds before adding cosmetic polish|
|Bounded impact feedback improves major-cast payoff|Players lose caret/threat visibility or find stopping irritating|Reduce/remove global feedback and strengthen local reactions|
|Permanent discovery supports experimentation|Players grind the same easy route and avoid trying new words|Change reward structure/encounters; do not add stat grind automatically|

## Audit provenance

Three read-only agents supplied distinct audits: current spell/runtime inventory, requirements/level research, and composition/visual research. Root integrated the documents. Sources were inspected as described, not all at identical depth. The playable code audit baseline is recorded in README; the task changes only this documentation package, its checks and changelog. Old design documents remain historical context.
