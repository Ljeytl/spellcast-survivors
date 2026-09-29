# Style rune sprites v1

One generated RGBA sheet and 24 named Godot AtlasTexture resources. No gameplay/HUD integration yet.

- Sheet: `style-runes-v1.png`, 1536 × 1024, actual alpha transparency (828,125 fully transparent pixels). The viewer may show dark RGB beneath transparent pixels; this is not an opaque background.
- Rank resources: `rank_f` through `rank_sss`, plus `rank_stone`.
- Meter: `meter_left`, `meter_rail`, `meter_right`, `meter_trough`.
- Fills: `fill_teal`, `fill_cyan`, `fill_blue_violet`, `fill_violet`, `fill_gold`.
- Overlays: `halo_cyan`, `halo_gold`, `rank_spark`, `spell_sealed`, `spell_ready`.
- Exact source rectangles are in `regions.json`. Load named `.tres` files as textures; the original image remains intact. Regions are manually assigned from the generated layout, not a uniform 6×4 grid. Native dimensions differ.

Use nearest-neighbor filtering and normalize display sizes in the eventual HUD. Use container clipping for fill progress, not per-value image assets. Render score digits/multiplier as text. F/E can use a subdued fill modulation; the five colored fill sources cover D upward. The rail's joining edges need an in-game assembly check before assuming seamless tiling. No animation frames are included; animate fill, opacity and overlay accents in code later.

Visual review: D resembles an angular rune/triangle and C a chevron; those follow the chosen sharp direction but need readability review at HUD size. S/SS/SSS are distinct zigzag counts. Some fill strips have dark framing baked in; compare full-width stretch versus repeat before adopting. Soft glow is included in alpha and region clipping may trim faint tails. This is an asset-preparation delivery, not a claim that the final HUD has been playtested.

Generated with the built-in image tool using `docs/style-scoring/art/style-meter-stone-v2.png` as the shape reference. Original grayscale concept retained separately. Runtime scenes are unchanged.

## Generation prompt

Create ONE transparent PNG sprite sheet, landscape 1536x1024 preferred, using attached image ONLY as visual style reference. Not a concept board: isolated game HUD sprites on genuine alpha transparency. NO opaque backdrop, checker pattern baked into pixels, headings, labels, prose, arrows, assembly demos or extra artwork. Sharp scratched stone ritual magic, simple chunky pixel art, limited shades. Dark rough slate with angular carved Latin glyphs and broken incised magical circles, colored light through cuts. NO metal frame, gold metal, keycaps, ornate Viking braids, serif lettering, photoreal shading.
Strict grid: SIX columns and FOUR rows (24 cells), each item centered within its own cell with generous transparent gutters. All cells same size, do not draw cell borders. No glow crosses cell edges. Keep silhouettes simple and clearly separable for cropping.
Row1 six rank badges left to right: F, E, D, C, B, A. Each is same rough round stone size with sharp legible scratched glyph and faint ritual-circle cuts. F dim gray-blue; E muted sage; D colored teal; C cyan; B blue-violet; A bright violet. D C B A MUST HAVE NOTICEABLE COLOR, increasing with rank. Keep C recognizable C with squared angular top/bottom, D angular but readable.
Row2 six sprites: S badge violet/pink; SS badge violet-gold; SSS badge fiery luminous gold; empty stone rank medallion without glyph; separate cyan broken rune-circle halo with transparent interior; separate gold broken rune-circle halo with transparent interior. S letters are angular zigzag cuts but must read as Latin S, multiple S distinct, never dollar or digit. Stone material always remains dark gray.
Row3 six sprites: stone meter left endcap; straight horizontal top-and-bottom center rail segment with empty transparent opening; stone right endcap; dark recessed rectangular trough tile; isolated short glowing teal incised fill strip; isolated short glowing cyan incised fill strip. Rails have plain square flat joining edges, consistent thickness, no curves or taper at joins. Fill strips same width/height, rectangular cores, little glow.
Row4 six sprites: isolated blue-violet fill strip; isolated violet fill strip; isolated hot-gold fill strip; small scratched-white four-point rank-up spark; dim sealed spell circular sigil; same spell circular sigil illuminated violet-gold. All fills share geometry and size. Symbols simple and readable.
24 separate sprites total; exact listed order. No assembled UI examples, no numbers, no words except the nine rank badges. Favor clarity and reusable parts over intricate detail. All sprites complete, uncut, mutually separated by transparent space. This is an asset sheet for later manual slicing; pixel-art look consistent with the reference's rough stone and sharp magic incisions, but with the richer color specified.
