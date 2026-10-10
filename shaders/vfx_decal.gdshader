shader_type canvas_item;
// Chunky-magic decal (scorch etc.). Rasterized once on the CPU:
// rgb = colour, a = encoded Bayer threshold ((b + 1) / 17, 0 = empty).
// Dissolve is a single uniform, so a fading decal costs no CPU per frame.
uniform float limit = 1.0;

void fragment() {
	vec4 c = texelFetch(TEXTURE, ivec2(floor(UV * vec2(textureSize(TEXTURE, 0)))), 0);
	float b = floor(c.a * 17.0 + 0.5) - 1.0;
	if (c.a < 0.03 || b / 16.0 >= limit) {
		discard;
	}
	COLOR = vec4(c.rgb, 1.0);
}
