// Palette-swap shader for creature parts.
//
// Source sprite textures are grayscale (luminance = shading only, no color).
// This shader looks the grayscale value up in a small 1px-tall "palette"
// texture to produce the final color, so a single shape asset can be
// recolored into many skin/coat variants without new art per combination.
//
// See docs/ART_PIPELINE.md for the full rationale and art requirements.

shader_type canvas_item;

uniform sampler2D palette : filter_nearest;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec4 result = texture(palette, vec2(source.r, 0.5));
	result.a = source.a;
	COLOR = result;
}
