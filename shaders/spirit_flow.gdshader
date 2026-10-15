shader_type canvas_item;
render_mode unshaded;

uniform float phase = 0.0;
uniform float flow_amount = 0.018;

varying vec4 item_color;

void vertex() {
	item_color = COLOR;
}

void fragment() {
	vec2 uv = UV;
	float tail = 1.0 - smoothstep(0.18, 0.68, uv.x);
	uv.y += sin(uv.x * 9.0 - phase * 4.0) * flow_amount * tail;
	uv.y += sin(uv.x * 16.0 + phase * 2.3) * flow_amount * 0.35 * tail;
	vec4 painted = texture(TEXTURE, uv);
	float inside = step(0.0, uv.y) * step(uv.y, 1.0);
	COLOR = item_color * vec4(painted.rgb, painted.a * inside);
}
