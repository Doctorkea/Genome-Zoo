extends Node2D
class_name Pen

## A placeable zoo enclosure. Footprint is set in grid cells; brick wall
## tiles and solid fence collision are generated at runtime so one scene
## covers every pen size. World grass shows through the interior.

const BRICK_SCALE: float = 0.5
const FENCE_LAYER: int = 4 # bit for "fences" — animals set collision_mask to this

const ANIMAL_SCENE: PackedScene = preload("res://scenes/Animal.tscn")
const ZooFx := preload("res://scripts/fx.gd")
const BREED_ROLL: float = 0.035
const BREED_CHECK: float = 4.0
const TEX_FLAT: Texture2D = preload("res://art/tiles/pen/brick_flat.png")
const TEX_UP: Texture2D = preload("res://art/tiles/pen/brick_up.png")
const TEX_TOP_CORNER: Texture2D = preload("res://art/tiles/pen/brick_top_corner.png")
const TEX_BOTTOM_CORNER: Texture2D = preload("res://art/tiles/pen/brick_bottom_corner.png")

@export var footprint_cells: Vector2i = Vector2i(4, 3)

var origin_cell: Vector2i = Vector2i.ZERO
var catalog_id: String = ""
var listed_capacity: int = -1
var enjoyment_bonus: float = 0.0
var animals: Array[Node] = []
var _mate_a: Animal = null
var _mate_b: Animal = null
var _meet: Vector2 = Vector2.ZERO
var _breed_wait: float = 0.0


func _ready() -> void:
	add_to_group("pens")
	_build_walls()
	_breed_wait = randf_range(1.0, BREED_CHECK)
	set_process(animal_capacity() > 2)


func _process(delta: float) -> void:
	if _mate_a != null:
		_tick_courtship()
		return
	if animal_capacity() <= 2:
		return
	_breed_wait -= delta
	if _breed_wait > 0.0:
		return
	_breed_wait = BREED_CHECK
	if randf() <= BREED_ROLL:
		try_start_mating()


func get_size_pixels() -> Vector2:
	return Vector2(
		footprint_cells.x * GridService.CELL_SIZE,
		footprint_cells.y * GridService.CELL_SIZE
	)


func wall_thickness() -> float:
	return float(GridService.CELL_SIZE) * BRICK_SCALE


func animal_capacity() -> int:
	if listed_capacity > 0:
		return listed_capacity
	if not catalog_id.is_empty():
		var item: Dictionary = BuildCatalog.get_item(catalog_id)
		if not item.is_empty() and item.has("capacity"):
			return int(item.get("capacity", 2))
	return 5 if footprint_cells.x >= 6 else 2


func occupant_count() -> int:
	return living_animals().size()


func can_accept_animal() -> bool:
	return occupant_count() < animal_capacity()


func living_animals() -> Array[Animal]:
	var found: Array[Animal] = []
	for occupant in animals:
		var animal := occupant as Animal
		if animal != null and is_instance_valid(animal) and not animal.is_queued_for_deletion():
			found.append(animal)
	return found


func has_animal_perk(perk_id: String) -> bool:
	for animal in living_animals():
		if animal.has_perk(perk_id):
			return true
	return false


## How well the herd reads as one exhibit. RCT-style: a 25% cut at worst, with a
## dead zone so close looks (or a matching herd) stay at full value.
const COMPATIBLE_CLASH: float = 0.22
const MIN_ENJOYMENT: float = 0.78


func enjoyment_factor() -> float:
	var clash: float = trait_clash()
	var base: float = 1.0
	if clash > COMPATIBLE_CLASH:
		var t: float = clampf((clash - COMPATIBLE_CLASH) / (1.0 - COMPATIBLE_CLASH), 0.0, 1.0)
		base = lerpf(1.0, MIN_ENJOYMENT, t * t)
	return clampf(base + enjoyment_bonus, MIN_ENJOYMENT, 1.2)


## Sparse pens are a tad less exciting (Planet Zoo appeal / social-group size).
func occupancy_factor() -> float:
	var cap: int = maxi(1, animal_capacity())
	var n: int = occupant_count()
	if n <= 0:
		return 0.0
	var fill: float = clampf(float(n) / float(cap), 0.0, 1.0)
	return lerpf(0.88, 1.0, sqrt(fill))


func trait_clash() -> float:
	var herd: Array[Animal] = living_animals()
	if herd.size() < 2:
		return 0.0
	var total: float = 0.0
	var pairs: int = 0
	for i in range(herd.size()):
		var tags_a: Dictionary = herd[i].get_stats().get("tags", {})
		for j in range(i + 1, herd.size()):
			total += TraitLibrary.tag_clash(tags_a, herd[j].get_stats().get("tags", {}))
			pairs += 1
	if pairs <= 0:
		return 0.0
	return clampf(total / float(pairs), 0.0, 1.0)


## Local-space bounds animals should wander within — inset a little from the
## walls so they don't spend all their time bumping into fences.
func get_interior_bounds() -> Rect2:
	var size := get_size_pixels()
	var margin := wall_thickness() + 6.0
	return Rect2(Vector2(margin, margin), size - Vector2(margin, margin) * 2.0)


## Tighter than the grass interior so a 40px animal body stays off the bricks.
func get_wander_bounds() -> Rect2:
	var inner := get_interior_bounds()
	var keep: float = maxf(8.0, (wall_thickness() + Animal.BODY_RADIUS) - inner.position.x)
	var size := Vector2(inner.size.x - keep * 2.0, inner.size.y - keep * 2.0)
	if size.x < 24.0:
		size.x = maxf(24.0, inner.size.x - 8.0)
	if size.y < 16.0:
		size.y = maxf(16.0, inner.size.y - 8.0)
	var pos := inner.position + (inner.size - size) * 0.5
	return Rect2(pos, size)


func world_rect() -> Rect2:
	return Rect2(global_position, get_size_pixels())


func exhibit_signature() -> String:
	var bits: PackedStringArray = PackedStringArray()
	for occupant in animals:
		var animal := occupant as Animal
		if animal == null or not is_instance_valid(animal):
			continue
		bits.append(animal.exhibit_id())
	bits.sort()
	return " ".join(bits)


func exhibit_tags() -> Dictionary:
	var counts: Dictionary = {}
	for tag in TraitLibrary.TAGS:
		counts[tag] = 0
	for animal in living_animals():
		var tags: Dictionary = animal.get_stats().get("tags", {})
		for tag in TraitLibrary.TAGS:
			counts[tag] = int(counts.get(tag, 0)) + int(tags.get(tag, 0))
	return counts


func frontage_point() -> Vector2:
	var spots: Array[Vector2] = viewing_points()
	if not spots.is_empty():
		return spots[0]
	var size := get_size_pixels()
	return Vector2(global_position.x + size.x * 0.5, global_position.y + size.y + 24.0)


## Grass just outside the fence so guests can press up and look in.
func viewing_points() -> Array[Vector2]:
	var rect := world_rect()
	var gap: float = 22.0
	var raw: Array[Vector2] = []
	for t in [0.22, 0.5, 0.78]:
		raw.append(Vector2(rect.position.x + rect.size.x * t, rect.end.y + gap))
		raw.append(Vector2(rect.position.x + rect.size.x * t, rect.position.y - gap))
		raw.append(Vector2(rect.position.x - gap, rect.position.y + rect.size.y * t))
		raw.append(Vector2(rect.end.x + gap, rect.position.y + rect.size.y * t))
	var spots: Array[Vector2] = []
	for point in raw:
		if _is_viewing_spot(point):
			spots.append(point)
	return spots


func _is_viewing_spot(point: Vector2) -> bool:
	var map := GridService.map_size()
	if point.x < 8.0 or point.x > map.x - 8.0 or point.y < 8.0:
		return false
	if point.y > GridService.parking_rect().end.y - 2.0:
		return false
	if GridService.road_rect().has_point(point):
		return false
	var cell := GridService.world_to_cell(point)
	if GridService.is_area_in_world(cell, Vector2i.ONE) and GridService.is_cell_occupied(cell):
		return false
	return GridService.grass_rect().has_point(point) or GridService.parking_rect().has_point(point)


func register_animal(animal: Node) -> void:
	if not animals.has(animal):
		animals.append(animal)


func unregister_animal(animal: Node) -> void:
	animals.erase(animal)
	if animal == _mate_a or animal == _mate_b:
		_stop_courtship()


func can_breed() -> bool:
	if animal_capacity() <= 2:
		return false
	var herd: Array[Animal] = living_animals()
	return herd.size() >= 2 and herd.size() + 1 <= animal_capacity() and _mate_a == null


func is_courting() -> bool:
	return _mate_a != null and is_instance_valid(_mate_a)


func courtship_point() -> Vector2:
	return to_global(_meet)


func try_start_mating() -> bool:
	if not can_breed():
		return false
	var herd: Array[Animal] = living_animals()
	herd.shuffle()
	return start_courtship(herd[0], herd[1])


func start_courtship(first: Animal, second: Animal) -> bool:
	if first == null or second == null or first == second:
		return false
	if not can_breed():
		return false
	_mate_a = first
	_mate_b = second
	_meet = get_wander_bounds().get_center()
	first.steer_to(_meet + Vector2(-18.0, 0.0))
	second.steer_to(_meet + Vector2(18.0, 0.0))
	return true


func finish_courtship() -> Animal:
	if _mate_a == null or _mate_b == null:
		return null
	if not is_instance_valid(_mate_a) or not is_instance_valid(_mate_b):
		_stop_courtship()
		return null
	if not can_accept_animal():
		_stop_courtship()
		return null
	var child := _spawn_child(_mate_a, _mate_b)
	_burst_hearts()
	_stop_courtship()
	return child


func _tick_courtship() -> void:
	if _mate_a == null or _mate_b == null or not is_instance_valid(_mate_a) or not is_instance_valid(_mate_b):
		_stop_courtship()
		return
	if _mate_a.has_arrived() and _mate_b.has_arrived():
		finish_courtship()


func _stop_courtship() -> void:
	if _mate_a != null and is_instance_valid(_mate_a):
		_mate_a.clear_busy()
	if _mate_b != null and is_instance_valid(_mate_b):
		_mate_b.clear_busy()
	_mate_a = null
	_mate_b = null


func _burst_hearts() -> void:
	var mid: Vector2 = _meet
	if _mate_a != null and is_instance_valid(_mate_a):
		ZooFx.burst(_mate_a, ZooFx.Kind.HEART, Vector2(0.0, -28.0))
	if _mate_b != null and is_instance_valid(_mate_b):
		ZooFx.burst(_mate_b, ZooFx.Kind.HEART, Vector2(0.0, -28.0))
	var marker := Node2D.new()
	add_child(marker)
	marker.position = mid
	ZooFx.burst(marker, ZooFx.Kind.HEART, Vector2.ZERO)
	var tree := get_tree()
	if tree != null:
		tree.create_timer(1.4).timeout.connect(func() -> void:
			if is_instance_valid(marker):
				marker.queue_free()
		)


func _spawn_child(first: Animal, second: Animal) -> Animal:
	var child := ANIMAL_SCENE.instantiate() as Animal
	add_child(child)
	child.position = _meet
	child.set_pen(self)
	child.catalog_id = "born"
	child.creature_name = SaveService.child_name(first.creature_name, second.creature_name)
	var mixed: Dictionary = _mix_loadout(first, second)
	child.visuals.apply_loadout(mixed.get("parts", {}), int(mixed.get("color", 0)), mixed.get("hidden", []))
	register_animal(child)
	Events.animal_born.emit(child)
	Events.placement_succeeded.emit("born")
	return child


func _mix_loadout(first: Animal, second: Animal) -> Dictionary:
	var parts: Dictionary = {}
	var hidden: Array = []
	var vis_a: CreatureVisuals = first.visuals
	var vis_b: CreatureVisuals = second.visuals
	for slot in vis_a.get_slots():
		var src: CreatureVisuals = vis_a if randf() < 0.5 else vis_b
		parts[slot] = src.get_current_index(slot)
		if not src.is_slot_visible(slot):
			hidden.append(slot)
	var color_index: int = vis_a.get_current_palette_index() if randf() < 0.5 else vis_b.get_current_palette_index()
	return {"parts": parts, "hidden": hidden, "color": color_index}


func snapshot() -> Dictionary:
	var occupants: Array = []
	for animal in living_animals():
		occupants.append(animal.snapshot())
	return {
		"id": catalog_id,
		"x": origin_cell.x,
		"y": origin_cell.y,
		"sx": footprint_cells.x,
		"sy": footprint_cells.y,
		"capacity": animal_capacity(),
		"bonus": enjoyment_bonus,
		"animals": occupants,
	}


func _build_walls() -> void:
	var size := get_size_pixels()
	var thick := wall_thickness()
	_add_collision(Vector2(0, 0), Vector2(size.x, thick))
	_add_collision(Vector2(0, size.y - thick), Vector2(size.x, thick))
	_add_collision(Vector2(0, 0), Vector2(thick, size.y))
	_add_collision(Vector2(size.x - thick, 0), Vector2(thick, size.y))
	_lay_bricks()


func _lay_bricks() -> void:
	var step := wall_thickness()
	var cols: int = int(round(get_size_pixels().x / step))
	var rows: int = int(round(get_size_pixels().y / step))
	_add_brick(TEX_TOP_CORNER, 0, 0)
	_add_brick(TEX_TOP_CORNER, cols - 1, 0, true, false)
	_add_brick(TEX_BOTTOM_CORNER, 0, rows - 1, true, false)
	_add_brick(TEX_BOTTOM_CORNER, cols - 1, rows - 1)
	for x in range(1, cols - 1):
		_add_brick(TEX_FLAT, x, 0)
		_add_brick(TEX_FLAT, x, rows - 1)
	for y in range(1, rows - 1):
		_add_brick(TEX_UP, 0, y)
		_add_brick(TEX_UP, cols - 1, y, true, false)


func _add_brick(
	texture: Texture2D,
	cell_x: int,
	cell_y: int,
	flip_h: bool = false,
	flip_v: bool = false
) -> void:
	var step := wall_thickness()
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.flip_h = flip_h
	sprite.flip_v = flip_v
	sprite.scale = Vector2(BRICK_SCALE, BRICK_SCALE)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(cell_x, cell_y) * step
	add_child(sprite)


func _add_collision(local_pos: Vector2, wall_size: Vector2) -> void:
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
