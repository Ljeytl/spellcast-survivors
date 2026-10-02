shader_type canvas_item;
// Day-cycle colour grade (experiment/day-cycle). Tints the world toward `hue` like
// coloured light, then restores each pixel's original brightness, so evening and night
// read through colour, not darkness, and colours keep their saturation.
// hue.a is how strongly the grade applies; brightness dims slightly.
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec4 hue = vec4(1.0, 1.0, 1.0, 0.0);
uniform float brightness = 1.0;

void fragment() {
	vec3 c = texture(screen_texture, SCREEN_UV).rgb;
	vec3 weights = vec3(0.299, 0.587, 0.114);
	vec3 lit = c * hue.rgb;
	lit *= dot(c, weights) / max(dot(lit, weights), 0.001);
	COLOR = vec4(clamp(mix(c, lit, hue.a) * brightness, 0.0, 1.0), 1.0);
}
