extends CharacterBody2D
class_name Animal

## A placed creature: wanders inside its pen, collides with the pen's solid
## fences, and reports itself + its stats when clicked.

const SPEED: float = 110.0 # ~one 100px tile per second so wander reads at this scale
const MIN_PAUSE: float = 0.6
const MAX_PAUSE: float = 2.2

const ANIMAL_LAYER: int = 2
const FENCE_LAYER: int = 4

@onready var visuals: CreatureVisuals = $Creature
@onready var _wander_timer: Timer = $WanderTimer

var _pen: Pen = null
var _target: Vector2 = Vector2.ZERO
var creature_name: String = "Unnamed"


func _ready() -> void:
	input_pickable = true
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = ANIMAL_LAYER
	collision_mask = FENCE_LAYER

	_wander_timer.one_shot = true
	_wander_timer.timeout.connect(_pick_new_target)
	input_event.connect(_on_input_event)

	_pick_new_target()


func set_pen(pen: Pen) -> void:
	_pen = pen


func _physics_process(_delta: float) -> void:
	var to_target := _target - position
	if to_target.length() < 4.0:
		velocity = Vector2.ZERO
	else:
		velocity = to_target.normalized() * SPEED
		_face_direction(velocity.x)
	move_and_slide()


## The creature rig is drawn facing right by default (see Creature.tscn).
## Mirror the whole rig around its own local origin when walking left, since
## it's a side-on sprite, not a top-down one.
func _face_direction(x_velocity: float) -> void:
	if absf(x_velocity) < 1.0:
		return
	var magnitude := absf(visuals.scale.x)
	visuals.scale.x = magnitude if x_velocity > 0.0 else -magnitude


func _pick_new_target() -> void:
	if _pen != null:
		var bounds: Rect2 = _pen.get_interior_bounds()
		_target = Vector2(
			randf_range(bounds.position.x, bounds.position.x + bounds.size.x),
			randf_range(bounds.position.y, bounds.position.y + bounds.size.y)
		)
	else:
		_target = position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
	_wander_timer.wait_time = randf_range(MIN_PAUSE, MAX_PAUSE)
	_wander_timer.start()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Events.animal_selected.emit(self)


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
		"families": int(score.get("families", 0)),
		"thrill": int(score.get("thrill", 0)),
	}
