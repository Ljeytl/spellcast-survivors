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
uniform vec4 fields[32];               // center x, y (cells), radius / half-width (cells), fade-in/out vis
uniform vec2 field_goo[32];            // x: 0 none, 1 water pool, 2 plague pockets; y: field age (s)
uniform vec4 field_axis[32];           // line fields: half-length axis x, y (cells), zero for disks; z = look index; w = floor style
uniform vec4 floor_cols[24];           // 3 per look
uniform vec4 rim_cols[16];             // 2 per look
uniform sampler2D light_tex : filter_nearest;
uniform vec2 light_origin;             // light texel (0,0) in light cells
uniform float light_cell;              // cells per light texel
uniform vec4 lit1;
uniform vec4 lit2;
uniform sampler2D water_tex : filter_nearest;   // g = water ground (sandbox wGround), a = plague ground (gooGround)
uniform bool water_on = false;

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

// Pool and plague-pocket goo, computed here instead of on the CPU (sandbox
// FX.water.fieldGoo / FX.plague.fieldGoo): same noise, same thresholds.
bool goo_in(ivec2 c, vec2 ctr, float r, float age, int kind) {
	vec2 s = vec2(c) / k;
	if (kind == 1) {
		if (length(vec2(c) - ctr) > r - 1.5 * k) {
			return false;
		}
		float n = vn(s.x * 0.14 + t * 0.3, s.y * 0.14) * 0.7 + vn(s.x * 0.35, s.y * 0.35 - t * 0.6) * 0.3;
		return n > 0.34 + max(0.0, 1.0 - age * 2.0) * 0.6;
	}
	if (length(vec2(c) - ctr) > r - 2.0 * k) {
		return false;
	}
	float n2 = vn(s.x * 0.16, s.y * 0.16 + t * 0.25) + vn(s.x * 0.4 + 5.0, s.y * 0.4 - t * 0.5) * 0.3;
	return n2 > 0.9 - min(1.0, age * 2.0) * 0.06;
}

void fragment() {
	ivec2 sz = textureSize(TEXTURE, 0);
	ivec2 p = clamp(ivec2(floor(UV * vec2(sz))), ivec2(0), sz - 1);
	ivec2 a = p + origin;
	vec4 col = texelFetch(TEXTURE, p, 0);
	// CPU ground texels (rings, crystals) sit on top of field floors
	bool covered = col.a > 0.01;
	for (int i = 0; i < 32 && !covered; i++) {
		if (i >= field_count) {
			break;
		}
		vec4 f = fields[i];
		vec2 ax = field_axis[i].xy;
		float L = length(ax);
		vec2 off = vec2(a) - f.xy;
		float r = f.z;
		float d;
		if (L > 0.0) {
			// line field (sandbox wall): the hitbox is a rect, so measure to the rect
			vec2 u = ax / L;
			// Chebyshev distance: contour at d = r is the rect |along| <= L + r, |across| <= r
			d = max(abs(dot(off, u)) - L, abs(dot(off, vec2(-u.y, u.x))));
		} else {
			d = length(off);
		}
		if (d > r + 0.5 * k || bayer(a) >= f.w) {
			continue;
		}
		int look = int(field_axis[i].z + 0.5);
		if (L > 0.0 && field_axis[i].w > 1.5 && abs(d - r) < 0.7 * k) {
			vec2 s = vec2(a) / k;
			float edge_noise = vn(s.x * 0.35, s.y * 0.35 + t * 0.5);
			if (edge_noise < 0.6) {
				continue;
			}
			col = edge_noise > 0.72 ? rim_cols[look * 2] : floor_cols[1];
		} else if (abs(d - r) < 0.7 * k) {
			bool flick = look == 2 ? hs(a.x + tick * 8, a.y) > 0.6 : ((a.x + a.y + tick) & 3) == 0;
			col = rim_cols[look * 2 + (flick ? 1 : 0)];
		} else if (field_axis[i].w > 0.5 && field_axis[i].w < 1.5) {
			// sandbox drawEFields: element floor; ice barely drifts and glints
			vec2 s = vec2(a) / k;
			float drift = look == 1 ? 0.05 : 0.4;
			float n = vn(s.x * 0.3, s.y * 0.3 + t * drift) * 0.7 + vn(s.x * 0.8 + 3.0, s.y * 0.8) * 0.3;
			col = n > 0.68 ? floor_cols[look * 3 + 2] : (n > 0.48 ? floor_cols[look * 3 + 1] : floor_cols[look * 3]);
			if (look == 1 && hs(a.x, a.y) > 0.985 && ((tick + a.x) % 7) == 0) {
				col = vec4(1.0);
			}
			int gk = int(field_goo[i].x + 0.5);
			if (gk > 0 && goo_in(a, f.xy, r, field_goo[i].y, gk)) {
				float age = field_goo[i].y;
				bool up = !goo_in(a + ivec2(0, -1), f.xy, r, age, gk);
				bool edge = up || !goo_in(a + ivec2(0, 1), f.xy, r, age, gk) || !goo_in(a + ivec2(-1, 0), f.xy, r, age, gk) || !goo_in(a + ivec2(1, 0), f.xy, r, age, gk);
				if (gk == 1) {
					vec4 foam = vec4(0.804, 0.937, 0.992, 1.0);
					vec4 mid = vec4(0.247, 0.624, 0.894, 1.0);
					if (edge) {
						col = (up || ((a.x + a.y + tick) & 3) == 0) ? foam : mid;
					} else if (((a.x + a.y) & 1) == 0) {
						col = hs(a.x, a.y + (tick >> 1)) > 0.96 ? vec4(1.0) : mid;
					}
				} else {
					if (edge) {
						col = vec4(0.106, 0.102, 0.173, 1.0);
					} else {
						col = !goo_in(a + ivec2(0, -2), f.xy, r, age, gk) ? vec4(0.651, 0.894, 0.369, 1.0) : vec4(0.337, 0.698, 0.243, 1.0);
					}
				}
			}
		} else if (L > 0.0 && field_axis[i].w > 1.5) {
			// smoulder (a burning trail): only patches of char glow; the grass shows between them
			vec2 s = vec2(a) / k;
			float n = vn(s.x * 0.35, s.y * 0.35 + t * 0.5);
			if (n < 0.56) {
				continue;
			}
			col = n > 0.66 ? floor_cols[1] : floor_cols[0];
		} else if (L > 0.0) {
			vec2 s = vec2(a) / k;
			col = vn(s.x * 0.25, s.y * 0.25 + t * 0.8) > 0.6 ? floor_cols[1] : floor_cols[0];
		} else {
			vec2 s = vec2(a) / k;
			float n = vn(s.x * 0.32, s.y * 0.32 + t * 0.6) * 0.65 + vn(s.x * 0.7 + 9.0, s.y * 0.7 - t * 0.4) * 0.35;
			float ek = d / r;
			col = n > 0.72 - (1.0 - ek) * 0.12 ? floor_cols[2] : (n > 0.5 ? floor_cols[1] : floor_cols[0]);
		}
		covered = true;
		break;
	}
	// Plague goo on the ground (sandbox drawGoo(gooGround)): outlined pockets.
	if (water_on && texelFetch(TEXTURE, p, 0).a < 0.01) {
		ivec2 gsz = textureSize(water_tex, 0);
		float gv = texelFetch(water_tex, p, 0).a;
		if (gv >= 0.5) {
			float u = texelFetch(water_tex, clamp(p + ivec2(0, -1), ivec2(0), gsz - 1), 0).a;
			float d2 = texelFetch(water_tex, clamp(p + ivec2(0, 1), ivec2(0), gsz - 1), 0).a;
			float l = texelFetch(water_tex, clamp(p + ivec2(-1, 0), ivec2(0), gsz - 1), 0).a;
			float r2 = texelFetch(water_tex, clamp(p + ivec2(1, 0), ivec2(0), gsz - 1), 0).a;
			float u2 = texelFetch(water_tex, clamp(p + ivec2(0, -2), ivec2(0), gsz - 1), 0).a;
			if (u < 0.5 || d2 < 0.5 || l < 0.5 || r2 < 0.5) {
				col = vec4(0.106, 0.102, 0.173, 1.0);
			} else {
				col = u2 < 0.5 ? vec4(0.651, 0.894, 0.369, 1.0) : vec4(0.337, 0.698, 0.243, 1.0);
			}
			covered = true;
		}
	}
	// Ground water (sandbox drawWater, ground): see-through checker surface with
	// glints, foam edge. Under rings and crystals (CPU texels), over floors.
	if (water_on && texelFetch(TEXTURE, p, 0).a < 0.01) {
		ivec2 wsz = textureSize(water_tex, 0);
		float g = texelFetch(water_tex, p, 0).g;
		if (g >= 0.5) {
			bool up = texelFetch(water_tex, clamp(p + ivec2(0, -1), ivec2(0), wsz - 1), 0).g < 0.5;
			bool edge = up || texelFetch(water_tex, clamp(p + ivec2(0, 1), ivec2(0), wsz - 1), 0).g < 0.5
				|| texelFetch(water_tex, clamp(p + ivec2(-1, 0), ivec2(0), wsz - 1), 0).g < 0.5
				|| texelFetch(water_tex, clamp(p + ivec2(1, 0), ivec2(0), wsz - 1), 0).g < 0.5;
			vec4 foam = vec4(0.804, 0.937, 0.992, 1.0);   // #cdeffd
			vec4 mid = vec4(0.247, 0.624, 0.894, 1.0);    // #3f9fe4
			if (edge) {
				col = (up || ((a.x + a.y + tick) & 3) == 0) ? foam : mid;
				covered = true;
			} else if (((a.x + a.y) & 1) == 0) {
				col = hs(a.x, a.y + (tick >> 1)) > 0.96 ? vec4(1.0) : mid;
				covered = true;
			}
		}
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
