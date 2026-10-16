# Spirit playground

Open `index.html` directly in a browser. It is self-contained, works offline, and has no package dependencies. For a served preview, run `python3 -m http.server 8783 --directory tools/spirit-playground` from the repository root.

Move the pointer over the field. Touch works too; focus the field and use arrow keys to move the target, or Space to pause. Choose Ghost, Wisp or Both. Size changes the whole creature; Tail reach changes the fold length; Follow speed changes pursuit response. Demo path supplies continuous motion. Gentle motion defaults to the browser's reduced-motion preference. Settings are temporary and reset on reload.

## Design target and scope

The original ghost and soul-wisp concept images are the target, not the earlier Godot light-and-wake study. Preserve broad overlapping folds, cream/aqua color depth, an expressive ghost face and a warm light nested inside the wisp. This is an exploratory translation and tuning surface, not an accepted spell replacement.

The ghost uses four separate broad folds; the wisp uses three translucent folds and wrapping inner material. The core follows a damped target; smoothed speed controls extension, angular lag bends the folds, and low-speed motion curls their ends. Fold roots attach directly to the core. A segment-length bound limits stretching during abrupt pointer reversals. The renderer draws smooth filled ribbon contours and layered color bands, not sprite images.

## Carrying the result into the engine

Preserve the approved form, numeric response and silhouette rather than replacing the browser result with a vaguely similar particle effect. Port the head's damped response, angle smoothing, normalized fold centerlines, width profiles, lag, length limits and layer order. Canvas gradients will need equivalent material shading; identical appearance is not automatic.

Before integration, record the same hover, slow drift, fast pursuit, abrupt turn and stop paths in both implementations at the same apparent scale and timestep. Compare reference silhouette/material fidelity separately from motion matching. This playground does not establish game-scale readability, combat behavior, sound, camera or performance grades.

## Verification

Browser interaction coverage includes both forms, all selection modes and sliders, pursuit, settling, pointer exit, keyboard control, demo, pause, repeated Space, paused resize and mode changes, gentle motion, and desktop/narrow layouts. The review evidence is tied to the source revision outside the shipped tool. No game scenes or save data are touched.
