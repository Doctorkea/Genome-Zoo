extends Node

## Artist part textures plus shared palettes.
##
## Every option is a square PNG posed on the same canvas (100×100 or larger;
## the rig scales it to one grass cell). See docs/ART_PIPELINE.md.
## Autoloaded as "PlaceholderArt".

const CANVAS_SIZE: int = 100 # matches GridService.CELL_SIZE / one grass tile

## slot -> ordered res:// paths. Indices match TraitLibrary.OPTIONS.
const ART_FILES: Dictionary = {
	"body": [
		"res://art/creatures/parts/body_jimmothy.png",
	],
	"head": [
		"res://art/creatures/parts/head_gorilla.png",
		"res://art/creatures/parts/head_lizard.png",
		"res://art/creatures/parts/head_jimmothy.png",
		"res://art/creatures/parts/head_cockatoo.png",
		"res://art/creatures/parts/head_turtle.png",
		"res://art/creatures/parts/head_frog.png",
		"res://art/creatures/parts/head_hamster.png",
		"res://art/creatures/parts/head_duck.png",
		"res://art/creatures/parts/head_lion.png",
	],
	"front_legs": [
		"res://art/creatures/parts/front_legs_turtle.png",
		"res://art/creatures/parts/front_legs_horse.png",
		"res://art/creatures/parts/front_legs_lizard.png",
		"res://art/creatures/parts/front_legs_lion.png",
		"res://art/creatures/parts/front_legs_trex.png",
		"res://art/creatures/parts/front_legs_chimory.png",
	],
	"back_legs": [
		"res://art/creatures/parts/back_legs_sheep.png",
		"res://art/creatures/parts/back_legs_horse.png",
		"res://art/creatures/parts/back_legs_jimmothy.png",
		"res://art/creatures/parts/back_legs_bird.png",
		"res://art/creatures/parts/back_legs_elephant.png",
		"res://art/creatures/parts/back_legs_gorilla.png",
		"res://art/creatures/parts/back_legs_lion.png",
		"res://art/creatures/parts/back_legs_turtle.png",
	],
	"tail": [
		"res://art/creatures/parts/tail_pig.png",
		"res://art/creatures/parts/tail_sheep.png",
		"res://art/creatures/parts/tail_tentacle.png",
		"res://art/creatures/parts/tail_fire.png",
		"res://art/creatures/parts/tail_lion.png",
		"res://art/creatures/parts/tail_lizard.png",
		"res://art/creatures/parts/tail_scorpion.png",
		"res://art/creatures/parts/tail_jimmothy.png",
	],
}

## Shared pose regions inside the 100×100 guide (side-on, facing right).
const REGION_BODY := Rect2(28, 34, 48, 32)
const REGION_HEAD := Rect2(62, 18, 34, 32)
const REGION_FRONT_LEGS := Rect2(54, 62, 18, 30)
const REGION_BACK_LEGS := Rect2(18, 57, 25, 41)
const REGION_TAIL := Rect2(4, 40, 28, 22)

var _shape_cache: Dictionary = {} # slot (String) -> Array[Texture2D]
var _palette_cache: Array[Texture2D] = []


func get_canvas_size() -> int:
	return CANVAS_SIZE


func get_shape_options(slot: String) -> Array[Texture2D]:
	if not _shape_cache.has(slot):
		_shape_cache[slot] = _load_slot(slot)
	return _shape_cache[slot]


func get_palette_options() -> Array[Texture2D]:
	if _palette_cache.is_empty():
		var coats: Array = TraitLibrary.OPTIONS.get("color", [])
		for option in coats:
			_palette_cache.append(_make_gradient_palette(TraitLibrary.coat_base_color(option)))
	return _palette_cache


func _load_slot(slot: String) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	var files: Array = ART_FILES.get(slot, [])
	if files.is_empty():
		push_warning("PlaceholderArt: unknown slot '%s'" % slot)
		return textures
	for path_value in files:
		var path := str(path_value)
		if not ResourceLoader.exists(path):
			push_warning("PlaceholderArt: missing part art %s" % path)
			continue
		var tex := load(path) as Texture2D
		if tex != null:
			textures.append(_normalize_part(tex))
	return textures


func _normalize_part(tex: Texture2D) -> Texture2D:
	var img := tex.get_image()
	if img == null:
		return tex
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	var width: int = img.get_width()
	var height: int = img.get_height()
	const INK_CUT: float = 0.32
	var sum: float = 0.0
	var count: int = 0
	for y in range(height):
		for x in range(width):
			var pixel: Color = img.get_pixel(x, y)
			if pixel.a < 0.08:
				continue
			var lum: float = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114
			if lum < INK_CUT:
				continue
			sum += lum
			count += 1
	if count < 8:
		return tex
	var mean: float = sum / float(count)
	var target: float = 0.72
	var contrast: float = 0.75
	for y in range(height):
		for x in range(width):
			var pixel: Color = img.get_pixel(x, y)
			if pixel.a < 0.04:
				continue
			var lum: float = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114
			var mapped: float
			if lum < INK_CUT:
				mapped = clampf(pow(lum, 1.45) * 0.38, 0.0, 0.08)
			else:
				mapped = clampf((lum - mean) * contrast + target, 0.34, 0.82)
			img.set_pixel(x, y, Color(mapped, mapped, mapped, pixel.a))
	_thicken_base_ink(img)
	_ink_outer_rim(img)
	var mip_err := img.generate_mipmaps()
	if mip_err != OK:
		push_warning("PlaceholderArt: could not build mipmaps for a part")
	return ImageTexture.create_from_image(img)


## Grow the sprite's own dark strokes by a few source pixels so they still
## read after the 400px Fresco parts are scaled onto a 100px grass cell.
## Only paints over existing fill — never a second offset outline.
func _thicken_base_ink(img: Image) -> void:
	var width: int = img.get_width()
	var height: int = img.get_height()
	var radius: int = clampi(int(round(float(width) / 220.0)), 1, 3)
	var radius_sq: int = radius * radius
	var ink := PackedByteArray()
	ink.resize(width * height)
	for y in range(height):
		for x in range(width):
			var pixel: Color = img.get_pixel(x, y)
			if pixel.a < 0.12:
				continue
			var lum: float = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114
			if lum < 0.12:
				ink[y * width + x] = 1
	var thickened: Image = img.duplicate()
	for y in range(height):
		for x in range(width):
			if ink[y * width + x] == 1:
				continue
			var pixel: Color = img.get_pixel(x, y)
			if pixel.a < 0.2:
				continue
			var near_ink := false
			for oy in range(-radius, radius + 1):
				for ox in range(-radius, radius + 1):
					if ox * ox + oy * oy > radius_sq:
						continue
					var nx: int = x + ox
					var ny: int = y + oy
					if nx < 0 or ny < 0 or nx >= width or ny >= height:
						continue
					if ink[ny * width + nx] == 1:
						near_ink = true
						break
				if near_ink:
					break
			if not near_ink:
				continue
			thickened.set_pixel(x, y, Color(0.04, 0.04, 0.04, pixel.a))
	img.copy_from(thickened)


## Light anti-aliased fringes read as white hairlines on the grass. Crush
## the silhouette ring to ink so the back copies and outer edge stay black.
func _ink_outer_rim(img: Image) -> void:
	var width: int = img.get_width()
	var height: int = img.get_height()
	var edge := PackedByteArray()
	edge.resize(width * height)
	for y in range(height):
		for x in range(width):
			var pixel: Color = img.get_pixel(x, y)
			if pixel.a < 0.03:
				continue
			var on_edge: bool = pixel.a < 0.55
			if not on_edge:
				for d: Vector2i in [
					Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
					Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
				]:
					var nx: int = x + d.x
					var ny: int = y + d.y
					if nx < 0 or ny < 0 or nx >= width or ny >= height:
						on_edge = true
						break
					if img.get_pixel(nx, ny).a < 0.12:
						on_edge = true
						break
			if on_edge:
				edge[y * width + x] = 1
	for y in range(height):
		for x in range(width):
			if edge[y * width + x] != 1:
				continue
			var pixel: Color = img.get_pixel(x, y)
			img.set_pixel(x, y, Color(0.03, 0.03, 0.03, maxf(pixel.a, 0.92)))


func _make_gradient_palette(base: Color) -> ImageTexture:
	var width := 8
	var img := Image.create(width, 1, false, Image.FORMAT_RGBA8)
	for x in range(width):
		var t: float = float(x) / float(width - 1)
		var c: Color
		if t < 0.5:
			c = base.lerp(Color(0.12, 0.09, 0.07), (0.5 - t) * 0.55)
		else:
			c = base.lerp(Color(0.96, 0.93, 0.88), (t - 0.5) * 0.9)
		img.set_pixel(x, 0, c)
	return ImageTexture.create_from_image(img)
