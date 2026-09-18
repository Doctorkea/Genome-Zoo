extends Node2D
class_name CreatureVisuals

## Runtime trait renderer for a single creature.
##
## Shape traits are swapped by assigning a new Texture2D to each slot's
## Sprite2D. Skin/color is applied to every part at once via a shared
## palette-swap ShaderMaterial. Placeholder textures come from the
## PlaceholderArt autoload. See docs/ART_PIPELINE.md for the full rationale.

const SLOTS: Array[String] = ["tail", "legs", "arms", "body", "head", "eyes", "mouth"]

@onready var _slot_nodes: Dictionary = {
	"tail": $Tail,
	"legs": $Legs,
	"arms": $Arms,
	"body": $Body,
	"head": $Head,
	"eyes": $Eyes,
	"mouth": $Mouth,
}

var _options: Dictionary = {} # slot (String) -> Array[Texture2D]
var _current_index: Dictionary = {} # slot (String) -> int
var _palette_options: Array[Texture2D] = []
var _current_palette_index: int = 0

var _skin_material: ShaderMaterial


func _ready() -> void:
	_skin_material = ShaderMaterial.new()
	_skin_material.shader = load("res://scripts/shaders/palette_swap.gdshader")

	_palette_options = PlaceholderArt.get_palette_options()

	for slot in SLOTS:
		_options[slot] = PlaceholderArt.get_shape_options(slot)
		_current_index[slot] = 0
		var sprite: Sprite2D = _slot_nodes[slot]
		sprite.material = _skin_material
		if not _options[slot].is_empty():
			sprite.texture = _options[slot][0]

	set_skin(0)


func get_slots() -> Array[String]:
	return SLOTS


func get_option_count(slot: String) -> int:
	return _options.get(slot, []).size()


func get_current_index(slot: String) -> int:
	return _current_index.get(slot, 0)


func get_current_palette_index() -> int:
	return _current_palette_index


## Swap the shape shown in a given slot to the option at `option_index`.
func set_part_shape(slot: String, option_index: int) -> void:
	var options: Array = _options.get(slot, [])
	if options.is_empty():
		return
	var index: int = option_index % options.size()
	var sprite: Sprite2D = _slot_nodes.get(slot)
	if sprite == null:
		push_warning("CreatureVisuals: unknown slot '%s'" % slot)
		return
	sprite.texture = options[index]
	_current_index[slot] = index


## Recolor every part at once by picking a palette (skin/coat) index.
func set_skin(option_index: int) -> void:
	if _palette_options.is_empty():
		return
	_current_palette_index = option_index % _palette_options.size()
	_skin_material.set_shader_parameter("palette", _palette_options[_current_palette_index])
