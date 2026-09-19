extends Node

## Headless smoke test — exercises the core systems without needing real
## mouse/window input, so it can run via CLI: see docs/DEMO.md for the
## exact command. Not part of the game; safe to delete or ignore in-editor.


func _ready() -> void:
	print("=== SMOKE TEST START ===")

	_test_grid_service()
	_test_placeholder_art()
	var pen := _test_pen()
	var animal := _test_animal(pen)
	_test_creature_mutation(animal)
	_test_build_mode()
	_test_mutagen_service()
	_test_hud(animal)

	print("=== SMOKE TEST PASSED ===")
	get_tree().quit()


func _test_grid_service() -> void:
	var cell := GridService.world_to_cell(Vector2(250, 140))
	assert(cell == Vector2i(2, 1), "world_to_cell wrong: %s" % [cell])
	assert(GridService.is_area_free(Vector2i(0, 0), Vector2i(4, 3)), "area should start free")
	GridService.occupy_area(Vector2i(0, 0), Vector2i(4, 3), self)
	assert(not GridService.is_area_free(Vector2i(0, 0), Vector2i(4, 3)), "area should now be occupied")
	print("GridService OK")


func _test_placeholder_art() -> void:
	for slot in ["body", "head", "eyes", "mouth", "front_legs", "back_legs", "tail"]:
		var opts := PlaceholderArt.get_shape_options(slot)
		assert(opts.size() == 3, "%s should have 3 options, got %d" % [slot, opts.size()])
	assert(PlaceholderArt.get_palette_options().size() == 3, "should have 3 palettes")
	print("PlaceholderArt OK")


func _test_pen() -> Pen:
	var pen_scene: PackedScene = load("res://scenes/Pen.tscn")
	var pen := pen_scene.instantiate() as Pen
	pen.footprint_cells = Vector2i(6, 5)
	add_child(pen)
	assert(pen.get_size_pixels() == Vector2(600, 500), "pen size wrong: %s" % [pen.get_size_pixels()])
	var bounds := pen.get_interior_bounds()
	assert(bounds.size.x > 0 and bounds.size.y > 0, "interior bounds should be positive")
	print("Pen OK — size=%s bounds=%s" % [pen.get_size_pixels(), bounds])
	return pen


func _test_animal(pen: Pen) -> Animal:
	var animal_scene: PackedScene = load("res://scenes/Animal.tscn")
	var animal := animal_scene.instantiate() as Animal
	pen.add_child(animal)
	animal.set_pen(pen)
	animal.creature_name = "Test Critter"
	pen.register_animal(animal)
	var stats: Dictionary = animal.get_stats()
	assert(stats.get("name") == "Test Critter", "animal name not set")
	assert((stats.get("parts") as Array).size() == 7, "expected 7 parts, got %s" % [stats.get("parts")])
	print("Animal OK — stats=%s" % [stats])
	return animal


func _test_creature_mutation(animal: Animal) -> void:
	animal.visuals.set_part_shape("head", 1)
	assert(animal.visuals.get_current_index("head") == 1, "head mutation didn't apply")
	animal.visuals.set_skin(2)
	assert(animal.visuals.get_current_palette_index() == 2, "skin mutation didn't apply")
	print("Creature mutation OK — stats=%s" % [animal.get_stats()])


func _test_build_mode() -> void:
	var build_mode := Node2D.new()
	build_mode.set_script(load("res://scripts/build_mode.gd"))
	add_child(build_mode)
	build_mode.set_mode(BuildMode.Mode.PLACE_PEN_SMALL)
	assert(build_mode.current_mode == BuildMode.Mode.PLACE_PEN_SMALL, "set_mode didn't apply")
	print("BuildMode OK")


func _test_mutagen_service() -> void:
	var start_points: int = MutagenService.points
	assert(MutagenService.spend(5), "should afford spending 5")
	assert(MutagenService.points == start_points - 5, "points didn't decrease")
	assert(not MutagenService.spend(100000), "shouldn't afford spending 100000")
	print("MutagenService OK — points=%d" % MutagenService.points)


func _test_hud(animal: Animal) -> void:
	var hud := CanvasLayer.new()
	hud.set_script(load("res://scripts/hud.gd"))
	add_child(hud)
	var build_mode := Node2D.new()
	build_mode.set_script(load("res://scripts/build_mode.gd"))
	add_child(build_mode)
	hud.set_build_mode(build_mode)
	Events.animal_selected.emit(animal)
	print("HUD OK")
