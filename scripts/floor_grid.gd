extends Node2D

## Zoo floor: HSB 79 / 100 / 70 fill, then a dense scatter of grass blades
## with larger tufts sitting in the gaps.

const BLADE_PATHS: Array[String] = [
	"res://art/tiles/grass/blade_1.png",
	"res://art/tiles/grass/blade_2.png",
	"res://art/tiles/grass/blade_3.png",
	"res://art/tiles/grass/blade_4.png",
	"res://art/tiles/grass/blade_5.png",
	"res://art/tiles/grass/blade_6.png",
]
const TUFT_PATHS: Array[String] = [
	"res://art/tiles/grass/tuft_1.png",
	"res://art/tiles/grass/tuft_2.png",
	"res://art/tiles/grass/tuft_3.png",
	"res://art/tiles/grass/tuft_4.png",
	"res://art/tiles/grass/tuft_5.png",
	"res://art/tiles/grass/tuft_6.png",
	"res://art/tiles/grass/tuft_7.png",
]
const BLADE_SPACING: float = 18.0
const BLADE_SKIP: float = 0.04
const TUFT_SPACING: float = 86.0
const TUFT_SKIP: float = 0.22

var _grass_color: Color = Color.from_hsv(79.0 / 360.0, 0.80, 0.66)
var _stamp_modulate: Color = Color(0.86, 0.90, 0.72)
var _tufts: Array[Texture2D] = []
var _rects: Array[Rect2] = []
var _flips: Array[bool] = []
var _baked: Texture2D


func _ready() -> void:
	z_index = -1
	texture_filter = TEXTURE_FILTER_NEAREST
	_tufts.clear()
	_rects.clear()
	_flips.clear()
	var blades: Array[Texture2D] = _load_textures(BLADE_PATHS)
	var clumps: Array[Texture2D] = _load_textures(TUFT_PATHS)
	if not blades.is_empty():
		_scatter(blades, BLADE_SPACING, BLADE_SKIP, 0.46, 0.78, true, 1)
	if not clumps.is_empty():
		_scatter(clumps, TUFT_SPACING, TUFT_SKIP, 0.70, 0.94, false, 17)
	_sort_by_depth()
	_bake()
	queue_redraw()


func _draw() -> void:
	var size := GridService.world_size()
	if _baked != null:
		draw_texture(_baked, Vector2.ZERO)
		return
	draw_rect(Rect2(Vector2.ZERO, size), _grass_color, true)
	for i in range(_rects.size()):
		var dest: Rect2 = _rects[i]
		var tex: Texture2D = _tufts[i]
		if _flips[i]:
			draw_set_transform(Vector2(dest.position.x + dest.size.x, dest.position.y), 0.0, Vector2(-1.0, 1.0))
			draw_texture_rect(tex, Rect2(Vector2.ZERO, dest.size), false, _stamp_modulate)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_texture_rect(tex, dest, false, _stamp_modulate)


func _load_textures(paths: Array[String]) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for path in paths:
		var tex := load(path) as Texture2D
		if tex == null or tex.get_width() <= 0 or tex.get_height() <= 0:
			push_warning("FloorGrid: could not load %s" % path)
			continue
		textures.append(tex)
	return textures


func _scatter(
	textures: Array[Texture2D],
	spacing: float,
	skip_chance: float,
	min_scale: float,
	max_scale: float,
	allow_flip: bool,
	lane: int
) -> void:
	var world := GridService.world_size()
	var type_count: int = textures.size()
	var cols: int = maxi(1, ceili(world.x / spacing))
	var rows: int = maxi(1, ceili(world.y / spacing))
	for row in range(rows):
		for col in range(cols):
			var h: int = _hash(col + row * 131 + lane * 97, lane)
			if _unit(h, 6) < skip_chance:
				continue
			var jitter := Vector2(
				(_unit(h, 1) - 0.5) * spacing * 0.78,
				(_unit(h, 2) - 0.5) * spacing * 0.78
			)
			var pos := Vector2((float(col) + 0.5) * spacing, (float(row) + 0.5) * spacing) + jitter
			var scale: float = lerpf(min_scale, max_scale, _unit(h, 3))
			var idx: int = _hash(col * 5 + row * 11 + lane, 9) % type_count
			var flip: bool = allow_flip and _unit(h, 5) < 0.5
			_stamp(textures[idx], pos, scale, flip, world)


func _stamp(tex: Texture2D, pos: Vector2, scale: float, flip: bool, world: Vector2) -> void:
	var dest_size: Vector2 = tex.get_size() * scale
	dest_size.x = maxf(4.0, roundf(dest_size.x))
	dest_size.y = maxf(4.0, roundf(dest_size.y))
	var dest := Rect2((pos - Vector2(dest_size.x * 0.5, dest_size.y * 0.82)).round(), dest_size)
	dest.position.x = clampf(dest.position.x, 0.0, world.x - dest.size.x)
	dest.position.y = clampf(dest.position.y, 0.0, world.y - dest.size.y)
	_tufts.append(tex)
	_rects.append(dest)
	_flips.append(flip)


func _sort_by_depth() -> void:
	var order: Array[int] = []
	for i in range(_rects.size()):
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool:
		return _rects[a].end.y < _rects[b].end.y
	)
	var tufts: Array[Texture2D] = []
	var rects: Array[Rect2] = []
	var flips: Array[bool] = []
	for i in order:
		tufts.append(_tufts[i])
		rects.append(_rects[i])
		flips.append(_flips[i])
	_tufts = tufts
	_rects = rects
	_flips = flips


func _bake() -> void:
	var world := GridService.world_size()
	var width: int = maxi(1, int(round(world.x)))
	var height: int = maxi(1, int(round(world.y)))
	var atlas := Image.create(width, height, false, Image.FORMAT_RGBA8)
	atlas.fill(_grass_color)
	var raw: Dictionary = {}
	var tinted: Dictionary = {}
	for i in range(_rects.size()):
		var dest: Rect2 = _rects[i]
		var tex: Texture2D = _tufts[i]
		var dw: int = maxi(1, int(round(dest.size.x)))
		var dh: int = maxi(1, int(round(dest.size.y)))
		var key := "%d_%d_%d_%d" % [tex.get_rid().get_id(), dw, dh, 1 if _flips[i] else 0]
		var stamp: Image = tinted.get(key)
		if stamp == null:
			var src: Image = raw.get(tex)
			if src == null:
				src = tex.get_image()
				if src == null:
					continue
				src = src.duplicate()
				if src.is_compressed():
					src.decompress()
				src.convert(Image.FORMAT_RGBA8)
				_multiply_rgb(src, _stamp_modulate)
				raw[tex] = src
			stamp = src.duplicate()
			if _flips[i]:
				stamp.flip_x()
			if stamp.get_width() != dw or stamp.get_height() != dh:
				stamp.resize(dw, dh, Image.INTERPOLATE_NEAREST)
			tinted[key] = stamp
		var dx: int = int(round(dest.position.x))
		var dy: int = int(round(dest.position.y))
		var blit := Rect2i(0, 0, stamp.get_width(), stamp.get_height())
		if dx < 0:
			blit.position.x -= dx
			blit.size.x += dx
			dx = 0
		if dy < 0:
			blit.position.y -= dy
			blit.size.y += dy
			dy = 0
		if dx + blit.size.x > width:
			blit.size.x = width - dx
		if dy + blit.size.y > height:
			blit.size.y = height - dy
		if blit.size.x <= 0 or blit.size.y <= 0:
			continue
		atlas.blend_rect(stamp, blit, Vector2i(dx, dy))
	_baked = ImageTexture.create_from_image(atlas)


func _multiply_rgb(img: Image, tint: Color) -> void:
	var data: PackedByteArray = img.get_data()
	var n: int = data.size()
	var tr: float = tint.r
	var tg: float = tint.g
	var tb: float = tint.b
	for i in range(0, n, 4):
		data[i] = clampi(int(round(float(data[i]) * tr)), 0, 255)
		data[i + 1] = clampi(int(round(float(data[i + 1]) * tg)), 0, 255)
		data[i + 2] = clampi(int(round(float(data[i + 2]) * tb)), 0, 255)
	img.set_data(img.get_width(), img.get_height(), img.has_mipmaps(), Image.FORMAT_RGBA8, data)


func _hash(i: int, lane: int) -> int:
	var n: int = i * 747796405 + 2891336453 + lane * 1597334677
	n = n ^ (n >> 16)
	return absi(n)


func _unit(seed_n: int, lane: int) -> float:
	var n: int = absi(seed_n * (lane * 374761393 + 668265263))
	return float(n % 10000) / 10000.0
