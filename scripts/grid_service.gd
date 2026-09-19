extends Node

## Grid <-> world coordinate helpers, plus pen-placement occupancy tracking.
## Autoloaded as "GridService".

const CELL_SIZE: int = 100 # one grid cell == one 100x100 floor tile (the art scale reference)
const WORLD_COLS: int = 16
const WORLD_ROWS: int = 10
## Prison Architect-style frontage below the grass. Pens cannot be built here.
const PARKING_HEIGHT: int = 96
const ROAD_HEIGHT: int = 148

var _occupied_cells: Dictionary = {} # Vector2i -> Node (the Pen occupying that cell)


func world_size() -> Vector2:
	return Vector2(WORLD_COLS * CELL_SIZE, WORLD_ROWS * CELL_SIZE)


func map_size() -> Vector2:
	var grass := world_size()
	return Vector2(grass.x, grass.y + PARKING_HEIGHT + ROAD_HEIGHT)


func grass_rect() -> Rect2:
	return Rect2(Vector2.ZERO, world_size())


func parking_rect() -> Rect2:
	var grass := world_size()
	return Rect2(0.0, grass.y, grass.x, float(PARKING_HEIGHT))


func road_rect() -> Rect2:
	var grass := world_size()
	return Rect2(0.0, grass.y + float(PARKING_HEIGHT), grass.x, float(ROAD_HEIGHT))


func apply_camera_limits(camera: Camera2D) -> void:
	var size := map_size()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(size.x)
	camera.limit_bottom = int(size.y)
	camera.limit_smoothed = false


## Keeps a camera center such that its view rectangle stays on the map.
func clamp_camera_center(center: Vector2, view_size: Vector2) -> Vector2:
	var bounds := map_size()
	var half := view_size * 0.5
	var result := center
	if view_size.x >= bounds.x:
		result.x = bounds.x * 0.5
	else:
		result.x = clampf(center.x, half.x, bounds.x - half.x)
	if view_size.y >= bounds.y:
		result.y = bounds.y * 0.5
	else:
		result.y = clampf(center.y, half.y, bounds.y - half.y)
	return result.round()


func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(world_pos.x / CELL_SIZE)), int(floor(world_pos.y / CELL_SIZE)))


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)


func is_area_in_world(origin_cell: Vector2i, size_cells: Vector2i) -> bool:
	return origin_cell.x >= 0 and origin_cell.y >= 0 \
		and origin_cell.x + size_cells.x <= WORLD_COLS \
		and origin_cell.y + size_cells.y <= WORLD_ROWS


## Returns true if every cell in the `size_cells` rectangle starting at
## `origin_cell` is currently unoccupied.
func is_cell_occupied(cell: Vector2i) -> bool:
	return _occupied_cells.has(cell)


func is_area_free(origin_cell: Vector2i, size_cells: Vector2i) -> bool:
	for x in range(size_cells.x):
		for y in range(size_cells.y):
			var cell := origin_cell + Vector2i(x, y)
			if _occupied_cells.has(cell):
				return false
	return true


func is_area_placeable(origin_cell: Vector2i, size_cells: Vector2i) -> bool:
	return is_area_in_world(origin_cell, size_cells) and is_area_free(origin_cell, size_cells)


## Marks every cell in the `size_cells` rectangle as occupied by `by`.
func occupy_area(origin_cell: Vector2i, size_cells: Vector2i, by: Node) -> void:
	for x in range(size_cells.x):
		for y in range(size_cells.y):
			_occupied_cells[origin_cell + Vector2i(x, y)] = by


func free_area(origin_cell: Vector2i, size_cells: Vector2i, by: Node) -> void:
	for x in range(size_cells.x):
		for y in range(size_cells.y):
			var cell := origin_cell + Vector2i(x, y)
			if _occupied_cells.get(cell) == by:
				_occupied_cells.erase(cell)
