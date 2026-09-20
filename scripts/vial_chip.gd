extends Button
class_name VialChip

## Drag a serum onto a labelled DNA pair. Clicks do not splice.

var vial_id: String = ""
var _hover_tween: Tween


func setup(id: String) -> void:
	vial_id = id
	if is_inside_tree():
		_refresh()


func _ready() -> void:
	toggle_mode = false
	custom_minimum_size = Vector2(150, 48)
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	focus_mode = Control.FOCUS_NONE
	expand_icon = false
	add_theme_constant_override("icon_max_width", 36)
	resized.connect(_center_pivot)
	mouse_entered.connect(_set_hot.bind(true))
	mouse_exited.connect(_set_hot.bind(false))
	_refresh()
	if not Events.vials_changed.is_connected(_on_vials_changed):
		Events.vials_changed.connect(_on_vials_changed)


func _center_pivot() -> void:
	pivot_offset = size * 0.5


func _set_hot(hot: bool) -> void:
	if disabled:
		return
	if _hover_tween != null:
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var target: Vector2 = Vector2(1.08, 1.08) if hot else Vector2.ONE
	_hover_tween.tween_property(self, "scale", target, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_vials_changed(_stock: Dictionary) -> void:
	_refresh()


func _refresh() -> void:
	var vial: Dictionary = GeneTree.get_vial(vial_id)
	if vial.is_empty():
		text = "Empty vial"
		icon = null
		disabled = true
		tooltip_text = "Unlock a serum on the gene tree."
		return
	var count: int = GeneTree.stock_of(vial_id)
	var vial_name: String = str(vial.get("name", "Serum"))
	text = "%s  ×%d" % [vial_name, count]
	icon = SerumArt.texture(vial_id)
	disabled = count <= 0 or not GeneTree.is_vial_unlocked(vial_id)
	var hint: String = str(vial.get("hint", ""))
	if count > 0:
		if hint.is_empty():
			tooltip_text = "Drag %s onto a DNA pair." % vial_name
		else:
			tooltip_text = "%s Drag onto a DNA pair." % hint
	else:
		tooltip_text = "Buy %s from the vial shop." % vial_name


func _get_drag_data(_at_position: Vector2) -> Variant:
	if vial_id.is_empty() or not GeneTree.is_usable_vial(vial_id):
		return null
	scale = Vector2.ONE
	var preview := TextureRect.new()
	preview.texture = SerumArt.texture(vial_id)
	preview.custom_minimum_size = Vector2(52, 60)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)
	return {"vial_id": vial_id}
