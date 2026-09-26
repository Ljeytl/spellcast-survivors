# Stone keycap assets

Runtime assets: `assets/typecast/Keys`, 68 transparent PNGs at 32×32 pixels: A–Z, 0–9, and 32 standard keyboard punctuation glyphs. Space uses the supplied blank key. Alphabet filenames use the uppercase letter; other glyphs use their hexadecimal Unicode value (`u005f.png` is underscore).

The built-in image-generation tool produced these source atlases, using the supplied stone logo keys as style references. This directory is excluded from Godot resource imports; only the small individual keys ship. Regenerate the native exports with:

```
Godot --headless --path . --script tools/export_key_atlas.gd
```

## Alphabet prompt specification

Transparent pixel-art sprite atlas matching the supplied 32×32 chipped ivory stone keys, dark block lettering, beveled edges, and original palette. Eight columns and four rows in a uniform grid. Rows: A–H, I–P, Q–X, Y–Z then six blank keys. No headings, extra text, or perspective distortion. Each cell must remain readable when exported at 32×32.

## Symbol prompt

Create a companion sprite atlas matching the reference ivory chipped stone keyboard keycaps exactly in color, pixel-block glyph style, bevel, straight front view. Transparent background. 8 columns by 6 rows, equally sized square cells in a precise regular grid, each key separated by transparent gutter. Each cell downsampled will be a 32x32 game sprite so keep glyph very clear and pixel-like, no tiny details. ONLY the following glyphs engraved one per key in EXACT row order, no headings or labels. Row 1: 0 1 2 3 4 5 6 7. Row 2: 8 9 - _ / \ + =. Row 3: [ ] { } ' , ? . Row 4: : ; ! ~ ` $ # @. Row 5: % ^ & * ( ) < >. Row 6: | " then six blank keys. All punctuation characters distinct and legible, particularly slash vs backslash, quote vs apostrophe, colon vs semicolon, minus centered vs underscore low. Preserve consistent ivory stone square shape and dark charcoal glyphs. No perspective distortion, no additional text. Reference is style input; create a new companion atlas of symbols and digits.
