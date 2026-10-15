shader_type canvas_item;
render_mode unshaded;
uniform bool slash = false;
uniform bool reduced = false;
uniform float age = 0.0;
uniform float span = 1.745;
uniform float flip = 1.0;
uniform vec4 core_color : source_color = vec4(1.0, 0.97, 0.72, 1.0);

varying vec4 item_color;

void vertex() {
	item_color = COLOR;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	vec3 color;
	float alpha;
	if (slash) {
		float r = length(p) * 1.04;
		float angle = atan(p.y, p.x) * flip;
		float t = (angle + span * 0.5) / span;
		float pressure = pow(max(0.0, sin(clamp(t, 0.0, 1.0) * 3.141593)), 0.65);
		float width = 0.035 + pressure * 0.37;
		float edge = 0.98 - 0.013 * sin(t * 28.0);
		float band = (edge - r) / width;
		float sweep = clamp(age / 0.13, 0.0, 1.0);
		float elapsed = age - t * 0.13;
		float fade = 1.0 - smoothstep(0.02, 0.14, elapsed);
		float bristle = sin(band * 72.0 + sin(t * 12.0) * 2.0);
		float fibers = mix(reduced ? 0.82 : 0.65, 1.0, smoothstep(-0.65, 0.5, bristle));
		alpha = smoothstep(0.0, 0.07, band) * (1.0 - smoothstep(0.7, 1.0, band));
		alpha *= smoothstep(0.0, 0.035, t) * (1.0 - smoothstep(0.96, 1.0, t));
		alpha *= (1.0 - smoothstep(sweep - 0.025, sweep, t)) * fade * fibers;
		color = mix(vec3(0.43, 0.27, 0.83), vec3(0.63, 0.87, 1.0), (1.0 - smoothstep(0.2, 0.85, band)));
		color = mix(color, vec3(1.0, 0.98, 0.88), (1.0 - smoothstep(0.08, 0.35, band)) * 0.9);
	} else {
		float x = UV.x;
		float flow = age * (reduced ? 5.0 : 9.0);
		float tail = 1.0 - smoothstep(0.1, 0.8, x);
		float curl = sin(x * 12.0 + flow) * tail * 0.11;
		float y = p.y + curl + sin(x * 24.0 - flow * 0.7) * tail * 0.045;
		float width = pow(sin(clamp(x, 0.0, 1.0) * 3.141593), 1.3) * (0.16 + x * 0.48);
		float edge = abs(y) / max(0.001, width);
		float bristle = sin(y * 90.0 + x * 13.0 + flow * 0.3);
		float fibers = mix(0.45, 1.0, smoothstep(-0.7, 0.5, bristle));
		alpha = (1.0 - smoothstep(0.65, 1.1, edge)) * smoothstep(0.02, 0.22, x);
		alpha *= mix(fibers, 1.0, smoothstep(0.45, 0.85, x));
		float heat = (1.0 - clamp(edge, 0.0, 1.0)) * smoothstep(0.12, 0.85, x);
		color = mix(vec3(0.85, 0.13, 0.035), vec3(1.0, 0.58, 0.08), smoothstep(0.0, 0.5, heat));
		color = mix(color, core_color.rgb, smoothstep(0.35, 0.8, heat));
	}
	COLOR = vec4(color, alpha) * item_color;
}
