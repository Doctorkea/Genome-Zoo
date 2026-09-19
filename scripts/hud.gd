extends CanvasLayer

## Game HUD: mode toolbar, click-to-inspect stats panel with a live
## thumbnail, and the DNA Lab minigame panel. Built entirely in code —
## see docs/DEMO.md for controls, docs/ui_research.md for the Godot GUI
## patterns this follows (Containers, CanvasLayer, signals over polling).

const MUTATE_COST: int = 5
const SHAPE_SLOTS: Array[String] = ["body", "head", "eyes", "mouth", "front_legs", "back_legs", "tail"]

var _selected_animal: Animal = null
var _build_mode: BuildMode = null

var _points_label: Label
var _stats_panel: PanelContainer
var _stats_name_label: Label
var _stats_parts_label: Label
var _thumb_viewport: SubViewport
var _thumb_camera: Camera2D
var _lab_panel: PanelContainer


func _ready() -> void:
	layer = 10
	_build_toolbar()
	_build_stats_panel()
	_build_lab_panel()
	Events.animal_selected.connect(_on_animal_selected)
	Events.mutagen_points_changed.connect(_on_points_changed)


func set_build_mode(build_mode: BuildMode) -> void:
	_build_mode = build_mode


# ---------------------------------------------------------------------------
# Toolbar
# ---------------------------------------------------------------------------

func _build_toolbar() -> void:
	var bar := HBoxContainer.new()
	bar.position = Vector2(12, 12)
	add_child(bar)

	bar.add_child(_make_mode_button("Place Small Pen", BuildMode.Mode.PLACE_PEN_SMALL))
	bar.add_child(_make_mode_button("Place Large Pen", BuildMode.Mode.PLACE_PEN_LARGE))
	bar.add_child(_make_mode_button("Place Animal", BuildMode.Mode.PLACE_ANIMAL))
	bar.add_child(_make_mode_button("Cancel", BuildMode.Mode.NONE))

	bar.add_child(VSeparator.new())

	_points_label = Label.new()
	_points_label.text = "Mutagen: 0"
	bar.add_child(_points_label)


func _make_mode_button(label: String, mode: int) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.pressed.connect(func(): _on_mode_button_pressed(mode))
	return btn


func _on_mode_button_pressed(mode: int) -> void:
	if _build_mode != null:
		_build_mode.set_mode(mode)


func _on_points_changed(points: int) -> void:
	_points_label.text = "Mutagen: %d" % points


# ---------------------------------------------------------------------------
# Stats / thumbnail panel
# ---------------------------------------------------------------------------

func _build_stats_panel() -> void:
	_stats_panel = PanelContainer.new()
	_stats_panel.position = Vector2(460, 12)
	_stats_panel.visible = false
	add_child(_stats_panel)

	var vbox := VBoxContainer.new()
	_stats_panel.add_child(vbox)

	var thumb_container := SubViewportContainer.new()
	thumb_container.custom_minimum_size = Vector2(96, 96)
	thumb_container.stretch = true
	vbox.add_child(thumb_container)

	_thumb_viewport = SubViewport.new()
	_thumb_viewport.size = Vector2i(96, 96)
	_thumb_viewport.transparent_bg = true
	_thumb_viewport.world_2d = get_tree().root.world_2d
	thumb_container.add_child(_thumb_viewport)

	_thumb_camera = Camera2D.new()
	_thumb_camera.zoom = Vector2(1.6, 1.6)
	_thumb_viewport.add_child(_thumb_camera)
	_thumb_camera.make_current()

	_stats_name_label = Label.new()
	vbox.add_child(_stats_name_label)

	_stats_parts_label = Label.new()
	_stats_parts_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_stats_parts_label.custom_minimum_size = Vector2(180, 0)
	vbox.add_child(_stats_parts_label)

	var mutate_btn := Button.new()
	mutate_btn.text = "Edit DNA"
	mutate_btn.pressed.connect(_on_mutate_pressed)
	vbox.add_child(mutate_btn)


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


# ---------------------------------------------------------------------------
# DNA Lab (minigame)
# ---------------------------------------------------------------------------

func _build_lab_panel() -> void:
	_lab_panel = PanelContainer.new()
	_lab_panel.position = Vector2(180, 100)
	_lab_panel.visible = false
	add_child(_lab_panel)

	var vbox := VBoxContainer.new()
	_lab_panel.add_child(vbox)

	var title := Label.new()
	title.text = "DNA Lab"
	vbox.add_child(title)

	for slot in SHAPE_SLOTS:
		vbox.add_child(_build_lab_row(slot))

	vbox.add_child(_build_color_row())

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func(): _lab_panel.visible = false)
	vbox.add_child(close_btn)


func _build_lab_row(slot: String) -> Control:
	var row := HBoxContainer.new()

	var label := Label.new()
	label.text = slot.capitalize()
	label.custom_minimum_size = Vector2(70, 0)
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
	_on_animal_selected(_selected_animal) # refresh the stats panel text


func _build_color_row() -> Control:
	var row := HBoxContainer.new()

	var label := Label.new()
	label.text = "Color"
	label.custom_minimum_size = Vector2(70, 0)
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


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
