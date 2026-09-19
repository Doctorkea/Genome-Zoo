// Coat fill + ink lines.
//
// Midtones get a realistic animal pattern as darker pigment in the same
// palette. Markings use the part texture UVs so hop, squash, and facing
// keep the coat planted on the drawing. The darkest texels (outlines)
// are composited on top so the linework stays readable.

shader_type canvas_item;

uniform sampler2D palette : filter_nearest;
uniform vec4 mark_color : source_color = vec4(0.18, 0.10, 0.06, 1.0);
uniform int pattern : hint_range(0, 8) = 0;
uniform float pattern_amount : hint_range(0.0, 1.0) = 0.35;
uniform float pattern_scale : hint_range(0.5, 24.0) = 4.0;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	return vnoise(p) * 0.55 + vnoise(p * 2.13 + 1.7) * 0.3 + vnoise(p * 4.27 + 5.2) * 0.15;
}

// Leopard: mix of solid spots and open rosettes.
float leopard(vec2 uv) {
	float mark = 0.0;
	for (int layer = 0; layer < 2; layer++) {
		float sc = pattern_scale * mix(1.0, 1.85, float(layer));
		vec2 p = uv * sc + vec2(float(layer) * 3.1, float(layer) * 1.7);
		vec2 g = floor(p);
		float n = hash21(g);
		vec2 f = fract(p) - 0.5;
		f -= (vec2(n, fract(n * 13.7)) - 0.5) * 0.22;
		float d = length(f * vec2(1.0, 0.82));
		float ring = smoothstep(0.12, 0.18, d) * (1.0 - smoothstep(0.26, 0.38, d));
		float solid = 1.0 - smoothstep(0.10, 0.22, d);
		float cell = mix(solid, ring, step(0.68, n));
		mark = max(mark, cell * step(0.38, n));
	}
	return mark;
}

// Tiger: warped, broken bands that run down the body.
float tiger(vec2 uv) {
	vec2 w = uv;
	w.x += (fbm(uv * 2.4) - 0.5) * 0.2;
	w.y += (fbm(uv * 1.6 + 4.0) - 0.5) * 0.08;
	float phase = w.x * pattern_scale * 6.28318 + fbm(w * 2.6) * 1.6;
	float band = sin(phase);
	float stripe = smoothstep(0.08, 0.62, band);
	float broken = smoothstep(0.18, 0.5, fbm(w * vec2(1.1, 4.2)));
	float taper = 0.65 + vnoise(w * 2.2) * 0.35;
	return stripe * broken * taper;
}

// Zebra: tighter, higher-contrast wavy stripes.
float zebra(vec2 uv) {
	vec2 w = uv;
	w.x += (fbm(uv * 3.0) - 0.5) * 0.12;
	float band = sin(w.x * pattern_scale * 8.0 + fbm(w * 2.0) * 0.9);
	return smoothstep(0.0, 0.55, band);
}

// Piebald / cow: big smooth continents of pigment.
float piebald(vec2 uv) {
	float n = fbm(uv * pattern_scale * 0.85 + 2.2);
	return smoothstep(0.46, 0.6, n);
}

// Fish/reptile scales: overlapping ovals, darker at the rim.
float scales(vec2 uv) {
	vec2 p = uv * pattern_scale;
	p.x += 0.5 * mod(floor(p.y), 2.0);
	vec2 f = fract(p) - 0.5;
	float d = length(f * vec2(1.0, 1.15));
	return smoothstep(0.16, 0.42, d);
}

float toad(vec2 uv) {
	return smoothstep(0.4, 0.72, fbm(uv * pattern_scale));
}

float hide(vec2 uv) {
	return fbm(uv * pattern_scale * vec2(2.8, 5.5)) * 0.85;
}

float tabby(vec2 uv) {
	vec2 w = uv;
	w.x += (fbm(uv * 2.0) - 0.5) * 0.12;
	float streak = sin(w.x * pattern_scale * 5.2 + uv.y * 1.4);
	return smoothstep(0.15, 0.7, streak) * (0.45 + fbm(w * 3.0) * 0.55);
}

float coat_mark(vec2 uv) {
	if (pattern == 1) {
		return leopard(uv);
	}
	if (pattern == 2) {
		return tiger(uv);
	}
	if (pattern == 3) {
		return scales(uv);
	}
	if (pattern == 4) {
		return toad(uv);
	}
	if (pattern == 5) {
		return hide(uv);
	}
	if (pattern == 6) {
		return piebald(uv);
	}
	if (pattern == 7) {
		return zebra(uv);
	}
	if (pattern == 8) {
		return tabby(uv);
	}
	return fbm(uv * pattern_scale * 5.0) * 0.22;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float lum = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	float ink = (1.0 - smoothstep(0.06, 0.28, lum)) * source.a;
	float mark = coat_mark(UV) * (1.0 - ink);
	float fill_base = clamp(mix(lum, 0.72, 0.2), 0.16, 0.94);
	float look = mix(fill_base, 0.08, mark * pattern_amount);
	vec4 mapped = texture(palette, vec2(look, 0.5));
	vec3 coat = mix(mapped.rgb, mark_color.rgb, mark * pattern_amount * 0.4);
	vec3 line_col = vec3(0.07, 0.05, 0.04);
	vec3 rgb = mix(coat, line_col, ink);
	COLOR = vec4(rgb, source.a);
}
