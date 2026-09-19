extends Control

## Game HUD: top resource plaque, bottom build dock, right exhibit card,
## and a DNA Lab workbench. Layout follows zoo/tycoon conventions
## (Prison Architect, Planet Zoo, Two Point Hospital) with a Spore-style
## part palette for mutations. See .cursor/skills/godot-gui/SKILL.md.

const MUTATE_COST: int = 5
const FILL_GOOD := Color(0.247, 0.478, 0.29, 1)
const FILL_BAD := Color(0.769, 0.271, 0.212, 1)

@onready var _points_label: Label = %MutagenLabel
@onready var _stats_panel: PanelContainer = %StatsPanel
@onready var _stats_name_label: Label = %StatsName
@onready var _stats_archetype_label: Label = %StatsArchetype
@onready var _stats_tags_label: Label = %StatsTags
@onready var _stats_parts_label: Label = %StatsParts
@onready var _families_bar: ProgressBar = %FamiliesBar
@onready var _families_value: Label = %FamiliesValue
@onready var _thrill_bar: ProgressBar = %ThrillBar
@onready var _thrill_value: Label = %ThrillValue
@onready var _thumb_viewport: SubViewport = %ThumbViewport
@onready var _thumb_camera: Camera2D = %ThumbCamera
@onready var _lab_panel: PanelContainer = %LabPanel
@onready var _lab_slots: Container = %LabSlots
@onready var _lab_rows: Container = %LabRows
@onready var _lab_hint: Label = %LabHint
@onready var _lab_subject: Label = %LabSubject
@onready var _hint_label: Label = %HintLabel
@onready var _btn_small: Button = %PlaceSmallPen
@onready var _btn_large: Button = %PlaceLargePen
@onready var _btn_animal: Button = %PlaceAnimal

var _selected_animal: Animal = null
var _build_mode: BuildMode = null
var _active_lab_slot: String = ""
var _slot_buttons: Dictionary = {} # slot -> Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thumb_viewport.world_2d = get_tree().root.world_2d
	_thumb_camera.make_current()
	_ink_paper_labels(_stats_panel)
	_ink_paper_labels(_lab_panel)
	_build_lab_slots()
	Events.animal_selected.connect(_on_animal_selected)
	Events.mutagen_points_changed.connect(_on_points_changed)
	_on_points_changed(MutagenService.points)


func _ink_paper_labels(root: Node) -> void:
	var ink := Color(0.11, 0.09, 0.063, 1)
	var muted := Color(0.42, 0.36, 0.26, 1)
	for node in root.find_children("*", "Label", true, false):
		var label := node as Label
		if label == null:
			continue
		if label.theme_type_variation == "PaperMuted":
			label.add_theme_color_override("font_color", muted)
		else:
			label.add_theme_color_override("font_color", ink)


func set_build_mode(build_mode: BuildMode) -> void:
	_build_mode = build_mode
	_refresh_tool_buttons()


func _on_place_small_pen() -> void:
	_toggle_mode(BuildMode.Mode.PLACE_PEN_SMALL)


func _on_place_large_pen() -> void:
	_toggle_mode(BuildMode.Mode.PLACE_PEN_LARGE)


func _on_place_animal() -> void:
	_toggle_mode(BuildMode.Mode.PLACE_ANIMAL)


func _on_cancel() -> void:
	_set_mode(BuildMode.Mode.NONE)


func _toggle_mode(mode: int) -> void:
	if _build_mode != null and _build_mode.current_mode == mode:
		_set_mode(BuildMode.Mode.NONE)
	else:
		_set_mode(mode)


func _set_mode(mode: int) -> void:
	if _build_mode != null:
		_build_mode.set_mode(mode)
	_refresh_tool_buttons()


func _refresh_tool_buttons() -> void:
	var mode: int = _build_mode.current_mode if _build_mode != null else BuildMode.Mode.NONE
	_btn_small.set_pressed_no_signal(mode == BuildMode.Mode.PLACE_PEN_SMALL)
	_btn_large.set_pressed_no_signal(mode == BuildMode.Mode.PLACE_PEN_LARGE)
	_btn_animal.set_pressed_no_signal(mode == BuildMode.Mode.PLACE_ANIMAL)


func _on_points_changed(points: int) -> void:
	_points_label.text = str(points)
	_refresh_slot_affordability(points)


func _refresh_slot_affordability(points: int) -> void:
	var can_afford := points >= MUTATE_COST
	for slot in _slot_buttons:
		var btn: Button = _slot_buttons[slot]
		if is_instance_valid(btn):
			btn.disabled = not can_afford
			btn.tooltip_text = "" if can_afford else "Need %d mutagen" % MUTATE_COST


func _on_animal_selected(animal: Node) -> void:
	var typed := animal as Animal
	if typed == null:
		return
	_selected_animal = typed
	_stats_panel.visible = true
	_hint_label.visible = false
	_refresh_inspect()
	if _lab_panel.visible:
		_refresh_lab_header()


func _refresh_inspect() -> void:
	if _selected_animal == null:
		return
	var stats: Dictionary = _selected_animal.get_stats()
	_stats_name_label.text = stats.get("name", "Unnamed")
	_stats_archetype_label.text = str(stats.get("archetype", "Unspecialized"))
	_stats_tags_label.text = TraitLibrary.format_tags(stats.get("tags", {}))
	_stats_parts_label.text = ", ".join(stats.get("parts", []))
	_set_meter(_families_bar, _families_value, int(stats.get("families", 0)))
	_set_meter(_thrill_bar, _thrill_value, int(stats.get("thrill", 0)))
	_thumb_camera.global_position = _selected_animal.global_position


func _set_meter(bar: ProgressBar, value_label: Label, score: int) -> void:
	bar.value = clampf(float(score), bar.min_value, bar.max_value)
	value_label.text = _signed(score)
	var fill := StyleBoxFlat.new()
	fill.bg_color = FILL_GOOD if score >= 0 else FILL_BAD
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", fill)


func _signed(value: int) -> String:
	if value > 0:
		return "+%d" % value
	return str(value)


func _on_deselect() -> void:
	_selected_animal = null
	_stats_panel.visible = false
	_hint_label.visible = true
	_on_close_lab()


func _on_mutate_pressed() -> void:
	if _selected_animal == null:
		return
	_lab_panel.visible = true
	_refresh_lab_header()
	_clear_children(_lab_rows)
	_lab_hint.text = "Pick a body slot. Drafting costs %d mutagen and shows three options." % MUTATE_COST
	_active_lab_slot = ""
	_refresh_slot_toggles()


func _on_close_lab() -> void:
	_lab_panel.visible = false
	_active_lab_slot = ""
	_clear_children(_lab_rows)
	_refresh_slot_toggles()


func _refresh_lab_header() -> void:
	if _selected_animal == null:
		_lab_subject.text = ""
		return
	_lab_subject.text = _selected_animal.creature_name


func _build_lab_slots() -> void:
	for child in _lab_slots.get_children():
		child.queue_free()
	_slot_buttons.clear()
	var slots: Array[String] = TraitLibrary.SHAPE_SLOTS.duplicate()
	slots.append(TraitLibrary.COLOR_SLOT)
	for slot in slots:
		var btn := Button.new()
		btn.toggle_mode = true
		btn.text = TraitLibrary.slot_display_name(slot)
		btn.pressed.connect(_on_lab_slot_pressed.bind(slot))
		_lab_slots.add_child(btn)
		_slot_buttons[slot] = btn
	_refresh_slot_affordability(MutagenService.points)


func _on_lab_slot_pressed(slot: String) -> void:
	if _selected_animal == null:
		return
	if not MutagenService.can_afford(MUTATE_COST):
		_lab_hint.text = "Need %d mutagen to draft this slot." % MUTATE_COST
		_refresh_slot_toggles()
		return
	if not MutagenService.spend(MUTATE_COST):
		return
	_active_lab_slot = slot
	_refresh_slot_toggles()
	_show_draft(slot)


func _refresh_slot_toggles() -> void:
	for slot in _slot_buttons:
		var btn: Button = _slot_buttons[slot]
		if is_instance_valid(btn):
			btn.set_pressed_no_signal(slot == _active_lab_slot)


func _show_draft(slot: String) -> void:
	_clear_children(_lab_rows)
	var current_index := _current_index_for_slot(slot)
	var option: Dictionary = TraitLibrary.get_option(slot, current_index)
	_lab_hint.text = "Current %s: %s. Pick a replacement." % [
		TraitLibrary.slot_display_name(slot).to_lower(),
		option.get("name", "?"),
	]
	var count := TraitLibrary.get_option_count(slot)
	for i in range(count):
		_lab_rows.add_child(_make_option_card(slot, i, i == current_index))


func _make_option_card(slot: String, index: int, is_current: bool) -> Button:
	var option := TraitLibrary.get_option(slot, index)
	var tags: Array = option.get("tags", [])
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(200, 72)
	btn.toggle_mode = true
	btn.button_pressed = is_current
	btn.text = "%s\n%s" % [option.get("name", "?"), ", ".join(tags)]
	btn.pressed.connect(_on_option_card_picked.bind(slot, index))
	return btn


func _on_option_card_picked(slot: String, index: int) -> void:
	if _selected_animal == null:
		return
	if slot == TraitLibrary.COLOR_SLOT:
		_selected_animal.visuals.set_skin(index)
	else:
		_selected_animal.visuals.set_part_shape(slot, index)
	Events.creature_mutated.emit(_selected_animal, slot)
	_refresh_inspect()
	_show_draft(slot)


func _current_index_for_slot(slot: String) -> int:
	if _selected_animal == null:
		return 0
	if slot == TraitLibrary.COLOR_SLOT:
		return _selected_animal.visuals.get_current_palette_index()
	return _selected_animal.visuals.get_current_index(slot)


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
