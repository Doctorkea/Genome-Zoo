extends Node

## Pure trait/tag data for the DNA Lab and visitor scoring.
##
## Shape option indices match PlaceholderArt / CreatureVisuals. Color index
## matches the palette list. See docs/GAME_DESIGN.md.

const SHAPE_SLOTS: Array[String] = [
	"body", "head", "eyes", "front_legs", "back_legs", "tail"
]
const COLOR_SLOT: String = "color"

const TAGS: Array[String] = [
	"Cute", "Elegant", "Majestic", "Weird", "Scary", "Bulky", "Gross", "Silly"
]

## Dominant-tag → skill archetype. Cute / Gross / Silly never win this
## lookup on their own — they only swing visitor scores.
const ARCHETYPE_BY_TAG: Dictionary = {
	"Elegant": "Nimble",
	"Bulky": "Tanky",
	"Scary": "Predator",
	"Weird": "Novelty",
	"Majestic": "Showpiece",
}

## Tie-break order when two archetype tags share the lead.
const ARCHETYPE_PRIORITY: Array[String] = [
	"Majestic", "Scary", "Elegant", "Weird", "Bulky"
]

const FAMILIES_LOVES: Array[String] = ["Cute", "Elegant", "Majestic"]
const FAMILIES_HATES: Array[String] = ["Scary", "Gross"]
const THRILL_LOVES: Array[String] = ["Scary", "Weird", "Majestic"]
const THRILL_HATES: Array[String] = ["Cute"]

## slot -> Array of {id, name, tags}
const OPTIONS: Dictionary = {
	"body": [
		{"id": "jimothy", "name": "Jimothy Body", "tags": ["Cute", "Bulky"]},
		{"id": "round", "name": "Round Body", "tags": ["Cute", "Bulky"]},
		{"id": "spiky", "name": "Spiky Body", "tags": ["Scary", "Majestic"]},
	],
	"head": [
		{"id": "jimothy", "name": "Jimothy Head", "tags": ["Cute"]},
		{"id": "horned", "name": "Horned Head", "tags": ["Scary", "Majestic"]},
		{"id": "bulbous", "name": "Bulbous Head", "tags": ["Weird", "Gross"]},
	],
	"eyes": [
		{"id": "big", "name": "Big Round Eyes", "tags": ["Cute", "Silly"]},
		{"id": "beady", "name": "Beady Eyes", "tags": ["Scary"]},
		{"id": "compound", "name": "Compound Eyes", "tags": ["Weird", "Gross"]},
	],
	"front_legs": [
		{"id": "jimothy", "name": "Jimothy Arm", "tags": ["Cute", "Bulky"]},
		{"id": "slender", "name": "Slender Front Legs", "tags": ["Elegant", "Silly"]},
		{"id": "many", "name": "Many Front Legs", "tags": ["Weird", "Gross"]},
	],
	"back_legs": [
		{"id": "jimothy", "name": "Jimothy Leg", "tags": ["Cute", "Bulky"]},
		{"id": "slender", "name": "Slender Back Legs", "tags": ["Elegant", "Silly"]},
		{"id": "many", "name": "Many Back Legs", "tags": ["Weird", "Gross"]},
	],
	"tail": [
		{"id": "short", "name": "Short Tail", "tags": ["Cute", "Bulky"]},
		{"id": "long", "name": "Long Tail", "tags": ["Elegant", "Weird"]},
		{"id": "forked", "name": "Forked Tail", "tags": ["Weird", "Gross"]},
	],
	"color": [
		{"id": "fur", "name": "Soft Fur", "tags": ["Cute"]},
		{"id": "scales", "name": "Iridescent Scales", "tags": ["Majestic", "Elegant"]},
		{"id": "slime", "name": "Oozing Slime", "tags": ["Gross", "Weird"]},
	],
}


func slot_display_name(slot: String) -> String:
	match slot:
		"front_legs":
			return "Front Legs"
		"back_legs":
			return "Back Legs"
		"color":
			return "Color"
		_:
			return slot.capitalize()


func get_option_count(slot: String) -> int:
	var list: Array = OPTIONS.get(slot, [])
	return list.size()


func get_option(slot: String, index: int) -> Dictionary:
	var list: Array = OPTIONS.get(slot, [])
	if list.is_empty():
		push_warning("TraitLibrary: unknown slot '%s'" % slot)
		return {}
	return list[index % list.size()]


func option_label(slot: String, index: int) -> String:
	var option := get_option(slot, index)
	if option.is_empty():
		return "#%d" % (index + 1)
	var tags: Array = option.get("tags", [])
	return "%s (%s)" % [option.get("name", "?"), ", ".join(tags)]


func score_visuals(visuals: CreatureVisuals) -> Dictionary:
	var indices: Dictionary = {}
	for slot in SHAPE_SLOTS:
		indices[slot] = visuals.get_current_index(slot)
	return score_loadout(indices, visuals.get_current_palette_index())


func score_loadout(slot_indices: Dictionary, color_index: int) -> Dictionary:
	var counts := _empty_counts()
	for slot in SHAPE_SLOTS:
		var index: int = int(slot_indices.get(slot, 0))
		_add_option_tags(counts, slot, index)
	_add_option_tags(counts, COLOR_SLOT, color_index)

	var families := _approval(counts, FAMILIES_LOVES, FAMILIES_HATES)
	var thrill := _approval(counts, THRILL_LOVES, THRILL_HATES)
	var archetype := _dominant_archetype(counts)

	return {
		"tags": counts,
		"archetype": archetype,
		"families": families,
		"thrill": thrill,
	}


func format_tags(counts: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for tag in TAGS:
		var n: int = int(counts.get(tag, 0))
		if n > 0:
			parts.append("%s %d" % [tag, n])
	if parts.is_empty():
		return "No tags"
	return ", ".join(parts)


func format_approval(families: int, thrill: int) -> String:
	return "Families %s  ·  Thrill-Seekers %s" % [_signed(families), _signed(thrill)]


func _empty_counts() -> Dictionary:
	var counts: Dictionary = {}
	for tag in TAGS:
		counts[tag] = 0
	return counts


func _add_option_tags(counts: Dictionary, slot: String, index: int) -> void:
	var option := get_option(slot, index)
	var tags: Array = option.get("tags", [])
	for tag in tags:
		counts[tag] = int(counts.get(tag, 0)) + 1


func _approval(counts: Dictionary, loves: Array[String], hates: Array[String]) -> int:
	var score := 0
	for tag in loves:
		score += int(counts.get(tag, 0))
	for tag in hates:
		score -= int(counts.get(tag, 0))
	return score


func _dominant_archetype(counts: Dictionary) -> String:
	var best_tag := ""
	var best_count := 0
	for tag in ARCHETYPE_PRIORITY:
		var n: int = int(counts.get(tag, 0))
		if n > best_count:
			best_count = n
			best_tag = tag
	if best_count <= 0:
		return "Unspecialized"
	return ARCHETYPE_BY_TAG.get(best_tag, "Unspecialized")


func _signed(value: int) -> String:
	if value > 0:
		return "+%d" % value
	return str(value)
