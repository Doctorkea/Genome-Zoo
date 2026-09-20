// Coat wash + ink lines.
//
// The drawing stays in charge: original luminance is the form, coat color
// is a light wash, and pattern is a ghost overlay. Only the sprite's own
// dark strokes become ink — no offset copies or outline bags.

shader_type canvas_item;

uniform sampler2D palette : filter_nearest;
uniform sampler2D pattern_map : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 mark_color : source_color = vec4(0.18, 0.10, 0.06, 1.0);
uniform int pattern : hint_range(0, 10) = 0;
uniform float pattern_amount : hint_range(0.0, 1.0) = 0.35;
uniform float pattern_scale : hint_range(0.5, 24.0) = 4.0;
uniform float coat_opacity : hint_range(0.0, 1.0) = 0.52;

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

float texture_mark(vec2 uv, bool bright) {
	vec3 rgb = texture(pattern_map, uv * pattern_scale).rgb;
	float lum = dot(rgb, vec3(0.299, 0.587, 0.114));
	if (bright) {
		return smoothstep(0.16, 0.78, lum);
	}
	return smoothstep(0.22, 0.58, 1.0 - lum);
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
	if (pattern == 9) {
		return texture_mark(uv, false);
	}
	if (pattern == 10) {
		return texture_mark(uv, true);
	}
	return fbm(uv * pattern_scale * 5.0) * 0.22;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float lum = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	float ink = (1.0 - smoothstep(0.05, 0.2, lum)) * source.a;
	float mark = coat_mark(UV) * (1.0 - ink);
	float pattern_vis = mark * pattern_amount * 0.4;
	float look = clamp(mix(lum, pattern == 10 ? 0.94 : 0.18, pattern_vis), 0.08, 0.92);
	vec3 mapped = texture(palette, vec2(look, 0.5)).rgb;
	vec3 drawing = vec3(lum);
	vec3 coat = mix(drawing, mapped, coat_opacity);
	coat = mix(coat, mark_color.rgb, pattern_vis * (pattern == 10 ? 0.7 : 0.45));
	if (pattern == 10) {
		vec3 spark = texture(pattern_map, UV * pattern_scale).rgb;
		coat = mix(coat, max(coat, spark), pattern_amount * 0.45);
	}
	coat *= mix(0.88, 1.06, lum);
	vec3 line_col = vec3(0.05, 0.04, 0.03);
	vec3 rgb = mix(coat, line_col, ink);
	COLOR = vec4(rgb, source.a);
}
