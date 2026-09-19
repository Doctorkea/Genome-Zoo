extends Control

## Game HUD: mode toolbar, click-to-inspect stats panel with a live
## thumbnail, and the DNA Lab minigame panel.
##
## Scene-authored under CanvasLayer on Main (Control root + zoo_theme).
## Full-rect wrappers use MOUSE_FILTER_IGNORE so world clicks still reach
## animals. See .cursor/skills/godot-gui/SKILL.md.

const MUTATE_COST: int = 5
const SHAPE_SLOTS: Array[String] = ["body", "head", "eyes", "front_legs", "back_legs", "tail"]

@onready var _points_label: Label = %MutagenLabel
@onready var _stats_panel: PanelContainer = %StatsPanel
@onready var _stats_name_label: Label = %StatsName
@onready var _stats_parts_label: Label = %StatsParts
@onready var _thumb_viewport: SubViewport = %ThumbViewport
@onready var _thumb_camera: Camera2D = %ThumbCamera
@onready var _lab_panel: PanelContainer = %LabPanel
@onready var _lab_rows: VBoxContainer = %LabRows

var _selected_animal: Animal = null
var _build_mode: BuildMode = null


func _ready() -> void:
	_thumb_viewport.world_2d = get_tree().root.world_2d
	# Children are already in the tree when the Control root runs _ready.
	_thumb_camera.make_current()
	_build_lab_rows()
	Events.animal_selected.connect(_on_animal_selected)
	Events.mutagen_points_changed.connect(_on_points_changed)


func set_build_mode(build_mode: BuildMode) -> void:
	_build_mode = build_mode


func _build_lab_rows() -> void:
	for child in _lab_rows.get_children():
		child.queue_free()
	for slot in SHAPE_SLOTS:
		_lab_rows.add_child(_build_lab_row(slot))
	_lab_rows.add_child(_build_color_row())


func _on_place_small_pen() -> void:
	_set_mode(BuildMode.Mode.PLACE_PEN_SMALL)


func _on_place_large_pen() -> void:
	_set_mode(BuildMode.Mode.PLACE_PEN_LARGE)


func _on_place_animal() -> void:
	_set_mode(BuildMode.Mode.PLACE_ANIMAL)


func _on_cancel() -> void:
	_set_mode(BuildMode.Mode.NONE)


func _set_mode(mode: int) -> void:
	if _build_mode != null:
		_build_mode.set_mode(mode)


func _on_points_changed(points: int) -> void:
	_points_label.text = "Mutagen: %d" % points


func _on_animal_selected(animal: Node) -> void:
	var typed := animal as Animal
	if typed == null:
		return
	_selected_animal = typed
	_stats_panel.visible = true

	var stats: Dictionary = typed.get_stats()
	_stats_name_label.text = stats.get("name", "Unnamed")
	_stats_parts_label.text = ", ".join(stats.get("parts", []))

	_thumb_camera.global_position = typed.global_position


func _build_lab_row(slot: String) -> Control:
	var row := HBoxContainer.new()

	var label := Label.new()
	label.text = slot.capitalize()
	label.custom_minimum_size = Vector2(96, 0)
	row.add_child(label)

	var options_box := HBoxContainer.new()
	row.add_child(options_box)

	var mutate_btn := Button.new()
	mutate_btn.text = "Mutate (%d)" % MUTATE_COST
	mutate_btn.pressed.connect(func(): _on_slot_mutate_pressed(slot, options_box))
	row.add_child(mutate_btn)

	return row


func _on_slot_mutate_pressed(slot: String, options_box: Control) -> void:
	if _selected_animal == null:
		return
	if not MutagenService.spend(MUTATE_COST):
		return

	_clear_children(options_box)

	var count := _selected_animal.visuals.get_option_count(slot)
	for i in range(count):
		var opt_btn := Button.new()
		opt_btn.text = "#%d" % (i + 1)
		opt_btn.pressed.connect(func(): _on_option_picked(slot, i, options_box))
		options_box.add_child(opt_btn)


func _on_option_picked(slot: String, index: int, options_box: Control) -> void:
	if _selected_animal == null:
		return
	_selected_animal.visuals.set_part_shape(slot, index)
	Events.creature_mutated.emit(_selected_animal, slot)
	_clear_children(options_box)
	_on_animal_selected(_selected_animal)


func _build_color_row() -> Control:
	var row := HBoxContainer.new()

	var label := Label.new()
	label.text = "Color"
	label.custom_minimum_size = Vector2(96, 0)
	row.add_child(label)

	var options_box := HBoxContainer.new()
	row.add_child(options_box)

	var mutate_btn := Button.new()
	mutate_btn.text = "Mutate (%d)" % MUTATE_COST
	mutate_btn.pressed.connect(func(): _on_color_mutate_pressed(options_box))
	row.add_child(mutate_btn)

	return row


func _on_color_mutate_pressed(options_box: Control) -> void:
	if _selected_animal == null:
		return
	if not MutagenService.spend(MUTATE_COST):
		return

	_clear_children(options_box)

	var count := PlaceholderArt.get_palette_options().size()
	for i in range(count):
		var opt_btn := Button.new()
		opt_btn.text = "#%d" % (i + 1)
		opt_btn.pressed.connect(func(): _on_color_picked(i, options_box))
		options_box.add_child(opt_btn)


func _on_color_picked(index: int, options_box: Control) -> void:
	if _selected_animal == null:
		return
	_selected_animal.visuals.set_skin(index)
	_clear_children(options_box)


func _on_mutate_pressed() -> void:
	if _selected_animal == null:
		return
	_lab_panel.visible = true


func _on_close_lab() -> void:
	_lab_panel.visible = false


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
