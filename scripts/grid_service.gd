extends Node

## Grid <-> world coordinate helpers, plus pen-placement occupancy tracking.
## Autoloaded as "GridService".

const CELL_SIZE: int = 32

var _occupied_cells: Dictionary = {} # Vector2i -> Node (the Pen occupying that cell)


func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(world_pos.x / CELL_SIZE)), int(floor(world_pos.y / CELL_SIZE)))


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)


## Returns true if every cell in the `size_cells` rectangle starting at
## `origin_cell` is currently unoccupied.
func is_area_free(origin_cell: Vector2i, size_cells: Vector2i) -> bool:
	for x in range(size_cells.x):
		for y in range(size_cells.y):
			var cell := origin_cell + Vector2i(x, y)
			if _occupied_cells.has(cell):
				return false
	return true


## Marks every cell in the `size_cells` rectangle as occupied by `by`.
func occupy_area(origin_cell: Vector2i, size_cells: Vector2i, by: Node) -> void:
	for x in range(size_cells.x):
		for y in range(size_cells.y):
			_occupied_cells[origin_cell + Vector2i(x, y)] = by
