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


func _ready() -> void:
	warmup()


func warmup() -> void:
	get_palette_options()
	for slot in ART_FILES.keys():
		get_shape_options(str(slot))
	var fx := preload("res://scripts/fx.gd")
	fx.puff_tex()
	fx.speck_tex()
	fx.cloud_tex()
	fx.ground_shadow_tex()


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
	img.convert(Image.FORMAT_RGBA8)
	var width: int = img.get_width()
	var height: int = img.get_height()
	var data: PackedByteArray = img.get_data()
	const INK_CUT: float = 0.32
	var sum: float = 0.0
	var count: int = 0
	var n: int = width * height
	for i in range(n):
		var o: int = i * 4
		var a: float = float(data[o + 3]) / 255.0
		if a < 0.08:
			continue
		var lum: float = (float(data[o]) * 0.299 + float(data[o + 1]) * 0.587 + float(data[o + 2]) * 0.114) / 255.0
		if lum < INK_CUT:
			continue
		sum += lum
		count += 1
	if count < 8:
		return tex
	var mean: float = sum / float(count)
	var target: float = 0.72
	var contrast: float = 0.75
	for i in range(n):
		var o: int = i * 4
		var a: float = float(data[o + 3]) / 255.0
		if a < 0.04:
			continue
		var lum: float = (float(data[o]) * 0.299 + float(data[o + 1]) * 0.587 + float(data[o + 2]) * 0.114) / 255.0
		var mapped: float
		if lum < INK_CUT:
			mapped = clampf(pow(lum, 1.45) * 0.38, 0.0, 0.08)
		else:
			mapped = clampf((lum - mean) * contrast + target, 0.34, 0.82)
		var gray: int = clampi(int(round(mapped * 255.0)), 0, 255)
		data[o] = gray
		data[o + 1] = gray
		data[o + 2] = gray
	data = _thicken_base_ink(data, width, height)
	data = _ink_outer_rim(data, width, height)
	img.set_data(width, height, false, Image.FORMAT_RGBA8, data)
	var mip_err := img.generate_mipmaps()
	if mip_err != OK:
		push_warning("PlaceholderArt: could not build mipmaps for a part")
	return ImageTexture.create_from_image(img)


## Grow the sprite's own dark strokes by a few source pixels so they still
## read after the 400px Fresco parts are scaled onto a 100px grass cell.
## Only paints over existing fill — never a second offset outline.
func _thicken_base_ink(data: PackedByteArray, width: int, height: int) -> PackedByteArray:
	var n: int = width * height
	var radius: int = clampi(int(round(float(width) / 220.0)), 1, 3)
	var radius_sq: int = radius * radius
	var ink := PackedByteArray()
	ink.resize(n)
	var seeds: PackedInt32Array = PackedInt32Array()
	for i in range(n):
		var o: int = i * 4
		var a: float = float(data[o + 3]) / 255.0
		if a < 0.12:
			continue
		var lum: float = (float(data[o]) * 0.299 + float(data[o + 1]) * 0.587 + float(data[o + 2]) * 0.114) / 255.0
		if lum < 0.12:
			ink[i] = 1
			seeds.append(i)
	var thickened := data.duplicate()
	for i in seeds:
		var x: int = i % width
		var y: int = int(i / width)
		for oy in range(-radius, radius + 1):
			for ox in range(-radius, radius + 1):
				if ox * ox + oy * oy > radius_sq:
					continue
				var nx: int = x + ox
				var ny: int = y + oy
				if nx < 0 or ny < 0 or nx >= width or ny >= height:
					continue
				var ni: int = ny * width + nx
				if ink[ni] == 1:
					continue
				var o: int = ni * 4
				if float(data[o + 3]) / 255.0 < 0.2:
					continue
				thickened[o] = 10
				thickened[o + 1] = 10
				thickened[o + 2] = 10
	return thickened


## Light anti-aliased fringes read as white hairlines on the grass. Crush
## the silhouette ring to ink so the back copies and outer edge stay black.
func _ink_outer_rim(data: PackedByteArray, width: int, height: int) -> PackedByteArray:
	var n: int = width * height
	var edge := PackedByteArray()
	edge.resize(n)
	for y in range(height):
		for x in range(width):
			var i: int = y * width + x
			var o: int = i * 4
			var a: float = float(data[o + 3]) / 255.0
			if a < 0.03:
				continue
			var on_edge: bool = a < 0.55
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
					var na: float = float(data[(ny * width + nx) * 4 + 3]) / 255.0
					if na < 0.12:
						on_edge = true
						break
			if on_edge:
				edge[i] = 1
	for i in range(n):
		if edge[i] != 1:
			continue
		var o: int = i * 4
		data[o] = 8
		data[o + 1] = 8
		data[o + 2] = 8
		data[o + 3] = maxi(data[o + 3], 235)
	return data


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
