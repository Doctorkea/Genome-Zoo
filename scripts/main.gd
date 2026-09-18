extends Node2D

## Root of the demo: wires the camera, build mode, and HUD together.
## Right-drag to pan, scroll wheel to zoom. See docs/DEMO.md.

const ZOOM_STEP: float = 0.1
const MIN_ZOOM: float = 0.5
const MAX_ZOOM: float = 2.5

@onready var _build_mode: BuildMode = $BuildMode
@onready var _hud: CanvasLayer = $HUD
@onready var _camera: Camera2D = $Camera2D

var _panning: bool = false
var _pan_start_mouse: Vector2 = Vector2.ZERO
var _pan_start_cam: Vector2 = Vector2.ZERO


func _ready() -> void:
	# 2D physics picking (click-to-select on animals) is off by default.
	get_viewport().physics_object_picking = true
	_camera.make_current()
	_hud.set_build_mode(_build_mode)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_panning = event.pressed
			_pan_start_mouse = event.position
			_pan_start_cam = _camera.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_camera(-ZOOM_STEP)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_camera(ZOOM_STEP)
	elif event is InputEventMouseMotion and _panning:
		var delta := (event.position - _pan_start_mouse) / _camera.zoom
		_camera.position = _pan_start_cam - delta


func _zoom_camera(amount: float) -> void:
	var new_zoom: float = clampf(_camera.zoom.x + amount, MIN_ZOOM, MAX_ZOOM)
	_camera.zoom = Vector2(new_zoom, new_zoom)
