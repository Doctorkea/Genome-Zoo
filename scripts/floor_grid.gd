extends Node2D

## Zoo floor: the artist's 100×100 grass tiles, drawn 1:1 on the grid.

const COLS: int = 16
const ROWS: int = 10

const GRASS: Array[Texture2D] = [
	preload("res://art/tiles/grass/grass_1.png"),
	preload("res://art/tiles/grass/grass_2.png"),
	preload("res://art/tiles/grass/grass_3.png"),
	preload("res://art/tiles/grass/grass_4.png"),
	preload("res://art/tiles/grass/grass_5.png"),
]

const FLOWERS: Array[Texture2D] = [
	preload("res://art/tiles/grass/grass_flowers_1.png"),
	preload("res://art/tiles/grass/grass_flowers_2.png"),
	preload("res://art/tiles/grass/grass_flowers_3.png"),
	preload("res://art/tiles/grass/grass_flowers_4.png"),
]


func _ready() -> void:
	z_index = -1
	texture_filter = TEXTURE_FILTER_NEAREST
	queue_redraw()


func _draw() -> void:
	var cell: int = GridService.CELL_SIZE
	var grass_count: int = GRASS.size()
	var flower_count: int = FLOWERS.size()
	for y in range(ROWS):
		for x in range(COLS):
			var n: int = absi((x * 73856093) ^ (y * 19349663))
			var tex: Texture2D = FLOWERS[n % flower_count] if (n % 100) < 16 else GRASS[n % grass_count]
			draw_texture_rect(tex, Rect2(x * cell, y * cell, cell, cell), false)
