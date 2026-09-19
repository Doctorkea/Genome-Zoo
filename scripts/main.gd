extends Node2D

## Root of the demo: wires the camera, build mode, and HUD together.
## Right-drag to pan, scroll wheel to zoom. See docs/DEMO.md.

## Integer zoom so floor tiles stay on pixel boundaries.
## 0.5 is omitted — that view is wider than the 16×10 world.
const ZOOM_LEVELS: Array[float] = [1.0, 2.0]

@onready var _build_mode: BuildMode = $BuildMode
@onready var _hud: Control = $HUDLayer/HUD
@onready var _camera: Camera2D = $Camera2D
@onready var _street: Street = $Street

var _panning: bool = false
var _pan_start_mouse: Vector2 = Vector2.ZERO
var _pan_start_cam: Vector2 = Vector2.ZERO


func _ready() -> void:
	# 2D physics picking (click-to-select on animals) is off by default.
	get_viewport().physics_object_picking = true
	_fit_window_to_hud()
	_camera.make_current()
	GridService.apply_camera_limits(_camera)
	_hud.set_build_mode(_build_mode)
	_camera.zoom = Vector2(ZOOM_LEVELS[0], ZOOM_LEVELS[0])
	var view: Vector2 = get_viewport().get_visible_rect().size / _camera.zoom
	var map := GridService.map_size()
	_camera.position = _clamped_camera_position(Vector2(map.x * 0.5, map.y - view.y * 0.36))
	if SaveService.pending_load:
		SaveService.pending_load = false
		SaveService.load_into(_build_mode)


func _fit_window_to_hud() -> void:
	# Integer window scale crops a 1280x720 HUD inside a smaller editor game tab.
	# Keep-aspect fractional scale letterboxes the full frame instead.
	var win := get_window()
	win.content_scale_size = Vector2i(1280, 720)
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	win.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_panning = event.pressed
			_pan_start_mouse = event.position
			_pan_start_cam = _camera.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			if not _gui_blocks_zoom():
				_zoom_camera(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			if not _gui_blocks_zoom():
				_zoom_camera(1)
	elif event is InputEventMouseMotion and _panning:
		var motion := event as InputEventMouseMotion
		var delta: Vector2 = (motion.position - _pan_start_mouse) / _camera.zoom
		_camera.position = _clamped_camera_position(_pan_start_cam - delta)


func _gui_blocks_zoom() -> bool:
	var node: Node = get_viewport().gui_get_hovered_control()
	while node is Control:
		var ctrl := node as Control
		if ctrl.mouse_filter == Control.MOUSE_FILTER_STOP:
			return true
		node = node.get_parent()
	return false


func _zoom_camera(direction: int) -> void:
	var current: float = _camera.zoom.x
	var index := 0
	var best_dist: float = absf(ZOOM_LEVELS[0] - current)
	for i in range(ZOOM_LEVELS.size()):
		var dist: float = absf(ZOOM_LEVELS[i] - current)
		if dist < best_dist:
			best_dist = dist
			index = i
	index = clampi(index + direction, 0, ZOOM_LEVELS.size() - 1)
	var new_zoom: float = ZOOM_LEVELS[index]
	_camera.zoom = Vector2(new_zoom, new_zoom)
	_camera.position = _clamped_camera_position(_camera.position)


func _clamped_camera_position(desired: Vector2) -> Vector2:
	var view: Vector2 = get_viewport().get_visible_rect().size / _camera.zoom
	return GridService.clamp_camera_center(desired, view)
