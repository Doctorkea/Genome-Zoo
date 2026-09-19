extends Node2D
class_name Pen

## A placeable zoo enclosure. Footprint is set in grid cells; the floor and
## solid fence walls are generated at runtime so one scene covers every pen
## size (a Prison-Architect-style rectangular prefab). Placeholder visuals
## only — see docs/ART_PIPELINE.md.

const WALL_THICKNESS: float = 10.0
const FLOOR_COLOR: Color = Color(0.36, 0.52, 0.30) # placeholder grass green
const WALL_COLOR: Color = Color(0.42, 0.30, 0.20) # placeholder fence brown

const FENCE_LAYER: int = 4 # bit for "fences" — animals set collision_mask to this

@export var footprint_cells: Vector2i = Vector2i(4, 3)

var animals: Array[Node] = []


func _ready() -> void:
	_build_floor()
	_build_walls()


func get_size_pixels() -> Vector2:
	return Vector2(
		footprint_cells.x * GridService.CELL_SIZE,
		footprint_cells.y * GridService.CELL_SIZE
	)


## Local-space bounds animals should wander within — inset a little from the
## walls so they don't spend all their time bumping into fences.
func get_interior_bounds() -> Rect2:
	var size := get_size_pixels()
	var margin := WALL_THICKNESS + 6.0
	return Rect2(Vector2(margin, margin), size - Vector2(margin, margin) * 2.0)


func register_animal(animal: Node) -> void:
	if not animals.has(animal):
		animals.append(animal)


func unregister_animal(animal: Node) -> void:
	animals.erase(animal)


func _build_floor() -> void:
	var floor_poly := _make_rect_polygon(get_size_pixels(), FLOOR_COLOR)
	floor_poly.z_index = -10
	add_child(floor_poly)


func _build_walls() -> void:
	var size := get_size_pixels()
	_add_wall(Vector2(0, 0), Vector2(size.x, WALL_THICKNESS)) # top
	_add_wall(Vector2(0, size.y - WALL_THICKNESS), Vector2(size.x, WALL_THICKNESS)) # bottom
	_add_wall(Vector2(0, 0), Vector2(WALL_THICKNESS, size.y)) # left
	_add_wall(Vector2(size.x - WALL_THICKNESS, 0), Vector2(WALL_THICKNESS, size.y)) # right


func _add_wall(local_pos: Vector2, wall_size: Vector2) -> void:
	var visual := _make_rect_polygon(wall_size, WALL_COLOR)
	visual.position = local_pos
	add_child(visual)

	var body := StaticBody2D.new()
	body.position = local_pos + wall_size / 2.0
	body.collision_layer = FENCE_LAYER
	body.collision_mask = 0

	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = wall_size
	shape.shape = rect_shape
	body.add_child(shape)

	add_child(body)


func _make_rect_polygon(size: Vector2, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, size.y), Vector2(0, size.y)
	])
	poly.color = color
	return poly
