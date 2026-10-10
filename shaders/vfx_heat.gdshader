shader_type canvas_item;
// Chunky-magic air layer. One texel = one VFX cell.
// Composites, per cell: under_tex (smoke) -> emissive heat field (glow halo +
// banded palette, sandbox drawHeat) -> TEXTURE (embers, bodies, flashes).

uniform sampler2D heat_tex : filter_nearest;
uniform sampler2D under_tex : filter_nearest;
uniform float thresholds[5];
uniform vec4 colors[5];
uniform vec4 glow;
uniform ivec2 origin;   // world cell of texel (0,0), keeps dither parity world-locked

float heat_at(ivec2 p, ivec2 sz) {
	return texelFetch(heat_tex, clamp(p, ivec2(0), sz - 1), 0).r;
}

void fragment() {
	ivec2 sz = textureSize(heat_tex, 0);
	ivec2 p = clamp(ivec2(floor(UV * vec2(sz))), ivec2(0), sz - 1);
	float h = heat_at(p, sz);
	float bl = h * 4.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			if (x != 0 || y != 0) {
				bl += heat_at(p + ivec2(x, y), sz);
			}
		}
	}
	bl /= 12.0;
	ivec2 a = p + origin;
	bool odd = ((a.x + a.y) & 1) == 1;
	vec4 col = texelFetch(under_tex, p, 0);
	if (bl > 0.05 && h < 0.12 && (bl > 0.12 || odd)) {
		col = glow;
	}
	if (h > 0.0) {
		float v = h + (odd ? 0.08 : -0.08);
		for (int i = 0; i < 5; i++) {
			if (v >= thresholds[i]) {
				col = colors[i];
				break;
			}
		}
	}
	vec4 over = texelFetch(TEXTURE, p, 0);
	if (over.a > 0.5) {
		col = over;
	}
	COLOR = col;
}
