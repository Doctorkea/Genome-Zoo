extends Control
class_name DnaStrand

## Vertical ATGC ladder. Each labelled pair is a body-part drop target.
## Extra rungs stay decorative so the strand still reads as a full helix.

signal vial_dropped(vial_id: String, slot: String)
signal slot_hovered(slot: String)

const RUNG_COUNT: int = 7
const PAIR: Dictionary = {"A": "T", "T": "A", "G": "C", "C": "G"}
const LEFT_PATTERN: Array[String] = ["A", "G", "T", "C", "A", "G", "T"]
const RUNG_SLOTS: Array[String] = [
	"",
	"head",
	"front_legs",
	"back_legs",
	"tail",
	"color",
	"",
]
const BASE_COLORS: Dictionary = {
	"A": Color(0.91, 0.64, 0.09, 1),
	"T": Color(0.22, 0.47, 0.40, 1),
	"G": Color(0.70, 0.28, 0.22, 1),
	"C": Color(0.27, 0.35, 0.52, 1),
}

var _hover_slot: String = ""
var _marked_slot: String = ""
var _flash_slot: String = ""
var _flash_t: float = 0.0
var _t: float = 0.0
var _dragging: bool = false
var _rung_rects: Array[Rect2] = []
var _parts: Dictionary = {} # slot -> {name, look}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(420, 200)
	set_process(false)
	resized.connect(queue_redraw)
	mouse_exited.connect(_on_mouse_exited)
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()


func highlight(slot: String) -> void:
	_marked_slot = slot
	queue_redraw()


func flash(slot: String) -> void:
	_flash_slot = slot
	_flash_t = 0.55
	highlight(slot)
	queue_redraw()


func arm(_slot: String) -> void:
	highlight(_slot)


func set_parts(parts: Dictionary) -> void:
	_parts = parts.duplicate(true)
	queue_redraw()


func notes_text() -> String:
	var lines: PackedStringArray = PackedStringArray()
	for slot in RUNG_SLOTS:
		if slot.is_empty():
			continue
		lines.append(_label_for(slot))
	return "\n".join(lines)


func _on_visibility_changed() -> void:
	set_process(visible)
	if visible:
		queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	var dragging: bool = get_viewport().gui_is_dragging()
	if dragging != _dragging:
		_dragging = dragging
		if not dragging:
			_set_hover("")
	if _flash_t > 0.0:
		_flash_t = maxf(0.0, _flash_t - delta)
		if _flash_t <= 0.0:
			_flash_slot = ""
	queue_redraw()


func _set_hover(slot: String) -> void:
	if slot == _hover_slot:
		return
	_hover_slot = slot
	slot_hovered.emit(slot)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_set_hover(_slot_at((event as InputEventMouseMotion).position))


func _draw() -> void:
	var size := get_size()
	_rung_rects.clear()
	var rail_x_left: float = size.x * 0.14
	var rail_x_right: float = size.x * 0.32
	var top: float = 16.0
	var bottom: float = size.y - 16.0
	var rail := Color(0.16, 0.20, 0.17, 1)
	draw_line(Vector2(rail_x_left, top), Vector2(rail_x_left, bottom), rail, 5.0)
	draw_line(Vector2(rail_x_right, top), Vector2(rail_x_right, bottom), rail, 5.0)
	_draw_caption(Vector2(rail_x_left - 20.0, 12.0), "5'")
	_draw_caption(Vector2(rail_x_right + 8.0, 12.0), "3'")
	_draw_caption(Vector2(rail_x_left - 20.0, size.y - 2.0), "3'")
	_draw_caption(Vector2(rail_x_right + 8.0, size.y - 2.0), "5'")

	var step: float = (bottom - top) / float(RUNG_COUNT + 1)
	for i in range(RUNG_COUNT):
		var y: float = top + step * float(i + 1)
		var slot: String = RUNG_SLOTS[i] if i < RUNG_SLOTS.size() else ""
		var decorative: bool = slot.is_empty()
		var sway: float = sin(_t * 2.4 + float(i) * 0.85) * (5.0 if not decorative else 2.2)
		var x0: float = rail_x_left + sway
		var x1: float = rail_x_right - sway
		var rung := Rect2(minf(x0, rail_x_left) - 22.0, y - 18.0, size.x - 12.0, 36.0)
		_rung_rects.append(rung)
		var hot: bool = slot == _hover_slot and not decorative
		var marked: bool = slot == _marked_slot and not decorative
		var flashing: bool = slot == _flash_slot and _flash_t > 0.0
		if not decorative and (hot or marked or flashing or _dragging):
			var pulse: float = 0.55 + 0.45 * sin(_t * 9.0) if _dragging else 1.0
			var wash_a: float = 0.10
			if flashing:
				wash_a = 0.22 * (_flash_t / 0.55)
			elif hot:
				wash_a = 0.18
			elif marked:
				wash_a = 0.12
			wash_a *= pulse
			draw_rect(
				Rect2(rung.position.x, rung.position.y, size.x - rung.position.x - 6.0, rung.size.y),
				Color(0.91, 0.64, 0.09, wash_a),
				true
			)
			if hot or _dragging:
				draw_rect(
					Rect2(rung.position.x, rung.position.y, 4.0, rung.size.y),
					Color(0.91, 0.64, 0.09, 0.85 * pulse),
					true
				)
		_draw_pair(x0, x1, y, LEFT_PATTERN[i], decorative, hot or flashing)
		if not decorative:
			_draw_limb_label(
				Vector2(maxf(x0, x1) + 20.0, y + 5.0),
				_label_for(slot),
				hot or marked or flashing
			)


func _label_for(slot: String) -> String:
	var heading: String = TraitLibrary.slot_display_name(slot)
	var info: Dictionary = _parts.get(slot, {})
	if info.is_empty():
		return heading
	var part_name: String = str(info.get("name", "—"))
	var look: String = str(info.get("look", ""))
	if look.is_empty():
		return "%s | %s" % [heading, part_name]
	return "%s | %s | %s" % [heading, part_name, look]


func _draw_pair(x0: float, x1: float, y: float, left_base: String, decorative: bool, hot: bool) -> void:
	var right_base: String = PAIR[left_base]
	var bar := Color(0.55, 0.46, 0.28, 0.42 if decorative else 0.9)
	if hot:
		bar = Color(0.91, 0.64, 0.09, 0.95)
	draw_line(Vector2(x0, y), Vector2(x1, y), bar, 3.5 if hot else 3.0)
	_draw_base(Vector2(x0, y), left_base, decorative, hot)
	_draw_base(Vector2(x1, y), right_base, decorative, hot)


func _draw_base(center: Vector2, base: String, decorative: bool, hot: bool) -> void:
	var color: Color = BASE_COLORS.get(base, Color.WHITE)
	if decorative:
		color.a = 0.45
	var radius: float = 13.0 if hot else 11.0
	draw_circle(center, radius, color)
	draw_arc(center, radius, 0.0, TAU, 24, Color(0.11, 0.09, 0.06, 0.55), 1.5)
	var font: Font = get_theme_default_font()
	var font_size: int = 13
	var text_size: Vector2 = font.get_string_size(base, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var ink := Color(0.98, 0.95, 0.88, 0.55 if decorative else 1.0)
	draw_string(
		font,
		center + Vector2(-text_size.x * 0.5, text_size.y * 0.35),
		base,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		ink
	)


func _draw_limb_label(pos: Vector2, text: String, hot: bool) -> void:
	var font: Font = get_theme_default_font()
	var ink := Color(0.11, 0.09, 0.06, 1) if hot else Color(0.32, 0.26, 0.18, 1)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, ink)


func _draw_caption(pos: Vector2, text: String) -> void:
	var font: Font = get_theme_default_font()
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.42, 0.36, 0.26, 1))


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var slot: String = _slot_at(at_position)
	_set_hover(slot)
	if slot.is_empty():
		return false
	if not (data is Dictionary):
		return false
	var vial_id: String = str(data.get("vial_id", ""))
	return not vial_id.is_empty() and not GeneTree.get_vial(vial_id).is_empty()


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var slot: String = _slot_at(at_position)
	_hover_slot = ""
	_dragging = false
	if not (data is Dictionary) or slot.is_empty():
		queue_redraw()
		return
	var vial_id: String = str(data.get("vial_id", ""))
	if vial_id.is_empty():
		return
	flash(slot)
	vial_dropped.emit(vial_id, slot)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_dragging = false
		_set_hover("")


func _slot_at(at_position: Vector2) -> String:
	for i in range(_rung_rects.size()):
		if not _rung_rects[i].has_point(at_position):
			continue
		if i < RUNG_SLOTS.size():
			return RUNG_SLOTS[i]
	return ""


func _on_mouse_exited() -> void:
	if not _dragging:
		_set_hover("")
