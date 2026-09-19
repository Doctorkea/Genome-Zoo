extends Node2D
class_name Car

## Road car. Stays facing along the road. Drop-offs and pickups slide
## into a parallel kerb stall, then slide back out.

enum Role { TRAFFIC, DROPOFF, PICKUP }
enum State { DRIVE, PARK_IN, PARKED, PARK_OUT, LEAVE }

const SIZE := Vector2(100, 50) # ~one pen cell long, reads against 50px brick walls
const SPEED: float = 200.0
const GAP: float = 28.0
const TEX_BODY: Texture2D = preload("res://art/vehicles/car.png")
const TINT_SHADER: Shader = preload("res://scripts/shaders/car_tint.gdshader")

var role: int = Role.TRAFFIC
var direction: int = 1
var lane_y: float = 0.0
var bay_index: int = -1
var stall_pos: Vector2 = Vector2.ZERO
var body_color: Color = Color(0.75, 0.22, 0.18)

var _state: int = State.DRIVE
var _street: Street
var _hold: float = 0.0
var _sprite: Sprite2D
var _tint: ShaderMaterial


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite2D"
	_sprite.texture = TEX_BODY
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_tint = ShaderMaterial.new()
	_tint.shader = TINT_SHADER
	_sprite.material = _tint
	var tex_size := TEX_BODY.get_size()
	if tex_size.x > 0.0:
		var s: float = SIZE.x / tex_size.x
		_sprite.scale = Vector2(s, s)
	add_child(_sprite)
	_apply_tint()


static func random_body_color() -> Color:
	return Color.from_hsv(randf(), randf_range(0.42, 0.88), randf_range(0.40, 0.95))


func setup(street: Street, car_role: int, dir: int, start: Vector2, color: Color) -> void:
	_street = street
	role = car_role
	direction = dir
	body_color = color
	position = start
	lane_y = start.y
	rotation = 0.0 if dir > 0 else PI
	z_index = 1
	_apply_tint()


func assign_stall(index: int, park_at: Vector2) -> void:
	bay_index = index
	stall_pos = park_at


func is_parked() -> bool:
	return _state == State.PARKED


func _apply_tint() -> void:
	if _tint != null:
		_tint.set_shader_parameter("body_color", body_color)


func _process(delta: float) -> void:
	match _state:
		State.DRIVE:
			_drive(delta)
		State.PARK_IN:
			_slide_toward(stall_pos, delta)
			if position.distance_to(stall_pos) <= 3.0:
				position = stall_pos
				_hold = 0.45
				_state = State.PARKED
		State.PARKED:
			_hold -= delta
			if _hold <= 0.0:
				if _street != null:
					if role == Role.PICKUP:
						_street.board_visitor(self)
					else:
						_street.drop_visitor(self)
				_state = State.PARK_OUT
		State.PARK_OUT:
			var rejoin := Vector2(position.x, lane_y)
			_slide_toward(rejoin, delta)
			if absf(position.y - lane_y) <= 2.0:
				position.y = lane_y
				_state = State.LEAVE
		State.LEAVE:
			_drive(delta)
	if _is_off_map():
		_finish()


func _drive(delta: float) -> void:
	if _blocked():
		return
	position += Vector2.RIGHT.rotated(rotation) * SPEED * delta
	if role != Role.TRAFFIC and _state == State.DRIVE and _reached_stall():
		_state = State.PARK_IN


func _slide_toward(target: Vector2, delta: float) -> void:
	if _blocked():
		return
	position = position.move_toward(target, SPEED * delta)


func _reached_stall() -> bool:
	if bay_index < 0:
		return false
	var ahead: float = (stall_pos.x - position.x) * float(direction)
	return ahead <= SIZE.x * 0.5 and ahead >= -SIZE.x * 0.32


func _blocked() -> bool:
	return _street != null and _street.is_car_blocked(self)


func _is_off_map() -> bool:
	var map := GridService.map_size()
	return position.x < -SIZE.x * 1.6 or position.x > map.x + SIZE.x * 1.6


func _finish() -> void:
	if _street != null and bay_index >= 0:
		_street.release_bay(bay_index)
	queue_free()
