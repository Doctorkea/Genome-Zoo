extends Node2D
class_name ParkObject

## One-cell park furniture. Guests can walk the cell; pens cannot.

const ZooFx := preload("res://scripts/fx.gd")

var catalog_id: String = "park_bench"
var origin_cell: Vector2i = Vector2i.ZERO

@onready var _sprite: Sprite2D = Sprite2D.new()


func _ready() -> void:
	add_to_group("park_objects")
	z_index = 1
	if _sprite.get_parent() == null:
		add_child(_sprite)
	_sprite.centered = true
	_sprite.position = Vector2(GridService.CELL_SIZE, GridService.CELL_SIZE) * 0.5
	_sprite.texture = _make_texture()


func setup(item_id: String, cell: Vector2i) -> void:
	catalog_id = item_id
	origin_cell = cell
	position = GridService.cell_to_world(cell)
	if is_inside_tree():
		_sprite.texture = _make_texture()
		_attach_fx()


func _make_texture() -> Texture2D:
	var image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var fill := Color(0.55, 0.38, 0.22, 1)
	match catalog_id:
		"park_bench":
			fill = Color(0.62, 0.42, 0.22, 1)
		"park_snack":
			fill = Color(0.86, 0.36, 0.28, 1)
		"park_lamp":
			fill = Color(0.92, 0.78, 0.32, 1)
		"park_poster":
			fill = Color(0.32, 0.48, 0.72, 1)
	for y in range(10, 38):
		for x in range(8, 40):
			var edge := x == 8 or x == 39 or y == 10 or y == 37
			image.set_pixel(x, y, Color(0.12, 0.09, 0.06, 1) if edge else fill)
	if catalog_id == "park_lamp":
		for y in range(6, 16):
			for x in range(18, 30):
				image.set_pixel(x, y, Color(1.0, 0.92, 0.55, 1))
	var tex := ImageTexture.create_from_image(image)
	return tex


func _attach_fx() -> void:
	if has_node("AmbientFx"):
		return
	var mid := Vector2(GridService.CELL_SIZE, GridService.CELL_SIZE) * 0.5
	var fx: GPUParticles2D = null
	match catalog_id:
		"park_snack":
			fx = ZooFx.loop(self, ZooFx.Kind.STEAM, mid + Vector2(0.0, -8.0))
		"park_lamp":
			fx = ZooFx.loop(self, ZooFx.Kind.EMBER, mid + Vector2(0.0, -10.0))
		_:
			return
	if fx != null:
		fx.name = "AmbientFx"
