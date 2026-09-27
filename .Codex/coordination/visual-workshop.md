# Approved visual workshop pass

Baseline: f3374ba. Root owns workshop/capture/page tools in feature/visual-workshop. Separate spellbook and spell-art agents own separate managed worktrees. No shared implementation checkout.

- [x] Smooth native loops and GIF export for all implemented spells and particle factories.
- [x] Live browser renderer with independent sizing, variant comparison, playback, reset and configuration export.
- [x] Run-only Spellbook and full implemented Necronomicon; no unlock side effects.
- [x] Simple friend-style spell art and generated particle stamps; geometric effects remain procedural.
- [ ] Exact-revision visual/functional checks, independent review, sequential merge, current artifact refresh and cleanup.

Contracts: do not change combat balance. Native fixture and browser sandbox use isolated profiles. Browser configuration is preview-only and exported explicitly. Keep the older interactive game checkout alive while its process runs. Slime animation remains future work.

Integration order: review spellbooks; review art; bring both into root workshop; regenerate native loops from that exact candidate; verify browser and capture output; merge workshop. Root maintains Changelog and roadmap.

Reviewed and merged: books PR45 af167e8, art PR46 aa9a321, health hit flash PR47 9ac6ceb. Workshop review fixed paused timer progression, stale Step continuations and filtered export identity. Native sizing and transport negative controls reject the intended defects. Browser and final artifact checks remain in progress.
