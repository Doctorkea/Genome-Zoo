extends Node

## Headless smoke test — exercises the core systems without needing real
## mouse/window input, so it can run via CLI: see docs/DEMO.md for the
## exact command. Not part of the game; safe to delete or ignore in-editor.


func _ready() -> void:
	print("=== SMOKE TEST START ===")

	_test_grid_service()
	_test_build_catalog()
	_test_floor_tiles()
	_test_placeholder_art()
	_test_trait_library()
	var pen := _test_pen()
	var animal := _test_animal(pen)
	_test_creature_mutation(animal)
	_test_build_mode()
	_test_wallet_service()
	_test_quests()
	var hud := _test_hud(animal)
	_test_street(hud)

	print("=== SMOKE TEST PASSED ===")
	get_tree().quit()


func _test_grid_service() -> void:
	var cell := GridService.world_to_cell(Vector2(250, 140))
	assert(cell == Vector2i(2, 1), "world_to_cell wrong: %s" % [cell])
	assert(GridService.is_area_free(Vector2i(0, 0), Vector2i(4, 3)), "area should start free")
	GridService.occupy_area(Vector2i(0, 0), Vector2i(4, 3), self)
	assert(not GridService.is_area_free(Vector2i(0, 0), Vector2i(4, 3)), "area should now be occupied")
	GridService.free_area(Vector2i(0, 0), Vector2i(4, 3), self)
	assert(GridService.is_area_free(Vector2i(0, 0), Vector2i(4, 3)), "freed area should be empty again")
	GridService.occupy_area(Vector2i(0, 0), Vector2i(4, 3), self)
	assert(GridService.is_area_in_world(Vector2i(0, 0), Vector2i(4, 3)), "origin pad should be on the grass")
	assert(not GridService.is_area_in_world(Vector2i(14, 0), Vector2i(4, 3)), "pen must not hang off the world")
	assert(GridService.map_size().y > GridService.world_size().y, "map should include the road below the grass")
	assert(GridService.parking_rect().position.y == GridService.world_size().y, "parking sits on the grass edge")
	assert(GridService.road_rect().position.y > GridService.parking_rect().position.y, "road sits below the parking strip")
	assert(not GridService.is_area_in_world(Vector2i(0, GridService.WORLD_ROWS), Vector2i(2, 1)), "road cells are not buildable")
	print("GridService OK")


func _test_build_catalog() -> void:
	assert(BuildCatalog.items_for(BuildCatalog.CAT_PENS).size() == 2, "should list two pens")
	assert(BuildCatalog.items_for(BuildCatalog.CAT_ANIMALS).size() == 6, "should list six base animals")
	assert(BuildCatalog.get_item("chimory").get("name") == "Chimory", "chimory should be a base animal")
	assert(BuildCatalog.get_item("jimmothy").get("name") == "Jimmothy", "jimmothy should be a base animal")
	assert(int(BuildCatalog.get_item("jimmothy").get("cost", 0)) == 20, "jimmothy should cost $20")
	var jimothy: Dictionary = BuildCatalog.get_item("jimothy")
	assert(jimothy.get("name") == "Jimothy", "jimothy should be in the catalog")
	assert(int(jimothy.get("cost", 0)) > 0, "jimothy should cost cash")
	assert(BuildCatalog.get_item("horse").get("name") == "Horse", "horse should be a base animal")
	print("BuildCatalog OK")


func _test_floor_tiles() -> void:
	var grass_paths: Array[String] = [
		"res://art/tiles/grass/blade_1.png",
		"res://art/tiles/grass/blade_2.png",
		"res://art/tiles/grass/blade_3.png",
		"res://art/tiles/grass/blade_4.png",
		"res://art/tiles/grass/blade_5.png",
		"res://art/tiles/grass/blade_6.png",
		"res://art/tiles/grass/tuft_1.png",
		"res://art/tiles/grass/tuft_2.png",
		"res://art/tiles/grass/tuft_3.png",
		"res://art/tiles/grass/tuft_4.png",
		"res://art/tiles/grass/tuft_5.png",
		"res://art/tiles/grass/tuft_6.png",
		"res://art/tiles/grass/tuft_7.png",
	]
	for path in grass_paths:
		var tex: Texture2D = load(path)
		assert(tex != null, "missing grass sprite %s" % path)
		assert(tex.get_width() > 0 and tex.get_height() > 0, "%s has no size" % path)
	var floor: Node2D = (load("res://scripts/floor_grid.gd") as GDScript).new()
	add_child(floor)
	var placed: Array = floor.get("_tufts")
	var rects: Array = floor.get("_rects")
	var flips: Array = floor.get("_flips")
	assert(placed.size() > 2500, "blades should spam the lawn, got %d" % placed.size())
	assert(placed.size() < 7000, "lawn draw list got too heavy, got %d" % placed.size())
	var seen: Dictionary = {}
	var flipped: int = 0
	var min_side: float = 999.0
	var max_side: float = 0.0
	var smalls: int = 0
	var clumps: int = 0
	var quadrants: Array[int] = [0, 0, 0, 0]
	var world: Vector2 = GridService.world_size()
	for i in range(rects.size()):
		seen[placed[i]] = true
		if bool(flips[i]):
			flipped += 1
		var side: float = maxf(rects[i].size.x, rects[i].size.y)
		min_side = minf(min_side, side)
		max_side = maxf(max_side, side)
		if side < 42.0:
			smalls += 1
		if side > 60.0:
			clumps += 1
		var mid: Vector2 = rects[i].get_center()
		var qx: int = 0 if mid.x < world.x * 0.5 else 1
		var qy: int = 0 if mid.y < world.y * 0.5 else 1
		quadrants[qx + qy * 2] += 1
	assert(seen.size() == 13, "should use 6 blades + 7 tufts, got %d" % seen.size())
	assert(flipped > 800, "some blades should be flipped, got %d" % flipped)
	assert(smalls > 2000, "most stamps should be small blades, got %d" % smalls)
	assert(clumps > 80, "larger tufts should sit among the blades, got %d" % clumps)
	assert(min_side < 20.0, "blades should stay small, min side %s" % min_side)
	assert(max_side > 60.0 and max_side < 110.0, "tufts should read bigger than blades, max side %s" % max_side)
	for q in quadrants:
		assert(q > 400, "grass should cover every quadrant, got %s" % [quadrants])
	floor.queue_free()
	print("Floor tiles OK — stamps=%d flipped=%d cell=%d" % [placed.size(), flipped, GridService.CELL_SIZE])


func _test_placeholder_art() -> void:
	var canvas := PlaceholderArt.get_canvas_size()
	assert(canvas == 100, "canvas should match one grass tile (100), got %d" % canvas)
	assert(canvas == GridService.CELL_SIZE, "canvas must equal GridService.CELL_SIZE")
	var expected_counts := {
		"body": 5,
		"head": 12,
		"front_legs": 5,
		"back_legs": 5,
		"tail": 5,
	}
	for slot in ["body", "head", "front_legs", "back_legs", "tail"]:
		var opts := PlaceholderArt.get_shape_options(slot)
		var want: int = int(expected_counts[slot])
		assert(opts.size() == want, "%s should have %d options, got %d" % [slot, want, opts.size()])
		for i in range(opts.size()):
			var tex: Texture2D = opts[i]
			assert(tex.get_width() == tex.get_height(),
				"%s option %d must be square, got %dx%d" % [slot, i, tex.get_width(), tex.get_height()])
			assert(tex.get_width() >= canvas,
				"%s option %d is %dpx, expected at least %d" % [slot, i, tex.get_width(), canvas])
	assert(PlaceholderArt.get_palette_options().size() == 3, "should have 3 palettes")
	for path in [
		"res://art/creatures/parts/body_jimothy.png",
		"res://art/creatures/parts/head_jimothy.png",
		"res://art/creatures/parts/front_legs_jimothy.png",
		"res://art/creatures/parts/back_legs_jimothy.png",
		"res://art/creatures/parts/body_chimory.png",
		"res://art/creatures/parts/head_gorilla.png",
		"res://art/creatures/parts/head_cockatoo.png",
		"res://art/creatures/parts/head_turtle.png",
		"res://art/creatures/parts/head_lizard.png",
		"res://art/creatures/parts/head_frog.png",
		"res://art/creatures/parts/head_hamster.png",
		"res://art/creatures/parts/head_duck.png",
		"res://art/creatures/parts/head_lion.png",
		"res://art/creatures/parts/front_legs_chimory.png",
		"res://art/creatures/parts/back_legs_chimory.png",
		"res://art/creatures/parts/tail_chimory.png",
		"res://art/creatures/parts/body_jimmothy.png",
		"res://art/creatures/parts/head_jimmothy.png",
		"res://art/creatures/parts/front_legs_jimmothy.png",
		"res://art/creatures/parts/back_legs_jimmothy.png",
		"res://art/creatures/parts/tail_jimmothy.png",
	]:
		var part: Texture2D = load(path)
		assert(part != null, "missing Jimothy part %s" % path)
		assert(part.get_width() == part.get_height(),
			"%s must be square, got %dx%d" % [path, part.get_width(), part.get_height()])
		assert(part.get_width() >= canvas,
			"%s is %dpx, expected at least %d" % [path, part.get_width(), canvas])
	print("PlaceholderArt OK — all parts %dx%d" % [canvas, canvas])


func _test_pen() -> Pen:
	var pen_scene: PackedScene = load("res://scenes/Pen.tscn")
	var pen := pen_scene.instantiate() as Pen
	pen.footprint_cells = Vector2i(6, 5)
	add_child(pen)
	assert(pen.get_size_pixels() == Vector2(600, 500), "pen size wrong: %s" % [pen.get_size_pixels()])
	var bounds := pen.get_interior_bounds()
	assert(bounds.size.x > 0 and bounds.size.y > 0, "interior bounds should be positive")
	assert(is_equal_approx(pen.wall_thickness(), 50.0), "brick walls should draw at half a cell")
	assert(is_equal_approx(bounds.position.x, 56.0) and is_equal_approx(bounds.position.y, 56.0),
		"interior inset should match the scaled brick wall")
	var wander := pen.get_wander_bounds()
	assert(wander.position.x >= pen.wall_thickness() + Animal.BODY_RADIUS,
		"wander area should keep animal bodies off the bricks")
	assert(wander.end.x <= pen.get_size_pixels().x - (pen.wall_thickness() + Animal.BODY_RADIUS),
		"wander area should stay inside the right wall")
	assert(pen.viewing_points().size() >= 3, "pens should have grass spots to look in")
	assert(pen.animal_capacity() == 5, "large pens should hold 5 animals")
	var bricks := 0
	for child in pen.get_children():
		if child is Sprite2D:
			bricks += 1
			var tex: Texture2D = (child as Sprite2D).texture
			assert(tex != null and tex.get_width() == 100 and tex.get_height() == 100,
				"brick source tiles should stay 100x100")
			assert((child as Sprite2D).scale == Vector2(0.5, 0.5), "brick tiles should draw at half size")
	assert(bricks == 40, "6x5 pen should tile 40 half-size brick pieces, got %d" % bricks)
	print("Pen OK — size=%s bounds=%s bricks=%d" % [pen.get_size_pixels(), bounds, bricks])
	return pen


func _test_animal(pen: Pen) -> Animal:
	var animal_scene: PackedScene = load("res://scenes/Animal.tscn")
	var animal := animal_scene.instantiate() as Animal
	pen.add_child(animal)
	animal.set_pen(pen)
	animal.creature_name = "Test Critter"
	pen.register_animal(animal)
	var stats: Dictionary = animal.get_stats()
	assert(Animal.SPEED < 70.0, "animals should amble, not dash")
	assert(Animal.MIN_PAUSE >= 5.0, "animals should loaf between walks")
	assert((stats.get("parts") as Array).size() == 6, "expected 5 parts + color, got %s" % [stats.get("parts")])
	assert(stats.get("archetype") == "Tanky", "default animal should be Tanky, got %s" % stats.get("archetype"))
	var visitors: Dictionary = stats.get("visitors", {})
	assert(int(visitors.get("children", 0)) > 0, "children should like the default cute stack")
	assert(int(visitors.get("parents", 1)) == 0, "parents should stay neutral")
	assert(int(visitors.get("goths", 0)) < 0, "goths should hate the cute default")
	assert(is_equal_approx(pen.trait_clash(), 0.0), "one animal should not clash with itself")
	assert(is_equal_approx(pen.enjoyment_factor(), 1.0), "a single look should be a clear exhibit")
	assert(pen.occupancy_factor() >= 0.88 and pen.occupancy_factor() <= 1.0,
		"a stocked pen should still be worth viewing")
	var gloop := animal_scene.instantiate() as Animal
	pen.add_child(gloop)
	gloop.set_pen(pen)
	gloop.visuals.apply_loadout(
		{"body": 1, "head": 2, "front_legs": 2, "back_legs": 2, "tail": 2},
		2,
		[]
	)
	pen.register_animal(gloop)
	assert(pen.trait_clash() > 0.55, "cute + gloop in one pen should confuse the crowd")
	assert(pen.enjoyment_factor() < 0.92, "mixed traits should lower enjoyment")
	assert(pen.enjoyment_factor() > 0.75, "a mixed pen should still be worth looking at")
	pen.unregister_animal(gloop)
	gloop.queue_free()
	print("Animal OK — stats=%s" % [stats])
	return animal


func _test_trait_library() -> void:
	var head0: Dictionary = TraitLibrary.get_option("head", 0)
	assert(head0.get("name") == "Jimothy Head", "head 0 should be Jimothy Head")
	assert(TraitLibrary.get_option_count("body") == 5, "body should have 5 options")
	assert(TraitLibrary.get_option_count("head") == 12, "head should include the artist head set")
	assert(TraitLibrary.get_option_count("color") == 3, "color should have 3 palettes")
	assert(TraitLibrary.get_option("head", 3).get("name") == "Gorilla Head", "gorilla head should be in the pool")
	assert(TraitLibrary.get_option("head", 4).get("name") == "Horse Head", "jimmothy head should be in the pool")
	assert(TraitLibrary.get_option("head", 5).get("name") == "Cockatoo Head", "cockatoo head should be in the pool")
	assert(TraitLibrary.get_option("head", 11).get("name") == "Lion Head", "lion head should be in the pool")
	var seen_colors: Dictionary = {}
	for visitor in TraitLibrary.VISITORS:
		var tint: Color = TraitLibrary.visitor_color(str(visitor.get("id", "")))
		var key := "%s,%s,%s" % [snappedf(tint.r, 0.01), snappedf(tint.g, 0.01), snappedf(tint.b, 0.01)]
		assert(not seen_colors.has(key), "visitor colours should be unique, clash on %s" % visitor.get("id"))
		seen_colors[key] = true
	assert(seen_colors.size() == TraitLibrary.VISITORS.size(), "every visitor type needs a colour")
	assert(TraitLibrary.visitor_sprite_paths("children").size() == 2, "children should randomise boy/girl")
	assert(TraitLibrary.visitor_sprite_paths("parents").size() == 2, "parents should randomise mum/dad")
	for path in TraitLibrary.visitor_sprite_paths("children"):
		assert(load(path) != null, "missing child sprite %s" % path)
	for path in TraitLibrary.visitor_sprite_paths("parents"):
		assert(load(path) != null, "missing parent sprite %s" % path)
	var family_kinds: PackedStringArray = TraitLibrary.family_member_kinds()
	assert(family_kinds.has("parents") and family_kinds.has("children"),
		"a family car should carry parents and kids")
	assert(family_kinds.size() >= 2 and family_kinds.size() <= 4, "family size should stay small")

	var zeros: Dictionary = {}
	for slot in TraitLibrary.SHAPE_SLOTS:
		zeros[slot] = 0
	var baseline: Dictionary = TraitLibrary.score_loadout(zeros, 0)
	assert(baseline.get("archetype") == "Tanky", "default loadout should be Tanky, got %s" % baseline.get("archetype"))
	var base_visitors: Dictionary = baseline.get("visitors", {})
	assert(int(base_visitors.get("children", 0)) > 0, "children should like the cute default")
	assert(int(base_visitors.get("parents", 1)) == 0, "parents should stay neutral")
	assert(int(base_visitors.get("goths", 0)) < 0, "goths should hate the cute default")
	assert(int(base_visitors.get("scientists", 0)) < 0, "scientists should call the cute default mediocre")
	assert(int(base_visitors.get("thrill", 0)) < 0, "thrill-seekers should hate the cute default")

	var weird: Dictionary = {}
	for slot in TraitLibrary.SHAPE_SLOTS:
		weird[slot] = 2
	var novelty: Dictionary = TraitLibrary.score_loadout(weird, 2)
	assert(novelty.get("archetype") == "Novelty", "weird loadout should be Novelty, got %s" % novelty.get("archetype"))
	var novelty_visitors: Dictionary = novelty.get("visitors", {})
	assert(int(novelty_visitors.get("goths", 0)) > 0, "goths should like the gross/weird stack")
	assert(int(novelty_visitors.get("thrill", 0)) > 0, "thrill-seekers should like the scary stack")
	assert(int(novelty_visitors.get("scientists", 0)) > 0, "scientists should like a unique stack")
	var crowd: Dictionary = TraitLibrary.crowd_notes(baseline.get("tags", {}))
	var like_names: PackedStringArray = PackedStringArray()
	var dislike_names: PackedStringArray = PackedStringArray()
	for note in crowd.get("likes", []):
		like_names.append(str(note.get("name", "")))
		if str(note.get("name", "")) == "Children":
			assert(str(note.get("reason", "")).contains("cute"), "children should mention cute")
	for note in crowd.get("dislikes", []):
		dislike_names.append(str(note.get("name", "")))
	assert(like_names.has("Children"), "default crowd should include children")
	assert(not like_names.has("Parents"), "parents stay quiet when they have no opinion")
	assert(dislike_names.has("Goths"), "goths should stay away from the cute default")
	assert(dislike_names.has("Thrill-Seekers"), "thrill-seekers should stay away from the cute default")
	var roster: Array[Dictionary] = TraitLibrary.audience_notes(baseline.get("tags", {}))
	assert(roster.size() == TraitLibrary.VISITORS.size(), "audience roster should list every visitor type")
	var parent_reason := ""
	for note in roster:
		if str(note.get("name", "")) == "Parents":
			parent_reason = str(note.get("reason", ""))
	assert(parent_reason.contains("ride"), "parents still get a reason when they shrug")
	var lead: Dictionary = TraitLibrary.prominent_look(baseline.get("tags", {}))
	assert(str(lead.get("name", "")) == "Cute", "default prominent look should be Cute")
	var tied: Dictionary = {"Bulky": 4, "Cute": 4}
	assert(str(TraitLibrary.prominent_look(tied).get("name", "")) == "Bulky",
		"tied looks should pick the first name alphabetically")
	var chrono: Array[Dictionary] = TraitLibrary.present_looks(baseline.get("tags", {}))
	assert(chrono.size() == 2 and str(chrono[0].get("name", "")) == "Cute",
		"present looks should stay in tag-list order")
	assert(TraitLibrary.slot_display_name("body") == "Torso", "body slot should display as Torso")
	for _i in range(16):
		var other: int = TraitLibrary.pick_other_index("head", 1)
		assert(other != 1, "pick_other_index must not pick the current option")
		assert(other >= 0 and other < TraitLibrary.get_option_count("head"), "pick_other_index out of range: %d" % other)
	for _j in range(16):
		var cute: int = TraitLibrary.pick_other_with_tag("head", 0, "Cute", 0)
		assert(cute != 0, "cute serum should change a cute head")
		assert(TraitLibrary.option_has_tag("head", cute, "Cute"), "cute pick must keep the Cute tag")
	assert(TraitLibrary.option_rarity("body", 2) == 2, "spiky body should be exotic")
	assert(TraitLibrary.pick_other_from_ids("head", 0, ["lion", "horned"]) != 0,
		"exotic pool should swap onto a listed head")
	assert(TraitLibrary.pick_other_with_tag("color", 0, "Cute", 0) == 0,
		"fur is the only Cute color, so the serum should fail")
	assert(int(TraitLibrary.get_option("head", 11).get("rarity", -1)) == 2,
		"lion head should be exotic")
	assert(TraitLibrary.tag_clash(baseline.get("tags", {}), baseline.get("tags", {})) == 0.0,
		"identical loadouts should not clash")
	assert(TraitLibrary.tag_clash(baseline.get("tags", {}), novelty.get("tags", {})) > 0.6,
		"cute vs weird/gross should clash")
	print("TraitLibrary OK — baseline=%s novelty=%s" % [baseline, novelty])


func _test_creature_mutation(animal: Animal) -> void:
	var before: Dictionary = animal.get_stats()
	animal.visuals.set_part_shape("head", 1)
	assert(animal.visuals.get_current_index("head") == 1, "head mutation didn't apply")
	animal.visuals.set_skin(2)
	assert(animal.visuals.get_current_palette_index() == 2, "skin mutation didn't apply")
	var after: Dictionary = animal.get_stats()
	assert(after.get("archetype") != "", "mutated animal should still have an archetype")
	var before_visitors: Dictionary = before.get("visitors", {})
	var after_visitors: Dictionary = after.get("visitors", {})
	assert(int(after_visitors.get("goths", 0)) != int(before_visitors.get("goths", 0)) \
		or int(after_visitors.get("children", 0)) != int(before_visitors.get("children", 0)),
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
	assert(jimothy.visuals.get_node_or_null("Eyes") == null, "eyes slot should be gone; eyes live on the head")
	assert(not jimothy.visuals.get_node("Tail").visible, "Jimothy demo should hide procedural tail")
	var occupied_origin := jimothy.get_pen().origin_cell
	var occupied_size := jimothy.get_pen().footprint_cells
	var first_pen: Pen = jimothy.get_pen()
	assert(first_pen.animal_capacity() == 2, "small pens should hold 2 animals")
	assert(first_pen.can_accept_animal(), "starter exhibit still has a free stall")
	var extra: Animal = (load("res://scenes/Animal.tscn") as PackedScene).instantiate() as Animal
	first_pen.add_child(extra)
	extra.set_pen(first_pen)
	first_pen.register_animal(extra)
	assert(first_pen.occupant_count() == 2, "small pens should fill at two animals")
	assert(not first_pen.can_accept_animal(), "a full small pen should refuse a third")
	first_pen.unregister_animal(extra)
	extra.queue_free()
	assert(not GridService.is_area_free(occupied_origin, occupied_size), "starter pad should occupy grass")
	build_mode.delete_animal(jimothy)
	assert(jimothy.is_queued_for_deletion(), "delete animal should queue the creature")
	assert(is_instance_valid(first_pen), "deleting an animal should leave the pen")
	assert(not GridService.is_area_free(occupied_origin, occupied_size), "empty pen should still occupy grass")
	build_mode.delete_pen(first_pen)
	assert(first_pen.is_queued_for_deletion(), "delete pen should queue the paddock")
	assert(GridService.is_area_free(occupied_origin, occupied_size), "deleted pen should free its grass")
	var second: Animal = build_mode.spawn_starter_exhibit()
	var second_pen: Pen = second.get_pen()
	build_mode.delete_pen(second_pen)
	assert(second.is_queued_for_deletion(), "deleting a pen should also delete animals inside")
	assert(second_pen.is_queued_for_deletion(), "delete pen should queue the occupied paddock")
	assert(GridService.is_area_free(occupied_origin, occupied_size), "tearing down an occupied pen should free grass")
	print("BuildMode OK")


func _test_wallet_service() -> void:
	var start_money: int = WalletService.money
	assert(WalletService.spend(5), "should afford spending $5")
	assert(WalletService.money == start_money - 5, "cash didn't decrease")
	assert(not WalletService.spend(100000), "shouldn't afford spending $100000")
	var before_tick: int = WalletService.money
	assert(WalletService.collect_tickets() == 0, "empty zoo should pay nothing")
	assert(WalletService.money == before_tick, "ticket collection should not mint cash with no guests")
	print("WalletService OK — money=%d" % WalletService.money)


func _test_quests() -> void:
	assert(GeneTree.is_vial_unlocked("cute"), "Cute serum should start unlocked")
	assert(GeneTree.stock_of("cute") >= 1, "the lab should start with one Cute charge")
	assert(not GeneTree.is_vial_unlocked("scary"), "Scary should stay gated until a quest pays it out")
	assert(QuestBoard.current().get("id") == "fence", "first quest should ask for a pen")
	assert(QuestBoard.reward_text().contains("$15"), "quest should show a cash reward")
	QuestBoard.evaluate()
	assert(QuestBoard.ready_to_claim, "a placed pen should complete Fence it in")
	var money_before: int = WalletService.money
	assert(QuestBoard.claim(), "should claim the pen quest")
	assert(WalletService.money == money_before + 15, "claiming should pay the cash reward")
	assert(QuestBoard.current().get("id") == "stock", "next quest should ask for an animal")
	assert(QuestBoard.reward_text().contains("$20"), "stock quest should show its reward")
	assert(QuestBoard.claim(), "a placed animal should complete Something to look at")
	assert(QuestBoard.current().get("id") == "splice", "third quest should ask for a mutation")
	assert(QuestBoard.reward_text().contains("Majestic"), "splice quest should unlock Majestic serum")
	assert(not QuestBoard.ready_to_claim, "splice should wait for a lab drop")
	var cute_before: int = GeneTree.stock_of("cute")
	WalletService.money += 40
	Events.money_changed.emit(WalletService.money)
	assert(GeneTree.buy_vial("cute"), "should afford Cute serum")
	assert(GeneTree.stock_of("cute") == cute_before + 1, "buying should add a Cute charge")
	assert(GeneTree.consume_vial("cute"), "should consume a Cute charge")
	assert(GeneTree.stock_of("cute") == cute_before, "consume should return to the start count")
	print("Quests OK — current=%s" % QuestBoard.current().get("id"))


func _test_hud(animal: Animal) -> Control:
	var hud_scene: PackedScene = load("res://scenes/ui/HUD.tscn")
	var hud := hud_scene.instantiate() as Control
	add_child(hud)
	var build_mode := Node2D.new()
	build_mode.set_script(load("res://scripts/build_mode.gd"))
	add_child(build_mode)
	hud.set_build_mode(build_mode)
	hud._on_cat_pens()
	assert(hud.get_node("%CatalogRibbon").visible, "Pens tab should open the catalog ribbon")
	assert(hud.get_node("%CatalogRow").get_child_count() == 2, "Pens ribbon should show two priced pens")
	Events.animal_selected.emit(animal)
	assert(hud.get_node("%StatsPanel").visible, "stats panel should show after select")
	var archetype_text: String = hud.get_node("%StatsArchetype").text
	assert(archetype_text.contains("Tanky") or archetype_text.contains(str(animal.get_stats().get("archetype"))),
		"stats panel should show archetype, got '%s'" % archetype_text)
	assert(_tag_meter_names(hud.get_node("%LooksLead")).contains("Bulky") \
		or _tag_meter_names(hud.get_node("%LooksLead")).contains("Cute"),
		"collapsed looks should show the prominent trait")
	assert(not hud.get_node("%AudienceList").visible, "audience starts closed")
	assert(not hud.get_node("%LooksList").visible, "looks list starts closed")
	hud._on_toggle_audience()
	assert(hud.get_node("%AudienceList").visible, "audience dropdown should open")
	assert(not hud.get_node("%LooksList").visible, "opening audience should keep looks closed")
	var audience_copy := _crowd_card_text(hud.get_node("%AudienceList"))
	assert(audience_copy.contains("Likes"), "audience should group likes")
	assert(audience_copy.contains("Dislikes"), "audience should group dislikes")
	assert(audience_copy.contains("Children"), "audience should list children")
	assert(audience_copy.contains("Scientists"), "audience should list scientists")
	assert(not audience_copy.contains("Parents"), "audience should hide visitors with no opinion")
	assert(hud.get_node("%CardScroll") != null, "exhibit card should scroll inside itself")
	hud._on_toggle_looks()
	assert(hud.get_node("%LooksList").visible, "looks dropdown should open")
	assert(not hud.get_node("%AudienceList").visible, "opening looks should close audience")
	assert(not hud.get_node("%LooksLead").visible, "expanded looks hides the single lead")
	assert(hud.get_node("%LooksList").get_child_count() > 1, "expanded looks should list every present trait")
	assert(str(hud.get_node("%WalletLabel").text).begins_with("$"), "wallet chip should show cash")
	hud._on_mutate_pressed()
	assert(hud.get_node("%LabPanel").visible, "DNA Lab should open from the exhibit card")
	assert(hud.get_node("%StatsPanel").get_parent() == hud.get_node("%LabCardHost"),
		"exhibit card should sit on the right of the lab")
	hud._on_open_quests()
	assert(hud.get_node("%QuestPanel").visible, "quest overlay should open")
	assert(str(hud.get_node("%QuestName").text) != "", "quest card should show a title")
	assert(str(hud.get_node("%QuestReward").text).begins_with("Reward:"), "quest card should show the reward")
	hud._on_close_quests()
	hud._on_open_shop()
	assert(hud.get_node("%ShopList").get_child_count() > 0, "shop should list unlocked serums")
	hud._on_close_shop()
	assert(hud.get_node("%VialRow").get_child_count() > 0, "lab tray should show unlocked serums")
	animal.visuals.set_part_shape("head", 1)
	var head_before: int = animal.visuals.get_current_index("head")
	hud._on_lab_slot_pressed("head")
	if GeneTree.stock_of("cute") <= 0:
		GeneTree.add_stock("cute", 1)
	hud._on_vial_dropped("cute")
	var head_after: int = animal.visuals.get_current_index("head")
	assert(head_after != head_before, "Cute serum should change the selected part")
	assert(TraitLibrary.option_has_tag("head", head_after, "Cute"), "Cute serum should land on a Cute head")
	animal.visuals.set_skin(0)
	var cute_stock: int = GeneTree.stock_of("cute")
	if cute_stock <= 0:
		GeneTree.add_stock("cute", 1)
		cute_stock = GeneTree.stock_of("cute")
	hud._on_lab_slot_pressed("color")
	hud._on_vial_dropped("cute")
	assert(animal.visuals.get_current_palette_index() == 0, "fur has no other Cute form")
	assert(GeneTree.stock_of("cute") == cute_stock, "a failed drop should not consume a charge")
	GeneTree.unlock_vial("linger", 1)
	hud._on_vial_dropped("linger")
	assert(animal.has_perk(GeneTree.PERK_LINGER), "Linger graft should attach without swapping a part")
	assert(animal.get_pen().has_animal_perk(GeneTree.PERK_LINGER), "the pen should expose the graft")
	assert(hud.get_node("%DeleteAnimal") != null, "exhibit card should have a delete animal button")
	Events.pen_selected.emit(animal.get_pen())
	assert(hud.get_node("%PenPanel").visible, "pen card should show after clicking a paddock")
	assert(str(hud.get_node("%PenDetail").text).contains("/"), "pen card should show occupancy")
	assert(not hud.get_node("%StatsPanel").visible, "pen card should hide the exhibit card")
	assert(hud.get_node("%DeletePen") != null, "pen card should have a delete pen button")
	hud._on_close_pen()
	assert(not hud.get_node("%PenPanel").visible, "Close should hide the pen card")
	var solo: Visitor = (load("res://scenes/Visitor.tscn") as PackedScene).instantiate()
	add_child(solo)
	solo.setup(null, "goths", Vector2(220, 180))
	Events.visitor_selected.emit(solo)
	assert(hud.get_node("%GuestPanel").visible, "guest card should show after clicking a visitor")
	assert(not hud.get_node("%StatsPanel").visible, "guest card should hide the exhibit card")
	assert(str(hud.get_node("%GuestName").text) == "A goth", "solo guest card should name the visitor")
	assert(str(hud.get_node("%GuestKind").text).contains("Goth"), "guest card should say what they are")
	var like_copy := _crowd_card_text(hud.get_node("%GuestLikes"))
	var hate_copy := _crowd_card_text(hud.get_node("%GuestDislikes"))
	assert(like_copy.contains("Scary"), "goths should list Scary as a like")
	assert(hate_copy.contains("Cute"), "goths should list Cute as a dislike")
	assert(hud.get_node("%GuestThumbCamera") != null, "guest card should have a follow camera")
	assert(str(hud.get_node("%GuestThought").text).contains("grim"),
		"guest thoughts should say how they feel about the zoo, got '%s'" % hud.get_node("%GuestThought").text)
	hud._on_close_guest()
	assert(not hud.get_node("%GuestPanel").visible, "Close should hide the guest card")
	solo.free()
	print("HUD OK")
	return hud


func _test_street(hud: Control = null) -> void:
	var street_scene: PackedScene = load("res://scenes/Street.tscn")
	var street: Node = street_scene.instantiate()
	add_child(street)
	assert(street.bay_count() == 6, "should mark six parallel roadside parks")
	assert(street.westbound_y() > GridService.parking_rect().end.y, "the near lane stays on the asphalt")
	assert(street.westbound_y() < street.eastbound_y(), "left-hand traffic uses the lane beside the parks")
	assert(Car.SIZE.x >= float(GridService.CELL_SIZE) * 0.9, "cars should read at pen-cell scale")
	assert(Visitor.DISPLAY_HEIGHT > 40.0 and Visitor.DISPLAY_HEIGHT < 60.0,
		"patrons should be a quarter smaller than the old 68px height")
	assert(GridService.parking_rect().size.y > Car.SIZE.y + 16.0, "parking strip should fit a car")
	assert(street.visitor_cap() == GeneTree.visitor_cap(), "street cap should follow gene-tree park perks")
	var passer: Node = street.spawn_traffic(1)
	assert(passer != null and int(passer.get("role")) == 0, "passing cars should spawn on the road")
	var dropoff: Node = street.spawn_dropoff()
	assert(dropoff != null and int(dropoff.get("role")) == 1, "a free bay should take a drop-off car")
	assert(int(dropoff.get("bay_index")) >= 0, "drop-off cars need a reserved bay")
	street.drop_visitor(dropoff)
	assert(street.visitor_count() >= 1, "getting out should spawn a visitor")
	var park: Vector2 = GridService.parking_rect().get_center()
	var leader: Visitor = street.spawn_family(park)
	assert(leader != null and leader.is_leader(), "family drop should return a parent lead")
	var party: Array = street.family_of(leader)
	assert(party.size() >= 2, "families should get out of one car together, got %d" % party.size())
	var saw_kid := false
	for mate in party:
		if str(mate.visitor_id) == "children":
			saw_kid = true
	assert(saw_kid, "family cars should include children")
	var family_card: Dictionary = leader.inspect_party()
	assert(bool(family_card.get("family", false)), "a family inspect should treat the group as one")
	assert(str(family_card.get("title", "")) == "A family", "family card should say who they are")
	assert(str(family_card.get("kind", "")).contains("parent"), "family card should say what they are")
	assert(str(family_card.get("kind", "")).contains("child"), "family card should mention the children")
	var family_likes: PackedStringArray = family_card.get("likes", PackedStringArray())
	var family_hates: PackedStringArray = family_card.get("dislikes", PackedStringArray())
	assert(family_likes.has("Cute") and family_likes.has("Silly"), "family likes should union the children's tastes")
	assert(family_hates.has("Scary"), "family dislikes should union the children's tastes")
	var kid: Visitor = null
	for mate in party:
		if str(mate.visitor_id) == "children":
			kid = mate
			break
	assert(kid != null, "family inspect needs a child member")
	var kid_card: Dictionary = kid.inspect_party()
	assert(str(kid_card.get("title", "")) == str(family_card.get("title", "")), "clicking any family member should open the same card")
	assert(str(family_card.get("thought", "")).contains("kids"),
		"family thoughts should say how they feel about the zoo")
	var span: float = leader.party_span()
	assert(span >= 36.0, "follow camera should cover the family, span %s" % span)
	if party.size() >= 3:
		assert(span > 36.0, "follow camera should zoom out to fit the group, span %s" % span)
	if hud != null:
		Events.visitor_selected.emit(kid)
		assert(hud.get_node("%GuestPanel").visible, "clicking a family should open the guest card")
		assert(str(hud.get_node("%GuestName").text) == "A family", "guest card should name the family as one")
		assert(str(hud.get_node("%GuestKind").text).contains("together"), "guest card should describe the family")
		assert(_crowd_card_text(hud.get_node("%GuestLikes")).contains("Cute"), "family guest card should list likes")
		assert(_crowd_card_text(hud.get_node("%GuestDislikes")).contains("Scary"), "family guest card should list dislikes")
		assert(str(hud.get_node("%GuestThought").text).contains("kids"),
			"family guest card should show a shared thought")
		hud._process(0.0)
		var cam: Camera2D = hud.get_node("%GuestThumbCamera") as Camera2D
		assert(cam != null, "family guest card should keep a follow camera")
		assert(cam.global_position.distance_to(leader.party_center()) < 80.0,
			"follow camera should track the family as a group")
		hud._on_close_guest()
		assert(not hud.get_node("%GuestPanel").visible, "Close should hide the family guest card")
	var guest: Visitor = leader
	assert(guest.get("fill_color") == TraitLibrary.visitor_color(str(guest.get("visitor_id"))),
		"visitor colour should match their type")
	var sprite: Sprite2D = guest.get_node("Sprite2D") as Sprite2D
	assert(sprite != null and sprite.texture != null, "patrons should use the visitor sprite")
	var family: PackedStringArray = TraitLibrary.visitor_sprite_paths(str(guest.get("visitor_id")))
	assert(family.has(str(guest.get("look_path"))), "guest should pick a sprite for their type")
	assert(not GridService.road_rect().has_point(guest.position), "patrons must not spawn on the road")
	var full_ticket: int = guest.ticket_value()
	var expected_full: int = maxi(1, int(round(float(Visitor.TICKET_MAX) * GeneTree.ticket_multiplier())))
	assert(full_ticket == expected_full, "fresh guests should pay full tickets, got %d expected %d" % [full_ticket, expected_full])
	guest.interest = Visitor.MAX_INTEREST * 0.2
	assert(int(guest.ticket_value()) == 0, "unhappy guests should stop spending")
	guest.interest = Visitor.MAX_INTEREST * 0.55
	var low_ticket: int = guest.ticket_value()
	assert(low_ticket > 0 and low_ticket < full_ticket, "bored guests should pay less, got %d vs %d" % [low_ticket, full_ticket])
	guest.interest = Visitor.MAX_INTEREST
	guest._drain_interest(2.0)
	assert(guest.interest < Visitor.MAX_INTEREST, "interest should drain while idle")
	guest.interest = Visitor.MAX_INTEREST
	var heading: Vector2 = street.wander_point(guest)
	var attracted := false
	for node in get_tree().get_nodes_in_group("pens"):
		var pen := node as Pen
		if pen == null or pen.exhibit_signature().is_empty():
			continue
		for spot in pen.viewing_points():
			if heading.distance_to(spot) <= 1.0:
				attracted = true
				break
	assert(attracted, "visitors should walk to a pen fence to look in")
	guest.hail()
	assert(int(guest.get("pickup_bay")) >= 0, "right-click hail should reserve a kerb stall")
	assert(int(guest.ticket_value()) == 0, "leaving guests should stop paying")
	for mate in street.family_of(guest):
		assert(int(mate.pickup_bay) == int(guest.pickup_bay), "the family should share one pickup car")
		assert(bool(mate._leaving), "the whole family should leave together")
	guest.pickup_bay = -1
	guest._leaving = false
	guest._state = 1
	guest.interest = Visitor.MAX_INTEREST
	var before_pay: int = WalletService.money
	var paid: int = WalletService.collect_tickets()
	assert(paid > 0, "interested guests should pay tickets")
	assert(WalletService.money == before_pay + paid, "ticket cash should be added")
	guest.global_position = Vector2(80.0, 80.0)
	var build := Node2D.new()
	build.set_script(load("res://scripts/build_mode.gd"))
	add_child(build)
	var crushed: int = build.crush_visitors_in_rect(Rect2(0.0, 0.0, 400.0, 300.0))
	assert(crushed == 1, "placing a pen on a guest should despawn them, got %d" % crushed)
	assert(guest.is_queued_for_deletion(), "crushed guests should despawn")
	print("Street OK — bays=%d visitors=%d" % [street.bay_count(), street.visitor_count()])


func _crowd_card_text(root: Node) -> String:
	var bits: PackedStringArray = PackedStringArray()
	for node in root.find_children("*", "Label", true, false):
		var label := node as Label
		if label != null:
			bits.append(label.text)
	return " ".join(bits)


func _tag_meter_names(root: Node) -> String:
	var bits: PackedStringArray = PackedStringArray()
	for node in root.find_children("*", "Label", true, false):
		var label := node as Label
		if label != null:
			bits.append(label.text)
	return " ".join(bits)
