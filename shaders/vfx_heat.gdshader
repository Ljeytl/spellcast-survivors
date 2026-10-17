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
uniform sampler2D water_tex : filter_nearest;   // r = water air (sandbox wAir), g = water ground, b = plague air (gooAir), a = plague ground
uniform bool water_on = false;
uniform float t;
// Tsunami wall (one at a time) computed here, not splatted on the CPU.
uniform bool wave_on = false;
uniform vec4 wave_a;    // origin x, y (cells), direction x, y
uniform vec4 wave_b;    // front, half length, half width (cells), fade
uniform float k;        // cells per sandbox unit

float wave_val(ivec2 p) {
	vec2 c = vec2(p + origin) - wave_a.xy;
	vec2 dir = wave_a.zw;
	float across = dot(c, vec2(-dir.y, dir.x));
	if (abs(across) > wave_b.z) {
		return 0.0;
	}
	float wob = sin(across / k * 0.4 + t * 6.0) * 1.2 * k;
	float along = dot(c, dir) - (wave_b.x + wave_b.y * 0.35 + wob);
	return max(0.0, 1.0 - abs(along) / (wave_b.y * 1.25)) * 1.8 * wave_b.w;
}
const vec4 W_HI = vec4(1.0);
const vec4 W_LIGHT = vec4(0.651, 0.902, 1.0, 1.0);    // #a6e6ff
const vec4 W_MID = vec4(0.247, 0.624, 0.894, 1.0);    // #3f9fe4

float water_at(ivec2 p, ivec2 sz) {
	float v = texelFetch(water_tex, clamp(p, ivec2(0), sz - 1), 0).r;
	return wave_on ? v + wave_val(p) : v;
}
float goo_at(ivec2 p, ivec2 sz) {
	return texelFetch(water_tex, clamp(p, ivec2(0), sz - 1), 0).b;
}
// sandbox EL.plague
const vec4 G_HI = vec4(0.894, 0.984, 0.690, 1.0);     // #e4fbb0
const vec4 G_LIGHT = vec4(0.651, 0.894, 0.369, 1.0);  // #a6e45e
const vec4 G_MID = vec4(0.337, 0.698, 0.243, 1.0);    // #56b23e
const vec4 G_DARK = vec4(0.173, 0.431, 0.227, 1.0);   // #2c6e3a
const vec4 G_LINE = vec4(0.106, 0.102, 0.173, 1.0);   // #1b1a2c

// sandbox drawGoo: dark outline, highlight up-left, shade down-right
vec4 goo_color(ivec2 p, ivec2 sz, vec4 fallback) {
	if (goo_at(p, sz) < 0.5) {
		return fallback;
	}
	if (goo_at(p + ivec2(0, -1), sz) < 0.5 || goo_at(p + ivec2(0, 1), sz) < 0.5 || goo_at(p + ivec2(-1, 0), sz) < 0.5 || goo_at(p + ivec2(1, 0), sz) < 0.5) {
		return G_LINE;
	}
	bool tl = goo_at(p + ivec2(0, -2), sz) < 0.5 || goo_at(p + ivec2(-2, 0), sz) < 0.5;
	bool br = goo_at(p + ivec2(0, 2), sz) < 0.5 || goo_at(p + ivec2(2, 0), sz) < 0.5;
	if (tl && goo_at(p + ivec2(-1, -2), sz) < 0.5 && goo_at(p + ivec2(-2, -1), sz) < 0.5) {
		return G_HI;
	}
	return tl ? G_LIGHT : (br ? G_DARK : G_MID);
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
		col = goo_color(p, sz, col);
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
	if (over.a > 0.0) {
		float alpha = over.a + col.a * (1.0 - over.a);
		col = vec4((over.rgb * over.a + col.rgb * col.a * (1.0 - over.a)) / alpha, alpha);
	}
	COLOR = col;
}
