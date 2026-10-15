shader_type canvas_item;
render_mode unshaded;

uniform vec4 cells[80];
uniform int cell_count = 0;
uniform float phase = 0.0;
uniform float energy = 1.0;
varying vec2 point;

void vertex() {
	point = VERTEX;
}

void fragment() {
	vec2 p = point;
	vec2 turbulence = vec2(sin(p.y * 0.13 - phase * 3.1) + sin(p.x * 0.09 + phase * 2.2), cos(p.x * 0.12 - phase * 2.5));
	p += turbulence * 1.4;
	float core = 0.0;
	float vapor = 0.0;
	for (int i = 0; i < 80; i++) {
		if (i >= cell_count) { break; }
		vec2 d = (p - cells[i].xy) / max(cells[i].z, 0.1);
		float contribution = exp(-dot(d, d) * 2.6) * cells[i].w;
		if (i < 8) {
			core += contribution;
		} else {
			vec4 next = i + 1 < cell_count ? cells[i + 1] : vec4(0.0, 0.0, 12.0, 0.30);
			vec2 segment = next.xy - cells[i].xy;
			float along = clamp(dot(p - cells[i].xy, segment) / max(dot(segment, segment), 0.01), 0.0, 1.0);
			vec2 center = mix(cells[i].xy, next.xy, along);
			float radius = mix(cells[i].z, next.z, along);
			vec2 strand = (p - center) / max(radius, 0.1);
			float ribbon = exp(-dot(strand, strand) * 2.0) * mix(cells[i].w, next.w, along);
			vapor = max(vapor, ribbon);
		}
	}
	float grain = sin(p.x * 0.48 + p.y * 0.21 - phase * 5.0) * sin(p.y * 0.32 + phase * 2.7);
	core *= 1.0 + grain * 0.16;
	vec3 mist = mix(vec3(0.13, 0.39, 0.55), vec3(0.37, 0.90, 0.81), smoothstep(0.02, 0.28, vapor));
	mist *= 1.0 + grain * 0.12;
	vec3 light = mix(vec3(0.46, 0.93, 0.84), vec3(1.0, 0.97, 0.77), smoothstep(0.35, 1.5, core));
	vec3 color = mix(mist, light, smoothstep(0.10, 0.70, core));
	float alpha = max(smoothstep(0.025, 0.50, core) * 0.97, smoothstep(0.008, 0.28, vapor) * 0.85);
	COLOR = vec4(color, alpha * energy);
}
