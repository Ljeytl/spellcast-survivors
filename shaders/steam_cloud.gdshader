shader_type canvas_item;
render_mode unshaded;
uniform float age = 0.0;
uniform float dispersal = 0.0;
uniform bool reduced = false;

uniform int particle_count = 0;
uniform vec4 particles[48];

void fragment() {
	vec2 uv = UV;
	float flow = age * (reduced ? 0.35 : 0.7);
	uv.x += sin(uv.y * 19.0 + flow * 2.0) * sin(uv.y * 9.0 - flow) * 0.012;
	uv.y += sin(uv.x * 23.0 - flow) * 0.008;
	vec2 p = (uv - 0.5) * vec2(2.7, 3.0);
	float density = 0.0;
	float raised = 0.0;
	for (int i = 0; i < 48; i++) {
		if (i >= particle_count) { break; }
		vec4 puff = particles[i];
		float w = max(0.0, 1.0 - length(p - puff.xy) / puff.z);
		float top = max(0.0, 1.0 - length(p + vec2(0.0, 0.08) - puff.xy) / puff.z);
		density += puff.w * w * w;
		raised += puff.w * top * top;
	}
	float rise = smoothstep(0.0, 0.24, age);
	float fade = 1.0 - smoothstep(0.0, 1.4, dispersal);
	float grain = sin(uv.x * 85.0 + sin(uv.y * 32.0 + flow) * 2.0) * sin(uv.y * 97.0 - flow * 2.0);
	float tone = min(density, 2.8) + grain * 0.045;
	float rim = clamp((density - raised) * 2.0, -0.22, 0.22);
	vec3 shade = mix(vec3(0.34, 0.46, 0.61), vec3(0.69, 0.81, 0.89), smoothstep(0.18, 0.80, tone));
	shade = mix(shade, vec3(0.98, 0.98, 0.94), smoothstep(1.1, 2.6, tone + rim));
	float alpha = smoothstep(0.07, 0.34, density + grain * 0.026) * mix(0.58, 0.90, smoothstep(0.35, 1.1, density));
	COLOR = vec4(shade, alpha * rise * fade);
}
