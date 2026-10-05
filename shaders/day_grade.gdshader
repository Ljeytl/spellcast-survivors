shader_type canvas_item;
// Day-cycle colour grade (experiment/day-cycle). A film-style grade instead of a flat tint:
//   gain      — per-channel multiply, like the colour of the light (keeps each colour's
//               relationship to its neighbours, so grass stays greener than dirt at night)
//   shadow / highlight — split toning: dark pixels lean one way, bright pixels another
//               (dusk: purple shadows, orange highlights; night: blue shadows, moonlit tops)
//   saturation, contrast, brightness
//   light_keep — bright, saturated pixels (spells, fire, the wizard) keep most of their
//               own colour, so lights pop against the grade instead of being tinted with it.
// strength 0 = no grade at all.
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float strength = 0.0;
uniform vec3 gain = vec3(1.0);
uniform vec3 shadow = vec3(0.0);
uniform vec3 highlight = vec3(0.0);
uniform float saturation = 1.0;
uniform float contrast = 1.0;
uniform float brightness = 1.0;
uniform float light_keep = 0.0;
// Sky glow: a vertical wash screened over the world (top of screen = sky_top, bottom =
// sky_bottom), like light coming off the evening sky. Black = none.
uniform vec3 sky_top = vec3(0.0);
uniform vec3 sky_bottom = vec3(0.0);
// Hue rotation in degrees (positive = green toward teal/blue, negative = toward yellow).
uniform float hue_shift = 0.0;

vec3 rotate_hue(vec3 col, float degrees) {
	// Rotate in YIQ space: brightness stays, only the hue turns.
	mat3 to_yiq = mat3(vec3(0.299, 0.596, 0.211), vec3(0.587, -0.274, -0.523), vec3(0.114, -0.322, 0.312));
	mat3 to_rgb = mat3(vec3(1.0, 1.0, 1.0), vec3(0.956, -0.272, -1.106), vec3(0.621, -0.647, 1.703));
	vec3 yiq = to_yiq * col;
	float a = radians(-degrees);
	yiq.yz = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * yiq.yz;
	return to_rgb * yiq;
}

void fragment() {
	vec3 c = texture(screen_texture, SCREEN_UV).rgb;
	float luma = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 g = rotate_hue(c, hue_shift) * gain;
	float gl = dot(g, vec3(0.299, 0.587, 0.114));
	g = mix(vec3(gl), g, saturation);
	g += shadow * (1.0 - smoothstep(0.0, 0.55, luma)) + highlight * smoothstep(0.35, 1.0, luma);
	g = (g - 0.5) * contrast + 0.5;
	g *= brightness;
	vec3 wash = mix(sky_top, sky_bottom, smoothstep(0.0, 1.0, SCREEN_UV.y));
	g = vec3(1.0) - (vec3(1.0) - g) * (vec3(1.0) - wash);
	float maxc = max(c.r, max(c.g, c.b));
	float sat = maxc - min(c.r, min(c.g, c.b));
	float glow = smoothstep(0.55, 0.9, maxc) * smoothstep(0.3, 0.6, sat) * light_keep;
	g = mix(g, c, glow);
	COLOR = vec4(clamp(mix(c, g, strength), 0.0, 1.0), 1.0);
}
