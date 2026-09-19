extends Node

## Procedurally generates placeholder creature part textures.
##
## EVERY shape option for EVERY slot is drawn on the same CANVAS_SIZE×CANVAS_SIZE
## frame (100×100 — one grass tile). Parts are already posed in-place on that
## shared guide, so the Creature rig stacks them all at the origin and they line
## up. Replace with real art of the same canvas size later; nothing else changes.
##
## See docs/ART_PIPELINE.md. Autoloaded as "PlaceholderArt".

const CANVAS_SIZE: int = 100 # matches GridService.CELL_SIZE / one grass tile
const LIGHT_DIR: Vector2 = Vector2(-0.6, -0.8)

## Shared pose regions inside the 100×100 guide (side-on, facing right).
## Artist: draw each part only in its region; leave the rest transparent.
const REGION_BODY := Rect2(28, 34, 48, 32)
const REGION_HEAD := Rect2(62, 18, 34, 32) # includes snout — no separate mouth slot
const REGION_EYES := Rect2(78, 24, 12, 12)
const REGION_FRONT_LEGS := Rect2(54, 62, 18, 30)
const REGION_BACK_LEGS := Rect2(30, 62, 18, 30)
const REGION_TAIL := Rect2(4, 40, 28, 22)

const PALETTE_BASE_COLORS: Array[Color] = [
	Color(0.55, 0.36, 0.20), # warm, fur-ish brown
	Color(0.20, 0.55, 0.50), # cool, scales-ish teal
	Color(0.55, 0.30, 0.55), # slime/weird-ish violet
]

var _shape_cache: Dictionary = {} # slot (String) -> Array[Texture2D]
var _palette_cache: Array[Texture2D] = []


func get_canvas_size() -> int:
	return CANVAS_SIZE


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
		"front_legs":
			return _make_front_legs_options()
		"back_legs":
			return _make_back_legs_options()
		"tail":
			return _make_tail_options()
		_:
			push_warning("PlaceholderArt: unknown slot '%s'" % slot)
			return []


func _blank() -> Image:
	return Image.create(CANVAS_SIZE, CANVAS_SIZE, false, Image.FORMAT_RGBA8)


func _tex(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)


func _make_body_options() -> Array[Texture2D]:
	var r := REGION_BODY
	var cx := r.position.x + r.size.x * 0.5
	var cy := r.position.y + r.size.y * 0.5

	var img0 := _blank()
	_fill_ellipse(img0, cx, cy, r.size.x * 0.48, r.size.y * 0.48)

	var img1 := _blank()
	_fill_ellipse(img1, cx, cy, r.size.x * 0.5, r.size.y * 0.38)

	var img2 := _blank()
	_fill_rect(img2, r.position.x + 4, r.position.y + 4, r.end.x - 4, r.end.y - 4)

	return [_tex(img0), _tex(img1), _tex(img2)]


func _make_head_options() -> Array[Texture2D]:
	var r := REGION_HEAD
	var cx := r.position.x + r.size.x * 0.5
	var cy := r.position.y + r.size.y * 0.55

	var img0 := _blank()
	_fill_circle(img0, cx, cy, mini(r.size.x, r.size.y) * 0.42)

	var img1 := _blank()
	_fill_circle(img1, cx, cy + 2, mini(r.size.x, r.size.y) * 0.38)
	_fill_triangle(img1, Vector2(cx - 8, cy - 4), Vector2(cx - 4, cy - 16), Vector2(cx - 1, cy - 4))
	_fill_triangle(img1, Vector2(cx + 8, cy - 4), Vector2(cx + 4, cy - 16), Vector2(cx + 1, cy - 4))

	var img2 := _blank()
	_fill_ellipse(img2, cx, cy, r.size.x * 0.48, r.size.y * 0.36)

	return [_tex(img0), _tex(img1), _tex(img2)]


func _make_eyes_options() -> Array[Texture2D]:
	# Single eye — profile view. Drawn inside REGION_EYES on the shared canvas.
	var r := REGION_EYES
	var cx := r.position.x + r.size.x * 0.5
	var cy := r.position.y + r.size.y * 0.5

	var img0 := _blank()
	_fill_circle(img0, cx, cy, 4)

	var img1 := _blank()
	_fill_circle(img1, cx, cy, 5.5)

	var img2 := _blank()
	_fill_ellipse(img2, cx, cy, 5, 2)

	return [_tex(img0), _tex(img1), _tex(img2)]


func _make_front_legs_options() -> Array[Texture2D]:
	var r := REGION_FRONT_LEGS
	var mid_x := r.position.x + r.size.x * 0.5

	var img0 := _blank()
	_fill_rect(img0, mid_x - 4, r.position.y, mid_x + 4, r.end.y)

	var img1 := _blank()
	_fill_rect(img1, mid_x - 3, r.position.y, mid_x + 3, r.end.y)

	var img2 := _blank()
	_fill_rect(img2, mid_x - 6, r.position.y + 4, mid_x - 2, r.end.y)
	_fill_rect(img2, mid_x + 2, r.position.y + 4, mid_x + 6, r.end.y)

	return [_tex(img0), _tex(img1), _tex(img2)]


func _make_back_legs_options() -> Array[Texture2D]:
	var r := REGION_BACK_LEGS
	var mid_x := r.position.x + r.size.x * 0.5

	var img0 := _blank()
	_fill_rect(img0, mid_x - 4, r.position.y, mid_x + 4, r.end.y)

	var img1 := _blank()
	_fill_rect(img1, mid_x - 3, r.position.y, mid_x + 3, r.end.y)

	var img2 := _blank()
	_fill_rect(img2, mid_x - 7, r.position.y + 2, mid_x - 3, r.end.y)
	_fill_rect(img2, mid_x + 3, r.position.y + 2, mid_x + 7, r.end.y)

	return [_tex(img0), _tex(img1), _tex(img2)]


func _make_tail_options() -> Array[Texture2D]:
	var r := REGION_TAIL
	var tip := Vector2(r.position.x + 2, r.position.y + r.size.y * 0.5)
	var base_top := Vector2(r.end.x - 2, r.position.y + 4)
	var base_bot := Vector2(r.end.x - 2, r.end.y - 4)

	var img0 := _blank()
	_fill_triangle(img0, tip, base_top, base_bot)

	var img1 := _blank()
	_fill_triangle(img1, tip + Vector2(0, -2), base_top + Vector2(0, -2), base_bot + Vector2(0, 2))

	var img2 := _blank()
	_fill_ellipse(img2, r.position.x + r.size.x * 0.4, r.position.y + r.size.y * 0.5, 10, 9)

	return [_tex(img0), _tex(img1), _tex(img2)]


# ---------------------------------------------------------------------------
# Drawing primitives
# ---------------------------------------------------------------------------

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
				var l := _luminance(Vector2(dx, dy) / maxf(r, 0.001))
				img.set_pixel(x, y, Color(l, l, l, 1.0))


func _fill_ellipse(img: Image, cx: float, cy: float, rx: float, ry: float) -> void:
	var x0 := int(floor(cx - rx))
	var x1 := int(ceil(cx + rx))
	var y0 := int(floor(cy - ry))
	var y1 := int(ceil(cy + ry))
	for y in range(maxi(0, y0), mini(img.get_height(), y1 + 1)):
		for x in range(maxi(0, x0), mini(img.get_width(), x1 + 1)):
			var dx: float = ((x + 0.5) - cx) / maxf(rx, 0.001)
			var dy: float = ((y + 0.5) - cy) / maxf(ry, 0.001)
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
	var img := Image.create(width, 1, false, Image.FORMAT_RGBA8)
	for x in range(width):
		var t: float = float(x) / float(width - 1)
		var c: Color
		if t < 0.5:
			c = base.lerp(Color.BLACK, (0.5 - t) * 0.7)
		else:
			c = base.lerp(Color.WHITE, (t - 0.5) * 1.2)
		img.set_pixel(x, 0, c)
	return ImageTexture.create_from_image(img)
