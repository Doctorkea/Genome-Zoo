extends Node

## Headless smoke test — exercises the core systems without needing real
## mouse/window input, so it can run via CLI: see docs/DEMO.md for the
## exact command. Not part of the game; safe to delete or ignore in-editor.


func _ready() -> void:
	print("=== SMOKE TEST START ===")

	_test_grid_service()
	_test_floor_tiles()
	_test_placeholder_art()
	_test_trait_library()
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


func _test_floor_tiles() -> void:
	const ART_SIZE: int = 100
	for path in [
		"res://art/tiles/grass/grass_1.png",
		"res://art/tiles/grass/grass_2.png",
		"res://art/tiles/grass/grass_3.png",
		"res://art/tiles/grass/grass_4.png",
		"res://art/tiles/grass/grass_5.png",
		"res://art/tiles/grass/grass_flowers_1.png",
		"res://art/tiles/grass/grass_flowers_2.png",
		"res://art/tiles/grass/grass_flowers_3.png",
		"res://art/tiles/grass/grass_flowers_4.png",
	]:
		var tex: Texture2D = load(path)
		assert(tex != null, "missing floor tile %s" % path)
		assert(tex.get_width() == ART_SIZE and tex.get_height() == ART_SIZE,
			"%s is %dx%d, expected %dx%d" % [path, tex.get_width(), tex.get_height(), ART_SIZE, ART_SIZE])
	print("Floor tiles OK — 9 tiles at %dx%d, cell=%d" % [ART_SIZE, ART_SIZE, GridService.CELL_SIZE])


func _test_placeholder_art() -> void:
	var canvas := PlaceholderArt.get_canvas_size()
	assert(canvas == 100, "canvas should match one grass tile (100), got %d" % canvas)
	assert(canvas == GridService.CELL_SIZE, "canvas must equal GridService.CELL_SIZE")
	for slot in ["body", "head", "eyes", "front_legs", "back_legs", "tail"]:
		var opts := PlaceholderArt.get_shape_options(slot)
		assert(opts.size() == 3, "%s should have 3 options, got %d" % [slot, opts.size()])
		for i in range(opts.size()):
			var tex: Texture2D = opts[i]
			assert(tex.get_width() == canvas and tex.get_height() == canvas,
				"%s option %d is %dx%d, expected %dx%d" % [slot, i, tex.get_width(), tex.get_height(), canvas, canvas])
	assert(PlaceholderArt.get_palette_options().size() == 3, "should have 3 palettes")
	for path in [
		"res://art/creatures/parts/body_jimothy.png",
		"res://art/creatures/parts/head_jimothy.png",
		"res://art/creatures/parts/front_legs_jimothy.png",
		"res://art/creatures/parts/back_legs_jimothy.png",
	]:
		var part: Texture2D = load(path)
		assert(part != null, "missing Jimothy part %s" % path)
		assert(part.get_width() == canvas and part.get_height() == canvas,
			"%s is %dx%d, expected %dx%d" % [path, part.get_width(), part.get_height(), canvas, canvas])
	print("PlaceholderArt OK — all parts %dx%d" % [canvas, canvas])


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
	assert((stats.get("parts") as Array).size() == 7, "expected 6 parts + color, got %s" % [stats.get("parts")])
	assert(stats.get("archetype") == "Tanky", "default animal should be Tanky, got %s" % stats.get("archetype"))
	assert(int(stats.get("families", 0)) > 0, "families should like the default cute/bulky stack")
	print("Animal OK — stats=%s" % [stats])
	return animal


func _test_trait_library() -> void:
	var head0: Dictionary = TraitLibrary.get_option("head", 0)
	assert(head0.get("name") == "Jimothy Head", "head 0 should be Jimothy Head")
	assert(TraitLibrary.get_option_count("body") == 3, "each slot should have 3 options")
	assert(TraitLibrary.get_option_count("color") == 3, "color should have 3 palettes")

	var zeros: Dictionary = {}
	for slot in TraitLibrary.SHAPE_SLOTS:
		zeros[slot] = 0
	var baseline: Dictionary = TraitLibrary.score_loadout(zeros, 0)
	assert(baseline.get("archetype") == "Tanky", "default loadout should be Tanky, got %s" % baseline.get("archetype"))
	assert(int(baseline.get("families", 0)) > 0, "families should like the cute default")
	assert(int(baseline.get("thrill", 0)) < 0, "thrill-seekers should be bored by the cute default")

	var weird: Dictionary = {}
	for slot in TraitLibrary.SHAPE_SLOTS:
		weird[slot] = 2
	var novelty: Dictionary = TraitLibrary.score_loadout(weird, 2)
	assert(novelty.get("archetype") == "Novelty", "weird loadout should be Novelty, got %s" % novelty.get("archetype"))
	assert(int(novelty.get("families", 0)) < 0, "families should hate the gross/weird stack")
	assert(int(novelty.get("thrill", 0)) > 0, "thrill-seekers should like the weird stack")
	print("TraitLibrary OK — baseline=%s novelty=%s" % [baseline, novelty])


func _test_creature_mutation(animal: Animal) -> void:
	var before: Dictionary = animal.get_stats()
	animal.visuals.set_part_shape("head", 1)
	assert(animal.visuals.get_current_index("head") == 1, "head mutation didn't apply")
	animal.visuals.set_skin(2)
	assert(animal.visuals.get_current_palette_index() == 2, "skin mutation didn't apply")
	var after: Dictionary = animal.get_stats()
	assert(after.get("archetype") != "", "mutated animal should still have an archetype")
	assert(int(after.get("families", 0)) != int(before.get("families", 0)) or int(after.get("thrill", 0)) != int(before.get("thrill", 0)),
		"mutation should change at least one visitor score")
	print("Creature mutation OK — stats=%s" % [after])


func _test_build_mode() -> void:
	var build_mode := Node2D.new()
	build_mode.set_script(load("res://scripts/build_mode.gd"))
	add_child(build_mode)
	build_mode.set_mode(BuildMode.Mode.PLACE_PEN_SMALL)
	assert(build_mode.current_mode == BuildMode.Mode.PLACE_PEN_SMALL, "set_mode didn't apply")
	var jimothy: Animal = build_mode.spawn_starter_exhibit()
	assert(jimothy != null and jimothy.creature_name == "Jimothy", "starter exhibit should spawn Jimothy")
	assert(not jimothy.visuals.get_node("Eyes").visible, "Jimothy demo should hide procedural eyes")
	assert(not jimothy.visuals.get_node("Tail").visible, "Jimothy demo should hide procedural tail")
	print("BuildMode OK")


func _test_mutagen_service() -> void:
	var start_points: int = MutagenService.points
	assert(MutagenService.spend(5), "should afford spending 5")
	assert(MutagenService.points == start_points - 5, "points didn't decrease")
	assert(not MutagenService.spend(100000), "shouldn't afford spending 100000")
	print("MutagenService OK — points=%d" % MutagenService.points)


func _test_hud(animal: Animal) -> void:
	var hud_scene: PackedScene = load("res://scenes/ui/HUD.tscn")
	var hud := hud_scene.instantiate() as Control
	add_child(hud)
	var build_mode := Node2D.new()
	build_mode.set_script(load("res://scripts/build_mode.gd"))
	add_child(build_mode)
	hud.set_build_mode(build_mode)
	Events.animal_selected.emit(animal)
	assert(hud.get_node("%StatsPanel").visible, "stats panel should show after select")
	var archetype_text: String = hud.get_node("%StatsArchetype").text
	assert(archetype_text.contains("Tanky") or archetype_text.contains(str(animal.get_stats().get("archetype"))),
		"stats panel should show archetype, got '%s'" % archetype_text)
	assert(not hud.get_node("%StatsTags").text.is_empty(), "stats panel should list tags")
	print("HUD OK")
