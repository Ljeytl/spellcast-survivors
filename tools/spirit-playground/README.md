# Spirit playground

Open `index.html` directly in a browser. Keep `study.js` beside it. It works offline, requires WebGL, and has no package dependencies. For a served preview, run `python3 -m http.server 8783 --directory tools/spirit-playground` from the repository root.

Move the pointer over the field. Touch works too; focus the field and use arrow keys to move the target, or Space to pause. Choose Ghost, Wisp or Both. Size changes the whole creature; Tail reach changes the fold length; Follow speed changes pursuit response. Demo path supplies continuous motion. Gentle motion defaults to the browser's reduced-motion preference. Settings are temporary and reset on reload.

## Design target and scope

The original ghost and soul-wisp concept images are the target, not the earlier Godot light-and-wake study. Preserve broad overlapping folds, cream/aqua color depth, an expressive ghost face and a warm light nested inside the wisp. This is an exploratory translation and tuning surface, not an accepted spell replacement.

The ghost is one smoothly joined implicit volume: rounded head, shared shoulder and three curling folds. Fold positions lag movement, and the visible overlap changes with pose. Surface lighting remains in world space; eyes project onto the rounded head, track the target and blink. This is a stylized deformation model, not cloth simulation.

The wisp emits density, warmth and inner material into a 512-square field. Material advects through a curling velocity field, stays behind the moving source and dissipates. Half-float textures avoid visible quantization where supported; an 8-bit fallback has lower material quality. This is an advected field, not a pressure-solved fluid simulation. Tail reach controls dissipation; the ghost uses it for fold length. Press S while the field is focused to inspect silhouettes.

Research informed the separation of emitted material and retained folds: [Flurry](https://github.com/calumr/flurry), [curl noise](https://www.cs.ubc.ca/~rbridson/docs/bridson-siggraph2007-curlnoise.pdf), [GPU fluid techniques](https://developer.nvidia.com/gpugems/gpugems/part-vi-beyond-triangles/chapter-38-fast-fluid-dynamics-simulation-gpu), and [position-based dynamics](https://matthias-research.github.io/pages/publications/posBasedDyn.pdf). No implementation from these projects is bundled.

## Carrying the result into the engine

Preserve the selected form and numeric response. The current candidate is not visually approved. Port pursuit, gaze projection, fold lag and joined volume independently from the wisp's source, field transport and material shading. WebGL shaders require an engine-specific implementation and comparative captures; identical appearance is not automatic.

Before integration, record the same hover, slow drift, fast pursuit, abrupt turn and stop paths in both implementations at the same apparent scale and timestep. Compare reference silhouette/material fidelity separately from motion matching. This playground does not establish game-scale readability, combat behavior, sound, camera or performance grades.

## Verification

Functional checks and visual judgment are separate. Current browser checks exercise initialization, pursuit, pause, mode changes while paused, narrow resize, demo, keyboard target control and finite geometry; runtime errors are collected. Captures include idle, pursuit, reversal and settling. Previous Canvas-specific verification does not validate this renderer.

The latest independent still-image review rated the ghost C+ and wisp C before subsequent material refinements. Neither has an established B grade. Remaining targets: broader painted folds on the ghost and more distinct translucent veils on the wisp. Motion, game-scale readability and engine performance require separate review. Keep this draft unmerged until accepted.
