# Stone inscription style-meter concept

## Sprite preparation delivered

The [colored transparent sprite sheet](../../../assets/ui/style-runes/style-runes-v1.png) and [24 named Godot atlas resources](../../../assets/ui/style-runes/README.md) now provide separate rank, meter, fill and accent pieces. The v2 sheet below remains the original shape concept. This supersedes the earlier note that no recolored sheet exists. Runtime HUD/scoring is integrated in 0.1.27; the concept notes below preserve the design history. See asset notes for region sizes, transparency, prompt and legibility/assembly review limits.

## Latest review — color on the carved stone

User feedback: the revised scratched-stone shapes and magical circles are much closer to the desired direction; prefer the richer color from the first sheet. **D, C, B and A should already have color**, with less intensity than S/SS/SSS. Preserve rough dark stone and sharp carved marks; color belongs primarily in the inscriptions and circle marks, not metallic framing.

Suggested palette, still a proposal: faint light at F/E, dim teal at D, cyan at C, blue-violet at B, stronger violet at A, then violet-to-gold escalation across S/SS/SSS. Exact hues, glow coverage and brightness remain for visual review. Do not imply this exact palette was independently approved.

The saved v2 image has not been recolored; it is the shape reference. The rejected first image remains a color reference only, not the frame design. No new generation or runtime integration is part of this feedback update. **Continue design review; implement only once the user says ready.**

Generated with the built-in image tool; one revised concept board, not installed game art. The earlier ornate metal-framed image was rejected and is not a production candidate.

File: [style-meter-stone-v2.png](style-meter-stone-v2.png). Opaque background, 1536 × 1024 pixels. One sheet: nine rank badges; separated meter pieces and circle arcs; F/S/SSS assemblies; a rough transition strip.

Review notes: angular C/D and multiple S glyphs need small-scale legibility testing. The bottom strip repeats F instead of changing grade, so it is not an authoritative rank animation. Use the spec for behavior. Rails are not guaranteed seamless or aligned for automatic slicing. No alpha cutouts, sprite coordinates or frame timing are claimed ready. Keep as source reference until approved; manually slice/redraw and render text separately during implementation.

## Final generation prompt

Use case: ui-mockup. ONE landscape sheet with many separated modular UI pieces and assembled examples for a wizard style-score HUD. REPLACE previous generic ornate fantasy aesthetic completely. The precise direction is primitive ritual magic SCRATCHED INTO STONE: really sharp thin angular incised strokes, jagged lightning-like letters, rough broken slate, incomplete concentric magic circles, radial etched sigils. Not polished Norse metal jewelry, not Viking knotwork, no bronze/gold bezels, no shield crests, no serif type rank letters, no thick raised metallic borders, no keyboard keys. Simple intentionally rough pixel art, few shades, large visible pixels, restrained ash gray, bone white, muted cold cyan with brighter icy-white magic at SSS. Shapes feel scraped/chiseled by hand, sharp uneven cuts. Black neutral background with generous separation. Very little text besides exact rank letters.
Layout top: nine isolated rank glyphs F E D C B A S SS SSS in angular scratched lettering; each floats over a faint broken magic-circle engraving on an irregular flat stone shard. Latin ranks remain recognizable. S formed from 3 sharp diagonal/straight cuts, absolutely not curved serif S. Low ranks subdued gray, S and above white-cyan cuts illuminate with sparse spiked rune-circle fragments.
Middle: modular components, individually separated: narrow left broken-stone endcap, short tileable rough-stone horizontal rail, right broken-stone endcap, dark recessed track, three short etched luminous line fill pieces at increasing brightness, 4 broken circle arc pieces, 4 small angular scratched sigils, one sealed ritual-circle special-spell mark. Fill is a bright incision running through stone, NOT a glass tube filled with plasma. Use flat stone faces with carved linework. Keep borders minimal and thin.
Bottom: three assembled HUD examples labeled only F, S, SSS. Each has rune circle rank left, thin cracked stone rail extending right, a partially illuminated incised fill line with short angled tally cuts, and a separate plain RUN SCORE text placeholder below (no numeric values). F is simple and quiet, S gains an illuminated ritual arc, SSS has sharp fragmented halo rays but same core size. Include small 3-frame fill/rank-up/reset sequence in spare lower area. Clean repeated geometry and large gutters permit later manual slicing. No ornamental title banner, no prose or legends, no game background. It should look like a dark magical rite's carved stone inscriptions becoming charged, badass and spare, easy for a novice pixel artist to recreate.
