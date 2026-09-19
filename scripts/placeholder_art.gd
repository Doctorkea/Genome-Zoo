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
		"res://art/creatures/parts/head_jimothy.png",
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
		"res://art/creatures/parts/back_legs_frog.png",
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
		_shape_cache[slot] = _load_slot(slot)
	return _shape_cache[slot]


func get_palette_options() -> Array[Texture2D]:
	if _palette_cache.is_empty():
		for base in PALETTE_BASE_COLORS:
			_palette_cache.append(_make_gradient_palette(base))
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
			textures.append(tex)
	return textures


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
