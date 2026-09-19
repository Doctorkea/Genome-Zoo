extends CharacterBody2D
class_name Animal

## A placed creature: wanders inside its pen, collides with the pen's solid
## fences, and reports itself + its stats when clicked.

const SPEED: float = 42.0
const MIN_PAUSE: float = 6.0
const MAX_PAUSE: float = 16.0
const ARRIVE_DISTANCE: float = 8.0
const STUCK_SECONDS: float = 4.0
const BODY_RADIUS: float = 40.0
const MAX_PERKS: int = 2

const ANIMAL_LAYER: int = 2
const FENCE_LAYER: int = 4
const ZooFx := preload("res://scripts/fx.gd")

@onready var visuals: CreatureVisuals = $Creature
@onready var _wander_timer: Timer = $WanderTimer

var _pen: Pen = null
var _target: Vector2 = Vector2.ZERO
var creature_name: String = "Unnamed"
var catalog_id: String = ""
var perks: PackedStringArray = PackedStringArray()
var _pausing: bool = false
var _facing: float = 1.0
var _walk_phase: float = 0.0
var _idle_phase: float = 0.0
var _move_time: float = 0.0
var _walk_rate: float = 8.0
var _idle_rate: float = 2.1
var _bob_height: float = 4.5
var _prev_hop: float = 1.0


func _ready() -> void:
	add_to_group("animals")
	input_pickable = true
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = ANIMAL_LAYER
	collision_mask = FENCE_LAYER

	_wander_timer.one_shot = true
	_wander_timer.timeout.connect(_pick_new_target)
	input_event.connect(_on_input_event)
	_walk_phase = randf() * TAU
	_idle_phase = randf() * TAU
	_walk_rate = randf_range(6.8, 9.4)
	_idle_rate = randf_range(1.7, 2.6)
	_bob_height = randf_range(3.4, 5.6)
	_target = position
	_start_pause()


func set_pen(pen: Pen) -> void:
	_pen = pen
	position = _clamped_to_wander(position)
	_target = position


func get_pen() -> Pen:
	return _pen


func has_perk(perk_id: String) -> bool:
	return perks.has(perk_id)


func add_perk(perk_id: String) -> bool:
	if perk_id.is_empty() or has_perk(perk_id) or perks.size() >= MAX_PERKS:
		return false
	perks.append(perk_id)
	return true


func remove_perk(perk_id: String) -> void:
	var idx: int = perks.find(perk_id)
	if idx >= 0:
		perks.remove_at(idx)


func _physics_process(delta: float) -> void:
	var to_target := _target - position
	var moving: bool = to_target.length() >= ARRIVE_DISTANCE and not _pausing
	if moving:
		velocity = to_target.normalized() * SPEED
		_face_direction(velocity.x)
		_move_time += delta
		if _move_time >= STUCK_SECONDS:
			_pick_new_target()
	else:
		velocity = Vector2.ZERO
		_move_time = 0.0
		if not _pausing and to_target.length() < ARRIVE_DISTANCE:
			_start_pause()
	move_and_slide()
	if moving and get_slide_collision_count() > 0:
		velocity = Vector2.ZERO
		_target = position
		_start_pause()
		moving = false
	_animate(delta, moving)


## The creature rig is drawn facing right by default (see Creature.tscn).
## Mirror the whole rig around its own local origin when walking left, since
## it's a side-on sprite, not a top-down one.
func _face_direction(x_velocity: float) -> void:
	if absf(x_velocity) < 1.0:
		return
	_facing = 1.0 if x_velocity > 0.0 else -1.0


func _animate(delta: float, moving: bool) -> void:
	if visuals == null:
		return
	if moving:
		_walk_phase += delta * _walk_rate
		var hop: float = absf(sin(_walk_phase))
		visuals.position.y = -hop * _bob_height
		visuals.rotation = sin(_walk_phase) * 0.11
		var squash: float = 1.0 + hop * 0.055
		var stretch: float = 1.0 - hop * 0.045
		visuals.scale = Vector2(_facing * squash, stretch)
		if hop < 0.14 and _prev_hop >= 0.14:
			ZooFx.burst(self, ZooFx.Kind.DUST, Vector2(0.0, 22.0))
		_prev_hop = hop
	else:
		_idle_phase += delta * _idle_rate
		visuals.position.y = sin(_idle_phase) * 1.4
		visuals.rotation = sin(_idle_phase * 0.65) * 0.035
		visuals.scale = Vector2(_facing * (1.0 + sin(_idle_phase) * 0.02), 1.0 + sin(_idle_phase) * 0.03)


func _start_pause() -> void:
	_pausing = true
	_wander_timer.wait_time = randf_range(MIN_PAUSE, MAX_PAUSE)
	_wander_timer.start()


func _pick_new_target() -> void:
	_pausing = false
	_move_time = 0.0
	var area := _wander_rect()
	var picked := area.get_center()
	for _i in range(10):
		var candidate := Vector2(
			randf_range(area.position.x, area.end.x),
			randf_range(area.position.y, area.end.y)
		)
		if candidate.distance_to(position) >= 48.0:
			picked = candidate
			break
	_target = _clamped_to_wander(picked)


func _wander_rect() -> Rect2:
	if _pen != null:
		return _pen.get_wander_bounds()
	return Rect2(position - Vector2(16.0, 16.0), Vector2(32.0, 32.0))


func _clamped_to_wander(point: Vector2) -> Vector2:
	var area := _wander_rect()
	return Vector2(
		clampf(point.x, area.position.x, area.end.x),
		clampf(point.y, area.position.y, area.end.y)
	)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Events.animal_selected.emit(self)
		get_viewport().set_input_as_handled()


func get_stats() -> Dictionary:
	var score: Dictionary = TraitLibrary.score_visuals(visuals)
	var parts: Array = []
	for slot in visuals.get_slots():
		if not visuals.is_slot_visible(slot):
			continue
		var index: int = visuals.get_current_index(slot)
		var option: Dictionary = TraitLibrary.get_option(slot, index)
		parts.append(option.get("name", TraitLibrary.option_label(slot, index)))
	var color_option: Dictionary = TraitLibrary.get_option(
		TraitLibrary.COLOR_SLOT, visuals.get_current_palette_index()
	)
	parts.append(color_option.get("name", "Color"))
	return {
		"name": creature_name,
		"parts": parts,
		"color_index": visuals.get_current_palette_index(),
		"archetype": score.get("archetype", "Unspecialized"),
		"tags": score.get("tags", {}),
		"visitors": score.get("visitors", {}),
		"perks": Array(perks),
	}


func snapshot() -> Dictionary:
	var parts: Dictionary = {}
	if visuals != null:
		for slot in visuals.get_slots():
			parts[slot] = visuals.get_current_index(slot)
	return {
		"catalog_id": catalog_id,
		"name": creature_name,
		"parts": parts,
		"color": visuals.get_current_palette_index() if visuals != null else 0,
		"perks": Array(perks),
		"x": position.x,
		"y": position.y,
	}


func exhibit_id() -> String:
	var bits: PackedStringArray = PackedStringArray()
	bits.append(creature_name)
	if visuals == null:
		return " ".join(bits)
	for slot in visuals.get_slots():
		bits.append("%s%d" % [slot, visuals.get_current_index(slot)])
	bits.append("c%d" % visuals.get_current_palette_index())
	return "|".join(bits)
