extends Node2D
class_name BuildMode

## Pen and animal placement from the bottom catalog. Cash is spent on a
## successful place. Ghost preview snaps to the grid. See docs/DEMO.md.

enum Mode { NONE, PLACE_PEN_SMALL, PLACE_PEN_LARGE, PLACE_ANIMAL, PLACE_PATH, PLACE_PARK }

const PEN_SCENE: PackedScene = preload("res://scenes/Pen.tscn")
const ANIMAL_SCENE: PackedScene = preload("res://scenes/Animal.tscn")
const PARK_SCRIPT: GDScript = preload("res://scripts/park_object.gd")
const ZooFx := preload("res://scripts/fx.gd")
const PATH_TEXTURES: Array[Texture2D] = [
	preload("res://art/tiles/paths/path_1.png"),
	preload("res://art/tiles/paths/path_2.png"),
	preload("res://art/tiles/paths/path_3.png"),
	preload("res://art/tiles/paths/path_4.png"),
]

var current_mode: int = Mode.NONE
var current_item_id: String = ""

var _pens: Array[Pen] = []
var _animal_count: int = 0
var _path_tiles: Dictionary = {} # Vector2i -> Sprite2D
var _park_objects: Dictionary = {} # Vector2i -> ParkObject
var _last_path_cell := Vector2i(-999, -999)

@onready var _ghost: Polygon2D = Polygon2D.new()


func _ready() -> void:
	add_to_group("build_mode")
	_ghost.color = Color(1, 1, 1, 0.35)
	_ghost.visible = false
	add_child(_ghost)


func set_item(item_id: String) -> void:
	if current_item_id == item_id:
		item_id = ""
	current_item_id = item_id
	_sync_mode()
	_ghost.visible = false
	Events.build_tool_changed.emit(current_item_id)


func clear_tool() -> void:
	if current_item_id.is_empty() and current_mode == Mode.NONE:
		return
	current_item_id = ""
	_sync_mode()
	_ghost.visible = false
	_last_path_cell = Vector2i(-999, -999)
	Events.build_tool_changed.emit("")


func set_mode(mode: int) -> void:
	match mode:
		Mode.PLACE_PEN_SMALL:
			set_item("pen_small")
		Mode.PLACE_PEN_LARGE:
			set_item("pen_large")
		Mode.PLACE_ANIMAL:
			set_item("jimothy")
		_:
			clear_tool()


func _sync_mode() -> void:
	var item: Dictionary = BuildCatalog.get_item(current_item_id)
	var kind: String = str(item.get("kind", ""))
	match kind:
		"pen":
			var size: Vector2i = item.get("size_cells", Vector2i(4, 3))
			current_mode = Mode.PLACE_PEN_LARGE if size.x >= 6 else Mode.PLACE_PEN_SMALL
		"animal":
			current_mode = Mode.PLACE_ANIMAL
		"path":
			current_mode = Mode.PLACE_PATH
		"park":
			current_mode = Mode.PLACE_PARK
		_:
			current_mode = Mode.NONE


## Test helper: places a small pen and one Jimothy without charging cash.
func spawn_starter_exhibit() -> Animal:
	var origin_cell := Vector2i(4, 2)
	var size_cells := Vector2i(4, 3)
	var pen := PEN_SCENE.instantiate() as Pen
	pen.footprint_cells = size_cells
	pen.origin_cell = origin_cell
	pen.catalog_id = "pen_small"
	pen.listed_capacity = 2
	pen.position = GridService.cell_to_world(origin_cell)
	add_child(pen)
	GridService.occupy_area(origin_cell, size_cells, pen)
	_pens.append(pen)

	var animal := ANIMAL_SCENE.instantiate() as Animal
	pen.add_child(animal)
	var interior: Rect2 = pen.get_interior_bounds()
	animal.position = interior.position + interior.size * 0.5
	animal.set_pen(pen)
	_apply_species(animal, BuildCatalog.get_item("jimothy"))
	animal.catalog_id = "jimothy"
	_animal_count += 1
	pen.register_animal(animal)
	return animal


func _process(_delta: float) -> void:
	var over_gui := get_viewport().gui_get_hovered_control() != null
	if over_gui or current_mode == Mode.NONE:
		_ghost.visible = false
		return
	_ghost.visible = true
	if current_mode == Mode.PLACE_ANIMAL:
		_update_animal_ghost()
	else:
		_update_pen_ghost()
	if current_mode == Mode.PLACE_PATH and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_try_place_path()


func _update_pen_ghost() -> void:
	var item: Dictionary = BuildCatalog.get_item(current_item_id)
	var size_cells: Vector2i = item.get("size_cells", Vector2i(4, 3))
	if current_mode == Mode.PLACE_PATH:
		var path_cell := GridService.world_to_path_cell(get_global_mouse_position())
		var path_px := float(GridService.PATH_CELL_SIZE)
		_ghost.position = GridService.path_cell_to_world(path_cell)
		_ghost.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(path_px, 0), Vector2(path_px, path_px), Vector2(0, path_px)
		])
		var path_ok := GridService.is_path_placeable(path_cell)
		_ghost.color = Color(0.2, 1.0, 0.3, 0.35) if path_ok else Color(1.0, 0.2, 0.2, 0.35)
		return
	if current_mode == Mode.PLACE_PARK:
		var prop_cell := GridService.world_to_cell(get_global_mouse_position())
		var cell_px := float(GridService.CELL_SIZE)
		_ghost.position = GridService.cell_to_world(prop_cell)
		_ghost.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(cell_px, 0), Vector2(cell_px, cell_px), Vector2(0, cell_px)
		])
		var prop_ok := GridService.is_prop_placeable(prop_cell)
		_ghost.color = Color(0.2, 1.0, 0.3, 0.35) if prop_ok else Color(1.0, 0.2, 0.2, 0.35)
		return
	var origin_cell := GridService.world_to_cell(get_global_mouse_position())
	var world_pos := GridService.cell_to_world(origin_cell)
	var size_px := Vector2(size_cells.x * GridService.CELL_SIZE, size_cells.y * GridService.CELL_SIZE)
	_ghost.position = world_pos
	_ghost.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(size_px.x, 0), Vector2(size_px.x, size_px.y), Vector2(0, size_px.y)
	])
	var valid := GridService.is_area_placeable(origin_cell, size_cells)
	_ghost.color = Color(0.2, 1.0, 0.3, 0.35) if valid else Color(1.0, 0.2, 0.2, 0.35)


func _update_animal_ghost() -> void:
	var mouse_world := get_global_mouse_position()
	_ghost.position = mouse_world
	_ghost.polygon = PackedVector2Array([
		Vector2(-36, -28), Vector2(36, -28), Vector2(36, 28), Vector2(-36, 28)
	])
	var pen := _find_pen_at(mouse_world)
	var valid := pen != null and pen.can_accept_animal()
	_ghost.color = Color(0.2, 1.0, 0.3, 0.35) if valid else Color(1.0, 0.2, 0.2, 0.35)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		match current_mode:
			Mode.PLACE_PEN_SMALL, Mode.PLACE_PEN_LARGE:
				_try_place_pen()
			Mode.PLACE_ANIMAL:
				_try_place_animal()
			Mode.PLACE_PATH:
				_last_path_cell = Vector2i(-999, -999)
				_try_place_path()
			Mode.PLACE_PARK:
				_try_place_park()
			Mode.NONE:
				var pen := _find_pen_at(get_global_mouse_position())
				if pen != null:
					Events.pen_selected.emit(pen)


func _try_place_pen() -> void:
	var item: Dictionary = BuildCatalog.get_item(current_item_id)
	if item.is_empty():
		return
	var size_cells: Vector2i = item.get("size_cells", Vector2i(4, 3))
	var origin_cell := GridService.world_to_cell(get_global_mouse_position())
	if not GridService.is_area_placeable(origin_cell, size_cells):
		Events.placement_rejected.emit("That pen doesn't fit there.")
		return
	var cost: int = int(item.get("cost", 0))
	if not WalletService.spend(cost):
		Events.placement_rejected.emit("Need $%d for a %s." % [cost, item.get("name", "pen")])
		clear_tool()
		return

	var pen := PEN_SCENE.instantiate() as Pen
	pen.footprint_cells = size_cells
	pen.origin_cell = origin_cell
	pen.catalog_id = str(item.get("id", "pen_small"))
	pen.listed_capacity = int(item.get("capacity", 0))
	pen.enjoyment_bonus = float(item.get("enjoyment_bonus", 0.0))
	pen.position = GridService.cell_to_world(origin_cell)
	add_child(pen)
	GridService.occupy_area(origin_cell, size_cells, pen)
	_clear_path_sprites(origin_cell, size_cells)
	_clear_park_objects(origin_cell, size_cells)
	_pens.append(pen)
	crush_visitors_in_rect(pen.world_rect())
	Events.placement_succeeded.emit(current_item_id)
	TutorialService.on_pen_placed()
	ZooFx.pen_poof(pen, pen.get_size_pixels())
	_clear_if_broke(item)


func _try_place_animal() -> void:
	place_animal_at(get_global_mouse_position())


func _try_place_path() -> void:
	place_path_at(GridService.world_to_path_cell(get_global_mouse_position()))


func place_path_at(cell: Vector2i) -> bool:
	if current_mode != Mode.PLACE_PATH and str(BuildCatalog.get_item(current_item_id).get("kind", "")) != "path":
		return false
	if cell == _last_path_cell:
		return false
	if not GridService.is_path_placeable(cell):
		return false
	var item: Dictionary = BuildCatalog.get_item(current_item_id)
	if item.is_empty():
		item = BuildCatalog.get_item("path_stone")
	var cost: int = int(item.get("cost", 0))
	if not WalletService.spend(cost):
		Events.placement_rejected.emit("Need $%d for a path tile." % cost)
		clear_tool()
		return false
	GridService.add_path(cell)
	var tex_index: int = randi() % PATH_TEXTURES.size()
	var sprite := _make_path_sprite(cell, tex_index)
	add_child(sprite)
	_path_tiles[cell] = sprite
	_last_path_cell = cell
	Events.placement_succeeded.emit(str(item.get("id", "path_stone")))
	ZooFx.burst(sprite, ZooFx.Kind.DUST)
	_clear_if_broke(item)
	return true


func _make_path_sprite(cell: Vector2i, tex_index: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	var idx: int = tex_index % PATH_TEXTURES.size()
	sprite.texture = PATH_TEXTURES[idx]
	sprite.set_meta("tex_index", idx)
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.position = GridService.path_cell_center(cell)
	sprite.rotation = float(randi() % 4) * TAU * 0.25
	sprite.flip_h = randi() % 2 == 0
	var tex_size := sprite.texture.get_size()
	if tex_size.x > 0.0 and tex_size.y > 0.0:
		var tile_px := float(GridService.PATH_CELL_SIZE)
		sprite.scale = Vector2(tile_px / tex_size.x, tile_px / tex_size.y)
	sprite.z_index = 0
	return sprite


func _clear_path_sprites(origin_cell: Vector2i, size_cells: Vector2i) -> void:
	var origin := GridService.cell_to_world(origin_cell)
	var size := Vector2(size_cells.x * GridService.CELL_SIZE, size_cells.y * GridService.CELL_SIZE)
	var area := Rect2(origin, size)
	var stale: Array[Vector2i] = []
	for cell in _path_tiles.keys():
		if area.has_point(GridService.path_cell_center(cell)):
			stale.append(cell)
	for cell in stale:
		var sprite: Sprite2D = _path_tiles[cell]
		_path_tiles.erase(cell)
		if sprite != null and is_instance_valid(sprite):
			sprite.queue_free()


func place_animal_at(world_pos: Vector2) -> bool:
	var item: Dictionary = BuildCatalog.get_item(current_item_id)
	if item.is_empty() or str(item.get("kind", "")) != "animal":
		return false
	var pen := _find_pen_at(world_pos)
	if pen == null:
		Events.placement_rejected.emit("Drop them inside a pen.")
		return false
	if not pen.can_accept_animal():
		Events.placement_rejected.emit("This pen is full (%d/%d)." % [pen.occupant_count(), pen.animal_capacity()])
		return false
	var cost: int = int(item.get("cost", 0))
	if not WalletService.spend(cost):
		Events.placement_rejected.emit("Need $%d for a %s." % [cost, item.get("name", "animal")])
		clear_tool()
		return false

	var animal := ANIMAL_SCENE.instantiate() as Animal
	pen.add_child(animal)
	animal.position = pen.to_local(world_pos)
	animal.set_pen(pen)
	animal.catalog_id = str(item.get("id", ""))
	_apply_species(animal, item)
	_animal_count += 1
	pen.register_animal(animal)
	Events.placement_succeeded.emit(current_item_id)
	TutorialService.on_animal_placed()
	ZooFx.burst(animal, ZooFx.Kind.DUST, Vector2(0.0, 18.0))
	clear_tool()
	return true


func _apply_species(animal: Animal, item: Dictionary) -> void:
	animal.creature_name = str(item.get("name", "Unnamed"))
	var parts: Dictionary = item.get("parts", {})
	var hidden: Array = item.get("hide", [])
	animal.visuals.apply_loadout(parts, int(item.get("color", 0)), hidden)


func _clear_if_broke(item: Dictionary) -> void:
	var cost: int = int(item.get("cost", 0))
	if not WalletService.can_afford(cost):
		clear_tool()


func delete_animal(animal: Animal) -> void:
	if animal == null or not is_instance_valid(animal):
		return
	var pen := animal.get_pen()
	if pen != null:
		pen.unregister_animal(animal)
	_animal_count = maxi(0, _animal_count - 1)
	animal.queue_free()


func delete_pen(pen: Pen) -> void:
	if pen == null or not is_instance_valid(pen):
		return
	for occupant in pen.animals.duplicate():
		var animal := occupant as Animal
		if animal != null and is_instance_valid(animal):
			delete_animal(animal)
	GridService.free_area(pen.origin_cell, pen.footprint_cells, pen)
	_pens.erase(pen)
	pen.queue_free()


func crush_visitors_in_rect(world_rect: Rect2) -> int:
	var crushed: int = 0
	for node in get_tree().get_nodes_in_group("visitors"):
		var guest := node as Visitor
		if guest == null or not is_instance_valid(guest):
			continue
		if guest.overlaps_world_rect(world_rect.grow(8.0)):
			guest.crush()
			crushed += 1
	return crushed


func _find_pen_at(world_pos: Vector2) -> Pen:
	for pen in _pens:
		var local := pen.to_local(world_pos)
		var rect := Rect2(Vector2.ZERO, pen.get_size_pixels())
		if rect.has_point(local):
			return pen
	return null


func _try_place_park() -> void:
	place_park_at(GridService.world_to_cell(get_global_mouse_position()))


func place_park_at(cell: Vector2i) -> bool:
	if str(BuildCatalog.get_item(current_item_id).get("kind", "")) != "park":
		return false
	if not GridService.is_prop_placeable(cell):
		Events.placement_rejected.emit("That spot is taken.")
		return false
	var item: Dictionary = BuildCatalog.get_item(current_item_id)
	var cost: int = int(item.get("cost", 0))
	if not WalletService.spend(cost):
		Events.placement_rejected.emit("Need $%d for a %s." % [cost, item.get("name", "object")])
		clear_tool()
		return false
	_spawn_park(str(item.get("id", "")), cell)
	Events.placement_succeeded.emit(str(item.get("id", "")))
	var prop: Node2D = _park_objects.get(cell) as Node2D
	if prop != null:
		ZooFx.burst(prop, ZooFx.Kind.DUST, Vector2(GridService.CELL_SIZE, GridService.CELL_SIZE) * 0.5)
	_clear_if_broke(item)
	return true


func _spawn_park(item_id: String, cell: Vector2i, _paid: bool = true) -> Node2D:
	if item_id.is_empty():
		return null
	GridService.add_prop(cell, item_id)
	var prop: Node2D = PARK_SCRIPT.new()
	add_child(prop)
	prop.call("setup", item_id, cell)
	_park_objects[cell] = prop
	return prop


func _clear_park_objects(origin_cell: Vector2i, size_cells: Vector2i) -> void:
	for x in range(size_cells.x):
		for y in range(size_cells.y):
			var cell := origin_cell + Vector2i(x, y)
			if not _park_objects.has(cell):
				continue
			var prop: Node2D = _park_objects[cell]
			_park_objects.erase(cell)
			if prop != null and is_instance_valid(prop):
				prop.queue_free()


func snapshot_world() -> Dictionary:
	var pens: Array = []
	for pen in _pens:
		if pen != null and is_instance_valid(pen):
			pens.append(pen.snapshot())
	var paths: Array = []
	for cell in _path_tiles.keys():
		var c: Vector2i = cell
		var sprite: Sprite2D = _path_tiles[cell]
		var tex_index: int = 0
		if sprite != null and sprite.has_meta("tex_index"):
			tex_index = int(sprite.get_meta("tex_index"))
		paths.append({"x": c.x, "y": c.y, "tex": tex_index})
	var props: Array = []
	for cell in _park_objects.keys():
		var c: Vector2i = cell
		var prop: Node2D = _park_objects[cell]
		if prop != null and is_instance_valid(prop):
			props.append({"x": c.x, "y": c.y, "id": str(prop.get("catalog_id"))})
	return {"pens": pens, "paths": paths, "props": props}


func restore_world(data: Dictionary) -> void:
	clear_world()
	for row in data.get("pens", []):
		if not (row is Dictionary):
			continue
		_restore_pen(row)
	for row in data.get("paths", []):
		if not (row is Dictionary):
			continue
		var cell := Vector2i(int(row.get("x", 0)), int(row.get("y", 0)))
		if not GridService.is_path_placeable(cell) and GridService.has_path_cell(cell):
			continue
		GridService.add_path(cell)
		var sprite := _make_path_sprite(cell, int(row.get("tex", 0)))
		add_child(sprite)
		_path_tiles[cell] = sprite
	for row in data.get("props", []):
		if not (row is Dictionary):
			continue
		var cell := Vector2i(int(row.get("x", 0)), int(row.get("y", 0)))
		_spawn_park(str(row.get("id", "")), cell, false)


func _restore_pen(row: Dictionary) -> void:
	var origin := Vector2i(int(row.get("x", 0)), int(row.get("y", 0)))
	var size := Vector2i(int(row.get("sx", 4)), int(row.get("sy", 3)))
	var pen := PEN_SCENE.instantiate() as Pen
	pen.footprint_cells = size
	pen.origin_cell = origin
	pen.catalog_id = str(row.get("id", "pen_small"))
	pen.listed_capacity = int(row.get("capacity", 0))
	pen.enjoyment_bonus = float(row.get("bonus", 0.0))
	pen.position = GridService.cell_to_world(origin)
	add_child(pen)
	GridService.occupy_area(origin, size, pen)
	_pens.append(pen)
	for animal_row in row.get("animals", []):
		if not (animal_row is Dictionary):
			continue
		_restore_animal(pen, animal_row)


func _restore_animal(pen: Pen, row: Dictionary) -> void:
	var animal := ANIMAL_SCENE.instantiate() as Animal
	pen.add_child(animal)
	animal.catalog_id = str(row.get("catalog_id", ""))
	animal.creature_name = str(row.get("name", "Unnamed"))
	animal.position = Vector2(float(row.get("x", 40.0)), float(row.get("y", 40.0)))
	animal.set_pen(pen)
	var parts: Dictionary = row.get("parts", {})
	animal.visuals.apply_loadout(parts, int(row.get("color", 0)), [])
	for perk in row.get("perks", []):
		animal.add_perk(str(perk))
	pen.register_animal(animal)
	_animal_count += 1


func clear_world() -> void:
	for pen in _pens.duplicate():
		delete_pen(pen)
	for cell in _path_tiles.keys():
		var sprite: Sprite2D = _path_tiles[cell]
		if sprite != null and is_instance_valid(sprite):
			sprite.queue_free()
	_path_tiles.clear()
	for cell in _park_objects.keys():
		var prop: Node2D = _park_objects[cell]
		if prop != null and is_instance_valid(prop):
			prop.queue_free()
	_park_objects.clear()
	GridService.clear_paths()
	GridService.reset()
	_pens.clear()
	_animal_count = 0
