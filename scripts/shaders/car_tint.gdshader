shader_type canvas_item;

// Recolor the painted body, leave ink, glass, and lamps alone.
uniform vec4 body_color : source_color = vec4(0.78, 0.20, 0.18, 1.0);

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float lum = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	float red_lead = source.r - max(source.g, source.b);
	float body = smoothstep(0.06, 0.16, red_lead) * smoothstep(0.18, 0.34, lum);
	vec3 tinted = body_color.rgb * mix(0.42, 1.12, lum);
	COLOR = vec4(mix(source.rgb, tinted, body), source.a);
}
