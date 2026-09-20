extends Node2D
class_name Street

## Road plus a kerbside parallel-parking strip. Cars stay horizontal.
## Right-clicked patrons wait on the strip for a pickup.

const CAR_SCENE: PackedScene = preload("res://scenes/Car.tscn")
const VISITOR_SCENE: PackedScene = preload("res://scenes/Visitor.tscn")

const STALL_COUNT: int = 6
const STALL_GAP: float = 28.0
const MAX_VISITORS: int = 16

var is_open: bool = false
var hype_time: float = 0.0
var _bays: Array[Dictionary] = []
var _hail_queue: Array[Visitor] = []
var _pickup_claimed: Dictionary = {} # bay index -> true while a pickup car is coming
var _traffic_timer: float = 0.4
var _east_timer: float = 1.1
var _kerb_timer: float = 1.6
var _next_family_id: int = 1


func _ready() -> void:
	add_to_group("street")
	z_index = 0
	_layout_stalls()
	queue_redraw()
	Events.quest_changed.connect(_on_quest_changed)


func _on_quest_changed() -> void:
	_sync_stalls()


func has_exhibit() -> bool:
	for pen in _all_pens():
		if pen.occupant_count() >= 1:
			return true
	return false


func open_block_reason() -> String:
	if has_exhibit():
		return ""
	return "Need a pen with at least one animal."


func set_open(want: bool) -> bool:
	if want:
		var reason := open_block_reason()
		if not reason.is_empty():
			return false
		if is_open:
			return true
		is_open = true
		Events.zoo_hours_changed.emit(true)
		TutorialService.on_zoo_opened()
		return true
	if not is_open:
		return true
	is_open = false
	send_guests_home()
	Events.zoo_hours_changed.emit(false)
	return true


func send_guests_home() -> void:
	for guest in _visitors():
		if guest.is_leader() and not guest.is_leaving():
			guest.hail()


func bay_count() -> int:
	return _bays.size()


func visitor_count() -> int:
	var n: int = 0
	for child in get_children():
		if child is Visitor:
			n += 1
	return n


func visitor_cap() -> int:
	return GeneTree.visitor_cap()


func stall_count() -> int:
	return 9 if GeneTree.has_zoo_perk(GeneTree.PERK_MORE_PARKING) else STALL_COUNT


func has_creator() -> bool:
	for child in get_children():
		var guest := child as Visitor
		if guest != null and is_instance_valid(guest) and guest.visitor_id == "creators":
			return true
	return false


func westbound_y() -> float:
	var road := GridService.road_rect()
	return road.position.y + road.size.y * 0.28


func eastbound_y() -> float:
	var road := GridService.road_rect()
	return road.position.y + road.size.y * 0.72


func gate_point() -> Vector2:
	for _i in range(16):
		var cell := Vector2i(randi() % GridService.WORLD_COLS, GridService.WORLD_ROWS - 1)
		if GridService.is_cell_occupied(cell):
			continue
		return GridService.cell_to_world(cell) + Vector2(GridService.CELL_SIZE * 0.5, GridService.CELL_SIZE - 28.0)
	var grass := GridService.world_size()
	return Vector2(grass.x * 0.5, grass.y - 20.0)


func exit_point() -> Vector2:
	var park := GridService.parking_rect()
	return Vector2(randf_range(60.0, park.size.x - 60.0), park.position.y + park.size.y * 0.5)


func wander_point(visitor: Visitor = null) -> Vector2:
	if visitor != null:
		var benches: Array[Vector2] = GridService.prop_points("park_bench")
		if not benches.is_empty() and randf() < 0.28:
			return _prefer_clear_spot(visitor, benches)
	var unseen: Array[Pen] = _unseen_pens(visitor)
	var pool: Array[Pen] = unseen if not unseen.is_empty() else _stocked_pens()
	if pool.is_empty():
		pool = _all_pens()
	if not pool.is_empty():
		var pen: Pen = pool[randi() % pool.size()]
		var spots: Array[Vector2] = pen.viewing_points()
		if not spots.is_empty():
			return _prefer_clear_spot(visitor, spots)
		var look := _frontage_or_empty(pen)
		if look != Vector2.INF:
			return look
	for _i in range(16):
		var cell := Vector2i(randi() % GridService.WORLD_COLS, randi() % GridService.WORLD_ROWS)
		if GridService.is_cell_occupied(cell):
			continue
		var point := GridService.cell_to_world(cell) + Vector2(GridService.CELL_SIZE, GridService.CELL_SIZE) * 0.5
		if _is_park_walkable(point):
			return point
	return gate_point()


func hail_visitor(visitor: Visitor) -> Vector2:
	if visitor == null:
		return exit_point()
	if not _hail_queue.has(visitor):
		_hail_queue.append(visitor)
	var index := _free_bay_index()
	if index < 0:
		visitor.pickup_bay = -1
		return exit_point()
	_bays[index]["occupied"] = true
	visitor.pickup_bay = index
	return (_bays[index]["rect"] as Rect2).get_center()


func hail_family(leader: Visitor, dest: Vector2, bay: int) -> void:
	for mate in family_of(leader):
		if mate != leader:
			mate.join_hail(dest, bay)


func family_of(visitor: Visitor) -> Array[Visitor]:
	var found: Array[Visitor] = []
	if visitor == null:
		return found
	if visitor.family_id < 0:
		found.append(visitor)
		return found
	for child in get_children():
		var guest := child as Visitor
		if guest != null and guest.family_id == visitor.family_id:
			found.append(guest)
	return found


func pen_near(point: Vector2) -> Pen:
	var best: Pen = null
	var best_d: float = 96.0
	for pen in _all_pens():
		var rect := pen.world_rect()
		var closest := Vector2(
			clampf(point.x, rect.position.x, rect.end.x),
			clampf(point.y, rect.position.y, rect.end.y)
		)
		var d: float = point.distance_to(closest)
		if d < best_d:
			best_d = d
			best = pen
	return best


func drop_visitor(car: Car) -> void:
	if car == null:
		return
	var start := car.position + Vector2.UP * (Car.SIZE.y * 0.55 + 8.0)
	if GridService.road_rect().has_point(start):
		start = Vector2(car.position.x, GridService.parking_rect().get_center().y)
	start.y = minf(start.y, GridService.parking_rect().end.y - 8.0)
	if visitor_count() <= visitor_cap() - 3 and TraitLibrary.arrival_is_family():
		spawn_family(start)
	else:
		_spawn_solo(start)
	if not is_open:
		send_guests_home()


func spawn_family(start: Vector2) -> Visitor:
	var kinds: PackedStringArray = TraitLibrary.family_member_kinds()
	var fid: int = _next_family_id
	_next_family_id += 1
	var offsets: Array[Vector2] = [
		Vector2.ZERO,
		Vector2(-22.0, 8.0),
		Vector2(18.0, 12.0),
		Vector2(-8.0, 20.0),
	]
	var leader: Visitor = null
	for i in range(kinds.size()):
		var offset: Vector2 = offsets[i % offsets.size()]
		var guest := _make_guest(str(kinds[i]), start + offset)
		guest.family_id = fid
		guest.family_offset = offset
		if leader == null:
			leader = guest
			guest.family_leader = null
		else:
			guest.family_leader = leader
			if guest.visitor_id == "children":
				guest._speed *= 0.88
	return leader


func spawn_creator_crew(start: Vector2) -> Visitor:
	var fid: int = _next_family_id
	_next_family_id += 1
	var lead := _make_guest("creators", start)
	lead.family_id = fid
	lead.family_leader = null
	var cam := _make_guest("camera", start + Vector2(-22.0, 10.0))
	cam.family_id = fid
	cam.family_offset = Vector2(-22.0, 10.0)
	cam.family_leader = lead
	return lead


func _spawn_solo(start: Vector2) -> Visitor:
	var kind := TraitLibrary.random_solo_id(not has_creator())
	if kind == "creators":
		if visitor_count() > visitor_cap() - 2:
			return _make_guest(TraitLibrary.random_solo_id(false), start)
		return spawn_creator_crew(start)
	return _make_guest(kind, start)


func _make_guest(kind: String, start: Vector2) -> Visitor:
	var guest := VISITOR_SCENE.instantiate() as Visitor
	add_child(guest)
	guest.setup(self, kind, start)
	return guest


func board_visitor(car: Car) -> void:
	if car == null:
		return
	var guests: Array[Visitor] = _party_at(car.bay_index)
	if guests.is_empty():
		return
	_pickup_claimed.erase(car.bay_index)
	for guest in guests:
		_hail_queue.erase(guest)
		guest.pickup_bay = -1
		guest.board()


func release_bay(index: int) -> void:
	if index < 0 or index >= _bays.size():
		return
	_bays[index]["occupied"] = false
	_pickup_claimed.erase(index)
	_assign_waiting_bays()


func forget_visitor(visitor: Visitor) -> void:
	if visitor == null:
		return
	_hail_queue.erase(visitor)
	var bay: int = visitor.pickup_bay
	var mates: Array[Visitor] = family_of(visitor)
	mates.erase(visitor)
	visitor.pickup_bay = -1
	if visitor.is_leader() and not mates.is_empty():
		var neu: Visitor = mates[0]
		neu.family_leader = null
		for mate in mates:
			if mate != neu:
				mate.family_leader = neu
	var bay_held := false
	for mate in mates:
		if mate.pickup_bay == bay and bay >= 0:
			bay_held = true
			break
	if bay >= 0 and not bay_held:
		release_bay(bay)


func is_car_blocked(car: Car) -> bool:
	if car == null:
		return false
	var gap: float = Car.SIZE.x + Car.GAP
	for other in _cars():
		if other == car:
			continue
		if other.direction != car.direction:
			continue
		if absf(other.position.y - car.position.y) > Car.SIZE.y * 0.55:
			continue
		var along: float = (other.position.x - car.position.x) * float(car.direction)
		if along > 0.0 and along < gap:
			return true
	return false


func spawn_traffic(dir: int) -> Car:
	var map := GridService.map_size()
	var y: float = eastbound_y() if dir > 0 else westbound_y()
	var start := Vector2(-70.0 if dir > 0 else map.x + 70.0, y)
	if not _spawn_clear(start, dir):
		return null
	return _make_car(Car.Role.TRAFFIC, dir, start, -1, Vector2.ZERO)


func spawn_dropoff() -> Car:
	if not is_open:
		return null
	var index := _free_bay_index()
	if index < 0 or visitor_count() > visitor_cap() - 4:
		return null
	_bays[index]["occupied"] = true
	return _spawn_kerb_car(Car.Role.DROPOFF, index)


func spawn_pickup() -> Car:
	var guest := _next_waiting_guest()
	if guest == null or guest.pickup_bay < 0:
		return null
	if bool(_pickup_claimed.get(guest.pickup_bay, false)):
		return null
	_pickup_claimed[guest.pickup_bay] = true
	return _spawn_kerb_car(Car.Role.PICKUP, guest.pickup_bay)


func add_hype(seconds: float = 15.0) -> void:
	hype_time = minf(40.0, hype_time + maxf(0.0, seconds))


func _process(delta: float) -> void:
	if hype_time > 0.0:
		hype_time = maxf(0.0, hype_time - delta)
	if is_open and not has_exhibit():
		set_open(false)
	_assign_waiting_bays()
	_traffic_timer -= delta
	_east_timer -= delta
	_kerb_timer -= delta
	var scale: float = GeneTree.spawn_time_scale()
	if hype_time > 0.0:
		scale *= 0.55
	if _traffic_timer <= 0.0:
		spawn_traffic(-1)
		_traffic_timer = randf_range(2.0, 3.4) * scale
	if _east_timer <= 0.0:
		spawn_traffic(1)
		_east_timer = randf_range(2.0, 3.4) * scale
	if _kerb_timer <= 0.0:
		if _next_waiting_guest() != null:
			spawn_pickup()
		else:
			spawn_dropoff()
		_kerb_timer = randf_range(3.5, 6.5) * scale


func _spawn_kerb_car(role: int, bay_index: int) -> Car:
	var stall: Rect2 = _bays[bay_index]["rect"]
	var start := Vector2(GridService.map_size().x + 70.0, westbound_y())
	if not _spawn_clear(start, -1):
		if role == Car.Role.DROPOFF:
			_bays[bay_index]["occupied"] = false
		_pickup_claimed.erase(bay_index)
		return null
	return _make_car(role, -1, start, bay_index, stall.get_center())


func _make_car(role: int, dir: int, start: Vector2, bay_index: int, stall_center: Vector2) -> Car:
	var car := CAR_SCENE.instantiate() as Car
	add_child(car)
	car.setup(self, role, dir, start, Car.random_body_color())
	if bay_index >= 0:
		car.assign_stall(bay_index, stall_center)
	return car


func _spawn_clear(start: Vector2, dir: int) -> bool:
	for car in _cars():
		if car.direction != dir:
			continue
		if absf(car.position.y - start.y) > Car.SIZE.y * 0.55:
			continue
		if car.position.distance_to(start) < Car.SIZE.x + 48.0:
			return false
	return true


func _cars() -> Array[Car]:
	var found: Array[Car] = []
	for child in get_children():
		if child is Car:
			found.append(child)
	return found


func _free_bay_index() -> int:
	var open: Array[int] = []
	for i in range(_bays.size()):
		if not bool(_bays[i].get("occupied", false)):
			open.append(i)
	if open.is_empty():
		return -1
	return open[randi() % open.size()]


func _next_waiting_guest() -> Visitor:
	for guest in _hail_queue:
		if guest != null and is_instance_valid(guest) and guest.is_waiting() and guest.pickup_bay >= 0:
			return guest
	return null


func _party_at(bay_index: int) -> Array[Visitor]:
	for guest in _visitors():
		if guest.pickup_bay == bay_index:
			return family_of(guest)
	return []


func _visitors() -> Array[Visitor]:
	var found: Array[Visitor] = []
	for child in get_children():
		if child is Visitor:
			found.append(child)
	return found


func _assign_waiting_bays() -> void:
	for guest in _hail_queue:
		if guest == null or not is_instance_valid(guest):
			continue
		if guest.pickup_bay >= 0:
			continue
		var index := _free_bay_index()
		if index < 0:
			return
		_bays[index]["occupied"] = true
		guest.pickup_bay = index
		guest.go_to((_bays[index]["rect"] as Rect2).get_center())


func _prefer_clear_spot(visitor: Visitor, spots: Array[Vector2]) -> Vector2:
	if visitor == null:
		return spots[randi() % spots.size()]
	var path_spots: Array[Vector2] = []
	if GridService.has_any_path() or not GridService.prop_points("park_lamp").is_empty():
		for spot in spots:
			var cell := GridService.world_to_cell(spot)
			if GridService.has_path(cell) or GridService.has_lamp(cell) or GridService.has_bench(cell):
				path_spots.append(spot)
	var pool: Array[Vector2] = path_spots if not path_spots.is_empty() else spots
	var open: Array[Vector2] = []
	for spot in pool:
		if GridService.guest_line_clear(visitor.position, spot):
			open.append(spot)
	if not open.is_empty():
		return open[randi() % open.size()]
	return pool[randi() % pool.size()]


func _is_park_walkable(point: Vector2) -> bool:
	return GridService.is_guest_walkable(point)


func _frontage_or_empty(pen: Pen) -> Vector2:
	if pen == null:
		return Vector2.INF
	var look := pen.frontage_point()
	if _is_park_walkable(look):
		return look
	return Vector2.INF


func _all_pens() -> Array[Pen]:
	var found: Array[Pen] = []
	for node in get_tree().get_nodes_in_group("pens"):
		var pen := node as Pen
		if pen != null and is_instance_valid(pen):
			found.append(pen)
	return found


func _stocked_pens() -> Array[Pen]:
	var found: Array[Pen] = []
	for node in get_tree().get_nodes_in_group("pens"):
		var pen := node as Pen
		if pen != null and not pen.exhibit_signature().is_empty():
			found.append(pen)
	return found


func _unseen_pens(visitor: Visitor) -> Array[Pen]:
	var found: Array[Pen] = []
	for pen in _stocked_pens():
		if visitor == null or not visitor.has_seen(pen.exhibit_signature()):
			found.append(pen)
	return found


func _layout_stalls() -> void:
	_bays.clear()
	var park := GridService.parking_rect()
	var stall := Vector2(Car.SIZE.x + 14.0, Car.SIZE.y + 10.0)
	var count: int = stall_count()
	var row_width: float = float(count) * stall.x + float(maxi(count - 1, 0)) * STALL_GAP
	var x: float = (park.size.x - row_width) * 0.5
	var y: float = park.position.y + (park.size.y - stall.y) * 0.5
	for _i in range(count):
		_bays.append({
			"rect": Rect2(x, y, stall.x, stall.y),
			"occupied": false,
		})
		x += stall.x + STALL_GAP


func _sync_stalls() -> void:
	var want: int = stall_count()
	if _bays.size() == want:
		return
	var held: Dictionary = {}
	for i in range(_bays.size()):
		held[i] = bool(_bays[i].get("occupied", false))
	_layout_stalls()
	for i in range(_bays.size()):
		if bool(held.get(i, false)):
			_bays[i]["occupied"] = true
	queue_redraw()


func _draw() -> void:
	var park := GridService.parking_rect()
	var road := GridService.road_rect()
	var asphalt := Color(0.18, 0.18, 0.20)
	var paint := Color(0.70, 0.70, 0.66, 0.38)
	draw_rect(park, asphalt, true)
	draw_rect(road, asphalt, true)
	draw_rect(Rect2(Vector2(road.position.x, road.end.y - 2.0), Vector2(road.size.x, 2.0)), paint, true)
	var mid_y: float = road.position.y + road.size.y * 0.5
	var dash: float = 18.0
	var gap: float = 20.0
	var x: float = road.position.x + 10.0
	while x < road.end.x:
		draw_rect(Rect2(Vector2(x, mid_y - 1.0), Vector2(dash, 2.0)), Color(0.72, 0.62, 0.20, 0.4), true)
		x += dash + gap
	for bay in _bays:
		var rect: Rect2 = bay["rect"]
		draw_rect(Rect2(rect.position, Vector2(2.0, rect.size.y)), paint, true)
		draw_rect(Rect2(Vector2(rect.end.x - 2.0, rect.position.y), Vector2(2.0, rect.size.y)), paint, true)
