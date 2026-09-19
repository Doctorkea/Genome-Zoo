extends Control

## Boot menu. New zoo, continue, quit.

@onready var _continue: Button = %ContinueButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	_continue.disabled = not SaveService.has_save()


func _on_new_zoo() -> void:
	SaveService.start_new_game()


func _on_continue() -> void:
	SaveService.continue_game()


func _on_quit() -> void:
	get_tree().quit()
