extends Node2D
class_name BuildMode

## Pen and animal placement from the bottom catalog. Cash is spent on a
## successful place. Ghost preview snaps to the grid. See docs/DEMO.md.

enum Mode { NONE, PLACE_PEN_SMALL, PLACE_PEN_LARGE, PLACE_ANIMAL }

const PEN_SCENE: PackedScene = preload("res://scenes/Pen.tscn")
const ANIMAL_SCENE: PackedScene = preload("res://scenes/Animal.tscn")

var current_mode: int = Mode.NONE
var current_item_id: String = ""

var _pens: Array[Pen] = []
var _animal_count: int = 0

@onready var _ghost: Polygon2D = Polygon2D.new()


func _ready() -> void:
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
		_:
			current_mode = Mode.NONE


## Test helper: places a small pen and one Jimothy without charging cash.
func spawn_starter_exhibit() -> Animal:
	var origin_cell := Vector2i(4, 2)
	var size_cells := Vector2i(4, 3)
	var pen := PEN_SCENE.instantiate() as Pen
	pen.footprint_cells = size_cells
	pen.origin_cell = origin_cell
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


func _update_pen_ghost() -> void:
	var item: Dictionary = BuildCatalog.get_item(current_item_id)
	var size_cells: Vector2i = item.get("size_cells", Vector2i(4, 3))
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
	if event.is_action_pressed("ui_cancel"):
		clear_tool()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		match current_mode:
			Mode.PLACE_PEN_SMALL, Mode.PLACE_PEN_LARGE:
				_try_place_pen()
			Mode.PLACE_ANIMAL:
				_try_place_animal()
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
	pen.position = GridService.cell_to_world(origin_cell)
	add_child(pen)
	GridService.occupy_area(origin_cell, size_cells, pen)
	_pens.append(pen)
	crush_visitors_in_rect(pen.world_rect())
	Events.placement_succeeded.emit(current_item_id)
	_clear_if_broke(item)


func _try_place_animal() -> void:
	var item: Dictionary = BuildCatalog.get_item(current_item_id)
	if item.is_empty() or str(item.get("kind", "")) != "animal":
		return
	var mouse_world := get_global_mouse_position()
	var pen := _find_pen_at(mouse_world)
	if pen == null:
		Events.placement_rejected.emit("Drop them inside a pen.")
		return
	if not pen.can_accept_animal():
		Events.placement_rejected.emit("This pen is full (%d/%d)." % [pen.occupant_count(), pen.animal_capacity()])
		return
	var cost: int = int(item.get("cost", 0))
	if not WalletService.spend(cost):
		Events.placement_rejected.emit("Need $%d for a %s." % [cost, item.get("name", "animal")])
		clear_tool()
		return

	var animal := ANIMAL_SCENE.instantiate() as Animal
	pen.add_child(animal)
	animal.position = pen.to_local(mouse_world)
	animal.set_pen(pen)
	_apply_species(animal, item)
	_animal_count += 1
	pen.register_animal(animal)
	Events.placement_succeeded.emit(current_item_id)
	_clear_if_broke(item)


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
