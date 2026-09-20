extends Control
class_name SavePicker

## Shared load list for the title screen and pause menu.

signal save_chosen(path: String)
signal closed

@onready var _list: VBoxContainer = %SaveList
@onready var _empty: Label = %SaveEmpty
@onready var _scroll: ScrollContainer = %SaveScroll


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func open() -> void:
	visible = true
	_rebuild()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _rebuild() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var saves: Array[Dictionary] = SaveService.list_saves()
	var empty: bool = saves.is_empty()
	_empty.visible = empty
	_scroll.visible = not empty
	for save in saves:
		var btn := Button.new()
		btn.text = str(save.get("label", "Save"))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 52)
		btn.pressed.connect(_on_pick.bind(str(save.get("path", ""))))
		_list.add_child(btn)


func _on_pick(path: String) -> void:
	if path.is_empty():
		return
	visible = false
	save_chosen.emit(path)


func _on_back() -> void:
	close()


func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			close()
