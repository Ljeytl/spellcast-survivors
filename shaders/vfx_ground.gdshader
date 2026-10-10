shader_type canvas_item;
// Chunky-magic ground layer. One texel = one VFX cell. Per cell, in order:
//   field floor + rim (sandbox drawAreas, disk), else
//   CPU ground texel (TEXTURE), else
//   warm floor light near flames (sandbox drawFloorLight).
// Coordinates are world cells (texel + origin), so patterns stay world-locked.

uniform ivec2 origin;
uniform float k;                       // cells per sandbox unit
uniform float t;                       // VFX sim time (s)
uniform int tick;                      // sandbox (frame >> 3)
uniform int field_count;
uniform vec4 fields[16];               // center x, y (cells), radius (cells), fade-in/out vis
uniform vec4 floor_cols[3];
uniform vec4 rim_cols[2];
uniform sampler2D light_tex : filter_nearest;
uniform vec2 light_origin;             // light texel (0,0) in light cells
uniform float light_cell;              // cells per light texel
uniform vec4 lit1;
uniform vec4 lit2;

const int BAYER[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);

float bayer(ivec2 p) {
	return float(BAYER[((p.y & 3) << 2) | (p.x & 3)]) / 16.0;
}

// sandbox hs(): integer hash, identical bits to the JS/GDScript version
float hs(int x, int y) {
	uint n = uint(x) * 374761393u + uint(y) * 668265263u;
	n = (n ^ (n >> 13u)) * 1274126177u;
	return float(n ^ (n >> 16u)) / 4294967296.0;
}

float vn(float x, float y) {
	int xi = int(floor(x));
	int yi = int(floor(y));
	float xf = x - float(xi);
	float yf = y - float(yi);
	float u = xf * xf * (3.0 - 2.0 * xf);
	float v = yf * yf * (3.0 - 2.0 * yf);
	float a = hs(xi, yi);
	float b = hs(xi + 1, yi);
	float c = hs(xi, yi + 1);
	float d = hs(xi + 1, yi + 1);
	return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v;
}

void fragment() {
	ivec2 sz = textureSize(TEXTURE, 0);
	ivec2 p = clamp(ivec2(floor(UV * vec2(sz))), ivec2(0), sz - 1);
	ivec2 a = p + origin;
	vec4 col = texelFetch(TEXTURE, p, 0);
	bool covered = false;
	for (int i = 0; i < 16; i++) {
		if (i >= field_count) {
			break;
		}
		vec4 f = fields[i];
		float d = length(vec2(a) - f.xy);
		float r = f.z;
		if (d > r + 0.5 * k || bayer(a) >= f.w) {
			continue;
		}
		if (abs(d - r) < 0.7 * k) {
			col = rim_cols[((a.x + a.y + tick) & 3) == 0 ? 1 : 0];
		} else {
			vec2 s = vec2(a) / k;
			float n = vn(s.x * 0.32, s.y * 0.32 + t * 0.6) * 0.65 + vn(s.x * 0.7 + 9.0, s.y * 0.7 - t * 0.4) * 0.35;
			float ek = d / r;
			col = n > 0.72 - (1.0 - ek) * 0.12 ? floor_cols[2] : (n > 0.5 ? floor_cols[1] : floor_cols[0]);
		}
		covered = true;
		break;
	}
	if (!covered && col.a < 0.01) {
		ivec2 lsz = textureSize(light_tex, 0);
		vec2 q = vec2(a) / light_cell - light_origin - 0.5;
		ivec2 q0 = ivec2(floor(q));
		float raw = 0.0;
		for (int dy = -3; dy <= 3; dy++) {
			for (int dx = -3; dx <= 3; dx++) {
				ivec2 lp = q0 + ivec2(dx, dy);
				if (lp.x < 0 || lp.y < 0 || lp.x >= lsz.x || lp.y >= lsz.y) {
					continue;
				}
				float v = texelFetch(light_tex, lp, 0).r;
				if (v <= 0.0) {
					continue;
				}
				vec2 dd = vec2(lp) - q;
				float dist = length(vec2(dd.x, dd.y * 1.2));
				float w = max(0.0, 1.0 - dist / 2.8);
				raw += v * w * w;
			}
		}
		float L = 1.0 - exp(-raw * 0.3) + (bayer(a) - 0.5) * 0.3;
		if (L > 0.8) {
			col = lit2;
		} else if (L > 0.42) {
			col = lit1;
		}
	}
	COLOR = col;
}
