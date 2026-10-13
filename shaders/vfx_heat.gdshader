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
uniform sampler2D water_tex : filter_nearest;   // r = air goo (sandbox wAir), g = ground goo
uniform bool water_on = false;
const vec4 W_HI = vec4(1.0);
const vec4 W_LIGHT = vec4(0.651, 0.902, 1.0, 1.0);    // #a6e6ff
const vec4 W_MID = vec4(0.247, 0.624, 0.894, 1.0);    // #3f9fe4

float water_at(ivec2 p, ivec2 sz) {
	return texelFetch(water_tex, clamp(p, ivec2(0), sz - 1), 0).r;
}

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
	// Water in the air (sandbox drawWater, air): no dark outline, water is mostly
	// light; the top edge and the band just under it catch white.
	if (water_on) {
		float wv = water_at(p, sz);
		if (wv >= 0.5) {
			bool up = water_at(p + ivec2(0, -1), sz) < 0.5;
			bool edge = up || water_at(p + ivec2(0, 1), sz) < 0.5 || water_at(p + ivec2(-1, 0), sz) < 0.5 || water_at(p + ivec2(1, 0), sz) < 0.5;
			if (edge) {
				col = up ? W_HI : W_LIGHT;
			} else if (water_at(p + ivec2(0, -3), sz) < 0.5) {
				col = W_HI;
			} else {
				col = wv > 1.3 ? W_LIGHT : (odd ? W_LIGHT : W_MID);
			}
		}
	}
	// Halo: checkerboard only. A solid fringe outlined every flame blob on grass,
	// turning trail ends into dark-rimmed balls.
	if (bl > 0.05 && h < 0.12 && odd) {
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
