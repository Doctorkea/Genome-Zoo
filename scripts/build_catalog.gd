extends RefCounted
class_name BuildCatalog

## Priced build items for the bottom dock. Pens and base animals cost cash
## on successful place — Cities: Skylines / Prison Architect style.

const CAT_PENS: String = "pens"
const CAT_ANIMALS: String = "animals"
const CAT_PATHS: String = "paths"

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
		"id": "horse",
		"category": CAT_ANIMALS,
		"kind": "animal",
		"name": "Horse",
		"blurb": "Horse legs and head, no tail",
		"cost": 25,
		"parts": {"body": "jimmothy", "head": "jimmothy", "front_legs": "horse", "back_legs": "horse"},
		"color": 0,
		"hide": ["tail"],
	},
	{
		"id": "loin",
		"category": CAT_ANIMALS,
		"kind": "animal",
		"name": "Lion",
		"blurb": "All lion parts",
		"cost": 50,
		"parts": {"body": "jimmothy", "head": "lion", "front_legs": "lion", "back_legs": "lion", "tail": "lion"},
		"color": 0,
		"hide": [],
		"unlock_quest": "stock",
	},
	{
		"id": "gorllia",
		"category": CAT_ANIMALS,
		"kind": "animal",
		"name": "Gorllia",
		"blurb": "Gorilla with a sheep tail",
		"cost": 70,
		"parts": {"body": "jimmothy", "head": "gorilla", "front_legs": "turtle", "back_legs": "gorilla", "tail": "sheep"},
		"color": 0,
		"hide": [],
		"unlock_quest": "gates",
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
		"id": "path_delete",
		"category": CAT_PATHS,
		"kind": "delete_path",
		"name": "Delete path",
		"blurb": "Clear a walkway",
		"cost": 0,
	},
]


static func items_for(category: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for item in ITEMS:
		if str(item.get("category", "")) == category:
			found.append(item)
	if category == CAT_ANIMALS:
		for clone in SaveService.clones:
			if clone is Dictionary:
				found.append(clone)
	return found


static func get_item(item_id: String) -> Dictionary:
	for item in ITEMS:
		if str(item.get("id", "")) == item_id:
			return item
	for clone in SaveService.clones:
		if clone is Dictionary and str(clone.get("id", "")) == item_id:
			return clone
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
