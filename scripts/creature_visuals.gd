extends Node2D
class_name CreatureVisuals

## Runtime trait renderer for a single creature.
##
## Every part texture is the same canvas size (100×100 = one grass tile) with
## the silhouette already posed in-place. Legs and arms sit under the body;
## matching far copies sit further back, shifted toward the tail. Skin uses
## a shared palette-swap ShaderMaterial. See docs/ART_PIPELINE.md.

const SLOTS: Array[String] = ["tail", "back_legs", "front_legs", "body", "head"]
const FAR_LIMB_OFFSETS: Dictionary = {
	"back_legs": Vector2(6.0, -3.0),
	"front_legs": Vector2(-4.0, -3.0),
}

@onready var _slot_nodes: Dictionary = {
	"tail": $Tail,
	"back_legs": $BackLegs,
	"front_legs": $FrontLegs,
	"body": $Body,
	"head": $Head,
}
@onready var _far_limb_nodes: Dictionary = {
	"back_legs": $FarBackLegs,
	"front_legs": $FarFrontLegs,
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
			_apply_slot_texture(sprite, _options[slot][0])
		_sync_far_limb(slot)

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
	_apply_slot_texture(sprite, options[index])
	sprite.visible = true
	_current_index[slot] = index
	_sync_far_limb(slot)


## Map any square part texture onto one grass cell. High-res Fresco PNGs
## keep their pixels and are scaled down with mipmaps so the ink stays smooth.
func _apply_slot_texture(sprite: Sprite2D, tex: Texture2D) -> void:
	sprite.texture = tex
	var display := float(PlaceholderArt.get_canvas_size())
	var width := maxf(float(tex.get_width()), 1.0)
	var height := maxf(float(tex.get_height()), 1.0)
	sprite.scale = Vector2(display / width, display / height)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


func _sync_far_limb(slot: String) -> void:
	var far: Sprite2D = _far_limb_nodes.get(slot)
	if far == null:
		return
	var near: Sprite2D = _slot_nodes.get(slot)
	if near == null or near.texture == null:
		far.visible = false
		return
	far.material = _skin_material
	_apply_slot_texture(far, near.texture)
	far.position = FAR_LIMB_OFFSETS.get(slot, Vector2(4.0, -3.0))
	far.modulate = Color(0.72, 0.7, 0.68, 1.0)
	far.visible = near.visible


## Hide a slot without changing its option index. Used so a Horse can spawn
## without a tail, and so the DNA Lab can hide a part the player stripped.
func set_slot_visible(slot: String, slot_visible: bool) -> void:
	var sprite: Sprite2D = _slot_nodes.get(slot)
	if sprite == null:
		push_warning("CreatureVisuals: unknown slot '%s'" % slot)
		return
	sprite.visible = slot_visible
	var far: Sprite2D = _far_limb_nodes.get(slot)
	if far != null:
		far.visible = slot_visible


func is_slot_visible(slot: String) -> bool:
	var sprite: Sprite2D = _slot_nodes.get(slot)
	return sprite != null and sprite.visible


func apply_loadout(parts: Dictionary, color_index: int, hidden: Array = []) -> void:
	for slot in SLOTS:
		if parts.has(slot):
			set_part_shape(slot, int(parts[slot]))
	set_skin(color_index)
	for slot in hidden:
		set_slot_visible(str(slot), false)


## Recolor every part at once by picking a coat (palette + pattern) index.
func set_skin(option_index: int) -> void:
	if _palette_options.is_empty():
		return
	_current_palette_index = option_index % _palette_options.size()
	_skin_material.set_shader_parameter("palette", _palette_options[_current_palette_index])
	var look: Dictionary = TraitLibrary.get_option(TraitLibrary.COLOR_SLOT, _current_palette_index)
	_skin_material.set_shader_parameter("mark_color", TraitLibrary.coat_mark_color(look))
	_skin_material.set_shader_parameter("pattern", int(look.get("pattern", 0)))
	_skin_material.set_shader_parameter("pattern_amount", float(look.get("pattern_amount", 0.25)))
	_skin_material.set_shader_parameter("pattern_scale", float(look.get("pattern_scale", 4.0)))
	var pattern_tex: Texture2D = TraitLibrary.coat_pattern_texture(look)
	if pattern_tex != null:
		_skin_material.set_shader_parameter("pattern_map", pattern_tex)
