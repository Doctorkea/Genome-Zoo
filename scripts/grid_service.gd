extends Node

## Grid <-> world coordinate helpers, plus pen-placement occupancy tracking.
## Autoloaded as "GridService".

const CELL_SIZE: int = 100 # one grid cell == one 100x100 floor tile (the art scale reference)
## Path stamps sit at half a grass cell so a walkway reads as cobbles, not slabs.
const PATH_CELL_SIZE: int = 50
const WORLD_COLS: int = 16
const WORLD_ROWS: int = 10
## Prison Architect-style frontage below the grass. Pens cannot be built here.
const PARKING_HEIGHT: int = 96
const ROAD_HEIGHT: int = 148

var _occupied_cells: Dictionary = {} # Vector2i -> Node (the Pen occupying that cell)
var _path_cells: Dictionary = {} # path-grid Vector2i -> true
var _prop_cells: Dictionary = {} # grass Vector2i -> item_id


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


func world_to_path_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(world_pos.x / PATH_CELL_SIZE)), int(floor(world_pos.y / PATH_CELL_SIZE)))


func path_cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * PATH_CELL_SIZE, cell.y * PATH_CELL_SIZE)


func path_cell_center(cell: Vector2i) -> Vector2:
	return path_cell_to_world(cell) + Vector2(PATH_CELL_SIZE, PATH_CELL_SIZE) * 0.5


func is_path_cell_in_world(cell: Vector2i) -> bool:
	var origin := path_cell_to_world(cell)
	var grass := world_size()
	return origin.x >= 0.0 and origin.y >= 0.0 \
		and origin.x + float(PATH_CELL_SIZE) <= grass.x + 0.01 \
		and origin.y + float(PATH_CELL_SIZE) <= grass.y + 0.01


func is_area_in_world(origin_cell: Vector2i, size_cells: Vector2i) -> bool:
	return origin_cell.x >= 0 and origin_cell.y >= 0 \
		and origin_cell.x + size_cells.x <= WORLD_COLS \
		and origin_cell.y + size_cells.y <= WORLD_ROWS


## Returns true if every cell in the `size_cells` rectangle starting at
## `origin_cell` is currently unoccupied.
func is_cell_occupied(cell: Vector2i) -> bool:
	return _occupied_cells.has(cell)


func has_path_cell(cell: Vector2i) -> bool:
	return _path_cells.has(cell)


## True when any small path stamp sits inside this 100×100 grass cell.
func has_path(grass_cell: Vector2i) -> bool:
	var origin := cell_to_world(grass_cell)
	var start := world_to_path_cell(origin + Vector2(0.5, 0.5))
	var end := world_to_path_cell(origin + Vector2(CELL_SIZE - 0.5, CELL_SIZE - 0.5))
	for x in range(start.x, end.x + 1):
		for y in range(start.y, end.y + 1):
			if _path_cells.has(Vector2i(x, y)):
				return true
	return false


func has_any_path() -> bool:
	return not _path_cells.is_empty()


func is_path_placeable(cell: Vector2i) -> bool:
	if not is_path_cell_in_world(cell) or has_path_cell(cell):
		return false
	var grass := world_to_cell(path_cell_center(cell))
	return is_area_in_world(grass, Vector2i.ONE) and not is_cell_occupied(grass) and not has_prop(grass)


func add_path(cell: Vector2i) -> void:
	if is_path_placeable(cell):
		_path_cells[cell] = true


func remove_path(cell: Vector2i) -> void:
	_path_cells.erase(cell)


func clear_paths() -> void:
	_path_cells.clear()


func take_paths_in_area(origin_cell: Vector2i, size_cells: Vector2i) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	var origin := cell_to_world(origin_cell)
	var size := Vector2(size_cells.x * CELL_SIZE, size_cells.y * CELL_SIZE)
	var start := world_to_path_cell(origin + Vector2(0.5, 0.5))
	var end := world_to_path_cell(origin + size - Vector2(0.5, 0.5))
	for x in range(start.x, end.x + 1):
		for y in range(start.y, end.y + 1):
			var cell := Vector2i(x, y)
			if _path_cells.has(cell):
				_path_cells.erase(cell)
				found.append(cell)
	return found


func cell_center(cell: Vector2i) -> Vector2:
	return cell_to_world(cell) + Vector2(CELL_SIZE, CELL_SIZE) * 0.5


## Grass plus the parking strip, excluding road and pen footprints.
func is_guest_walkable(point: Vector2) -> bool:
	if road_rect().has_point(point):
		return false
	var map := map_size()
	if point.x < 8.0 or point.x > map.x - 8.0 or point.y < 8.0:
		return false
	if point.y > parking_rect().end.y - 2.0:
		return false
	var cell := world_to_cell(point)
	if is_area_in_world(cell, Vector2i.ONE) and is_cell_occupied(cell):
		return false
	return grass_rect().has_point(point) or parking_rect().has_point(point)


func is_guest_cell_walkable(cell: Vector2i) -> bool:
	return is_guest_walkable(cell_center(cell))


func guest_line_clear(from: Vector2, to: Vector2, step: float = 24.0) -> bool:
	var span: float = from.distance_to(to)
	if span <= 1.0:
		return is_guest_walkable(to)
	var n: int = maxi(1, int(ceil(span / step)))
	for i in range(1, n + 1):
		var t: float = float(i) / float(n)
		if not is_guest_walkable(from.lerp(to, t)):
			return false
	return true


func is_area_free(origin_cell: Vector2i, size_cells: Vector2i) -> bool:
	for x in range(size_cells.x):
		for y in range(size_cells.y):
			var cell := origin_cell + Vector2i(x, y)
			if _occupied_cells.has(cell) or _prop_cells.has(cell):
				return false
	return true


func is_area_placeable(origin_cell: Vector2i, size_cells: Vector2i) -> bool:
	return is_area_in_world(origin_cell, size_cells) and is_area_free(origin_cell, size_cells)


## Marks every cell in the `size_cells` rectangle as occupied by `by`.
func occupy_area(origin_cell: Vector2i, size_cells: Vector2i, by: Node) -> void:
	take_paths_in_area(origin_cell, size_cells)
	take_props_in_area(origin_cell, size_cells)
	for x in range(size_cells.x):
		for y in range(size_cells.y):
			_occupied_cells[origin_cell + Vector2i(x, y)] = by


func free_area(origin_cell: Vector2i, size_cells: Vector2i, by: Node) -> void:
	for x in range(size_cells.x):
		for y in range(size_cells.y):
			var cell := origin_cell + Vector2i(x, y)
			if _occupied_cells.get(cell) == by:
				_occupied_cells.erase(cell)


func reset() -> void:
	_occupied_cells.clear()
	_path_cells.clear()
	_prop_cells.clear()


func is_prop_placeable(cell: Vector2i) -> bool:
	return is_area_in_world(cell, Vector2i.ONE) and not is_cell_occupied(cell) and not _prop_cells.has(cell)


func has_prop(cell: Vector2i) -> bool:
	return _prop_cells.has(cell)


func prop_id(cell: Vector2i) -> String:
	return str(_prop_cells.get(cell, ""))


func add_prop(cell: Vector2i, item_id: String) -> void:
	if is_prop_placeable(cell) and not item_id.is_empty():
		_prop_cells[cell] = item_id


func remove_prop(cell: Vector2i) -> void:
	_prop_cells.erase(cell)


func take_props_in_area(origin_cell: Vector2i, size_cells: Vector2i) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for x in range(size_cells.x):
		for y in range(size_cells.y):
			var cell := origin_cell + Vector2i(x, y)
			if _prop_cells.has(cell):
				_prop_cells.erase(cell)
				found.append(cell)
	return found


func prop_points(item_id: String) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for cell in _prop_cells.keys():
		if str(_prop_cells[cell]) == item_id:
			points.append(cell_center(cell))
	return points


func nearest_prop(item_id: String, from: Vector2, max_dist: float = 220.0) -> Vector2:
	var best := Vector2.INF
	var best_d: float = max_dist
	for point in prop_points(item_id):
		var d: float = from.distance_to(point)
		if d < best_d:
			best_d = d
			best = point
	return best


func has_lamp(cell: Vector2i) -> bool:
	return prop_id(cell) == "park_lamp"


func has_bench(cell: Vector2i) -> bool:
	return prop_id(cell) == "park_bench"


func snapshot_props() -> Array:
	var rows: Array = []
	for cell in _prop_cells.keys():
		var c: Vector2i = cell
		rows.append({"x": c.x, "y": c.y, "id": str(_prop_cells[cell])})
	return rows


func snapshot_paths() -> Array:
	var rows: Array = []
	for cell in _path_cells.keys():
		var c: Vector2i = cell
		rows.append({"x": c.x, "y": c.y})
	return rows
