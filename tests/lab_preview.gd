extends Node

## Opens the DNA Lab on a starter animal so layout can be screenshot in-game.


func _ready() -> void:
	TutorialService.skip()
	var world_layer := CanvasLayer.new()
	world_layer.layer = 0
	add_child(world_layer)
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 20
	add_child(ui_layer)
	var hud: Control = (load("res://scenes/ui/HUD.tscn") as PackedScene).instantiate()
	ui_layer.add_child(hud)
	var build := Node2D.new()
	build.set_script(load("res://scripts/build_mode.gd"))
	world_layer.add_child(build)
	hud.set_build_mode(build)
	var animal: Animal = build.spawn_starter_exhibit()
	if animal == null:
		return
	animal.visuals.set_part_shape("head", 8)
	animal.visuals.set_part_shape("front_legs", 1)
	Events.animal_selected.emit(animal)
	hud._on_mutate_pressed()
