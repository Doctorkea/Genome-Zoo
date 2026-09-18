extends Node

## Placeholder mutagen-point economy. Ticks up over time as a simplified
## stand-in for ticket revenue (see docs/GAME_DESIGN.md) — enough to prove
## the "spend points to mutate a trait" loop without wiring in a real zoo
## economy yet. Autoloaded as "MutagenService".

@export var starting_points: int = 15
@export var points_per_tick: int = 1
@export var tick_seconds: float = 3.0

var points: int = 0

@onready var _timer: Timer = Timer.new()


func _ready() -> void:
	points = starting_points
	_timer.wait_time = tick_seconds
	_timer.autostart = true
	add_child(_timer)
	_timer.timeout.connect(_on_tick)
	Events.mutagen_points_changed.emit(points)


func _on_tick() -> void:
	points += points_per_tick
	Events.mutagen_points_changed.emit(points)


func can_afford(cost: int) -> bool:
	return points >= cost


## Spends `cost` points if affordable. Returns true on success.
func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	points -= cost
	Events.mutagen_points_changed.emit(points)
	return true
