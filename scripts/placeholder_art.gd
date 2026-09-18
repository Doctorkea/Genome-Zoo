extends Node

## Procedurally generates placeholder pixel-art-style textures at runtime:
## grayscale shape parts (for the trait-swap + palette-swap pipeline) and
## color palettes. Zero binary asset files — replace slot by slot with real
## art later; nothing else about the pipeline needs to change.
##
## See docs/ART_PIPELINE.md for the shape/palette pipeline this feeds into.
## Autoloaded as "PlaceholderArt".

const LIGHT_DIR: Vector2 = Vector2(-0.6, -0.8)

const PALETTE_BASE_COLORS: Array[Color] = [
	Color(0.55, 0.36, 0.20), # warm, fur-ish brown
	Color(0.20, 0.55, 0.50), # cool, scales-ish teal
	Color(0.55, 0.30, 0.55), # slime/weird-ish violet
]

var _shape_cache: Dictionary = {} # slot (String) -> Array[Texture2D]
var _palette_cache: Array[Texture2D] = []


func get_shape_options(slot: String) -> Array[Texture2D]:
	if not _shape_cache.has(slot):
		_shape_cache[slot] = _generate_slot(slot)
	return _shape_cache[slot]


func get_palette_options() -> Array[Texture2D]:
	if _palette_cache.is_empty():
		for base in PALETTE_BASE_COLORS:
			_palette_cache.append(_make_gradient_palette(base))
	return _palette_cache


func _generate_slot(slot: String) -> Array[Texture2D]:
	match slot:
		"body":
			return _make_body_options()
		"head":
			return _make_head_options()
		"eyes":
			return _make_eyes_options()
		"mouth":
			return _make_mouth_options()
		"arms":
			return _make_arms_options()
		"legs":
			return _make_legs_options()
		"tail":
			return _make_tail_options()
		_:
			push_warning("PlaceholderArt: unknown slot '%s'" % slot)
			return []


func _make_body_options() -> Array[Texture2D]:
	var img0 := _new_image(40, 40)
	_fill_circle(img0, 20, 20, 18)

	var img1 := _new_image(44, 32)
	_fill_ellipse(img1, 22, 16, 20, 13)

	var img2 := _new_image(36, 36)
	_fill_rect(img2, 4, 4, 32, 32)

	var options: Array[Texture2D] = [_to_texture(img0), _to_texture(img1), _to_texture(img2)]
	return options


func _make_head_options() -> Array[Texture2D]:
	var img0 := _new_image(26, 26)
	_fill_circle(img0, 13, 13, 11)

	var img1 := _new_image(28, 30)
	_fill_circle(img1, 14, 18, 10)
	_fill_triangle(img1, Vector2(6, 10), Vector2(10, 1), Vector2(13, 9))
	_fill_triangle(img1, Vector2(22, 10), Vector2(18, 1), Vector2(15, 9))

	var img2 := _new_image(32, 22)
	_fill_ellipse(img2, 16, 11, 14, 9)

	var options: Array[Texture2D] = [_to_texture(img0), _to_texture(img1), _to_texture(img2)]
	return options


func _make_eyes_options() -> Array[Texture2D]:
	var img0 := _new_image(28, 14)
	_fill_circle(img0, 8, 7, 5)
	_fill_circle(img0, 20, 7, 5)

	var img1 := _new_image(30, 16)
	_fill_circle(img1, 8, 8, 7)
	_fill_circle(img1, 22, 8, 7)

	var img2 := _new_image(28, 10)
	_fill_ellipse(img2, 8, 5, 6, 2)
	_fill_ellipse(img2, 20, 5, 6, 2)

	var options: Array[Texture2D] = [_to_texture(img0), _to_texture(img1), _to_texture(img2)]
	return options


func _make_mouth_options() -> Array[Texture2D]:
	var img0 := _new_image(18, 10)
	_fill_ellipse(img0, 9, 5, 6, 3)

	var img1 := _new_image(24, 10)
	_fill_ellipse(img1, 12, 5, 11, 4)

	var img2 := _new_image(20, 14)
	_fill_ellipse(img2, 10, 5, 7, 3)
	_fill_triangle(img2, Vector2(5, 7), Vector2(7, 13), Vector2(9, 7))
	_fill_triangle(img2, Vector2(15, 7), Vector2(13, 13), Vector2(11, 7))

	var options: Array[Texture2D] = [_to_texture(img0), _to_texture(img1), _to_texture(img2)]
	return options


func _make_arms_options() -> Array[Texture2D]:
	var img0 := _new_image(44, 18)
	_fill_rect(img0, 0, 4, 10, 14)
	_fill_rect(img0, 34, 4, 44, 14)

	var img1 := _new_image(52, 20)
	_fill_rect(img1, 0, 2, 9, 18)
	_fill_rect(img1, 43, 2, 52, 18)

	var img2 := _new_image(32, 14)
	_fill_rect(img2, 2, 4, 8, 10)
	_fill_rect(img2, 24, 4, 30, 10)

	var options: Array[Texture2D] = [_to_texture(img0), _to_texture(img1), _to_texture(img2)]
	return options


func _make_legs_options() -> Array[Texture2D]:
	var img0 := _new_image(36, 18)
	_fill_rect(img0, 4, 0, 15, 18)
	_fill_rect(img0, 21, 0, 32, 18)

	var img1 := _new_image(32, 28)
	_fill_rect(img1, 5, 0, 13, 28)
	_fill_rect(img1, 19, 0, 27, 28)

	var img2 := _new_image(44, 16)
	_fill_rect(img2, 2, 0, 9, 16)
	_fill_rect(img2, 13, 0, 20, 16)
	_fill_rect(img2, 24, 0, 31, 16)
	_fill_rect(img2, 35, 0, 42, 16)

	var options: Array[Texture2D] = [_to_texture(img0), _to_texture(img1), _to_texture(img2)]
	return options


func _make_tail_options() -> Array[Texture2D]:
	var img0 := _new_image(18, 16)
	_fill_triangle(img0, Vector2(0, 8), Vector2(18, 2), Vector2(18, 14))

	var img1 := _new_image(30, 12)
	_fill_triangle(img1, Vector2(0, 6), Vector2(30, 1), Vector2(30, 11))

	var img2 := _new_image(20, 20)
	_fill_ellipse(img2, 10, 10, 9, 9)

	var options: Array[Texture2D] = [_to_texture(img0), _to_texture(img1), _to_texture(img2)]
	return options


# ---------------------------------------------------------------------------
# Drawing primitives
# ---------------------------------------------------------------------------

func _new_image(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)


func _to_texture(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)


## Fake "light from upper-left" shading. `offset_norm` is roughly in [-1, 1]
## relative to the shape's own extents.
func _luminance(offset_norm: Vector2) -> float:
	var d := offset_norm.dot(LIGHT_DIR.normalized())
	return clampf(0.55 + 0.4 * d, 0.12, 0.95)


func _fill_circle(img: Image, cx: float, cy: float, r: float) -> void:
	var x0 := int(floor(cx - r))
	var x1 := int(ceil(cx + r))
	var y0 := int(floor(cy - r))
	var y1 := int(ceil(cy + r))
	for y in range(maxi(0, y0), mini(img.get_height(), y1 + 1)):
		for x in range(maxi(0, x0), mini(img.get_width(), x1 + 1)):
			var dx: float = (x + 0.5) - cx
			var dy: float = (y + 0.5) - cy
			if dx * dx + dy * dy <= r * r:
				var l := _luminance(Vector2(dx, dy) / r)
				img.set_pixel(x, y, Color(l, l, l, 1.0))


func _fill_ellipse(img: Image, cx: float, cy: float, rx: float, ry: float) -> void:
	var x0 := int(floor(cx - rx))
	var x1 := int(ceil(cx + rx))
	var y0 := int(floor(cy - ry))
	var y1 := int(ceil(cy + ry))
	for y in range(maxi(0, y0), mini(img.get_height(), y1 + 1)):
		for x in range(maxi(0, x0), mini(img.get_width(), x1 + 1)):
			var dx: float = ((x + 0.5) - cx) / rx
			var dy: float = ((y + 0.5) - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				var l := _luminance(Vector2(dx, dy))
				img.set_pixel(x, y, Color(l, l, l, 1.0))


func _fill_rect(img: Image, x0: float, y0: float, x1: float, y1: float) -> void:
	var cx := (x0 + x1) / 2.0
	var cy := (y0 + y1) / 2.0
	var hw := maxf((x1 - x0) / 2.0, 0.001)
	var hh := maxf((y1 - y0) / 2.0, 0.001)
	for y in range(maxi(0, int(floor(y0))), mini(img.get_height(), int(ceil(y1)))):
		for x in range(maxi(0, int(floor(x0))), mini(img.get_width(), int(ceil(x1)))):
			var dx: float = ((x + 0.5) - cx) / hw
			var dy: float = ((y + 0.5) - cy) / hh
			var l := _luminance(Vector2(dx, dy))
			img.set_pixel(x, y, Color(l, l, l, 1.0))


func _fill_triangle(img: Image, p0: Vector2, p1: Vector2, p2: Vector2) -> void:
	var min_x := int(floor(minf(p0.x, minf(p1.x, p2.x))))
	var max_x := int(ceil(maxf(p0.x, maxf(p1.x, p2.x))))
	var min_y := int(floor(minf(p0.y, minf(p1.y, p2.y))))
	var max_y := int(ceil(maxf(p0.y, maxf(p1.y, p2.y))))
	var center := (p0 + p1 + p2) / 3.0
	var reach := maxf(p0.distance_to(center), maxf(p1.distance_to(center), p2.distance_to(center)))
	reach = maxf(reach, 0.001)
	for y in range(maxi(0, min_y), mini(img.get_height(), max_y + 1)):
		for x in range(maxi(0, min_x), mini(img.get_width(), max_x + 1)):
			var p := Vector2(x + 0.5, y + 0.5)
			if _point_in_triangle(p, p0, p1, p2):
				var offset := (p - center) / reach
				var l := _luminance(offset)
				img.set_pixel(x, y, Color(l, l, l, 1.0))


func _point_in_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var d1 := _edge_sign(p, a, b)
	var d2 := _edge_sign(p, b, c)
	var d3 := _edge_sign(p, c, a)
	var has_neg := d1 < 0 or d2 < 0 or d3 < 0
	var has_pos := d1 > 0 or d2 > 0 or d3 > 0
	return not (has_neg and has_pos)


func _edge_sign(p1: Vector2, p2: Vector2, p3: Vector2) -> float:
	return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)


func _make_gradient_palette(base: Color) -> ImageTexture:
	var width := 8
	var img := _new_image(width, 1)
	for x in range(width):
		var t: float = float(x) / float(width - 1)
		var c: Color
		if t < 0.5:
			c = base.lerp(Color.BLACK, (0.5 - t) * 0.7)
		else:
			c = base.lerp(Color.WHITE, (t - 0.5) * 1.2)
		img.set_pixel(x, 0, c)
	return _to_texture(img)
