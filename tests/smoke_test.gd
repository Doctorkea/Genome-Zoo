extends Node

## Headless smoke test — exercises the core systems without needing real
## mouse/window input, so it can run via CLI: see docs/DEMO.md for the
## exact command. Not part of the game; safe to delete or ignore in-editor.

const ZooFx := preload("res://scripts/fx.gd")


func _ready() -> void:
	print("=== SMOKE TEST START ===")
	TutorialService.skip()

	_test_grid_service()
	_test_build_catalog()
	_test_floor_tiles()
	_test_placeholder_art()
	_test_fx()
	_test_trait_library()
	_test_serum_art()
	_test_zoo_hours_empty()
	var pen := _test_pen()
	var animal := _test_animal(pen)
	_test_creature_mutation(animal)
	_test_build_mode()
	_test_wallet_service()
	_test_quests()
	_test_title_and_save()
	_test_names_clones_and_breeding(pen, animal)
	var hud := await _test_hud(animal)
	_test_street(hud)

	print("=== SMOKE TEST PASSED ===")
	get_tree().quit(0)


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
	GridService.free_area(Vector2i(0, 0), Vector2i(4, 3), self)
	print("GridService OK")


func _test_build_catalog() -> void:
	assert(BuildCatalog.items_for(BuildCatalog.CAT_PENS).size() == 4, "should list four pens")
	assert(BuildCatalog.items_for(BuildCatalog.CAT_ANIMALS).size() == 3, "should list three base animals")
	assert(BuildCatalog.items_for(BuildCatalog.CAT_PATHS).size() == 2, "should list a path tile and a delete tool")
	assert(int(BuildCatalog.get_item("path_stone").get("cost", 0)) == 1, "stone path should cost $1")
	assert(str(BuildCatalog.get_item("path_delete").get("kind", "")) == "delete_path", "paths should include a delete tool")
	assert(GridService.PATH_CELL_SIZE == 50, "paths should be half a grass cell")
	assert(GridService.PATH_CELL_SIZE == GridService.CELL_SIZE / 2, "a path tile should sit on half a grass cell")
	assert(str(BuildCatalog.get_item("pen_large").get("unlock_quest", "")) == "expand", "large pens should wait on Another enclosure")
	assert(str(BuildCatalog.get_item("pen_gallery").get("unlock_quest", "")) == "stay", "gallery should wait on a later quest")
	assert(str(BuildCatalog.get_item("loin").get("unlock_quest", "")) == "stock", "Lion should wait on the second quest")
	assert(str(BuildCatalog.get_item("gorllia").get("unlock_quest", "")) == "gates", "Gorllia should wait on the third quest")
	assert(BuildCatalog.is_unlocked(BuildCatalog.get_item("pen_tiny")), "tiny pens should start unlocked")
	assert(BuildCatalog.is_unlocked(BuildCatalog.get_item("horse")), "Horse should start unlocked")
	assert(not BuildCatalog.is_unlocked(BuildCatalog.get_item("pen_large")), "large pens should start locked")
	assert(not BuildCatalog.is_unlocked(BuildCatalog.get_item("loin")), "Lion should start locked")
	assert(not BuildCatalog.is_unlocked(BuildCatalog.get_item("gorllia")), "Gorllia should start locked")
	assert(BuildCatalog.unlock_hint(BuildCatalog.get_item("pen_large")).contains("Another enclosure"),
		"locked tiles should name the quest that opens them")
	assert(BuildCatalog.get_item("loin").get("name") == "Lion", "lion should be a base animal")
	assert(BuildCatalog.get_item("gorllia").get("name") == "Gorllia", "gorllia should be a base animal")
	assert(int(BuildCatalog.get_item("horse").get("cost", 0)) == 25, "horse should cost $25")
	assert(int(BuildCatalog.get_item("pen_tiny").get("capacity", 0)) == 1, "tiny pen should hold one")
	assert(int(BuildCatalog.get_item("pen_gallery").get("capacity", 0)) == 4, "gallery should hold four")
	var rewarded: Dictionary = {"cute": true}
	for quest in QuestBoard.QUESTS:
		var vial_id: String = str(quest.get("reward_vial", ""))
		if not vial_id.is_empty():
			rewarded[vial_id] = true
		var perk_id: String = str(quest.get("reward_perk", ""))
		if not perk_id.is_empty():
			rewarded[perk_id] = true
	for vial in GeneTree.VIALS:
		var id: String = str(vial.get("id", ""))
		assert(bool(rewarded.get(id, false)), "serum %s needs a quest unlock" % id)
	assert(not bool(rewarded.get("open_longer", false)), "open longer should not be a quest perk")
	assert(bool(rewarded.get(GeneTree.PERK_TICKET_BOOTH, false)), "ticket booth should be a quest perk")
	assert(bool(rewarded.get(GeneTree.PERK_CROWD_PULL, false)), "crowd pull should be a quest perk")
	assert(bool(rewarded.get(GeneTree.PERK_MORE_PARKING, false)), "more parking should be a quest perk")
	assert(bool(rewarded.get(GeneTree.PERK_MORE_ADS, false)), "more advertising should be a quest perk")
	var horse: Dictionary = BuildCatalog.get_item("horse")
	assert(horse.get("name") == "Horse", "horse should be in the catalog")
	assert(int(horse.get("cost", 0)) > 0, "horse should cost cash")
	assert((horse.get("hide") as Array).has("tail"), "horse should spawn without a tail")
	assert(BuildCatalog.get_item("jimothy").is_empty(), "old jimothy starter should be gone")
	assert(BuildCatalog.get_item("jimmothy").is_empty(), "old jimmothy starter should be gone")
	assert(BuildCatalog.get_item("chimory").is_empty(), "old chimory starter should be gone")
	assert(BuildCatalog.get_item("gloop").is_empty(), "placeholder gloop should be gone")
	assert(BuildCatalog.get_item("spikeback").is_empty(), "placeholder spikeback should be gone")
	assert(BuildCatalog.get_item("park_bench").is_empty(), "benches should be gone")
	assert(BuildCatalog.get_item("park_snack").is_empty(), "snack carts should be gone")
	assert(Visitor.TICKET_MAX == 2, "tickets should cap at $2 before multipliers")
	assert(WalletService.starting_money == 80, "new zoos should start with $80")
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
		"body": 1,
		"head": 9,
		"front_legs": 6,
		"back_legs": 8,
		"tail": 8,
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
	assert(PlaceholderArt.get_palette_options().size() == TraitLibrary.get_option_count("color"),
		"each coat should have a palette")
	var body_tex: Texture2D = PlaceholderArt.get_shape_options("body")[0]
	var leg_tex: Texture2D = PlaceholderArt.get_shape_options("front_legs")[0]
	var body_mean: float = _fill_mean(body_tex)
	var leg_mean: float = _fill_mean(leg_tex)
	assert(absf(body_mean - leg_mean) < 0.08,
		"limb fill should match body brightness, body=%s legs=%s" % [body_mean, leg_mean])
	for path in [
		"res://art/creatures/parts/body_jimmothy.png",
		"res://art/creatures/parts/head_gorilla.png",
		"res://art/creatures/parts/head_lizard.png",
		"res://art/creatures/parts/head_jimmothy.png",
		"res://art/creatures/parts/head_cockatoo.png",
		"res://art/creatures/parts/head_turtle.png",
		"res://art/creatures/parts/head_frog.png",
		"res://art/creatures/parts/head_hamster.png",
		"res://art/creatures/parts/head_duck.png",
		"res://art/creatures/parts/head_lion.png",
		"res://art/creatures/parts/front_legs_turtle.png",
		"res://art/creatures/parts/front_legs_horse.png",
		"res://art/creatures/parts/front_legs_lizard.png",
		"res://art/creatures/parts/front_legs_lion.png",
		"res://art/creatures/parts/front_legs_trex.png",
		"res://art/creatures/parts/front_legs_chimory.png",
		"res://art/creatures/parts/back_legs_sheep.png",
		"res://art/creatures/parts/back_legs_horse.png",
		"res://art/creatures/parts/back_legs_jimmothy.png",
		"res://art/creatures/parts/back_legs_bird.png",
		"res://art/creatures/parts/back_legs_elephant.png",
		"res://art/creatures/parts/back_legs_gorilla.png",
		"res://art/creatures/parts/back_legs_lion.png",
		"res://art/creatures/parts/back_legs_turtle.png",
		"res://art/creatures/parts/tail_pig.png",
		"res://art/creatures/parts/tail_sheep.png",
		"res://art/creatures/parts/tail_tentacle.png",
		"res://art/creatures/parts/tail_fire.png",
		"res://art/creatures/parts/tail_lion.png",
		"res://art/creatures/parts/tail_lizard.png",
		"res://art/creatures/parts/tail_scorpion.png",
		"res://art/creatures/parts/tail_jimmothy.png",
	]:
		var part: Texture2D = load(path)
		assert(part != null, "missing artist part %s" % path)
		assert(part.get_width() == part.get_height(),
			"%s must be square, got %dx%d" % [path, part.get_width(), part.get_height()])
		assert(part.get_width() >= canvas,
			"%s is %dpx, expected at least %d" % [path, part.get_width(), canvas])
	print("PlaceholderArt OK — all parts %dx%d" % [canvas, canvas])


func _test_fx() -> void:
	assert(ZooFx.cloud_tex() != null, "smoke needs a puff texture")
	var host := Node2D.new()
	add_child(host)
	var dust := ZooFx.burst(host, ZooFx.Kind.DUST)
	assert(dust is GPUParticles2D, "dust should be a GPUParticles2D burst")
	assert(dust.process_material != null, "2D particles need a ParticleProcessMaterial")
	assert(dust.one_shot, "footfall/placement dust should be a one-shot burst")
	var cloud := ZooFx.pen_poof(host, Vector2(400.0, 300.0))
	assert(cloud is GPUParticles2D, "pens should poof with rising smoke")
	var cloud_mat := cloud.process_material as ParticleProcessMaterial
	assert(cloud_mat != null and cloud_mat.color.r >= 0.99 and cloud_mat.color.g >= 0.99,
		"pen smoke should stay white")
	assert(cloud_mat.scale_curve != null, "smoke should billow over its life")
	assert(cloud_mat.gravity.y < 0.0, "smoke should rise")
	assert(cloud_mat.scale_max >= 2.0, "stylized puffs should read as big cotton balls")
	assert(cloud.explosiveness >= 0.99, "pen smoke should burst all at once")
	assert(cloud.one_shot, "pen smoke should be a one-shot poof")
	assert(cloud.lifetime >= 1.4, "smoke should hang and fade, not pop")
	assert(cloud.texture.get_width() > cloud.texture.get_height(),
		"stylized smoke should use a puff flipbook")
	var cloud_draw := cloud.material as CanvasItemMaterial
	assert(cloud_draw != null and cloud_draw.particles_animation,
		"stylized smoke should animate its puff sheet")
	var puff_id: int = cloud.get_instance_id()
	cloud.free()
	ZooFx._free_id(puff_id)
	var revealed := {"ok": false}
	ZooFx.conceal_change(host, func() -> void:
		revealed["ok"] = true
	)
	assert(bool(revealed["ok"]), "headless serum poofs should apply the change immediately")
	var steam := ZooFx.loop(host, ZooFx.Kind.STEAM)
	assert(steam != null and steam.emitting, "steam loops should keep emitting")
	var hearts := ZooFx.burst(host, ZooFx.Kind.HEART)
	assert(hearts != null and hearts.texture != null, "mating should burst heart particles")
	assert((hearts.process_material as ParticleProcessMaterial).gravity.y < 0.0,
		"hearts should float up")
	host.queue_free()
	print("FX OK")


func _test_zoo_hours_empty() -> void:
	var street_scene: PackedScene = load("res://scenes/Street.tscn")
	var street: Node = street_scene.instantiate()
	add_child(street)
	assert(not bool(street.get("is_open")), "zoo should start closed")
	assert(not street.has_exhibit(), "an empty park has no exhibit")
	assert(not street.set_open(true), "opening needs a pen with an animal")
	assert(not bool(street.get("is_open")), "a failed open should stay closed")
	assert(street.spawn_dropoff() == null, "closed gates should not take drop-offs")
	var passer: Node = street.spawn_traffic(1)
	assert(passer != null, "passing cars still use the road when closed")
	if passer != null:
		passer.free()
	street.free()
	print("Zoo hours OK — starts closed")


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
	var tiny := pen_scene.instantiate() as Pen
	tiny.footprint_cells = Vector2i(3, 2)
	add_child(tiny)
	var tiny_walk := tiny.get_wander_bounds()
	assert(tiny_walk.size.x >= 80.0, "tiny pens should still have a walkable strip, got %s" % tiny_walk.size)
	assert(tiny_walk.size.y >= 12.0, "tiny pens should let animals shuffle, got %s" % tiny_walk.size)
	tiny.free()
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
	animal.creature_name = "Horse"
	animal.visuals.apply_loadout({
		"body": 0,
		"head": TraitLibrary.option_index_for_id("head", "jimmothy"),
		"front_legs": TraitLibrary.option_index_for_id("front_legs", "horse"),
		"back_legs": TraitLibrary.option_index_for_id("back_legs", "horse"),
	}, 0, ["tail"])
	pen.register_animal(animal)
	var stats: Dictionary = animal.get_stats()
	assert(Animal.SPEED < 70.0, "animals should amble, not dash")
	assert(Animal.MIN_PAUSE >= 5.0, "animals should loaf between walks")
	assert((stats.get("parts") as Array).size() == 5, "horse should list 4 parts + color, got %s" % [stats.get("parts")])
	assert(stats.get("archetype") == "Showpiece", "horse should be a Showpiece, got %s" % stats.get("archetype"))
	var visitors: Dictionary = stats.get("visitors", {})
	assert(int(visitors.get("tourists", 0)) > 0, "tourists should like the majestic horse")
	assert(int(visitors.get("parents", 1)) == 0, "parents should stay neutral")
	assert(int(visitors.get("goths", 0)) < 0, "goths should hate leftover cute parts")
	var shade: Sprite2D = animal.get_node_or_null("Shadow") as Sprite2D
	assert(shade != null and shade.visible and shade.texture != null, "animals should cast a ground shadow")
	assert(is_equal_approx(pen.trait_clash(), 0.0), "one animal should not clash with itself")
	assert(is_equal_approx(pen.enjoyment_factor(), 1.0), "a single look should be a clear exhibit")
	assert(pen.occupancy_factor() >= 0.88 and pen.occupancy_factor() <= 1.0,
		"a stocked pen should still be worth viewing")
	var gloop := animal_scene.instantiate() as Animal
	pen.add_child(gloop)
	gloop.set_pen(pen)
	gloop.visuals.apply_loadout(
		{"body": 0, "head": 1, "front_legs": 2, "back_legs": 2, "tail": 2},
		2,
		[]
	)
	pen.register_animal(gloop)
	assert(pen.trait_clash() > 0.55, "cute + gloop in one pen should confuse the crowd")
	assert(pen.enjoyment_factor() < 1.0, "mixed traits should lower enjoyment")
	assert(pen.enjoyment_factor() > 0.75, "a mixed pen should still be worth looking at")
	pen.unregister_animal(gloop)
	gloop.queue_free()
	print("Animal OK — stats=%s" % [stats])
	return animal


func _test_trait_library() -> void:
	var head0: Dictionary = TraitLibrary.get_option("head", 0)
	assert(head0.get("name") == "Gorilla Head", "head 0 should be Gorilla Head")
	assert(TraitLibrary.get_option_count("body") == 1, "body should be the shared Jimmothy torso")
	assert(TraitLibrary.get_option_count("head") == 9, "head should include the artist head set")
	assert(TraitLibrary.get_option_count("front_legs") == 6, "front legs should include the artist arm set")
	assert(TraitLibrary.get_option_count("back_legs") == 8, "back legs should include the artist leg set")
	assert(TraitLibrary.get_option_count("tail") == 8, "tail should include the artist tail set")
	assert(TraitLibrary.get_option_count("color") == 13, "coats should cover every serum tag")
	assert(TraitLibrary.get_option("color", TraitLibrary.option_index_for_id("color", "patches")).get("name") == "Cow Spots",
		"cow pattern should be a coat")
	assert(TraitLibrary.get_option("color", TraitLibrary.option_index_for_id("color", "giraffe")).get("name") == "Giraffe Spots",
		"giraffe pattern should be a coat")
	assert(TraitLibrary.get_option("color", TraitLibrary.option_index_for_id("color", "starry")).get("name") == "Starry Night",
		"star pattern should be a coat")
	for i in range(TraitLibrary.get_option_count("color")):
		var coat: Dictionary = TraitLibrary.get_option("color", i)
		var tex_path: String = str(coat.get("pattern_tex", ""))
		if tex_path.is_empty():
			continue
		assert(load(tex_path) != null, "missing coat pattern %s" % tex_path)
		assert(int(coat.get("pattern", 0)) >= 9, "%s should sample its pattern texture" % coat.get("name"))
	assert(TraitLibrary.TAGS.size() == 6, "looks should be a tight set of six")
	assert(not TraitLibrary.TAGS.has("Elegant") and not TraitLibrary.TAGS.has("Silly"),
		"Elegant and Silly should fold into Majestic and Weird")
	assert(TraitLibrary.slot_display_name("color") == "Coat", "color slot should display as Coat")
	for tag in TraitLibrary.TAGS:
		assert(TraitLibrary.ARCHETYPE_BY_TAG.has(tag), "look %s needs an overall type" % tag)
		assert(not str(TraitLibrary.LOOK_BUFF.get(tag, "")).is_empty(), "look %s needs a buff line" % tag)
		assert(not TraitLibrary.indices_with_tag("color", tag).is_empty(),
			"every serum tag needs a coat, missing %s" % tag)
	for slot in TraitLibrary.OPTIONS.keys():
		for i in range(TraitLibrary.get_option_count(str(slot))):
			var tags: Array = TraitLibrary.get_option(str(slot), i).get("tags", [])
			assert(tags.size() == 1, "%s option %d should have one look, got %s" % [slot, i, tags])
	assert(TraitLibrary.option_look("head", 0) == "Scary", "gorilla head should vote Scary")
	assert(TraitLibrary.overall_for_look("Cute") == "Cuddly", "Cute majority should read as Cuddly")
	assert(TraitLibrary.look_buff("Cute").to_lower().contains("kids"), "Cute buff should mention kids")
	assert(TraitLibrary.LAB_SLOTS.has("head") and not TraitLibrary.LAB_SLOTS.has("body"),
		"DNA Lab should mutate limbs, not the shared torso")
	assert(TraitLibrary.get_option("head", 0).get("name") == "Gorilla Head", "gorilla head should be in the pool")
	assert(TraitLibrary.option_has_tag("head", 0, "Scary"), "gorilla head should read as Scary")
	assert(not TraitLibrary.option_has_tag("head", 0, "Cute"), "gorilla head should not count as Cute")
	assert(TraitLibrary.option_has_tag("head", 1, "Weird"), "lizard head should read as Weird")
	assert(TraitLibrary.option_has_tag("front_legs", 4, "Weird"), "T. rex arms should read as Weird")
	assert(TraitLibrary.option_has_tag("tail", 0, "Cute"), "pig tail should stay Cute")
	assert(TraitLibrary.option_has_tag("tail", 4, "Majestic"), "lion tail should read as Majestic")
	assert(TraitLibrary.get_option("head", TraitLibrary.option_index_for_id("head", "jimmothy")).get("name") == "Horse Head",
		"horse head should be in the pool")
	assert(TraitLibrary.get_option("head", TraitLibrary.option_index_for_id("head", "cockatoo")).get("name") == "Cockatoo Head",
		"cockatoo head should be in the pool")
	assert(TraitLibrary.get_option("head", TraitLibrary.option_index_for_id("head", "lion")).get("name") == "Lion Head",
		"lion head should be in the pool")
	var seen_colors: Dictionary = {}
	for visitor in TraitLibrary.VISITORS:
		var tint: Color = TraitLibrary.visitor_color(str(visitor.get("id", "")))
		var key := "%s,%s,%s" % [snappedf(tint.r, 0.01), snappedf(tint.g, 0.01), snappedf(tint.b, 0.01)]
		assert(not seen_colors.has(key), "visitor colours should be unique, clash on %s" % visitor.get("id"))
		seen_colors[key] = true
	assert(seen_colors.size() == TraitLibrary.VISITORS.size(), "every visitor type needs a colour")
	assert(TraitLibrary.visitor_sprite_paths("children").size() == 2, "children should randomise boy/girl")
	assert(TraitLibrary.visitor_sprite_paths("parents").size() == 2, "parents should randomise mum/dad")
	assert(TraitLibrary.visitor_sprite_paths("goths").size() == 2, "goths should randomise girl/guy")
	assert(TraitLibrary.visitor_sprite_paths("tourists").size() == 2, "tourists should randomise girl/guy")
	assert(TraitLibrary.visitor_sprite_paths("creators").size() == 2, "creators should randomise girl/guy")
	assert(TraitLibrary.visitor_sprite_paths("thrill").size() == 2, "thrill-seekers should randomise girl/guy")
	assert(TraitLibrary.visitor_sprite_paths("camera").size() == 1, "the camera operator should use the camera-man sprite")
	for path in TraitLibrary.visitor_sprite_paths("children"):
		assert(load(path) != null, "missing child sprite %s" % path)
	for path in TraitLibrary.visitor_sprite_paths("parents"):
		assert(load(path) != null, "missing parent sprite %s" % path)
	for path in TraitLibrary.visitor_sprite_paths("goths"):
		assert(load(path) != null, "missing goth sprite %s" % path)
	for path in TraitLibrary.visitor_sprite_paths("tourists"):
		assert(load(path) != null, "missing tourist sprite %s" % path)
	for path in TraitLibrary.visitor_sprite_paths("creators"):
		assert(load(path) != null, "missing creator sprite %s" % path)
	for path in TraitLibrary.visitor_sprite_paths("thrill"):
		assert(load(path) != null, "missing thrill-seeker sprite %s" % path)
	for path in TraitLibrary.visitor_sprite_paths("camera"):
		assert(load(path) != null, "missing camera sprite %s" % path)
	assert(GuestTalk.line("creators", "film", "", 1).to_lower().contains("chat"),
		"creators should talk to chat when they film")
	for seed in range(8):
		assert(GuestTalk.line("creators", "film", "", seed).to_lower().contains("chat"),
			"every creator film line should talk to chat")
	assert(GuestTalk.line("goths", "arrive", "", 1).to_lower().contains("grim"),
		"goth chatter should still mention grim")
	assert(GuestTalk.line("family", "arrive", "", 1).to_lower().contains("kids"),
		"family chatter should still mention the kids")
	assert(GuestTalk.blurt("parent_goth", 1) != "", "parents should have panic lines")
	assert(GuestTalk.blurt("parent_mate", 1) == "DISGUSTING", "parents should shout DISGUSTING at mating")
	assert(GuestTalk.blurt("kid_goth", 1) != "", "kids should have scared lines")
	for seed in range(8):
		var family_leave := GuestTalk.line("family", "leaving", "", seed).to_lower()
		var parent_leave := GuestTalk.line("parents", "leaving", "", seed).to_lower()
		assert(not family_leave.contains("now") and not family_leave.contains("car"),
			"family hail should sound calm, got '%s'" % family_leave)
		assert(not parent_leave.contains("now") and not parent_leave.contains("car"),
			"parent hail should sound calm, got '%s'" % parent_leave)
	var family_kinds: PackedStringArray = TraitLibrary.family_member_kinds()
	assert(family_kinds.has("parents") and family_kinds.has("children"),
		"a family car should carry parents and kids")
	assert(family_kinds.size() >= 2 and family_kinds.size() <= 4, "family size should stay small")

	var zeros: Dictionary = {}
	for slot in TraitLibrary.SHAPE_SLOTS:
		zeros[slot] = 0
	zeros["head"] = TraitLibrary.option_index_for_id("head", "hamster")
	var baseline: Dictionary = TraitLibrary.score_loadout(zeros, 0)
	assert(baseline.get("archetype") == "Cuddly", "default loadout should be Cuddly, got %s" % baseline.get("archetype"))
	var base_visitors: Dictionary = baseline.get("visitors", {})
	assert(int(base_visitors.get("children", 0)) > 0, "children should like the cute default")
	assert(int(base_visitors.get("parents", 1)) == 0, "parents should stay neutral")
	assert(int(base_visitors.get("goths", 0)) < 0, "goths should hate the cute default")
	var cute_tags: Dictionary = baseline.get("tags", {})
	var family_tip: int = TraitLibrary.sight_bonus("parents", cute_tags, true)
	var thrill_tip: int = TraitLibrary.sight_bonus("thrill", {"Scary": 3}, false)
	var goth_on_cute: int = TraitLibrary.sight_bonus("goths", cute_tags, false)
	assert(family_tip == 1, "cute families should pay the smallest sight bonus, got %d" % family_tip)
	assert(thrill_tip > family_tip, "a predator crowd should pay more than a cute family")
	assert(goth_on_cute == 0, "goths should not tip a cute exhibit")
	assert(TraitLibrary.sight_bonus("creators", cute_tags, false) == 0,
		"creators should not tip a cute exhibit")
	assert(TraitLibrary.sight_bonus("creators", {"Weird": 3}, false) > family_tip,
		"creators should pay more than a cute family when they like a clip")
	for _i in range(24):
		assert(TraitLibrary.random_solo_id(false) != "creators",
			"a live creator should block another creator from rolling")
	assert(TraitLibrary.sight_bonus("children", {"Cute": 2, "Scary": 3}, false) == 0,
		"scared kids should not pay a cute bonus")
	assert(int(base_visitors.get("scientists", 1)) <= 0, "scientists should call the cute default mediocre")
	assert(int(base_visitors.get("thrill", 0)) < 0, "thrill-seekers should hate the cute default")

	var weird: Dictionary = {}
	for slot in TraitLibrary.SHAPE_SLOTS:
		weird[slot] = 2
	var novelty: Dictionary = TraitLibrary.score_loadout(weird, 2)
	assert(novelty.get("archetype") == "Novelty", "weird loadout should be Novelty, got %s" % novelty.get("archetype"))
	var novelty_visitors: Dictionary = novelty.get("visitors", {})
	assert(int(novelty_visitors.get("goths", 0)) > 0, "goths should like the gross/weird stack")
	assert(int(novelty_visitors.get("thrill", 0)) >= 0, "a weird stack with claws should not drive thrill-seekers away")
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
		"tied looks should pick the stronger overall look")
	var chrono: Array[Dictionary] = TraitLibrary.present_looks(baseline.get("tags", {}))
	assert(chrono.size() == 1 and str(chrono[0].get("name", "")) == "Cute",
		"default looks should be Cute only")
	assert(TraitLibrary.slot_display_name("body") == "Torso", "body slot should display as Torso")
	for _i in range(16):
		var other: int = TraitLibrary.pick_other_index("head", 1)
		assert(other != 1, "pick_other_index must not pick the current option")
		assert(other >= 0 and other < TraitLibrary.get_option_count("head"), "pick_other_index out of range: %d" % other)
	for _j in range(16):
		var cute: int = TraitLibrary.pick_other_with_tag("head", 0, "Cute", 0)
		assert(cute != 0, "cute serum should find a Cute head")
		assert(TraitLibrary.option_has_tag("head", cute, "Cute"), "cute pick must keep the Cute tag")
	assert(TraitLibrary.option_rarity("head", TraitLibrary.option_index_for_id("head", "lion")) == 2, "lion head should be exotic")
	assert(TraitLibrary.pick_other_from_ids("head", 0, ["lion"]) != 0,
		"exotic pool should swap onto a listed head")
	assert(TraitLibrary.pick_other_with_tag("color", 0, "Cute", 0) != 0,
		"cute serum should be able to change the coat")
	assert(int(TraitLibrary.get_option("head", TraitLibrary.option_index_for_id("head", "lion")).get("rarity", -1)) == 2,
		"lion head should be exotic")
	assert(TraitLibrary.tag_clash(baseline.get("tags", {}), baseline.get("tags", {})) == 0.0,
		"identical loadouts should not clash")
	assert(TraitLibrary.tag_clash(baseline.get("tags", {}), novelty.get("tags", {})) > 0.6,
		"cute vs weird/gross should clash")
	print("TraitLibrary OK — baseline=%s novelty=%s" % [baseline, novelty])


func _test_creature_mutation(animal: Animal) -> void:
	var before: Dictionary = animal.get_stats()
	animal.visuals.set_part_shape("head", 2)
	assert(animal.visuals.get_current_index("head") == 2, "head mutation didn't apply")
	var body_i: int = animal.visuals.get_node("Body").get_index()
	assert(animal.visuals.get_node("FrontLegs").get_index() < body_i, "near arms should draw under the body")
	assert(animal.visuals.get_node("BackLegs").get_index() < body_i, "near legs should draw under the body")
	assert(animal.visuals.get_node("FarFrontLegs").get_index() < animal.visuals.get_node("FrontLegs").get_index(),
		"far arms should draw behind the near arms")
	assert(animal.visuals.get_node("FarBackLegs").get_index() < animal.visuals.get_node("BackLegs").get_index(),
		"far legs should draw behind the near legs")
	animal.visuals.set_part_shape("front_legs", 1)
	assert(animal.visuals.get_node("FarFrontLegs").texture == animal.visuals.get_node("FrontLegs").texture,
		"far arms should match the near arms")
	animal.visuals.set_slot_visible("front_legs", false)
	assert(not animal.visuals.get_node("FarFrontLegs").visible, "hiding arms should hide the far copy")
	animal.visuals.set_slot_visible("front_legs", true)
	animal.visuals.set_part_shape("front_legs", 0)
	animal.visuals.set_skin(2)
	assert(animal.visuals.get_current_palette_index() == 2, "skin mutation didn't apply")
	animal.visuals.set_skin(4)
	assert(animal.visuals.get_current_palette_index() == 4, "stripe coat should apply")
	assert(int(animal.visuals.get_node("Body").material.get_shader_parameter("pattern")) == 2,
		"tiger stripes should set the stripe pattern")
	var giraffe_coat: int = TraitLibrary.option_index_for_id("color", "giraffe")
	animal.visuals.set_skin(giraffe_coat)
	assert(int(animal.visuals.get_node("Body").material.get_shader_parameter("pattern")) == 9,
		"giraffe coat should sample the dark pattern texture")
	assert(animal.visuals.get_node("Body").material.get_shader_parameter("pattern_map") != null,
		"giraffe coat should bind giraffe.png")
	var starry_coat: int = TraitLibrary.option_index_for_id("color", "starry")
	animal.visuals.set_skin(starry_coat)
	assert(int(animal.visuals.get_node("Body").material.get_shader_parameter("pattern")) == 10,
		"starry coat should sample the bright pattern texture")
	animal.visuals.set_skin(2)
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
	assert(build_mode.has_method("spawn_starter_exhibit"), "BuildMode script should attach")
	build_mode.set_item("pen_large")
	assert(build_mode.current_item_id == "", "locked pens should not arm the place tool")
	build_mode.set_mode(BuildMode.Mode.PLACE_PEN_SMALL)
	assert(build_mode.current_mode == BuildMode.Mode.PLACE_PEN_SMALL, "set_mode didn't apply")
	var horse: Animal = build_mode.spawn_starter_exhibit()
	assert(horse != null and horse.creature_name == "Horse", "starter exhibit should spawn Horse")
	assert(horse.visuals.get_node_or_null("Eyes") == null, "eyes slot should be gone; eyes live on the head")
	assert(not horse.visuals.get_node("Tail").visible, "Horse should spawn without a tail")
	var occupied_origin := horse.get_pen().origin_cell
	var occupied_size := horse.get_pen().footprint_cells
	var first_pen: Pen = horse.get_pen()
	assert(first_pen.animal_capacity() == 2, "small pens should hold 2 animals")
	assert(first_pen.can_accept_animal(), "starter exhibit still has a free stall")
	WalletService.money += 40
	build_mode.set_item("horse")
	assert(build_mode.current_mode == BuildMode.Mode.PLACE_ANIMAL, "catalog animal should arm place mode")
	var inside: Vector2 = first_pen.global_position + first_pen.get_size_pixels() * 0.5
	assert(build_mode.place_animal_at(inside), "should drop the selected animal in the pen")
	assert(build_mode.current_item_id == "", "placing an animal should drop the spawn tool")
	assert(build_mode.current_mode == BuildMode.Mode.NONE, "should not stay in animal-place mode")
	assert(first_pen.occupant_count() == 2, "small pens should fill at two animals")
	assert(not first_pen.can_accept_animal(), "a full small pen should refuse a third")
	assert(not GridService.is_area_free(occupied_origin, occupied_size), "starter pad should occupy grass")
	build_mode.delete_animal(horse)
	assert(horse.is_queued_for_deletion(), "delete animal should queue the creature")
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
	WalletService.money += 15
	build_mode.set_item("path_stone")
	assert(build_mode.current_mode == BuildMode.Mode.PLACE_PATH, "path catalog should arm path mode")
	assert(build_mode.place_path_at(Vector2i(0, 0)), "should stamp a path on empty grass")
	assert(GridService.has_path_cell(Vector2i(0, 0)), "path stamps should occupy the small path grid")
	assert(GridService.has_path(Vector2i(0, 0)), "path cells should be walkable path")
	assert(build_mode.current_item_id == "path_stone", "path tool should stay selected for painting")
	assert(not build_mode.place_path_at(Vector2i(0, 0)), "should not stack two paths on one cell")
	var first_tex: Texture2D = build_mode._path_tiles[Vector2i(0, 0)].texture
	var saw_other := false
	for i in range(1, 8):
		assert(build_mode.place_path_at(Vector2i(i, 0)), "should paint a short path of small stamps")
		if build_mode._path_tiles[Vector2i(i, 0)].texture != first_tex:
			saw_other = true
	assert(BuildMode.PATH_TEXTURES.size() == 4, "path tool should shuffle among the four rock drawings")
	assert(saw_other, "successive stamps should pick different rock drawings")
	build_mode.set_item("path_delete")
	assert(build_mode.current_mode == BuildMode.Mode.DELETE_PATH, "delete tool should arm path delete")
	assert(build_mode.remove_path_at(Vector2i(0, 0)), "delete tool should lift a path stamp")
	assert(not GridService.has_path_cell(Vector2i(0, 0)), "deleted path cells should be empty")
	assert(not build_mode._path_tiles.has(Vector2i(0, 0)), "deleted path sprites should go")
	assert(build_mode.current_item_id == "path_delete", "delete tool should stay selected")
	assert(not build_mode.remove_path_at(Vector2i(0, 0)), "delete tool should not remove an empty cell")
	GridService.clear_paths()
	print("BuildMode OK")


func _test_wallet_service() -> void:
	var start_money: int = WalletService.money
	assert(WalletService.spend(5, "Test buy"), "should afford spending $5")
	assert(WalletService.money == start_money - 5, "cash didn't decrease")
	assert(WalletService.ledger.size() > 0, "spending should log a till line")
	assert(int(WalletService.ledger[0].get("delta", 0)) == -5, "latest till line should be the $5 spend")
	assert(str(WalletService.ledger[0].get("reason", "")) == "Test buy", "till line should keep the spend reason")
	assert(WalletService.ledger.size() <= WalletService.LEDGER_MAX, "till log should keep only the last five moves")
	assert(not WalletService.spend(100000), "shouldn't afford spending $100000")
	var before_tick: int = WalletService.money
	assert(WalletService.collect_tickets() == 0, "empty zoo should pay nothing")
	assert(WalletService.money == before_tick, "ticket collection should not mint cash with no guests")
	assert(WalletService.last_tick_summary().contains("No tickets"), "empty collection should explain tickets and upkeep")
	print("WalletService OK — money=%d" % WalletService.money)


func _test_quests() -> void:
	assert(GeneTree.get_vial("elegant").is_empty(), "Elegant serum should be gone")
	assert(GeneTree.get_vial("silly").is_empty(), "Silly serum should be gone")
	assert(GeneTree.get_vial("majestic").get("name") == "Majestic serum", "Majestic serum should keep its name")
	assert(GeneTree.is_vial_unlocked("cute"), "Cute serum should start unlocked")
	assert(GeneTree.stock_of("cute") >= 1, "the lab should start with one Cute charge")
	assert(not GeneTree.is_vial_unlocked("scary"), "Scary should stay gated until a quest pays it out")
	assert(QuestBoard.current().get("id") == "fence", "first quest should ask for a pen")
	assert(QuestBoard.reward_text().contains("$10"), "quest should show a cash reward")
	QuestBoard.evaluate()
	assert(QuestBoard.ready_to_claim, "a placed pen should complete Fence it in")
	var money_before: int = WalletService.money
	assert(QuestBoard.claim(), "should claim the pen quest")
	assert(WalletService.money == money_before + 10, "claiming should pay the cash reward")
	assert(QuestBoard.current().get("id") == "stock", "next quest should ask for an animal")
	assert(not BuildCatalog.is_unlocked(BuildCatalog.get_item("loin")),
		"Lion should stay locked until the second quest is claimed")
	assert(QuestBoard.reward_text().contains("$10"), "stock quest should show its reward")
	assert(QuestBoard.claim(), "a placed animal should complete Something to look at")
	assert(BuildCatalog.is_unlocked(BuildCatalog.get_item("loin")),
		"Lion should unlock after the second quest")
	assert(not BuildCatalog.is_unlocked(BuildCatalog.get_item("gorllia")),
		"Gorllia should stay locked until the zoo opens")
	assert(QuestBoard.current().get("id") == "gates", "third quest should ask to open the zoo")
	assert(QuestBoard.reward_text().contains("$10"), "open-zoo quest should show its cash reward")
	assert(not QuestBoard.ready_to_claim, "gates should wait until the zoo opens")
	assert(str(QuestBoard.QUESTS[3].get("id", "")) == "splice", "mutation quest should follow opening the zoo")
	assert(str(QuestBoard.QUESTS[3].get("brief", "")).contains("Cute serum"),
		"mutation quest should name Cute serum")
	assert(str(QuestBoard.QUESTS[4].get("brief", "")).contains("Majestic serum"),
		"showpiece quest should name Majestic serum")
	assert(str(QuestBoard.QUESTS[6].get("id", "")) == "lots",
		"parking should follow the second enclosure")
	assert(str(QuestBoard.QUESTS[10].get("id", "")) == "ads",
		"advertising should follow the first ticket quest")
	assert(str(QuestBoard.QUESTS[QuestBoard.QUESTS.size() - 1].get("id", "")) == "brood",
		"breeding should be a later quest")
	assert(str(QuestBoard.QUESTS[QuestBoard.QUESTS.size() - 1].get("goal", "")) == "breed",
		"the last quest should watch for a birth")
	assert(QuestBoard.reward_text(QuestBoard.QUESTS[6]).contains("More parking"),
		"parking quest should name the parking perk")
	assert(QuestBoard.reward_text(QuestBoard.QUESTS[10]).contains("More advertising"),
		"advertising quest should name the ads perk")
	for quest in QuestBoard.QUESTS:
		assert(int(quest.get("reward_charges", 0)) == 0, "quests should not grant free charges")
		assert(not QuestBoard.reward_text(quest).to_lower().contains("charge"),
			"quest reward copy should not mention charges")
		var quest_copy: String = "%s %s %s" % [
			str(quest.get("title", "")),
			str(quest.get("brief", "")),
			QuestBoard.reward_text(quest),
		]
		assert(not quest_copy.to_lower().contains("bench"), "quests should not mention benches")
		assert(not quest_copy.to_lower().contains("snack"), "quests should not mention snacks")
		assert(not quest_copy.to_lower().contains("ticket booth"), "quests should not mention ticket booths")
	var cute_before: int = GeneTree.stock_of("cute")
	WalletService.money += 40
	Events.money_changed.emit(WalletService.money)
	assert(GeneTree.buy_vial("cute"), "should afford Cute serum")
	assert(GeneTree.stock_of("cute") == cute_before + 1, "buying should add a Cute charge")
	assert(GeneTree.consume_vial("cute"), "should consume a Cute charge")
	assert(GeneTree.stock_of("cute") == cute_before, "consume should return to the start count")
	print("Quests OK — current=%s" % QuestBoard.current().get("id"))


func _test_title_and_save() -> void:
	var previous_dir: String = SaveService.directory
	SaveService.directory = "user://saves_smoke"
	SaveService.clear_saves()
	var title_scene: PackedScene = load("res://scenes/ui/Title.tscn")
	var title := title_scene.instantiate() as Control
	add_child(title)
	assert(title.get_node("%NewButton") != null, "title should have New Game")
	assert(str(title.get_node("%NewButton").text) == "New Game", "title should say New Game")
	assert(title.get_node("%LoadSaveButton") != null, "title should have Load Save")
	assert(str(title.get_node("%LoadSaveButton").text) == "Load Save", "title should say Load Save")
	assert(str(title.get_node("%QuitButton").text) == "Exit", "title should say Exit")
	assert(str(title.get_node("%TitleLabel").text) == "GenomeZoo",
		"title should name the game")
	assert(str(title.get_node("%Tag").text).contains("grandeur in this view of life"),
		"title should quote Darwin")
	assert(str(title.get_node("%Tag").text).contains("Charles Darwin"),
		"title should credit Darwin")
	assert(title.get_node("Art").texture != null, "title should use the home art")
	assert(title.get_node("%SavePicker") != null, "title should have a load list")
	title.free()
	var build := Node2D.new()
	build.set_script(load("res://scripts/build_mode.gd"))
	add_child(build)
	var critter: Animal = build.spawn_starter_exhibit()
	assert(critter != null, "save test needs a starter exhibit")
	WalletService.money += 50
	build.set_item("path_stone")
	assert(build.place_path_at(Vector2i(4, 4)), "save test should place a path")
	var world: Dictionary = build.snapshot_world()
	assert((world.get("pens") as Array).size() == 1, "snapshot should keep the pen")
	assert((world.get("paths") as Array).size() == 1, "snapshot should keep paths")
	build.clear_world()
	assert((build.get("_pens") as Array).is_empty(), "clear_world should remove pens")
	assert(not GridService.has_path_cell(Vector2i(4, 4)), "clear_world should free path cells")
	build.restore_world(world)
	assert((build.get("_pens") as Array).size() == 1, "restore should rebuild the pen")
	var restored: Pen = (build.get("_pens") as Array)[0]
	assert(restored.occupant_count() == 1, "restore should keep the animal")
	assert(not restored.animals[0].visuals.is_slot_visible("tail"), "restore should keep a horse tailless")
	assert(GridService.has_path_cell(Vector2i(4, 4)), "restore should put the path back")
	SaveService.set_zoo_name("Sunny Vale")
	assert(SaveService.save_game(build), "save_game should write a slot")
	var listed: Array[Dictionary] = SaveService.list_saves()
	assert(listed.size() == 1, "one Save Zoo should make one slot")
	var label: String = str(listed[0].get("label", ""))
	assert(label.contains("Sunny Vale"), "save label should use the zoo name")
	assert(label.contains(":"), "save label should include the time")
	SaveService.set_zoo_name("Moon Park")
	assert(SaveService.save_game(build), "a second save should write another slot")
	assert(SaveService.list_saves().size() == 2, "each save should keep its own slot")
	var path: String = str(listed[0].get("path", ""))
	var file := FileAccess.open(path, FileAccess.READ)
	assert(file != null, "the named slot should be readable")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert(parsed is Dictionary, "the named slot should be JSON")
	var data: Dictionary = parsed
	assert(str(data.get("zoo_name", "")) == "Sunny Vale", "the slot should store the zoo name")
	assert(int(data.get("saved_at", 0)) > 0, "the slot should store the time")
	assert(data.has("clones"), "the slot should keep cloned animals")
	assert((data.get("world", {}).get("paths", []) as Array).size() == 1, "the slot should keep the path")
	var picker: Control = (load("res://scenes/ui/SavePicker.tscn") as PackedScene).instantiate()
	add_child(picker)
	picker.open()
	assert(not picker.get_node("%SaveEmpty").visible, "load list should hide the empty copy when slots exist")
	assert(picker.get_node("%SaveList").get_child_count() == 2, "load list should show each save")
	picker.free()
	SaveService.clear_saves()
	SaveService.directory = previous_dir
	SaveService.set_zoo_name(SaveService.DEFAULT_ZOO_NAME)
	build.delete_pen((build.get("_pens") as Array)[0])
	build.queue_free()
	print("Title/Save OK")


func _test_names_clones_and_breeding(pen: Pen, animal: Animal) -> void:
	assert(SaveService.NAME_MAX == 20, "zoo and creature names should cap at 20 characters")
	assert(SaveService.clean_name("abcdefghijklmnopqrstuvwxyz").length() == 20,
		"long names should truncate to 20 characters")
	assert(SaveService.child_name("Ada", "Beau") == "Ada-Beau", "cubs should hyphenate parent names")
	assert(SaveService.child_name("Supercalifragilistic", "Expialidocious").length() <= 20,
		"hyphenated cub names should stay within the cap")
	animal.set_creature_name("Ada")
	assert(animal.creature_name == "Ada", "animals should take a typed name")
	animal.set_creature_name("   ")
	assert(animal.creature_name == "Unnamed", "blank creature names should fall back")
	animal.set_creature_name("Horse")
	SaveService.clones.clear()
	var clone: Dictionary = SaveService.add_clone_from(animal)
	assert(not clone.is_empty(), "DNA Lab cloning should copy the animal")
	assert(str(clone.get("name", "")) == "Horse", "clones should keep the creature name")
	assert(int(clone.get("cost", 0)) == 100, "cloned animals should cost $100 to place")
	assert(not BuildCatalog.get_item(str(clone.get("id", ""))).is_empty(),
		"cloned animals should show up as placeables")
	var animal_items: Array[Dictionary] = BuildCatalog.items_for(BuildCatalog.CAT_ANIMALS)
	var saw_clone := false
	for item in animal_items:
		if str(item.get("id", "")) == str(clone.get("id", "")):
			saw_clone = true
	assert(saw_clone, "Animals catalog should list the clone")
	SaveService.clones.clear()
	var tiny_scene: PackedScene = load("res://scenes/Pen.tscn")
	var tiny := tiny_scene.instantiate() as Pen
	tiny.footprint_cells = Vector2i(3, 2)
	tiny.catalog_id = "pen_tiny"
	tiny.listed_capacity = 1
	add_child(tiny)
	var walker: Animal = (load("res://scenes/Animal.tscn") as PackedScene).instantiate()
	tiny.add_child(walker)
	tiny.register_animal(walker)
	walker.set_pen(tiny)
	var start: Vector2 = walker.position
	walker._pick_new_target()
	assert(walker.get("_target").distance_to(start) >= 8.0,
		"tiny-pen animals should pick a walk target, from %s to %s" % [start, walker.get("_target")])
	assert(not tiny.can_breed(), "one-slot pens should not breed")
	tiny.unregister_animal(walker)
	walker.free()
	tiny.free()
	var mate: Animal = (load("res://scenes/Animal.tscn") as PackedScene).instantiate()
	pen.add_child(mate)
	mate.set_pen(pen)
	mate.creature_name = "Beau"
	mate.visuals.apply_loadout({
		"body": 0,
		"head": 0,
		"front_legs": 0,
		"back_legs": 0,
		"tail": 0,
	}, 1, [])
	pen.register_animal(mate)
	assert(pen.can_breed(), "roomy pens with two animals and a free slot should breed")
	assert(pen.start_courtship(animal, mate), "two animals should walk in to mate")
	assert(pen.is_courting(), "mating should keep the pair busy")
	var parent: Visitor = (load("res://scenes/Visitor.tscn") as PackedScene).instantiate()
	add_child(parent)
	parent.setup(null, "parents", pen.global_position + Vector2(80.0, 80.0))
	parent._tick_mating_scare(0.016)
	assert(str(parent.get_node("Overhead/Bubble/Talk").text) == "DISGUSTING",
		"parents should shout DISGUSTING when they see mating")
	assert(bool(parent.get("_leaving")) or bool(parent.get("_panic")),
		"parents should run home from mating")
	parent.free()
	var cub: Animal = pen.finish_courtship()
	assert(cub != null, "mating should spawn a cub")
	assert(cub.creature_name == "Horse-Beau" or cub.creature_name == "Beau-Horse",
		"cubs should hyphenate parent names, got %s" % cub.creature_name)
	assert(cub.creature_name.length() <= 20, "cub names should stay within the cap")
	assert(QuestBoard.born, "a birth should count for the later quest")
	pen.unregister_animal(cub)
	cub.free()
	pen.unregister_animal(mate)
	mate.free()
	assert(pen.occupant_count() == 1, "breeding test should leave the original animal")
	print("Names/clones/breeding OK")


func _test_hud(animal: Animal) -> Control:
	var quest_snap: Dictionary = QuestBoard.snapshot()
	QuestBoard.reset()
	var hud_scene: PackedScene = load("res://scenes/ui/HUD.tscn")
	var hud := hud_scene.instantiate() as Control
	add_child(hud)
	var build_mode := Node2D.new()
	build_mode.set_script(load("res://scripts/build_mode.gd"))
	add_child(build_mode)
	hud.set_build_mode(build_mode)
	hud._on_cat_pens()
	assert(hud.get_node("%CatalogRibbon").visible, "Pens tab should open the catalog ribbon")
	assert(hud.get_node("%CatalogRow").get_child_count() == 4, "Pens ribbon should show four priced pens")
	assert(hud.get_node_or_null("%BuildHint") == null, "dock should not show a place hint")
	assert(not hud.get_node("%CancelBuild").visible, "cancel stays hidden until a tool is armed")
	var locked_large := false
	for child in hud.get_node("%CatalogRow").get_children():
		if child is Button and (child as Button).text.contains("Large"):
			assert((child as Button).disabled, "large pen should stay locked until Another enclosure")
			assert(child.get_node_or_null("Padlock") != null, "locked pens should show a padlock")
			locked_large = true
	assert(locked_large, "Pens ribbon should include the locked large pen")
	hud._dismiss_open_menu()
	assert(not hud.get_node("%CatalogRibbon").visible, "world click should close the catalog when no tool is armed")
	hud._on_cat_pens()
	WalletService.money += 80
	hud._on_catalog_tile_pressed("pen_tiny")
	assert(hud.get_node("%CatalogRibbon").visible, "catalog should stay open after picking a tool")
	assert(build_mode.current_item_id == "pen_tiny", "picking a tile should arm that tool")
	assert(hud.get_node("%CancelBuild").visible, "cancel should show while placing")
	hud._dismiss_open_menu()
	assert(hud.get_node("%CatalogRibbon").visible, "world click should not close the catalog while placing")
	assert(build_mode.current_item_id == "pen_tiny", "world click should not drop the tool")
	hud._on_cat_pens()
	assert(not hud.get_node("%CatalogRibbon").visible, "clicking Pens again should hide the catalog")
	assert(build_mode.current_item_id == "", "clicking Pens again should drop the place tool")
	assert(not hud.get_node("%CancelBuild").visible, "cancel should hide once the tool is dropped")
	hud._on_cat_animals()
	var locked_lion := false
	var locked_gorllia := false
	for child in hud.get_node("%CatalogRow").get_children():
		if child is Button and (child as Button).text.contains("Lion"):
			assert((child as Button).disabled, "Lion should stay locked until the second quest")
			assert(child.get_node_or_null("Padlock") != null, "locked animals should show a padlock")
			locked_lion = true
		if child is Button and (child as Button).text.contains("Gorllia"):
			assert((child as Button).disabled, "Gorllia should stay locked until the third quest")
			locked_gorllia = true
	assert(locked_lion, "Animals ribbon should include locked Lion")
	assert(locked_gorllia, "Animals ribbon should include locked Gorllia")
	hud._on_cat_paths()
	assert(hud.get_node("%CatalogRow").get_child_count() == 2, "Paths ribbon should show stone path and delete")
	var saw_delete_path := false
	for child in hud.get_node("%CatalogRow").get_children():
		if child is Button and (child as Button).text.contains("Delete path"):
			saw_delete_path = true
	assert(saw_delete_path, "Paths ribbon should include Delete path")
	assert(hud.get_node_or_null("%CatPark") == null, "Park tab should be gone")
	QuestBoard.apply_state(quest_snap)
	assert(str(hud.get_node("%ZooName").text) == "Evolution Zoo", "zoo plaque should start as Evolution Zoo")
	hud._commit_zoo_name("Sunny Vale")
	assert(SaveService.zoo_name == "Sunny Vale", "renaming the plaque should keep the zoo name")
	assert(str(hud.get_node("%ZooName").text) == "Sunny Vale", "plaque should show the new zoo name")
	hud._commit_zoo_name("   ")
	assert(SaveService.zoo_name == "Evolution Zoo", "blank names should fall back to Evolution Zoo")
	Events.animal_selected.emit(animal)
	assert(hud.get_node("%StatsPanel").visible, "stats panel should show after select")
	var archetype_text: String = hud.get_node("%StatsArchetype").text
	assert(archetype_text.contains("Cuddly") or archetype_text.contains(str(animal.get_stats().get("archetype"))),
		"stats panel should show archetype, got '%s'" % archetype_text)
	assert(_tag_meter_names(hud.get_node("%LooksLead")).contains("Majestic"),
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
	assert(audience_copy.contains("Tourists"), "audience should list tourists")
	assert(not audience_copy.contains("Parents"), "audience should hide visitors with no opinion")
	assert(hud.get_node("%CardScroll") != null, "exhibit card should scroll inside itself")
	hud._on_toggle_looks()
	assert(hud.get_node("%LooksList").visible, "looks dropdown should open")
	assert(not hud.get_node("%AudienceList").visible, "opening looks should close audience")
	assert(not hud.get_node("%LooksLead").visible, "expanded looks hides the single lead")
	assert(hud.get_node("%LooksList").get_child_count() >= 1, "expanded looks should list every present trait")
	assert(str(hud.get_node("%WalletLabel").text).begins_with("$"), "wallet chip should show cash")
	assert(str(hud.get_node("%HoursLabel").text) == "Zoo closed", "hours chip should start Zoo closed")
	assert(str(hud.get_node("%HoursDetail").text).contains("cannot arrive"), "closed chip should say guests cannot arrive")
	assert(str(hud.get_node("%ZooHoursButton").text) == "Open the zoo", "hours button should offer to open")
	hud._on_toggle_zoo_hours()
	assert(hud.get_node("%HoursPanel").visible, "opening with no exhibit should show an error popup")
	assert(str(hud.get_node("%HoursTitle").text) == "Can't open yet", "error popup should say it can't open")
	assert(str(hud.get_node("%HoursCopy").text).contains("pen"), "error popup should say why")
	assert(str(hud.get_node("%HoursLabel").text) == "Zoo closed", "open should fail until the street exists")
	hud._on_dismiss_hours()
	assert(not hud.get_node("%HoursPanel").visible, "closing the error popup should hide it")
	hud._on_mutate_pressed()
	assert(hud.get_node("%LabPanel").visible, "DNA Lab should open from the exhibit card")
	assert(hud.get_node_or_null("%LabShopList") == null, "DNA Lab should not embed the vial shop")
	assert(hud.get_node_or_null("%LabUndo") == null, "DNA Lab should not have an undo button")
	assert(not hud.get_node("%Deselect").visible, "exhibit card Close should hide while the lab is open")
	assert(hud.get_node_or_null("%LabSlots") == null, "DNA Lab should not use part buttons")
	assert(hud.get_node_or_null("%LimbNotes") == null, "limb copy should live on the DNA strand")
	var limb_copy: String = hud.get_node("%DnaStrand").notes_text()
	assert(not limb_copy.contains("Torso"), "DNA Lab should not list a torso")
	assert(limb_copy.contains("Head |"), "strand should name the head next to its pair")
	assert(limb_copy.contains("Coat |"), "strand should name the coat next to its pair")
	assert(limb_copy.contains("Front Legs |"), "strand should name the front legs next to its pair")
	assert(limb_copy.contains(" | "), "strand labels should use slot | part | look")
	assert(limb_copy.to_lower().contains("scary") or limb_copy.to_lower().contains("cute")
			or limb_copy.to_lower().contains("weird") or limb_copy.to_lower().contains("majestic")
			or limb_copy.to_lower().contains("bulky") or limb_copy.to_lower().contains("gross"),
		"strand labels should name each part's look")
	assert(hud.get_node("LabCenter") is MarginContainer, "DNA Lab should pin to the viewport with margins")
	assert(hud.get_node("%LabPanel").clip_contents, "DNA Lab should clip instead of growing off-screen")
	assert(hud.get_node("%LabPanel").custom_minimum_size.x <= 1.0, "DNA Lab should not force a huge width")
	assert(hud.get_node("%LabPanel").custom_minimum_size.y <= 1.0, "DNA Lab should not force a huge height")
	assert(str(hud.get_node("%LabSubject").text).contains(str(animal.get_stats().get("archetype", ""))),
		"DNA Lab should say the overall type from majority look")
	assert(str(hud.get_node("%LabName").text) == animal.creature_name,
		"DNA Lab should show the creature name")
	assert(int(hud.get_node("%LabNameEdit").max_length) == 20, "creature names should cap at 20 characters")
	assert(int(hud.get_node("%ZooNameEdit").max_length) == 20, "zoo names should cap at 20 characters")
	hud._commit_lab_name("Pip")
	assert(animal.creature_name == "Pip", "naming in the DNA Lab should rename the animal")
	assert(str(hud.get_node("%StatsName").text) == "Pip", "the exhibit card should use the new name")
	assert(str(hud.get_node("%LabName").text) == "Pip", "the DNA Lab should use the new name")
	hud._on_clone_animal()
	assert(SaveService.clones.size() == 1, "Clone animal should add a placeable copy")
	assert(int(SaveService.clones[0].get("cost", 0)) == 100, "cloned animals should cost $100 to place")
	hud._on_cat_animals()
	var saw_clone_tile := false
	for child in hud.get_node("%CatalogRow").get_children():
		if child is Button and (child as Button).text.contains("Pip"):
			saw_clone_tile = true
			assert((child as Button).text.contains("$100"), "clone tiles should list a $100 price")
	assert(saw_clone_tile, "cloned animals should appear on the Animals ribbon")
	assert(hud.get_node("%StatsPanel").get_parent() == hud.get_node("%LabCardHost"),
		"exhibit card should sit on the right of the lab")
	assert(hud.get_node_or_null("%HideQuests") == null, "quest popup should not have a Hide button")
	assert(hud.get_node_or_null("%ShowQuestHint") == null, "quests tab should not offer Show Quest Hint")
	assert(hud.get_node_or_null("%CoachHideEye") == null, "quest hint should not have a hide eye")
	assert(hud.get_node("%CoachPanel").get_parent().name == "TopRightOverlay",
		"active quest hint should sit under cash in the top right")
	hud._on_open_quests()
	assert(not hud.get_node("%QuestPanel").visible, "quest popup should hide while the DNA Lab is open")
	assert(not hud.get_node("%CatalogRibbon").visible, "opening quests should tuck the catalog")
	hud._on_close_lab()
	assert(hud.get_node("%QuestPanel").visible, "quest popup should return after the lab closes")
	assert(not hud.get_node("%CoachPanel").visible, "quest popup should hide the journey hint")
	assert(str(hud.get_node("%QuestName").text) != "", "quest card should show a title")
	assert(str(hud.get_node("%QuestReward").text).begins_with("Reward:"), "quest card should show the reward")
	var badge: TextureRect = hud.get_node("%QuestBadge") as TextureRect
	assert(badge != null and badge.visible, "Quests button should show a status badge")
	assert(badge.texture != null, "quest badge should have an icon")
	if QuestBoard.ready_to_claim:
		assert(str(badge.get_meta("kind")) == "reward", "claimable quests should show the gold ribbon")
	else:
		assert(str(badge.get_meta("kind")) == "quest", "active quests should show the red exclamation")
	var status_icon: TextureRect = hud.get_node("%QuestStatusIcon") as TextureRect
	assert(status_icon != null and status_icon.visible, "quest card should repeat the status icon")
	assert(str(status_icon.get_meta("kind")) == str(badge.get_meta("kind")), "button and card badges should match")
	hud._on_open_shop()
	assert(not hud.get_node("%QuestPanel").visible, "quest popup should hide while the shop is open")
	assert(hud.get_node("%ShopList").get_child_count() > 0, "shop should list unlocked serums")
	hud._on_close_shop()
	assert(hud.get_node("%QuestPanel").visible, "quest popup should return after the shop closes")
	hud._on_hide_quests()
	assert(not hud.get_node("%QuestPanel").visible, "Close should tuck the quest popup")
	hud._on_open_shop()
	hud._on_close_shop()
	assert(not hud.get_node("%QuestPanel").visible, "a hidden quest popup should stay hidden after menus close")
	hud._on_deselect()
	TutorialService.step = TutorialService.Step.OPEN
	TutorialService.seen = false
	Events.tutorial_changed.emit()
	assert(hud.get_node("%CoachPanel").visible, "active quest hint should show when menus are closed")
	assert(is_equal_approx(hud.get_node("%QuestButton").size.y, hud.get_node("%ShopButton").size.y),
		"Quests should stay the same height as Vial shop")
	assert(is_equal_approx(hud.get_node("%ZooHoursButton").size.y, hud.get_node("%ShopButton").size.y),
		"Open the zoo should stay the same height as Vial shop")
	assert(str(hud.get_node("%CoachTitle").text) == "Open the gates",
		"journey title should match the current step")
	assert(str(hud.get_node("%CoachCopy").text) == "Open the zoo so guests can arrive.",
		"quest hint should use the current tutorial line")
	Events.animal_selected.emit(animal)
	assert(not hud.get_node("%CoachPanel").visible, "inspecting an animal should hide the journey hint")
	hud._on_deselect()
	assert(hud.get_node("%CoachPanel").visible, "closing the exhibit card should bring the journey hint back")
	hud._on_open_shop()
	assert(not hud.get_node("%CoachPanel").visible, "the vial shop should hide the journey hint")
	hud._on_close_shop()
	assert(hud.get_node("%CoachPanel").visible, "closing the shop should bring the journey hint back")
	hud._on_open_quests()
	assert(not hud.get_node("%CoachPanel").visible, "the journey hint stays down while quests are open")
	hud._on_hide_quests()
	assert(hud.get_node("%CoachPanel").visible, "closing quests should show the journey hint again")
	var cash_click := InputEventMouseButton.new()
	cash_click.pressed = true
	cash_click.button_index = MOUSE_BUTTON_LEFT
	hud._on_wallet_gui_input(cash_click)
	assert(hud.get_node("%LedgerPanel").visible, "clicking cash should open the till log")
	assert(not hud.get_node("%CoachPanel").visible, "the till log should hide the journey hint")
	assert(str(hud.get_node("%LedgerSummary").text) != "", "till log should explain tickets and upkeep")
	assert(hud.get_node("%LedgerList").get_child_count() > 0, "till log should list recent cash moves")
	hud._close_ledger()
	assert(hud.get_node("%CoachPanel").visible, "closing the till log should bring the journey hint back")
	TutorialService.skip()
	Events.animal_selected.emit(animal)
	hud._on_mutate_pressed()
	assert(hud.get_node("%LabPanel").visible, "DNA Lab should reopen for splice tests")
	assert(hud.get_node("%VialRow").get_child_count() > 0, "lab tray should show unlocked serums")
	animal.visuals.set_part_shape("head", 0)
	hud._refresh_limb_notes()
	var head_before: int = animal.visuals.get_current_index("head")
	var notes: String = hud.get_node("%DnaStrand").notes_text().to_lower()
	assert(notes.contains("head |"), "strand should keep the slot name beside the pair")
	assert(notes.contains("gorilla"), "strand should name the current head")
	assert(notes.contains("scary"), "strand should name the current look")
	if GeneTree.stock_of("cute") <= 0:
		GeneTree.add_stock("cute", 1)
	hud._on_vial_clicked("cute")
	assert(animal.visuals.get_current_index("head") == head_before,
		"clicking a serum should not splice it")
	assert(str(hud.get_node("%LabHint").text).to_lower().contains("drag"),
		"clicking a serum should tell you to drag it")
	hud._on_vial_dropped("cute")
	assert(animal.visuals.get_current_index("head") == head_before,
		"a drop with no limb should not splice")
	hud._on_vial_dropped("cute", "head")
	var head_after: int = animal.visuals.get_current_index("head")
	assert(head_after != head_before, "Cute serum should change the dropped limb")
	assert(TraitLibrary.option_has_tag("head", head_after, "Cute"), "Cute serum should land on a Cute head")
	animal.visuals.set_skin(0)
	var cute_stock: int = GeneTree.stock_of("cute")
	if cute_stock <= 0:
		GeneTree.add_stock("cute", 1)
		cute_stock = GeneTree.stock_of("cute")
	hud._on_vial_dropped("cute", "color")
	var coat_after: int = animal.visuals.get_current_palette_index()
	assert(coat_after != 0, "Cute serum should change the coat")
	assert(TraitLibrary.option_has_tag("color", coat_after, "Cute"), "Cute serum should land on a Cute coat")
	assert(GeneTree.stock_of("cute") == cute_stock - 1, "a coat drop should consume a charge")
	GeneTree.unlock_vial("linger", 1)
	hud._on_vial_dropped("linger", "tail")
	assert(animal.has_perk(GeneTree.PERK_LINGER), "Linger graft should attach without swapping a part")
	assert(animal.get_pen().has_animal_perk(GeneTree.PERK_LINGER), "the pen should expose the graft")
	assert(str(hud.get_node("%StatsPerks").text).contains("Linger"), "exhibit card should list grafts")
	assert(not hud.get_node("%PauseScrim").visible, "pause overlay starts hidden")
	assert(str(hud.get_node("%ResumeButton").text) == "Resume", "pause should say Resume")
	assert(str(hud.get_node("%SaveButton").text) == "Save Zoo", "pause should say Save Zoo")
	assert(str(hud.get_node("%LoadSaveButton").text) == "Load Save", "pause should say Load Save")
	assert(str(hud.get_node("%TitleButton").text) == "Exit To Menu", "pause should say Exit To Menu")
	assert(hud.get_node_or_null("%QuitButton") == null, "pause should not quit the game")
	assert(hud.get_node("%SavePicker") != null, "pause should have a load list")
	hud.handle_escape()
	assert(not hud.get_node("%LabPanel").visible, "ESC should close the DNA Lab first")
	hud.handle_escape()
	assert(hud.get_node("%PauseScrim").visible, "ESC with no overlay should pause")
	assert(get_tree().paused, "pause overlay should pause the tree")
	hud._on_pause_load()
	await get_tree().process_frame
	assert(hud.get_node("%SavePicker").visible, "Load Save should open the save list")
	assert(not hud.get_node("%PauseScrim").visible, "the save list covers the pause panel")
	hud.handle_escape()
	assert(not hud.get_node("%SavePicker").visible, "ESC should close the save list first")
	assert(hud.get_node("%PauseScrim").visible, "closing the save list should return to pause")
	hud._on_resume()
	assert(not get_tree().paused, "Resume should unpause")
	assert(not hud.get_node("%PauseScrim").visible, "Resume should hide the pause overlay")
	assert(hud.get_node("%DeleteAnimal") != null, "exhibit card should have a delete animal button")
	Events.pen_selected.emit(animal.get_pen())
	assert(hud.get_node("%PenPanel").visible, "pen card should show after clicking a paddock")
	assert(not hud.get_node("%CoachPanel").visible, "inspecting a pen should hide the journey hint")
	assert(str(hud.get_node("%PenDetail").text).contains("/"), "pen card should show occupancy")
	assert(not hud.get_node("%StatsPanel").visible, "pen card should hide the exhibit card")
	assert(hud.get_node("%DeletePen") != null, "pen card should have a delete pen button")
	hud._dismiss_open_menu()
	assert(not hud.get_node("%PenPanel").visible, "clicking the world should hide the pen card")
	var solo: Visitor = (load("res://scenes/Visitor.tscn") as PackedScene).instantiate()
	add_child(solo)
	solo.setup(null, "goths", Vector2(220, 180))
	assert(TraitLibrary.visitor_sprite_paths("goths").has(str(solo.get("look_path"))),
		"goths should use the emo sprites")
	assert((solo.get_node("Sprite2D") as Sprite2D).modulate == Color.WHITE,
		"goth sprites should not take a type tint")
	Events.visitor_selected.emit(solo)
	assert(hud.get_node("%GuestPanel").visible, "guest card should show after clicking a visitor")
	assert(not hud.get_node("%CoachPanel").visible, "inspecting a visitor should hide the journey hint")
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
	var parent: Visitor = (load("res://scenes/Visitor.tscn") as PackedScene).instantiate()
	var kid: Visitor = (load("res://scenes/Visitor.tscn") as PackedScene).instantiate()
	var tourist: Visitor = (load("res://scenes/Visitor.tscn") as PackedScene).instantiate()
	var creator: Visitor = (load("res://scenes/Visitor.tscn") as PackedScene).instantiate()
	add_child(parent)
	add_child(kid)
	add_child(tourist)
	add_child(creator)
	parent.setup(null, "parents", Vector2(200, 200))
	kid.setup(null, "children", Vector2(205, 208))
	parent.family_id = 91
	kid.family_id = 91
	kid.family_leader = parent
	tourist.setup(null, "tourists", Vector2(198, 196))
	creator.setup(null, "creators", Vector2(400, 400))
	var camera: Visitor = (load("res://scenes/Visitor.tscn") as PackedScene).instantiate()
	add_child(camera)
	camera.setup(null, "camera", Vector2(410, 410))
	creator.family_id = 77
	camera.family_id = 77
	camera.family_leader = creator
	camera.family_offset = Vector2(-22.0, 10.0)
	assert(TraitLibrary.visitor_sprite_paths("creators").has(str(creator.get("look_path"))),
		"creators should use the influencer sprites")
	assert(str(camera.get("look_path")) == "res://art/visitors/camera_man.png",
		"the camera operator should use the camera-man sprite")
	assert((creator.get_node("Sprite2D") as Sprite2D).modulate == Color.WHITE,
		"creator sprites should not take a type tint")
	assert((camera.get_node("Sprite2D") as Sprite2D).modulate == Color.WHITE,
		"the camera operator should not take a type tint")
	assert(creator._can_talk() and not camera._can_talk(),
		"only the content creator should talk")
	assert(str(creator.inspect_party().get("title", "")) == "A content creator",
		"a creator crew should not inspect as a family")
	assert(not bool(creator.inspect_party().get("family", true)),
		"a creator plus camera should stay a film crew")
	assert(not creator.likes_exhibit({"Cute": 6}), "creators should not clip a cute default")
	assert(creator.likes_exhibit({"Majestic": 3}), "creators should clip a majestic exhibit")
	assert(creator.likes_exhibit({"Weird": 3}), "creators should clip a weird exhibit")
	assert(TraitLibrary.visitor_sprite_paths("tourists").has(str(tourist.get("look_path"))),
		"tourists should use the camera-hat sprites")
	assert((tourist.get_node("Sprite2D") as Sprite2D).modulate == Color.WHITE,
		"tourist sprites should not take a type tint")
	var thrill: Visitor = (load("res://scenes/Visitor.tscn") as PackedScene).instantiate()
	add_child(thrill)
	thrill.setup(null, "thrill", Vector2(240, 180))
	assert(TraitLibrary.visitor_sprite_paths("thrill").has(str(thrill.get("look_path"))),
		"thrill-seekers should use the crazy-hair sprites")
	assert((thrill.get_node("Sprite2D") as Sprite2D).modulate == Color.WHITE,
		"thrill-seeker sprites should not take a type tint")
	assert(is_equal_approx(thrill.draw_height(), parent.draw_height()),
		"thrill-seekers should stand as tall as the adults")
	assert(is_equal_approx(tourist.draw_height(), parent.draw_height()),
		"tourists should stand as tall as the adults")
	assert(kid.draw_height() < parent.draw_height() - 4.0,
		"children should be a little smaller than the adults")
	var parent_shadow: Sprite2D = parent.get_node("Shadow") as Sprite2D
	var kid_shadow: Sprite2D = kid.get_node("Shadow") as Sprite2D
	var tourist_shadow: Sprite2D = tourist.get_node("Shadow") as Sprite2D
	assert(parent_shadow != null and parent_shadow.visible and parent_shadow.texture != null,
		"adults should cast a ground shadow")
	assert(tourist_shadow != null and tourist_shadow.visible and tourist_shadow.texture != null,
		"tourists should cast a ground shadow")
	assert(kid_shadow != null and kid_shadow.visible and kid_shadow.texture != null,
		"children should cast a ground shadow")
	assert(kid_shadow.scale.x < parent_shadow.scale.x,
		"child shadows should be smaller than adult shadows")
	var fence: Vector2 = Vector2(
		animal.get_pen().world_rect().position.x - 24.0,
		animal.get_pen().world_rect().get_center().y
	)
	parent.global_position = fence
	kid.global_position = fence + Vector2(8.0, 6.0)
	var cash_before: int = WalletService.money
	var cute_pay: int = TraitLibrary.sight_bonus("parents", animal.get_pen().exhibit_tags(), true)
	parent._notice_exhibits()
	assert(WalletService.money == cash_before + cute_pay, "a family should pay for a cute exhibit")
	assert(parent.get_node("Overhead/Mood").texture == GuestMoodArt.heart(),
		"guests should flash a heart when they like an exhibit")
	kid._notice_exhibits()
	assert(WalletService.money == cash_before + cute_pay, "a family should only pay once per exhibit")
	var sour: Visitor = (load("res://scenes/Visitor.tscn") as PackedScene).instantiate()
	add_child(sour)
	sour.setup(null, "goths", fence)
	sour._notice_exhibits()
	assert(WalletService.money == cash_before + cute_pay, "goths should not pay for a cute exhibit")
	assert(sour.get_node("Overhead/Mood").texture == GuestMoodArt.tear(),
		"guests should flash a tear when they dislike an exhibit")
	sour.free()
	creator.global_position = fence
	creator._notice_exhibits()
	assert(bool(creator.get("_creator_boosted")),
		"a majestic exhibit should trigger creator engagement")
	assert(creator.get_node("Overhead/Bubble").visible, "creators should talk to chat at a pen")
	assert(not str(creator.get_node("Overhead/Bubble/Talk").text).is_empty(),
		"creators should say something after clipping")
	parent.position = Vector2(200, 200)
	kid.position = Vector2(205, 208)
	assert(GuestMoodArt.heart().get_width() >= 64, "mood hearts should be real art, not a 32px blob")
	assert(GuestMoodArt.bang().get_width() >= 64, "mood bangs should be real art, not a 32px blob")
	solo.position = Vector2(220, 200)
	parent._tick_goth_scare(0.2)
	kid._tick_goth_scare(0.2)
	var tourist_before: float = tourist.interest
	tourist._tick_goth_scare(1.0)
	assert(bool(parent.get("_panic")), "parents should panic when they see a goth")
	assert(int(parent.get("_state")) == Visitor.State.HAIL, "parents should bolt for the car")
	assert(float(parent.get("_speed")) >= Visitor.PANIC_SPEED - 0.1, "parents should run faster")
	var watcher: Visitor = (load("res://scenes/Visitor.tscn") as PackedScene).instantiate()
	add_child(watcher)
	watcher.setup(null, "parents", Vector2(solo.position.x - 240.0, solo.position.y))
	watcher._tick_goth_scare(0.2)
	assert(bool(watcher.get("_panic")), "parents should notice a goth a couple of tiles away")
	assert(int(watcher.get("_state")) == Visitor.State.HAIL, "parents should run for the car once they see a goth")
	watcher.free()
	assert(parent.get_node("Overhead/Mood").visible, "parents should flash an exclamation")
	assert(parent.get_node("Overhead/Bubble").visible, "parents should say something in a speech bubble")
	assert(str(parent.get_node("Overhead/Bubble/Talk").text) != "", "parent bubble should have a line")
	assert(int(parent.get_node("Overhead/Bubble/Talk").get_theme_font_size("font_size")) <= 10,
		"speech bubbles should stay small")
	assert(bool(kid.get("_panic")), "kids should panic when they see a goth")
	assert(kid.get_node("Overhead/Mood").visible, "kids should show a tear when scared")
	assert(not kid.get_node("Overhead/Bubble").visible, "only one parent should speak for the family")
	assert(tourist.interest < tourist_before, "tourists should sour when goths hang around")
	assert(tourist.get_node("Overhead/Mood").visible, "tourists should sweat when goths hang around")
	solo.set("_leaving", true)
	solo.set("_state", Visitor.State.HAIL)
	assert(not solo.is_scaring(), "a goth you sent home should stop scaring people")
	var money_before: int = WalletService.money
	if not bool(creator.get("_creator_boosted")):
		creator._post_creator_clip()
		assert(WalletService.money == money_before + Visitor.CREATOR_CLIP_CASH, "a clip should pay the zoo")
	assert(bool(creator.get("_creator_boosted")), "a creator should only pay once")
	hud._on_close_guest()
	assert(not hud.get_node("%GuestPanel").visible, "Close should hide the guest card")
	parent.free()
	kid.free()
	tourist.free()
	thrill.free()
	creator.free()
	camera.free()
	solo.free()
	print("HUD OK")
	return hud


func _test_street(hud: Control = null) -> void:
	var street_scene: PackedScene = load("res://scenes/Street.tscn")
	var street: Node = street_scene.instantiate()
	add_child(street)
	assert(not bool(street.get("is_open")), "a new street should start closed")
	assert(street.spawn_dropoff() == null, "closed gates should not take drop-offs")
	assert(street.has_exhibit(), "earlier tests should leave a stocked pen")
	if hud != null:
		hud._on_toggle_zoo_hours()
		assert(bool(street.get("is_open")), "Open zoo should work once a pen has an animal")
		assert(not hud.get_node("%HoursPanel").visible, "a successful open should not show the error popup")
		assert(str(hud.get_node("%ZooHoursButton").text) == "Close zoo", "open gates should offer Close zoo")
		assert(str(hud.get_node("%HoursLabel").text) == "Zoo open", "hours chip should say Zoo open")
		assert(str(hud.get_node("%HoursDetail").text).contains("visiting"), "open chip should say guests are visiting")
		assert(QuestBoard.current().get("id") == "gates", "open-zoo quest should still be active")
		assert(QuestBoard.ready_to_claim, "opening the zoo should complete the gates quest")
	else:
		assert(street.set_open(true), "a stocked pen should let the zoo open")
	assert(street.bay_count() == 6, "should mark six parallel roadside parks")
	assert(street.westbound_y() > GridService.parking_rect().end.y, "the near lane stays on the asphalt")
	assert(street.westbound_y() < street.eastbound_y(), "left-hand traffic uses the lane beside the parks")
	assert(Car.SIZE.x >= float(GridService.CELL_SIZE) * 0.9, "cars should read at pen-cell scale")
	assert(Visitor.DISPLAY_HEIGHT > 40.0 and Visitor.DISPLAY_HEIGHT < 60.0,
		"patrons should be a quarter smaller than the old 68px height")
	assert(GridService.parking_rect().size.y > Car.SIZE.y + 16.0, "parking strip should fit a car")
	assert(street.visitor_cap() == GeneTree.visitor_cap(), "street cap should follow gene-tree park perks")
	GridService.clear_paths()
	for x in range(1, 7):
		GridService.add_path(GridService.world_to_path_cell(GridService.cell_center(Vector2i(x, 0))))
	assert(GridService.has_path(Vector2i(1, 0)), "test path should land on empty grass")
	var pather: Visitor = street._make_guest("tourists", GridService.cell_center(Vector2i(1, 1)))
	pather.go_to(GridService.cell_center(Vector2i(6, 1)))
	var used_path := false
	for _i in range(900):
		pather._process(1.0 / 60.0)
		if GridService.has_path(GridService.world_to_cell(pather.position)):
			used_path = true
			break
	assert(used_path, "guests should follow laid paths instead of cutting across grass")
	pather.position = Vector2(-400.0, -400.0)
	pather.crush()
	GridService.clear_paths()
	var passer: Node = street.spawn_traffic(1)
	assert(passer != null and int(passer.get("role")) == 0, "passing cars should spawn on the road")
	var car_sprite: Sprite2D = passer.get_node_or_null("Sprite2D") as Sprite2D
	assert(car_sprite != null and car_sprite.texture != null, "cars should use the artist car texture")
	assert(car_sprite.texture.get_width() > 0, "car texture should have pixels")
	assert((passer as Car).body_color.a > 0.9, "each car should get a body tint")
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
	assert(family_likes.has("Cute"), "family likes should union the children's tastes")
	assert(family_hates.has("Scary"), "family dislikes should union the children's tastes")
	var kid: Visitor = null
	for mate in party:
		if str(mate.visitor_id) == "children":
			kid = mate
			break
	assert(kid != null, "family inspect needs a child member")
	var kid_card: Dictionary = kid.inspect_party()
	assert(str(kid_card.get("title", "")) == str(family_card.get("title", "")), "clicking any family member should open the same card")
	assert(str(family_card.get("thought", "")).to_lower().contains("kids"),
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
		assert(str(hud.get_node("%GuestThought").text).to_lower().contains("kids"),
			"family guest card should show a shared thought")
		hud._process(0.0)
		var cam: Camera2D = hud.get_node("%GuestThumbCamera") as Camera2D
		assert(cam != null, "family guest card should keep a follow camera")
		assert(cam.global_position.distance_to(leader.party_center()) < 80.0,
			"follow camera should track the family as a group")
		hud._on_close_guest()
		assert(not hud.get_node("%GuestPanel").visible, "Close should hide the family guest card")
	var crew: Visitor = street.spawn_creator_crew(park + Vector2(90.0, 0.0))
	assert(crew != null and crew.visitor_id == "creators", "a creator drop should spawn the talent")
	assert(street.has_creator(), "only the live creator should count as on site")
	var cam_op: Visitor = null
	for mate in street.family_of(crew):
		if str(mate.visitor_id) == "camera":
			cam_op = mate
			break
	assert(cam_op != null and cam_op.family_leader == crew, "a camera operator should follow the creator")
	assert(not bool(crew.inspect_party().get("family", true)), "the film crew should not inspect as a family")
	assert(str(crew.inspect_party().get("title", "")) == "A content creator",
		"the film crew card should name the creator")
	assert(not cam_op._can_talk(), "the camera operator should stay quiet")
	var hype_before: float = float(street.get("hype_time"))
	crew._post_creator_clip()
	assert(float(street.get("hype_time")) > hype_before, "a liked clip should speed up arrivals")
	var extra: Visitor = street._spawn_solo(park + Vector2(140.0, 0.0))
	assert(extra.visitor_id != "creators", "a second content creator should not spawn")
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
	var talking := 0
	for mate in street.family_of(guest):
		assert(int(mate.pickup_bay) == int(guest.pickup_bay), "the family should share one pickup car")
		assert(bool(mate._leaving), "the whole family should leave together")
		if mate.get_node("Overhead/Bubble").visible:
			talking += 1
			if not bool(guest.get("_panic")):
				var said := str(mate.get_node("Overhead/Bubble/Talk").text).to_lower()
				assert(not said.contains("now") and not said.contains("car"),
					"boarding a ride should sound calm, got '%s'" % said)
	assert(talking == 1, "only one parent should talk when the family leaves, got %d" % talking)
	var wall_origin := Vector2i(2, 4)
	GridService.occupy_area(wall_origin, Vector2i(12, 2), street)
	var walker: Visitor = street._make_guest("tourists", Vector2(700.0, 120.0))
	var start_y: float = walker.position.y
	walker.hail()
	assert(walker._state == Visitor.State.HAIL, "hail should send the guest walking home")
	var sway: float = 0.0
	var walk_sprite: Sprite2D = walker.get_node("Sprite2D") as Sprite2D
	for _i in range(1600):
		walker._process(1.0 / 60.0)
		if walk_sprite != null:
			sway = maxf(sway, absf(walk_sprite.rotation))
		if walker._state == Visitor.State.WAIT:
			break
		if walker.position.y >= GridService.parking_rect().position.y:
			break
	assert(sway > 0.03, "walking guests should sway on a walk cycle, got %s" % sway)
	assert(
		walker.position.y > start_y + 180.0 or walker._state == Visitor.State.WAIT,
		"leaving guests should walk around pens instead of freezing, stayed at %s" % walker.position
	)
	GridService.free_area(wall_origin, Vector2i(12, 2), street)
	walker.crush()
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
	var cap_before: int = street.visitor_cap()
	var ads_before: float = GeneTree.spawn_time_scale()
	GeneTree.grant_zoo_perk(GeneTree.PERK_MORE_PARKING)
	street._sync_stalls()
	assert(street.bay_count() == 9, "more parking should add roadside bays")
	assert(street.visitor_cap() == cap_before + 8, "more parking should raise guest capacity")
	GeneTree.grant_zoo_perk(GeneTree.PERK_MORE_ADS)
	assert(GeneTree.spawn_time_scale() < ads_before, "more advertising should speed arrivals")
	if hud != null:
		hud._on_toggle_zoo_hours()
		assert(hud.get_node("%HoursPanel").visible, "Close zoo should show a closing popup")
		assert(str(hud.get_node("%HoursTitle").text) == "Closing the zoo", "close popup should say the zoo is closing")
		assert(str(hud.get_node("%HoursCopy").text).contains("closing"), "close popup should explain guests leave")
		assert(bool(street.get("is_open")), "dismissing without confirm should leave the zoo open")
		hud._on_dismiss_hours()
		assert(bool(street.get("is_open")), "cancelling the close popup should keep the zoo open")
		hud._on_toggle_zoo_hours()
		hud._on_confirm_hours()
	else:
		assert(street.set_open(false), "should be able to close the zoo")
	assert(not bool(street.get("is_open")), "Close zoo should shut the gates")
	assert(street.spawn_dropoff() == null, "closed gates should stop new arrivals")
	for child in street.get_children():
		var leftover := child as Visitor
		if leftover != null and is_instance_valid(leftover) and not leftover.is_queued_for_deletion():
			assert(leftover.is_leaving(), "closing should send guests home immediately")
	if hud != null:
		assert(str(hud.get_node("%ZooHoursButton").text) == "Open the zoo", "closed gates should offer Open the zoo")
		assert(str(hud.get_node("%HoursLabel").text) == "Zoo closed", "hours chip should say Zoo closed")
		assert(str(hud.get_node("%HoursDetail").text).contains("cannot arrive"), "closed chip should say guests cannot arrive")
	print("Street OK — bays=%d visitors=%d" % [street.bay_count(), street.visitor_count()])


func _test_serum_art() -> void:
	assert(SerumArt.FLASK != null, "serum flask art should load")
	assert(SerumArt.texture("cute") != null, "each serum should have a flask icon")
	assert(SerumArt.LIQUID.has("scary"), "Scary serum should have its own flask colour")
	for vial in GeneTree.VIALS:
		var vial_id: String = str(vial.get("id", ""))
		assert(SerumArt.LIQUID.has(vial_id), "every vial needs a flask colour, missing %s" % vial_id)
		var tex: Texture2D = SerumArt.texture(vial_id)
		assert(tex != null, "missing flask for %s" % vial_id)
		assert(tex.get_width() == SerumArt.FLASK.get_width(), "every serum should use the shared flask")
	var cute: Color = _serum_liquid_mean("cute")
	var scary: Color = _serum_liquid_mean("scary")
	var weird: Color = _serum_liquid_mean("weird")
	assert(cute.r > 0.6 and cute.g > scary.g, "Cute serum should look peach, not crimson")
	assert(scary.r > scary.g * 1.4, "Scary serum should look crimson")
	assert(weird.g > weird.r, "Weird serum should look teal")
	var unknown: Texture2D = SerumArt.texture("not-a-vial")
	assert(unknown != null, "an unknown serum should still get the flask")
	print("SerumArt OK")


func _serum_liquid_mean(vial_id: String) -> Color:
	var tex: Texture2D = SerumArt.texture(vial_id)
	var img: Image = tex.get_image()
	if img == null:
		return Color.BLACK
	if img.is_compressed():
		img.decompress()
	var sum := Color(0, 0, 0, 0)
	var count: int = 0
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var pixel: Color = img.get_pixel(x, y)
			if pixel.a < 0.2:
				continue
			var brightest: float = maxf(pixel.r, maxf(pixel.g, pixel.b))
			var dullest: float = minf(pixel.r, minf(pixel.g, pixel.b))
			var sat: float = 0.0 if brightest <= 0.001 else (brightest - dullest) / brightest
			var chroma_purple: float = (pixel.r + pixel.b) * 0.5 - pixel.g
			var is_liquid: bool = (sat >= 0.28 and brightest >= 0.28) \
				or (chroma_purple > 0.08 and sat >= 0.10 and brightest >= 0.22)
			if not is_liquid:
				continue
			sum += pixel
			count += 1
	if count <= 0:
		return Color.BLACK
	return sum / float(count)


func _fill_mean(tex: Texture2D) -> float:
	var img: Image = tex.get_image()
	if img == null:
		return 0.0
	if img.is_compressed():
		img.decompress()
	var sum: float = 0.0
	var count: int = 0
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var pixel: Color = img.get_pixel(x, y)
			if pixel.a < 0.08:
				continue
			var lum: float = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114
			if lum < 0.30:
				continue
			sum += lum
			count += 1
	if count <= 0:
		return 0.0
	return sum / float(count)


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
