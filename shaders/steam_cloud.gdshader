shader_type canvas_item;
render_mode unshaded;
uniform float age = 0.0;
uniform float motion_age = 0.0;
uniform float dispersal = 0.0;
uniform bool reduced = false;
uniform vec2 pixel_grid = vec2(120.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}
float folds(vec2 p) {
	return noise(p) * 0.60 + noise(p * 2.03 + 8.1) * 0.28 + noise(p * 4.1 - 3.7) * 0.12;
}
void fragment() {
	vec2 uv = (floor(UV * pixel_grid) + 0.5) / pixel_grid;
	vec2 p = (uv - 0.5) * vec2(2.7, 3.0);
	float t = motion_age;
	vec2 flow = vec2(sin(p.y * 3.0 + t) * (reduced ? 0.10 : 0.17), t * 0.65);
	float broad = folds(p * 2.8 + flow);
	vec2 warped = p + vec2(broad - 0.5, noise(p * 3.0 + flow) - 0.5) * 0.30;
	warped.y += 0.08 + dispersal * 0.18;
	float shape = 1.0 - length(warped / vec2(1.02 + dispersal * 0.1, 0.74));
	float billow = noise(p * 5.0 + flow * 0.6);
	float mass = smoothstep(-0.10, 0.20, shape + (billow - 0.5) * 0.30);
	float formation = smoothstep(0.12, 0.85, age);
	float jets = 0.0;
	for (int i = 0; i < 3; i++) {
		float x = float(i - 1) * 0.52;
		float bend = sin(p.y * 4.0 + t * 2.2 + float(i)) * 0.07;
		float width = 0.08 + max(0.0, 0.55 - p.y) * 0.15;
		float jet = 1.0 - smoothstep(width * 0.5, width, abs(p.x - x - bend));
		jet *= smoothstep(-1.15, -0.65, p.y) * (1.0 - smoothstep(0.5, 0.75, p.y));
		jets = max(jets, jet);
	}
	float body = max(mass * formation, jets * smoothstep(0.0, 0.12, age) * (1.0 - formation * 0.83));
	float detail = folds(p * 5.0 + flow * 1.5 + vec2(broad));
	float thickness = smoothstep(0.18 + dispersal * 0.3, 0.72, detail);
	float fade = 1.0 - smoothstep(0.0, 1.4, dispersal);
	float alpha = body * mix(0.36, 0.91, thickness) * fade;
	vec3 shade = mix(vec3(0.42, 0.49, 0.52), vec3(0.86, 0.89, 0.88), smoothstep(0.22, 0.78, detail));
	shade += vec3(0.05) * smoothstep(0.25, 0.6, broad) * (1.0 - smoothstep(-0.5, 0.7, p.y));
	COLOR = vec4(shade, alpha);
}
