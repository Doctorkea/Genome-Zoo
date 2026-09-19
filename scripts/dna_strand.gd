extends Control
class_name DnaStrand

## Vertical ATGC ladder. One rung stays empty as the vial drop target.

signal vial_dropped(vial_id: String)

const RUNG_COUNT: int = 7
const BASES: Array[String] = ["A", "T", "G", "C"]
const PAIR: Dictionary = {"A": "T", "T": "A", "G": "C", "C": "G"}
const LEFT_PATTERN: Array[String] = ["A", "G", "T", "C", "A", "G", "T"]
const BASE_COLORS: Dictionary = {
	"A": Color(0.91, 0.64, 0.09, 1),
	"T": Color(0.22, 0.47, 0.40, 1),
	"G": Color(0.70, 0.28, 0.22, 1),
	"C": Color(0.27, 0.35, 0.52, 1),
}

var empty_index: int = 3
var can_accept_drop: bool = false

var _hovering_empty: bool = false
var _rung_rects: Array[Rect2] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(220, 320)
	resized.connect(queue_redraw)
	mouse_exited.connect(_on_mouse_exited)


func arm(slot: String) -> void:
	can_accept_drop = not slot.is_empty()
	if slot.is_empty():
		empty_index = 3
	else:
		empty_index = absi(slot.hash()) % RUNG_COUNT
	queue_redraw()


func _draw() -> void:
	var size := get_size()
	_rung_rects.clear()
	var rail_x_left: float = size.x * 0.28
	var rail_x_right: float = size.x * 0.72
	var top: float = 18.0
	var bottom: float = size.y - 18.0
	var rail := Color(0.16, 0.20, 0.17, 1)
	draw_line(Vector2(rail_x_left, top), Vector2(rail_x_left, bottom), rail, 5.0)
	draw_line(Vector2(rail_x_right, top), Vector2(rail_x_right, bottom), rail, 5.0)
	_draw_caption(Vector2(rail_x_left - 22.0, 14.0), "5'")
	_draw_caption(Vector2(rail_x_right + 8.0, 14.0), "3'")
	_draw_caption(Vector2(rail_x_left - 22.0, size.y - 4.0), "3'")
	_draw_caption(Vector2(rail_x_right + 8.0, size.y - 4.0), "5'")

	var step: float = (bottom - top) / float(RUNG_COUNT + 1)
	for i in range(RUNG_COUNT):
		var y: float = top + step * float(i + 1)
		var rung := Rect2(rail_x_left - 28.0, y - 16.0, rail_x_right - rail_x_left + 56.0, 32.0)
		_rung_rects.append(rung)
		if i == empty_index:
			_draw_empty_rung(rung)
		else:
			var left_base: String = LEFT_PATTERN[i]
			_draw_pair(rail_x_left, rail_x_right, y, left_base)


func _draw_pair(x0: float, x1: float, y: float, left_base: String) -> void:
	var right_base: String = PAIR[left_base]
	draw_line(Vector2(x0, y), Vector2(x1, y), Color(0.55, 0.46, 0.28, 0.85), 3.0)
	_draw_base(Vector2(x0, y), left_base)
	_draw_base(Vector2(x1, y), right_base)


func _draw_base(center: Vector2, base: String) -> void:
	var color: Color = BASE_COLORS.get(base, Color.WHITE)
	draw_circle(center, 11.0, color)
	draw_arc(center, 11.0, 0.0, TAU, 24, Color(0.11, 0.09, 0.06, 0.55), 1.5)
	var font: Font = get_theme_default_font()
	var font_size: int = 13
	var text_size: Vector2 = font.get_string_size(base, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(
		font,
		center + Vector2(-text_size.x * 0.5, text_size.y * 0.35),
		base,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color(0.98, 0.95, 0.88, 1)
	)


func _draw_empty_rung(rung: Rect2) -> void:
	var accent := Color(0.91, 0.64, 0.09, 1) if (_hovering_empty and can_accept_drop) else Color(0.55, 0.46, 0.28, 1)
	draw_rect(rung.grow(-2.0), Color(0.91, 0.64, 0.09, 0.10 if can_accept_drop else 0.04), true)
	_draw_dashed_rect(rung, accent)
	var label: String = "Click a vial" if can_accept_drop else "Pick a part"
	var font: Font = get_theme_default_font()
	var font_size: int = 12
	var text_size: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(
		font,
		rung.get_center() + Vector2(-text_size.x * 0.5, text_size.y * 0.3),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color(0.42, 0.36, 0.26, 1)
	)


func _draw_dashed_rect(rect: Rect2, color: Color) -> void:
	var pts: Array[Vector2] = [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
		rect.position,
	]
	for i in range(pts.size() - 1):
		_draw_dashed_line(pts[i], pts[i + 1], color)


func _draw_dashed_line(from: Vector2, to: Vector2, color: Color) -> void:
	var delta: Vector2 = to - from
	var length: float = delta.length()
	if length <= 0.0:
		return
	var dir: Vector2 = delta / length
	var drawn: float = 0.0
	while drawn < length:
		var start: Vector2 = from + dir * drawn
		var end: Vector2 = from + dir * minf(drawn + 5.0, length)
		draw_line(start, end, color, 2.0)
		drawn += 9.0


func _draw_caption(pos: Vector2, text: String) -> void:
	var font: Font = get_theme_default_font()
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.42, 0.36, 0.26, 1))


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var over_empty := _is_over_empty(at_position)
	if over_empty != _hovering_empty:
		_hovering_empty = over_empty
		queue_redraw()
	if not can_accept_drop or not over_empty:
		return false
	if not (data is Dictionary):
		return false
	var vial_id: String = str(data.get("vial_id", ""))
	return not vial_id.is_empty() and not GeneTree.get_vial(vial_id).is_empty()


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_hovering_empty = false
	queue_redraw()
	if data is Dictionary:
		vial_dropped.emit(str(data.get("vial_id", "")))


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		queue_redraw()
	if what == NOTIFICATION_DRAG_END and _hovering_empty:
		_hovering_empty = false
		queue_redraw()


func _is_over_empty(at_position: Vector2) -> bool:
	if empty_index < 0 or empty_index >= _rung_rects.size():
		return false
	return _rung_rects[empty_index].has_point(at_position)


func _on_mouse_exited() -> void:
	if _hovering_empty:
		_hovering_empty = false
		queue_redraw()
