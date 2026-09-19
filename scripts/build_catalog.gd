extends RefCounted
class_name BuildCatalog

## Priced build items for the bottom dock. Pens and base animals cost cash
## on successful place — Cities: Skylines / Prison Architect style.

const CAT_PENS: String = "pens"
const CAT_ANIMALS: String = "animals"

const ITEMS: Array[Dictionary] = [
	{
		"id": "pen_small",
		"category": CAT_PENS,
		"kind": "pen",
		"name": "Small pen",
		"blurb": "4×3 paddock, holds 2",
		"cost": 40,
		"size_cells": Vector2i(4, 3),
	},
	{
		"id": "pen_large",
		"category": CAT_PENS,
		"kind": "pen",
		"name": "Large pen",
		"blurb": "6×5 paddock, holds 5",
		"cost": 75,
		"size_cells": Vector2i(6, 5),
	},
	{
		"id": "jimothy",
		"category": CAT_ANIMALS,
		"kind": "animal",
		"name": "Jimothy",
		"blurb": "Soft, bulky starter stock",
		"cost": 30,
		"parts": {"body": 0, "head": 0, "front_legs": 0, "back_legs": 0, "tail": 0},
		"color": 0,
		"hide": ["tail"],
	},
	{
		"id": "horse",
		"category": CAT_ANIMALS,
		"kind": "animal",
		"name": "Horse",
		"blurb": "Long-legged paddock runner",
		"cost": 45,
		"parts": {"body": 0, "head": 0, "front_legs": 1, "back_legs": 1, "tail": 1},
		"color": 0,
		"hide": [],
	},
	{
		"id": "spikeback",
		"category": CAT_ANIMALS,
		"kind": "animal",
		"name": "Spikeback",
		"blurb": "Horned show-stopper",
		"cost": 50,
		"parts": {"body": 2, "head": 1, "front_legs": 0, "back_legs": 0, "tail": 0},
		"color": 1,
		"hide": [],
	},
	{
		"id": "gloop",
		"category": CAT_ANIMALS,
		"kind": "animal",
		"name": "Gloop",
		"blurb": "Weird crowd-gawker",
		"cost": 40,
		"parts": {"body": 1, "head": 2, "front_legs": 2, "back_legs": 2, "tail": 2},
		"color": 2,
		"hide": [],
	},
	{
		"id": "chimory",
		"category": CAT_ANIMALS,
		"kind": "animal",
		"name": "Chimory",
		"blurb": "Gorilla, frog, sheep, stinger",
		"cost": 55,
		"parts": {"body": 3, "head": 3, "front_legs": 3, "back_legs": 3, "tail": 3},
		"color": 0,
		"hide": [],
	},
	{
		"id": "jimmothy",
		"category": CAT_ANIMALS,
		"kind": "animal",
		"name": "Jimmothy",
		"blurb": "Horse face, curly tail",
		"cost": 20,
		"parts": {"body": 4, "head": 4, "front_legs": 4, "back_legs": 4, "tail": 4},
		"color": 0,
		"hide": [],
	},
]


static func items_for(category: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for item in ITEMS:
		if str(item.get("category", "")) == category:
			found.append(item)
	return found


static func get_item(item_id: String) -> Dictionary:
	for item in ITEMS:
		if str(item.get("id", "")) == item_id:
			return item
	return {}
