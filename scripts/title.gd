extends Control

## Boot menu. New game, load save, exit.

const SavePickerScript := preload("res://scripts/save_picker.gd")

@onready var _picker: SavePickerScript = %SavePicker


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	_picker.save_chosen.connect(_on_save_chosen)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _picker.visible:
		_picker.close()
		get_viewport().set_input_as_handled()


func _on_new_game() -> void:
	SaveService.start_new_game()


func _on_load_save() -> void:
	_picker.open.call_deferred()


func _on_save_chosen(path: String) -> void:
	SaveService.continue_from(path)


func _on_quit() -> void:
	get_tree().quit()
