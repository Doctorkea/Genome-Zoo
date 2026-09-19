extends Button
class_name VialChip

## Clickable tag or perk vial. Drop still works on the empty ATGC rung.

var vial_id: String = ""


func setup(id: String) -> void:
	vial_id = id
	if is_inside_tree():
		_refresh()


func _ready() -> void:
	toggle_mode = false
	custom_minimum_size = Vector2(148, 52)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_NONE
	_refresh()
	if not Events.vials_changed.is_connected(_on_vials_changed):
		Events.vials_changed.connect(_on_vials_changed)


func _on_vials_changed(_stock: Dictionary) -> void:
	_refresh()


func _refresh() -> void:
	var vial: Dictionary = GeneTree.get_vial(vial_id)
	if vial.is_empty():
		text = "Empty vial"
		disabled = true
		tooltip_text = "Unlock a serum on the gene tree."
		return
	var count: int = GeneTree.stock_of(vial_id)
	var vial_name: String = str(vial.get("name", "Serum"))
	text = "%s  ×%d" % [vial_name, count]
	disabled = count <= 0 or not GeneTree.is_vial_unlocked(vial_id)
	if count > 0:
		tooltip_text = "Click to apply %s." % vial_name
	else:
		tooltip_text = "Buy %s from the vial shop." % vial_name


func _get_drag_data(_at_position: Vector2) -> Variant:
	if vial_id.is_empty() or not GeneTree.is_usable_vial(vial_id):
		return null
	var vial: Dictionary = GeneTree.get_vial(vial_id)
	var preview := Label.new()
	preview.text = str(vial.get("name", "Serum"))
	preview.theme_type_variation = "PaperLabel"
	preview.add_theme_font_size_override("font_size", 16)
	set_drag_preview(preview)
	return {"vial_id": vial_id}
