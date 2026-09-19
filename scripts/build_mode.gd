extends Node2D
class_name BuildMode

## Handles pen/animal placement: ghost preview snapped to the grid, overlap
## validation, and click-to-confirm. See docs/DEMO.md for controls.

enum Mode { NONE, PLACE_PEN_SMALL, PLACE_PEN_LARGE, PLACE_ANIMAL }

const PEN_SCENE: PackedScene = preload("res://scenes/Pen.tscn")
const ANIMAL_SCENE: PackedScene = preload("res://scenes/Animal.tscn")

const PEN_SIZES: Dictionary = {
	Mode.PLACE_PEN_SMALL: Vector2i(4, 3),
	Mode.PLACE_PEN_LARGE: Vector2i(6, 5),
}

var current_mode: int = Mode.NONE

var _pens: Array[Pen] = []
var _animal_count: int = 0

@onready var _ghost: Polygon2D = Polygon2D.new()


func _ready() -> void:
	_ghost.color = Color(1, 1, 1, 0.35)
	_ghost.visible = false
	add_child(_ghost)


func set_mode(mode: int) -> void:
	current_mode = mode
	_ghost.visible = false


## Places a small pen and one Jimothy so the part-art demo is visible on Play.
func spawn_starter_exhibit() -> Animal:
	var origin_cell := Vector2i(4, 2)
	var size_cells := Vector2i(4, 3)
	var pen := PEN_SCENE.instantiate() as Pen
	pen.footprint_cells = size_cells
	pen.position = GridService.cell_to_world(origin_cell)
	add_child(pen)
	GridService.occupy_area(origin_cell, size_cells, pen)
	_pens.append(pen)

	var animal := ANIMAL_SCENE.instantiate() as Animal
	pen.add_child(animal)
	var interior: Rect2 = pen.get_interior_bounds()
	animal.position = interior.position + interior.size * 0.5
	animal.set_pen(pen)
	_animal_count += 1
	animal.creature_name = "Jimothy"
	animal.visuals.set_slot_visible("eyes", false)
	animal.visuals.set_slot_visible("tail", false)
	animal.set_physics_process(false)
	pen.register_animal(animal)
	return animal


func _process(_delta: float) -> void:
	if current_mode == Mode.PLACE_PEN_SMALL or current_mode == Mode.PLACE_PEN_LARGE:
		var over_gui := get_viewport().gui_get_hovered_control() != null
		_ghost.visible = not over_gui
		if not over_gui:
			_update_ghost()
	else:
		_ghost.visible = false


func _update_ghost() -> void:
	var size_cells: Vector2i = PEN_SIZES[current_mode]
	var origin_cell := GridService.world_to_cell(get_global_mouse_position())
	var world_pos := GridService.cell_to_world(origin_cell)
	var size_px := Vector2(size_cells.x * GridService.CELL_SIZE, size_cells.y * GridService.CELL_SIZE)

	_ghost.position = world_pos
	_ghost.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(size_px.x, 0), Vector2(size_px.x, size_px.y), Vector2(0, size_px.y)
	])

	var valid := GridService.is_area_free(origin_cell, size_cells)
	_ghost.color = Color(0.2, 1.0, 0.3, 0.35) if valid else Color(1.0, 0.2, 0.2, 0.35)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		match current_mode:
			Mode.PLACE_PEN_SMALL, Mode.PLACE_PEN_LARGE:
				_try_place_pen()
			Mode.PLACE_ANIMAL:
				_try_place_animal()


func _try_place_pen() -> void:
	var size_cells: Vector2i = PEN_SIZES[current_mode]
	var origin_cell := GridService.world_to_cell(get_global_mouse_position())
	if not GridService.is_area_free(origin_cell, size_cells):
		return

	var pen := PEN_SCENE.instantiate() as Pen
	pen.footprint_cells = size_cells
	pen.position = GridService.cell_to_world(origin_cell)
	add_child(pen)

	GridService.occupy_area(origin_cell, size_cells, pen)
	_pens.append(pen)


func _try_place_animal() -> void:
	var mouse_world := get_global_mouse_position()
	var pen := _find_pen_at(mouse_world)
	if pen == null:
		return

	var animal := ANIMAL_SCENE.instantiate() as Animal
	pen.add_child(animal)
	animal.position = pen.to_local(mouse_world)
	animal.set_pen(pen)

	_animal_count += 1
	animal.creature_name = "Critter %d" % _animal_count

	pen.register_animal(animal)


func _find_pen_at(world_pos: Vector2) -> Pen:
	for pen in _pens:
		var local := pen.to_local(world_pos)
		var rect := Rect2(Vector2.ZERO, pen.get_size_pixels())
		if rect.has_point(local):
			return pen
	return null
