extends Node

## Pure trait/tag data for the DNA Lab and visitor scoring.
##
## Shape option indices match PlaceholderArt / CreatureVisuals. Color index
## matches the palette list. See docs/GAME_DESIGN.md.

const SHAPE_SLOTS: Array[String] = [
	"body", "head", "front_legs", "back_legs", "tail"
]
## DNA Lab mutate slots. Body stays in SHAPE_SLOTS for scoring but is not
## player-swappable — every animal uses the shared Jimmothy torso.
const LAB_SLOTS: Array[String] = [
	"head", "front_legs", "back_legs", "tail"
]
const COLOR_SLOT: String = "color"

const TAGS: Array[String] = [
	"Cute", "Majestic", "Weird", "Scary", "Bulky", "Gross"
]

## Tag pairs that fight in one paddock. Planet Zoo treats incompatible mixes as a
## welfare hit, not a bonus; Zoo Tycoon guests also sour when predator/prey share.
const OPPOSING_TAGS: Array = [
	["Cute", "Scary"],
	["Cute", "Gross"],
	["Majestic", "Gross"],
	["Weird", "Scary"],
]

## Each part votes with exactly one look. Majority look is the overall type.
const ARCHETYPE_BY_TAG: Dictionary = {
	"Cute": "Cuddly",
	"Majestic": "Showpiece",
	"Weird": "Novelty",
	"Scary": "Predator",
	"Bulky": "Tanky",
	"Gross": "Foul",
}

## One visitor-facing job per look. Pairs that used to overlap are gone:
## Majestic covers pretty/grand, Weird covers odd/goofy.
const LOOK_BUFF: Dictionary = {
	"Cute": "Kids flock to it",
	"Majestic": "Tourists stop and stare",
	"Weird": "Creators and goths lean in",
	"Scary": "Thrill-seekers pay extra",
	"Bulky": "A steady crowd that does not spook",
	"Gross": "Goths love the ick",
}

## Tie-break when two looks share the lead. Cute yields so a Scary stack can still win.
const LOOK_PRIORITY: Array[String] = [
	"Majestic", "Scary", "Weird", "Bulky", "Gross", "Cute"
]

## Scary this high makes Children cry. Arrival gates (low/high zoo rating)
## and side effects (merchandise, hype) are data for later systems.
const CHILD_CRY_SCARY: int = 3

const VISITORS: Array[Dictionary] = [
	{
		"id": "children",
		"name": "Children",
		"loves": ["Cute"],
		"hates": ["Scary"],
		"arrives": "always",
		"effect": "cry",
	},
	{
		"id": "parents",
		"name": "Parents",
		"loves": [],
		"hates": [],
		"arrives": "always",
		"effect": "",
	},
	{
		"id": "tourists",
		"name": "Tourists",
		"loves": ["Majestic"],
		"hates": [],
		"arrives": "always",
		"effect": "merchandise",
	},
	{
		"id": "goths",
		"name": "Goths",
		"loves": ["Scary", "Gross", "Weird"],
		"hates": ["Cute"],
		"arrives": "low_rating",
		"effect": "",
	},
	{
		"id": "creators",
		"name": "Content Creators",
		"loves": ["Weird", "Majestic"],
		"hates": ["Gross"],
		"arrives": "always",
		"effect": "hype",
	},
	{
		"id": "thrill",
		"name": "Thrill-Seekers",
		"loves": ["Scary"],
		"hates": ["Cute"],
		"arrives": "always",
		"effect": "premium",
	},
	{
		"id": "scientists",
		"name": "Scientists",
		"loves": [],
		"hates": [],
		"arrives": "high_rating",
		"effect": "uniqueness",
	},
]

## slot -> Array of {id, name, tags}
const OPTIONS: Dictionary = {
	"body": [
		{"id": "jimmothy", "name": "Jimmothy Body", "tags": ["Cute"], "rarity": 0},
	],
	"head": [
		{"id": "gorilla", "name": "Gorilla Head", "tags": ["Scary"], "rarity": 2},
		{"id": "lizard", "name": "Lizard Head", "tags": ["Weird"], "rarity": 1},
		{"id": "jimmothy", "name": "Horse Head", "tags": ["Majestic"], "rarity": 1},
		{"id": "cockatoo", "name": "Cockatoo Head", "tags": ["Weird"], "rarity": 1},
		{"id": "turtle", "name": "Turtle Head", "tags": ["Bulky"], "rarity": 1},
		{"id": "frog", "name": "Frog Head", "tags": ["Weird"], "rarity": 1},
		{"id": "hamster", "name": "Hamster Head", "tags": ["Cute"], "rarity": 0},
		{"id": "duck", "name": "Duck Head", "tags": ["Cute"], "rarity": 0},
		{"id": "lion", "name": "Lion Head", "tags": ["Majestic"], "rarity": 2},
	],
	"front_legs": [
		{"id": "turtle", "name": "Turtle Arm", "tags": ["Cute"], "rarity": 0},
		{"id": "horse", "name": "Horse Arm", "tags": ["Majestic"], "rarity": 1},
		{"id": "lizard", "name": "Lizard Arm", "tags": ["Weird"], "rarity": 1},
		{"id": "lion", "name": "Lion Arm", "tags": ["Majestic"], "rarity": 1},
		{"id": "trex", "name": "T. rex Arm", "tags": ["Weird"], "rarity": 2},
		{"id": "chimory", "name": "Frog Arms", "tags": ["Weird"], "rarity": 2},
	],
	"back_legs": [
		{"id": "sheep", "name": "Sheep Leg", "tags": ["Cute"], "rarity": 0},
		{"id": "horse", "name": "Horse Leg", "tags": ["Majestic"], "rarity": 1},
		{"id": "jimmothy", "name": "Clawed Leg", "tags": ["Scary"], "rarity": 1},
		{"id": "bird", "name": "Bird Leg", "tags": ["Weird"], "rarity": 1},
		{"id": "elephant", "name": "Elephant Leg", "tags": ["Bulky"], "rarity": 1},
		{"id": "gorilla", "name": "Gorilla Leg", "tags": ["Bulky"], "rarity": 1},
		{"id": "lion", "name": "Lion Leg", "tags": ["Majestic"], "rarity": 1},
		{"id": "turtle", "name": "Turtle Leg", "tags": ["Bulky"], "rarity": 1},
	],
	"tail": [
		{"id": "pig", "name": "Pig Tail", "tags": ["Cute"], "rarity": 0},
		{"id": "sheep", "name": "Sheep Tail", "tags": ["Cute"], "rarity": 1},
		{"id": "tentacle", "name": "Tentacle Tail", "tags": ["Gross"], "rarity": 1},
		{"id": "fire", "name": "Fire Tail", "tags": ["Scary"], "rarity": 1},
		{"id": "lion", "name": "Lion Tail", "tags": ["Majestic"], "rarity": 1},
		{"id": "lizard", "name": "Lizard Tail", "tags": ["Weird"], "rarity": 1},
		{"id": "scorpion", "name": "Scorpion Tail", "tags": ["Scary"], "rarity": 2},
		{"id": "jimmothy", "name": "Curly Tail", "tags": ["Cute"], "rarity": 1},
	],
	"color": [
		{"id": "fur", "name": "Soft Fur", "tags": ["Cute"], "rarity": 0,
			"base": Color(0.62, 0.42, 0.24), "mark": Color(0.42, 0.26, 0.14),
			"pattern": 0, "pattern_scale": 4.5, "pattern_amount": 0.1},
		{"id": "scales", "name": "Fish Scales", "tags": ["Majestic"], "rarity": 1,
			"base": Color(0.22, 0.50, 0.48), "mark": Color(0.12, 0.28, 0.30),
			"pattern": 3, "pattern_scale": 6.8, "pattern_amount": 0.4},
		{"id": "slime", "name": "Toad Skin", "tags": ["Weird"], "rarity": 2,
			"base": Color(0.40, 0.48, 0.22), "mark": Color(0.22, 0.28, 0.10),
			"pattern": 4, "pattern_scale": 2.8, "pattern_amount": 0.38},
		{"id": "spots", "name": "Leopard Spots", "tags": ["Cute"], "rarity": 0,
			"base": Color(0.82, 0.62, 0.34), "mark": Color(0.28, 0.12, 0.04),
			"pattern": 9, "pattern_scale": 0.72, "pattern_amount": 0.88,
			"pattern_tex": "res://art/creatures/coats/leopard.png"},
		{"id": "stripes", "name": "Tiger Stripes", "tags": ["Scary"], "rarity": 1,
			"base": Color(0.84, 0.48, 0.16), "mark": Color(0.08, 0.05, 0.03),
			"pattern": 2, "pattern_scale": 3.6, "pattern_amount": 0.78},
		{"id": "hide", "name": "Elephant Hide", "tags": ["Bulky"], "rarity": 0,
			"base": Color(0.58, 0.52, 0.46), "mark": Color(0.38, 0.32, 0.28),
			"pattern": 5, "pattern_scale": 3.2, "pattern_amount": 0.22},
		{"id": "sleek", "name": "Seal Coat", "tags": ["Majestic"], "rarity": 1,
			"base": Color(0.52, 0.56, 0.60), "mark": Color(0.32, 0.34, 0.38),
			"pattern": 0, "pattern_scale": 5.0, "pattern_amount": 0.08},
		{"id": "patches", "name": "Cow Spots", "tags": ["Weird"], "rarity": 0,
			"base": Color(0.94, 0.92, 0.88), "mark": Color(0.08, 0.07, 0.06),
			"pattern": 9, "pattern_scale": 0.62, "pattern_amount": 0.92,
			"pattern_tex": "res://art/creatures/coats/cow.png"},
		{"id": "oil", "name": "Zebra Stripes", "tags": ["Majestic"], "rarity": 1,
			"base": Color(0.94, 0.93, 0.90), "mark": Color(0.08, 0.07, 0.06),
			"pattern": 9, "pattern_scale": 0.68, "pattern_amount": 0.94,
			"pattern_tex": "res://art/creatures/coats/zebra.png"},
		{"id": "bristles", "name": "Tabby Streaks", "tags": ["Cute"], "rarity": 1,
			"base": Color(0.62, 0.40, 0.20), "mark": Color(0.16, 0.10, 0.06),
			"pattern": 8, "pattern_scale": 3.8, "pattern_amount": 0.48},
		{"id": "mould", "name": "Toad Mottling", "tags": ["Gross"], "rarity": 1,
			"base": Color(0.40, 0.44, 0.20), "mark": Color(0.18, 0.22, 0.10),
			"pattern": 4, "pattern_scale": 2.2, "pattern_amount": 0.4},
		{"id": "giraffe", "name": "Giraffe Spots", "tags": ["Majestic"], "rarity": 1,
			"base": Color(0.86, 0.64, 0.28), "mark": Color(0.36, 0.16, 0.06),
			"pattern": 9, "pattern_scale": 0.58, "pattern_amount": 0.9,
			"pattern_tex": "res://art/creatures/coats/giraffe.png"},
		{"id": "starry", "name": "Starry Night", "tags": ["Weird"], "rarity": 1,
			"base": Color(0.08, 0.09, 0.16), "mark": Color(0.92, 0.94, 1.0),
			"pattern": 10, "pattern_scale": 0.85, "pattern_amount": 0.95,
			"pattern_tex": "res://art/creatures/coats/stars.png"},
	],
}

var _pattern_tex_cache: Dictionary = {} # path -> Texture2D with mipmaps


## Flat placeholder colours so a circle on the grass reads as a visitor type.
func visitor_spec(visitor_id: String) -> Dictionary:
	if visitor_id == "camera":
		return {
			"id": "camera",
			"name": "Camera operator",
			"loves": [],
			"hates": [],
		}
	for spec in VISITORS:
		if str(spec.get("id", "")) == visitor_id:
			return spec
	return {}


func visitor_display_name(visitor_id: String) -> String:
	var spec := visitor_spec(visitor_id)
	if spec.is_empty():
		return visitor_id.capitalize()
	return str(spec.get("name", visitor_id.capitalize()))


func visitor_approval(visitor_id: String, counts: Dictionary) -> int:
	return int(_score_visitors(counts).get(visitor_id, 0))


## Families and kids are common, so Cute pays least. Scarce guests and
## harder looks (Scary / Predator) pay more when they actually see a match.
func sight_bonus(visitor_id: String, tags: Dictionary, is_family: bool = false) -> int:
	if (is_family or visitor_id == "children") and int(tags.get("Scary", 0)) >= CHILD_CRY_SCARY:
		return 0
	var best_tag: String = ""
	var best_score: float = 0.0
	for tag in loved_tags_for(visitor_id, is_family):
		var n: int = int(tags.get(tag, 0))
		if n <= 0:
			continue
		var score: float = sight_tag_weight(tag) * (1.0 + 0.06 * float(n - 1))
		if score > best_score:
			best_score = score
			best_tag = tag
	if best_tag.is_empty():
		return 0
	var cash: int = maxi(1, int(round(sight_guest_weight(visitor_id, is_family) * sight_tag_weight(best_tag))))
	if best_tag != "Cute" and int(tags.get(best_tag, 0)) >= 3:
		cash += 1
	return cash


func loved_tags_for(visitor_id: String, is_family: bool = false) -> PackedStringArray:
	var loves := PackedStringArray()
	var spec: Dictionary = visitor_spec(visitor_id)
	for tag in spec.get("loves", []):
		var word: String = str(tag)
		if not loves.has(word):
			loves.append(word)
	if is_family or visitor_id == "children":
		if not loves.has("Cute"):
			loves.append("Cute")
	return loves


func hated_tags_for(visitor_id: String, is_family: bool = false) -> PackedStringArray:
	var hates := PackedStringArray()
	var spec: Dictionary = visitor_spec(visitor_id)
	for tag in spec.get("hates", []):
		var word: String = str(tag)
		if not hates.has(word):
			hates.append(word)
	if is_family or visitor_id == "children":
		if not hates.has("Scary"):
			hates.append("Scary")
	return hates


func sight_guest_weight(visitor_id: String, is_family: bool = false) -> float:
	if is_family:
		return 1.0
	match visitor_id:
		"children":
			return 1.0
		"parents":
			return 1.15
		"tourists":
			return 1.55
		"thrill":
			return 2.35
		"creators":
			return 2.75
		"camera":
			return 1.0
		"goths":
			return 3.15
		"scientists":
			return 3.5
		_:
			return 1.4


func sight_tag_weight(tag: String) -> float:
	match tag:
		"Cute":
			return 1.0
		"Bulky":
			return 1.3
		"Majestic":
			return 1.45
		"Weird":
			return 1.5
		"Gross":
			return 1.65
		"Scary":
			return 1.85
		_:
			return 1.0


func visitor_color(visitor_id: String) -> Color:
	match visitor_id:
		"children":
			return Color(1.0, 0.82, 0.18)
		"parents":
			return Color(0.28, 0.52, 0.86)
		"tourists":
			return Color(0.95, 0.45, 0.25)
		"goths":
			return Color(0.28, 0.18, 0.38)
		"creators":
			return Color(0.85, 0.30, 0.65)
		"camera":
			return Color(0.55, 0.58, 0.62)
		"thrill":
			return Color(0.85, 0.15, 0.16)
		"scientists":
			return Color(0.30, 0.75, 0.45)
		_:
			return Color(0.72, 0.72, 0.72)


func visitor_sprite_paths(visitor_id: String) -> PackedStringArray:
	match visitor_id:
		"children":
			return PackedStringArray([
				"res://art/visitors/child_boy.png",
				"res://art/visitors/child_girl.png",
			])
		"parents":
			return PackedStringArray([
				"res://art/visitors/parent_mum.png",
				"res://art/visitors/parent_dad.png",
			])
		"goths":
			return PackedStringArray([
				"res://art/visitors/goth_girl.png",
				"res://art/visitors/goth_guy.png",
			])
		"tourists":
			return PackedStringArray([
				"res://art/visitors/tourist_girl.png",
				"res://art/visitors/tourist_guy.png",
			])
		"creators":
			return PackedStringArray([
				"res://art/visitors/creator_girl.png",
				"res://art/visitors/creator_guy.png",
			])
		"thrill":
			return PackedStringArray([
				"res://art/visitors/thrill_girl.png",
				"res://art/visitors/thrill_guy.png",
			])
		"camera":
			return PackedStringArray([
				"res://art/visitors/camera_man.png",
			])
		_:
			return PackedStringArray(["res://art/visitors/patron.png"])


func arrival_is_family() -> bool:
	return randf() < 0.50


func random_visitor_id() -> String:
	if arrival_is_family():
		return "parents" if randf() < 0.5 else "children"
	return random_solo_id()


func zoo_tag_totals() -> Dictionary:
	var counts := _empty_counts()
	if get_tree() == null:
		return counts
	for node in get_tree().get_nodes_in_group("animals"):
		var animal := node as Animal
		if animal == null or not is_instance_valid(animal):
			continue
		var tags: Dictionary = animal.get_stats().get("tags", {})
		for tag in TAGS:
			counts[tag] = int(counts.get(tag, 0)) + int(tags.get(tag, 0))
	return counts


func park_uniqueness() -> int:
	var counts := zoo_tag_totals()
	var kinds: int = 0
	for tag in TAGS:
		if int(counts.get(tag, 0)) > 0:
			kinds += 1
	return kinds - 3


func park_rating() -> int:
	var counts := zoo_tag_totals()
	return int(counts.get("Cute", 0)) + int(counts.get("Majestic", 0)) \
		- int(counts.get("Scary", 0)) - int(counts.get("Gross", 0))


func random_solo_id(allow_creator: bool = true) -> String:
	var weights: Dictionary = {
		"tourists": 62,
		"thrill": 20,
		"goths": 6,
	}
	if allow_creator:
		weights["creators"] = 10
	var totals := zoo_tag_totals()
	var dark: int = int(totals.get("Scary", 0)) + int(totals.get("Gross", 0))
	if dark >= 4 or park_rating() < 0:
		weights["goths"] = 12
	if park_uniqueness() >= 2:
		weights["scientists"] = 6
	return _pick_weighted(weights)


func _pick_weighted(weights: Dictionary) -> String:
	var total: int = 0
	for key in weights.keys():
		total += int(weights[key])
	if total <= 0:
		return "tourists"
	var roll: int = randi() % total
	var acc: int = 0
	for key in weights.keys():
		acc += int(weights[key])
		if roll < acc:
			return str(key)
	return "tourists"


func family_member_kinds() -> PackedStringArray:
	var kinds := PackedStringArray()
	kinds.append("parents")
	if randf() < 0.72:
		kinds.append("parents")
	kinds.append("children")
	if randf() < 0.58:
		kinds.append("children")
	return kinds


func slot_display_name(slot: String) -> String:
	match slot:
		"body":
			return "Torso"
		"front_legs":
			return "Front Legs"
		"back_legs":
			return "Back Legs"
		"color":
			return "Coat"
		_:
			return slot.capitalize()


## Picks a different option index for `slot` than `current_index`.
## Returns `current_index` only when the slot has fewer than two options.
func pick_other_index(slot: String, current_index: int) -> int:
	var count := get_option_count(slot)
	if count <= 1:
		return current_index
	var wrapped := current_index % count
	var roll: int = randi() % (count - 1)
	if roll >= wrapped:
		roll += 1
	return roll


func option_rarity(slot: String, index: int) -> int:
	return int(get_option(slot, index).get("rarity", 0))


func option_has_tag(slot: String, index: int, tag: String) -> bool:
	return option_look(slot, index) == tag


## The single look this part votes with. Empty when the option is missing.
func option_look(slot: String, index: int) -> String:
	var tags: Array = get_option(slot, index).get("tags", [])
	if tags.is_empty():
		return ""
	return str(tags[0])


func look_buff(tag: String) -> String:
	return str(LOOK_BUFF.get(tag, ""))


func overall_for_look(tag: String) -> String:
	return str(ARCHETYPE_BY_TAG.get(tag, "Unspecialized"))


func option_index_for_id(slot: String, option_id: String) -> int:
	var list: Array = OPTIONS.get(slot, [])
	for i in range(list.size()):
		if str(list[i].get("id", "")) == option_id:
			return i
	return -1


func indices_with_tag(slot: String, tag: String, rarity_min: int = 0) -> Array[int]:
	var found: Array[int] = []
	var count := get_option_count(slot)
	for i in range(count):
		if option_rarity(slot, i) < rarity_min:
			continue
		if option_has_tag(slot, i, tag):
			found.append(i)
	return found


## Different option that carries `tag` and meets `rarity_min`. Returns
## `current_index` when the slot has no other matching form.
func pick_other_with_tag(slot: String, current_index: int, tag: String, rarity_min: int = 0) -> int:
	var matches := indices_with_tag(slot, tag, rarity_min)
	var others: Array[int] = []
	for index in matches:
		if index != current_index:
			others.append(index)
	if others.is_empty():
		return current_index
	if not option_has_tag(slot, current_index, tag):
		return others[randi() % others.size()]
	return others[randi() % others.size()]


func pick_other_from_ids(slot: String, current_index: int, option_ids: Array) -> int:
	var others: Array[int] = []
	for option_id in option_ids:
		var index := option_index_for_id(slot, str(option_id))
		if index >= 0 and index != current_index:
			others.append(index)
	if others.is_empty():
		return current_index
	return others[randi() % others.size()]


func vial_can_apply(vial: Dictionary, slot: String, current_index: int) -> bool:
	var kind: String = str(vial.get("kind", ""))
	if kind == GeneTree.VIAL_KIND_PERK:
		return true
	if slot.is_empty():
		return false
	if kind == GeneTree.VIAL_KIND_EXOTIC:
		for option_id in vial.get("pool", []):
			var index := option_index_for_id(slot, str(option_id))
			if index >= 0 and index != current_index:
				return true
		return false
	var tag: String = str(vial.get("tag", ""))
	if tag.is_empty():
		return false
	for index in indices_with_tag(slot, tag, int(vial.get("rarity_min", 0))):
		if index != current_index:
			return true
	return false


func get_option_count(slot: String) -> int:
	var list: Array = OPTIONS.get(slot, [])
	return list.size()


func get_option(slot: String, index: int) -> Dictionary:
	var list: Array = OPTIONS.get(slot, [])
	if list.is_empty():
		push_warning("TraitLibrary: unknown slot '%s'" % slot)
		return {}
	return list[index % list.size()]


func coat_base_color(option: Dictionary) -> Color:
	return _as_color(option.get("base", Color(0.55, 0.36, 0.20)))


func coat_mark_color(option: Dictionary) -> Color:
	return _as_color(option.get("mark", Color(0.35, 0.22, 0.12)))


func coat_pattern_texture(option: Dictionary) -> Texture2D:
	var path: String = str(option.get("pattern_tex", ""))
	if path.is_empty():
		return null
	if _pattern_tex_cache.has(path):
		return _pattern_tex_cache[path]
	var loaded := load(path) as Texture2D
	if loaded == null:
		return null
	var img := loaded.get_image()
	if img == null:
		_pattern_tex_cache[path] = loaded
		return loaded
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	var mip_err := img.generate_mipmaps()
	if mip_err != OK:
		push_warning("TraitLibrary: could not build mipmaps for %s" % path)
	var tex := ImageTexture.create_from_image(img)
	_pattern_tex_cache[path] = tex
	return tex


func _as_color(value: Variant) -> Color:
	if value is Color:
		return value
	if value is Vector3:
		var v: Vector3 = value
		return Color(v.x, v.y, v.z)
	return Color(0.55, 0.36, 0.20)


func option_label(slot: String, index: int) -> String:
	var option := get_option(slot, index)
	if option.is_empty():
		return "#%d" % (index + 1)
	var tags: Array = option.get("tags", [])
	return "%s (%s)" % [option.get("name", "?"), ", ".join(tags)]


func score_visuals(visuals: CreatureVisuals) -> Dictionary:
	var indices: Dictionary = {}
	for slot in SHAPE_SLOTS:
		if not visuals.is_slot_visible(slot):
			continue
		indices[slot] = visuals.get_current_index(slot)
	return score_loadout(indices, visuals.get_current_palette_index())


func score_loadout(slot_indices: Dictionary, color_index: int) -> Dictionary:
	var counts := _empty_counts()
	for slot in SHAPE_SLOTS:
		if not slot_indices.has(slot):
			continue
		var index: int = int(slot_indices.get(slot, 0))
		_add_option_tags(counts, slot, index)
	_add_option_tags(counts, COLOR_SLOT, color_index)

	var archetype := _dominant_archetype(counts)
	return {
		"tags": counts,
		"archetype": archetype,
		"visitors": _score_visitors(counts),
	}


func format_tags(counts: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for tag in TAGS:
		var n: int = int(counts.get(tag, 0))
		if n > 0:
			parts.append("%s ×%d" % [tag, n])
	if parts.is_empty():
		return "No traits yet"
	return "  ".join(parts)


func tag_distance(a: Dictionary, b: Dictionary) -> float:
	var dist: float = 0.0
	for tag in TAGS:
		dist += absf(float(a.get(tag, 0)) - float(b.get(tag, 0)))
	return dist


## 0 = same look, 1 = a fighting mix. Distance is soft; opposing tags (cute vs
## gross/scary) weigh more, matching Planet Zoo's compatible-mix bonus vs clash.
func tag_clash(a: Dictionary, b: Dictionary) -> float:
	var dist: float = clampf(tag_distance(a, b) / 10.0, 0.0, 1.0)
	var oppose: float = 0.0
	for pair in OPPOSING_TAGS:
		var left: String = str(pair[0])
		var right: String = str(pair[1])
		oppose += minf(float(a.get(left, 0)), float(b.get(right, 0)))
		oppose += minf(float(a.get(right, 0)), float(b.get(left, 0)))
	var oppose_n: float = clampf(oppose / 10.0, 0.0, 1.0)
	return clampf(dist * 0.65 + oppose_n * 0.35, 0.0, 1.0)


## Every visitor type, in roster order, with a reason even when they shrug.
func audience_notes(counts: Dictionary) -> Array[Dictionary]:
	var notes: Array[Dictionary] = []
	var scores: Dictionary = _score_visitors(counts)
	for spec in VISITORS:
		var id: String = str(spec.get("id", ""))
		var score: int = int(scores.get(id, 0))
		notes.append({
			"id": id,
			"name": str(spec.get("name", id)),
			"score": score,
			"reason": _visitor_reason(spec, counts, score),
		})
	return notes


## Groups visitors who actually have an opinion, with a short reason
## built from the tags they love or hate. Neutrals are omitted.
func crowd_notes(counts: Dictionary) -> Dictionary:
	var likes: Array[Dictionary] = []
	var dislikes: Array[Dictionary] = []
	for note in audience_notes(counts):
		var score: int = int(note.get("score", 0))
		if score > 0:
			likes.append(note)
		elif score < 0:
			dislikes.append(note)
	return {"likes": likes, "dislikes": dislikes}


## Highest-count look. Ties pick the stronger overall look.
func prominent_look(counts: Dictionary) -> Dictionary:
	var best_name := ""
	var best_amount := 0
	for tag in TAGS:
		var amount: int = int(counts.get(tag, 0))
		if amount <= 0:
			continue
		if amount > best_amount or (amount == best_amount and _look_outranks(tag, best_name)):
			best_name = tag
			best_amount = amount
	if best_name.is_empty():
		return {}
	return {"name": best_name, "amount": best_amount}


## Looks the creature actually has, in tag-list order.
func present_looks(counts: Dictionary) -> Array[Dictionary]:
	var looks: Array[Dictionary] = []
	for tag in TAGS:
		var amount: int = int(counts.get(tag, 0))
		if amount > 0:
			looks.append({"name": tag, "amount": amount})
	return looks


func format_approval(visitors: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for spec in VISITORS:
		var id: String = str(spec.get("id", ""))
		var score: int = int(visitors.get(id, 0))
		if score == 0:
			continue
		parts.append("%s %s" % [spec.get("name", id), _signed(score)])
	if parts.is_empty():
		return "No strong opinions yet"
	return ", ".join(parts)


func _score_visitors(counts: Dictionary) -> Dictionary:
	var scores: Dictionary = {}
	for spec in VISITORS:
		var id: String = str(spec.get("id", ""))
		if id == "scientists":
			scores[id] = _uniqueness_score(counts)
		elif id == "parents":
			scores[id] = 0
		else:
			var loves: Array = spec.get("loves", [])
			var hates: Array = spec.get("hates", [])
			scores[id] = _approval(counts, loves, hates)
	return scores


func _uniqueness_score(counts: Dictionary) -> int:
	var kinds := 0
	for tag in TAGS:
		if int(counts.get(tag, 0)) > 0:
			kinds += 1
	return kinds - 3


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


func _visitor_reason(spec: Dictionary, counts: Dictionary, score: int) -> String:
	var id: String = str(spec.get("id", ""))
	if id == "parents":
		return "along for the ride"
	if id == "scientists":
		if score > 0:
			return "the mix of traits"
		if score < 0:
			return "too ordinary"
		return "nothing unusual yet"
	var loved := _present_tags(counts, spec.get("loves", []))
	var hated := _present_tags(counts, spec.get("hates", []))
	if score > 0:
		if not loved.is_empty() and not hated.is_empty():
			return "%s, despite the %s" % [loved, hated]
		return loved if not loved.is_empty() else "what it is"
	if score < 0:
		if not hated.is_empty() and not loved.is_empty():
			return "%s outweighs the %s" % [hated, loved]
		if not hated.is_empty():
			return "too %s" % hated
		return "not their thing"
	var wants := _join_and(_tag_words(spec.get("loves", [])))
	if wants.is_empty():
		return "no strong opinion"
	return "waiting for %s" % wants


func _present_tags(counts: Dictionary, wanted: Array) -> String:
	var hits: PackedStringArray = PackedStringArray()
	for tag in wanted:
		if int(counts.get(tag, 0)) > 0:
			hits.append(str(tag).to_lower())
	return _join_and(hits)


func _tag_words(wanted: Array) -> PackedStringArray:
	var words: PackedStringArray = PackedStringArray()
	for tag in wanted:
		words.append(str(tag).to_lower())
	return words


func _join_and(words: PackedStringArray) -> String:
	if words.is_empty():
		return ""
	if words.size() == 1:
		return words[0]
	if words.size() == 2:
		return "%s and %s" % [words[0], words[1]]
	var head := PackedStringArray()
	for i in range(words.size() - 1):
		head.append(words[i])
	return "%s, and %s" % [", ".join(head), words[words.size() - 1]]


func _stronger_opinion(a: Dictionary, b: Dictionary) -> bool:
	return absi(int(a.get("score", 0))) > absi(int(b.get("score", 0)))


func _approval(counts: Dictionary, loves: Array, hates: Array) -> int:
	var score := 0
	for tag in loves:
		score += int(counts.get(tag, 0))
	for tag in hates:
		score -= int(counts.get(tag, 0))
	return score


func _dominant_archetype(counts: Dictionary) -> String:
	var lead := prominent_look(counts)
	if lead.is_empty():
		return "Unspecialized"
	return overall_for_look(str(lead.get("name", "")))


func _look_outranks(tag: String, other: String) -> bool:
	if other.is_empty():
		return true
	var a: int = LOOK_PRIORITY.find(tag)
	var b: int = LOOK_PRIORITY.find(other)
	if a < 0:
		a = LOOK_PRIORITY.size()
	if b < 0:
		b = LOOK_PRIORITY.size()
	if a != b:
		return a < b
	return tag < other


func _signed(value: int) -> String:
	if value > 0:
		return "+%d" % value
	return str(value)
