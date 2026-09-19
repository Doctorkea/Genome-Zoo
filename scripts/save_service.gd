extends Node

## One-slot JSON save under user://. Autoloaded as "SaveService".

const VERSION: int = 1
const PATH: String = "user://zoo.json"

var pending_load: bool = false


func has_save() -> bool:
	return FileAccess.file_exists(PATH)


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func reset_autoloads() -> void:
	GridService.reset()
	WalletService.reset()
	GeneTree.reset()
	QuestBoard.reset()
	TutorialService.reset()


func start_new_game() -> void:
	delete_save()
	pending_load = false
	reset_autoloads()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func continue_game() -> void:
	if not has_save():
		start_new_game()
		return
	pending_load = true
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func return_to_title() -> void:
	save_from_tree()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/Title.tscn")


func save_from_tree() -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	var tree := get_tree()
	if tree == null:
		return false
	var build := tree.get_first_node_in_group("build_mode") as BuildMode
	if build == null:
		return false
	return save_game(build)


func save_game(build: BuildMode) -> bool:
	if build == null:
		return false
	var payload := {
		"version": VERSION,
		"wallet": WalletService.snapshot(),
		"genes": GeneTree.snapshot(),
		"quests": QuestBoard.snapshot(),
		"tutorial": TutorialService.snapshot(),
		"world": build.snapshot_world(),
	}
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload))
	return true


func load_into(build: BuildMode) -> bool:
	if build == null or not has_save():
		return false
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return false
	var data: Dictionary = parsed
	if int(data.get("version", 0)) != VERSION:
		return false
	reset_autoloads()
	WalletService.apply_state(data.get("wallet", {}))
	GeneTree.apply_state(data.get("genes", {}))
	QuestBoard.apply_state(data.get("quests", {}))
	TutorialService.apply_state(data.get("tutorial", {}))
	build.restore_world(data.get("world", {}))
	QuestBoard.evaluate()
	Events.quest_changed.emit()
	return true
