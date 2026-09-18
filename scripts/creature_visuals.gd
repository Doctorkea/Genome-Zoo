extends Node2D
class_name CreatureVisuals

## Runtime trait renderer for a single creature.
##
## Shape traits (Head/Neck/Body/Limbs/Eyes) are swapped by assigning a new
## Texture2D to each slot's Sprite2D. Skin/coat traits are applied to every
## part at once via a shared palette-swap ShaderMaterial. See
## docs/ART_PIPELINE.md for the full rationale.

## Grayscale shape textures, keyed by slot name. Populate from your trait
## data table (see docs/GAME_DESIGN.md) — index order should match the
## trait library's option order for that slot.
@export var head_options: Array[Texture2D] = []
@export var neck_options: Array[Texture2D] = []
@export var body_options: Array[Texture2D] = []
@export var limb_options: Array[Texture2D] = []
@export var eye_options: Array[Texture2D] = []

## 1px-tall color-strip textures, one per skin/coat trait (Fur, Scales, Slime, ...).
@export var skin_palettes: Array[Texture2D] = []

@onready var _slots: Dictionary = {
	"head": $Head,
	"neck": $Neck,
	"body": $Body,
	"limbs": $Limbs,
	"eyes": $Eyes,
}

var _skin_material: ShaderMaterial


func _ready() -> void:
	_skin_material = ShaderMaterial.new()
	_skin_material.shader = load("res://scripts/shaders/palette_swap.gdshader")
	for sprite in _slots.values():
		sprite.material = _skin_material
	if not skin_palettes.is_empty():
		set_skin(0)


## Swap the shape shown in a given slot ("head", "neck", "body", "limbs", "eyes")
## to the option at `option_index` in that slot's array.
func set_part_shape(slot: String, option_index: int) -> void:
	var options := _options_for_slot(slot)
	if options.is_empty():
		return
	var sprite: Sprite2D = _slots.get(slot)
	if sprite == null:
		push_warning("CreatureVisuals: unknown slot '%s'" % slot)
		return
	sprite.texture = options[option_index % options.size()]


## Recolor every part at once by picking a palette (skin/coat trait) index.
func set_skin(option_index: int) -> void:
	if skin_palettes.is_empty():
		return
	_skin_material.set_shader_parameter(
		"palette", skin_palettes[option_index % skin_palettes.size()]
	)


func _options_for_slot(slot: String) -> Array:
	match slot:
		"head":
			return head_options
		"neck":
			return neck_options
		"body":
			return body_options
		"limbs":
			return limb_options
		"eyes":
			return eye_options
		_:
			return []
