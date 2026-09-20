extends Node2D

## Lineup of the texture coats so they can be screenshot in-game.

const COAT_IDS: Array[String] = ["spots", "patches", "oil", "giraffe", "starry"]


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.45, 0.72, 0.38))
	var cam := Camera2D.new()
	cam.enabled = true
	cam.position = Vector2(640.0, 360.0)
	add_child(cam)
	var packed: PackedScene = load("res://scenes/Animal.tscn") as PackedScene
	for i in COAT_IDS.size():
		var coat_id: String = COAT_IDS[i]
		var coat_index: int = TraitLibrary.option_index_for_id("color", coat_id)
		var animal: Animal = packed.instantiate()
		animal.position = Vector2(160.0 + float(i) * 240.0, 390.0)
		add_child(animal)
		animal.visuals.set_part_shape("head", 8)
		animal.visuals.set_part_shape("front_legs", 1)
		animal.visuals.set_part_shape("back_legs", 1)
		animal.visuals.set_skin(coat_index)
		var caption := Label.new()
		caption.text = str(TraitLibrary.get_option("color", coat_index).get("name", coat_id))
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.position = Vector2(70.0 + float(i) * 240.0, 520.0)
		caption.size = Vector2(180.0, 28.0)
		add_child(caption)
