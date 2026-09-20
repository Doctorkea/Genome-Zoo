extends Node

## Timestamped JSON slots under user://saves. Autoloaded as "SaveService".

const VERSION: int = 1
const SAVE_DIR: String = "user://saves"
const LEGACY_PATH: String = "user://zoo.json"
const DEFAULT_ZOO_NAME: String = "Evolution Zoo"
const NAME_MAX: int = 20
const MONTHS: Array[String] = [
	"Jan", "Feb", "Mar", "Apr", "May", "Jun",
	"Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
]

var directory: String = SAVE_DIR
var pending_load: bool = false
var pending_path: String = ""
var zoo_name: String = DEFAULT_ZOO_NAME
var clones: Array[Dictionary] = []


func has_save() -> bool:
	return not list_saves().is_empty()


func clear_saves() -> void:
	var dir := DirAccess.open(directory)
	if dir != null:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	if directory == SAVE_DIR and FileAccess.file_exists(LEGACY_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_PATH))


func delete_save() -> void:
	clear_saves()


func reset_autoloads() -> void:
	GridService.reset()
	WalletService.reset()
	GeneTree.reset()
	QuestBoard.reset()
	TutorialService.reset()
	clones.clear()
	set_zoo_name(DEFAULT_ZOO_NAME)


func start_new_game() -> void:
	pending_load = false
	pending_path = ""
	reset_autoloads()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func continue_game() -> void:
	var saves: Array[Dictionary] = list_saves()
	if saves.is_empty():
		start_new_game()
		return
	continue_from(str(saves[0].get("path", "")))


func continue_from(path: String) -> void:
	if path.is_empty() or not FileAccess.file_exists(path):
		return
	pending_path = path
	pending_load = true
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func return_to_title() -> void:
	pending_load = false
	pending_path = ""
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
	_ensure_dir()
	var saved_at: int = int(Time.get_unix_time_from_system())
	var payload := {
		"version": VERSION,
		"zoo_name": zoo_name,
		"saved_at": saved_at,
		"wallet": WalletService.snapshot(),
		"genes": GeneTree.snapshot(),
		"quests": QuestBoard.snapshot(),
		"tutorial": TutorialService.snapshot(),
		"clones": clones.duplicate(true),
		"world": build.snapshot_world(),
	}
	var path: String = _new_save_path(zoo_name, saved_at)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload))
	return true


func load_into(build: BuildMode, path: String = "") -> bool:
	if build == null:
		return false
	var use_path: String = path
	if use_path.is_empty():
		use_path = pending_path
	pending_path = ""
	if use_path.is_empty() or not FileAccess.file_exists(use_path):
		return false
	var file := FileAccess.open(use_path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return false
	var data: Dictionary = parsed
	if int(data.get("version", 0)) != VERSION:
		return false
	reset_autoloads()
	set_zoo_name(str(data.get("zoo_name", DEFAULT_ZOO_NAME)))
	WalletService.apply_state(data.get("wallet", {}))
	GeneTree.apply_state(data.get("genes", {}))
	QuestBoard.apply_state(data.get("quests", {}))
	TutorialService.apply_state(data.get("tutorial", {}))
	_apply_clones(data.get("clones", []))
	build.restore_world(data.get("world", {}))
	QuestBoard.evaluate()
	Events.quest_changed.emit()
	return true


func list_saves() -> Array[Dictionary]:
	_migrate_legacy()
	var out: Array[Dictionary] = []
	var dir := DirAccess.open(directory)
	if dir == null:
		return out
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var meta: Dictionary = read_save_meta(directory.path_join(file_name))
			if not meta.is_empty():
				out.append(meta)
		file_name = dir.get_next()
	dir.list_dir_end()
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("saved_at", 0)) > int(b.get("saved_at", 0))
	)
	return out


func read_save_meta(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return {}
	var data: Dictionary = parsed
	var name_text: String = str(data.get("zoo_name", DEFAULT_ZOO_NAME))
	if name_text.strip_edges().is_empty():
		name_text = DEFAULT_ZOO_NAME
	var saved_at: int = int(data.get("saved_at", 0))
	if saved_at <= 0:
		saved_at = int(FileAccess.get_modified_time(path))
	return {
		"path": path,
		"zoo_name": name_text,
		"saved_at": saved_at,
		"label": save_label(name_text, saved_at),
	}


func save_label(name_text: String, saved_at: int) -> String:
	return "%s\n%s" % [name_text, format_save_clock(saved_at)]


func format_save_clock(saved_at: int) -> String:
	var bias_minutes: int = int(Time.get_time_zone_from_system().get("bias", 0))
	var local_unix: int = saved_at + bias_minutes * 60
	var stamp: Dictionary = Time.get_datetime_dict_from_unix_time(local_unix)
	var month_index: int = clampi(int(stamp.get("month", 1)) - 1, 0, MONTHS.size() - 1)
	var hour_24: int = int(stamp.get("hour", 0))
	var suffix: String = "am"
	if hour_24 >= 12:
		suffix = "pm"
	var hour_12: int = hour_24 % 12
	if hour_12 == 0:
		hour_12 = 12
	return "%d %s %d, %d:%02d%s" % [
		int(stamp.get("day", 1)),
		MONTHS[month_index],
		int(stamp.get("year", 2026)),
		hour_12,
		int(stamp.get("minute", 0)),
		suffix,
	]


func set_zoo_name(value: String) -> void:
	var cleaned := clean_name(value, DEFAULT_ZOO_NAME)
	if zoo_name == cleaned:
		Events.zoo_renamed.emit(zoo_name)
		return
	zoo_name = cleaned
	Events.zoo_renamed.emit(zoo_name)


func clean_name(value: String, fallback: String = "Unnamed") -> String:
	var cleaned := value.strip_edges()
	if cleaned.is_empty():
		cleaned = fallback
	if cleaned.length() > NAME_MAX:
		cleaned = cleaned.substr(0, NAME_MAX).strip_edges()
		if cleaned.is_empty():
			cleaned = fallback
	return cleaned


func child_name(first: String, second: String) -> String:
	var left: String = clean_name(first, "Unnamed")
	var right: String = clean_name(second, "Unnamed")
	var joined: String = "%s-%s" % [left, right]
	if joined.length() <= NAME_MAX:
		return joined
	var budget: int = NAME_MAX - 1
	var left_keep: int = maxi(1, budget / 2)
	var right_keep: int = maxi(1, budget - left_keep)
	return "%s-%s" % [left.substr(0, left_keep), right.substr(0, right_keep)]


func add_clone_from(animal: Animal) -> Dictionary:
	if animal == null or not is_instance_valid(animal) or animal.visuals == null:
		return {}
	var clone_id: String = "clone_%d_%d" % [int(Time.get_unix_time_from_system()), clones.size() + 1]
	var parts: Dictionary = {}
	var hidden: Array = []
	for slot in animal.visuals.get_slots():
		parts[slot] = animal.visuals.get_current_index(slot)
		if not animal.visuals.is_slot_visible(slot):
			hidden.append(slot)
	var item := {
		"id": clone_id,
		"category": BuildCatalog.CAT_ANIMALS,
		"kind": "animal",
		"name": clean_name(animal.creature_name, "Clone"),
		"blurb": "Cloned in the DNA Lab",
		"cost": 100,
		"parts": parts,
		"color": animal.visuals.get_current_palette_index(),
		"hide": hidden,
		"perks": Array(animal.perks),
		"cloned": true,
	}
	clones.append(item)
	return item


func _apply_clones(raw: Variant) -> void:
	clones.clear()
	if not (raw is Array):
		return
	for row in raw:
		if row is Dictionary:
			var copy: Dictionary = (row as Dictionary).duplicate(true)
			copy["cost"] = 100
			copy["cloned"] = true
			clones.append(copy)


func _ensure_dir() -> void:
	var abs_path: String = ProjectSettings.globalize_path(directory)
	if not DirAccess.dir_exists_absolute(abs_path):
		DirAccess.make_dir_recursive_absolute(abs_path)


func _migrate_legacy() -> void:
	if directory != SAVE_DIR:
		return
	if not FileAccess.file_exists(LEGACY_PATH):
		return
	_ensure_dir()
	var dest: String = directory.path_join("legacy_zoo.json")
	if not FileAccess.file_exists(dest):
		var src := FileAccess.open(LEGACY_PATH, FileAccess.READ)
		var dst := FileAccess.open(dest, FileAccess.WRITE)
		if src != null and dst != null:
			dst.store_string(src.get_as_text())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_PATH))


func _new_save_path(name_text: String, saved_at: int) -> String:
	var stamp_dict: Dictionary = Time.get_datetime_dict_from_unix_time(saved_at)
	var stamp: String = "%04d%02d%02dT%02d%02d%02d" % [
		int(stamp_dict.get("year", 2026)),
		int(stamp_dict.get("month", 1)),
		int(stamp_dict.get("day", 1)),
		int(stamp_dict.get("hour", 0)),
		int(stamp_dict.get("minute", 0)),
		int(stamp_dict.get("second", 0)),
	]
	var slug: String = _slug(name_text)
	var path: String = directory.path_join("%s_%s.json" % [stamp, slug])
	var extra: int = 2
	while FileAccess.file_exists(path):
		path = directory.path_join("%s_%s_%d.json" % [stamp, slug, extra])
		extra += 1
	return path


func _slug(name_text: String) -> String:
	var out: String = ""
	for i in name_text.length():
		var ch: String = name_text.substr(i, 1).to_lower()
		var code: int = ch.unicode_at(0)
		var letter: bool = code >= 97 and code <= 122
		var digit: bool = code >= 48 and code <= 57
		if letter or digit:
			out += ch
		elif out.is_empty() or not out.ends_with("_"):
			out += "_"
	out = out.strip_edges()
	while out.begins_with("_"):
		out = out.substr(1)
	while out.ends_with("_"):
		out = out.substr(0, out.length() - 1)
	if out.is_empty():
		return "zoo"
	return out
