extends RefCounted
class_name BuildCatalog

## Priced build items for the bottom dock. Pens and base animals cost cash
## on successful place — Cities: Skylines / Prison Architect style.

const CAT_PENS: String = "pens"
const CAT_ANIMALS: String = "animals"
const CAT_PATHS: String = "paths"
const CAT_PARK: String = "park"

const ITEMS: Array[Dictionary] = [
	{
		"id": "pen_tiny",
		"category": CAT_PENS,
		"kind": "pen",
		"name": "Tiny pen",
		"blurb": "3×2 paddock, holds 1",
		"cost": 30,
		"size_cells": Vector2i(3, 2),
		"capacity": 1,
	},
	{
		"id": "pen_small",
		"category": CAT_PENS,
		"kind": "pen",
		"name": "Small pen",
		"blurb": "4×3 paddock, holds 2",
		"cost": 50,
		"size_cells": Vector2i(4, 3),
		"capacity": 2,
	},
	{
		"id": "pen_large",
		"category": CAT_PENS,
		"kind": "pen",
		"name": "Large pen",
		"blurb": "6×5 paddock, holds 5",
		"cost": 110,
		"size_cells": Vector2i(6, 5),
		"capacity": 5,
		"unlock_quest": "expand",
	},
	{
		"id": "pen_gallery",
		"category": CAT_PENS,
		"kind": "pen",
		"name": "Gallery",
		"blurb": "8×3 viewing edge, holds 4",
		"cost": 90,
		"size_cells": Vector2i(8, 3),
		"capacity": 4,
		"enjoyment_bonus": 0.06,
		"unlock_quest": "stay",
	},
	{
		"id": "jimothy",
		"category": CAT_ANIMALS,
		"kind": "animal",
		"name": "Jimothy",
		"blurb": "Soft, bulky starter stock",
		"cost": 40,
		"parts": {"body": 0, "head": 0, "front_legs": 0, "back_legs": 0, "tail": 0},
		"color": 0,
		"hide": [],
	},
	{
		"id": "chimory",
		"category": CAT_ANIMALS,
		"kind": "animal",
		"name": "Chimory",
		"blurb": "Gorilla, frog, sheep, stinger",
		"cost": 80,
		"parts": {"body": 0, "head": 1, "front_legs": 5, "back_legs": 0, "tail": 6},
		"color": 0,
		"hide": [],
		"unlock_quest": "fright",
	},
	{
		"id": "jimmothy",
		"category": CAT_ANIMALS,
		"kind": "animal",
		"name": "Jimmothy",
		"blurb": "Horse face, curly tail",
		"cost": 25,
		"parts": {"body": 0, "head": 3, "front_legs": 1, "back_legs": 1, "tail": 7},
		"color": 0,
		"hide": [],
	},
	{
		"id": "path_stone",
		"category": CAT_PATHS,
		"kind": "path",
		"name": "Stone path",
		"blurb": "Cobble walkway",
		"cost": 1,
	},
	{
		"id": "park_bench",
		"category": CAT_PARK,
		"kind": "park",
		"name": "Bench",
		"blurb": "Guests sit and linger",
		"cost": 15,
	},
	{
		"id": "park_snack",
		"category": CAT_PARK,
		"kind": "park",
		"name": "Snack cart",
		"blurb": "A dollar extra per nibble",
		"cost": 25,
		"unlock_quest": "till",
	},
	{
		"id": "park_lamp",
		"category": CAT_PARK,
		"kind": "park",
		"name": "Lamp",
		"blurb": "Guests prefer the lit grass",
		"cost": 12,
		"unlock_quest": "expand",
	},
	{
		"id": "park_poster",
		"category": CAT_PARK,
		"kind": "park",
		"name": "Poster stand",
		"blurb": "Hypes the nearest pen",
		"cost": 20,
		"unlock_quest": "fame",
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


static func is_unlocked(item: Dictionary) -> bool:
	var quest_id: String = str(item.get("unlock_quest", ""))
	if quest_id.is_empty():
		return true
	return QuestBoard.has_claimed(quest_id)


static func unlock_hint(item: Dictionary) -> String:
	var quest_id: String = str(item.get("unlock_quest", ""))
	if quest_id.is_empty():
		return ""
	var title: String = QuestBoard.title_of(quest_id)
	if title.is_empty():
		title = quest_id
	return "Finish \"%s\" to unlock." % title
