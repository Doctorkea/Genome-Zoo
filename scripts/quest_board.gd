extends Node

## One active park request at a time. Completing it pays cash and/or unlocks
## a serum. Autoloaded as "QuestBoard".

const QUESTS: Array[Dictionary] = [
	{
		"id": "fence",
		"title": "Fence it in",
		"brief": "Place a pen on the grass.",
		"goal": "place_pen",
		"reward_cash": 10,
	},
	{
		"id": "stock",
		"title": "Something to look at",
		"brief": "Put an animal in a pen.",
		"goal": "place_animal",
		"reward_cash": 10,
	},
	{
		"id": "gates",
		"title": "Open the gates",
		"brief": "Open the zoo so guests can arrive.",
		"goal": "zoo_open",
		"reward_cash": 10,
	},
	{
		"id": "splice",
		"title": "Tweak the DNA",
		"brief": "Open the DNA Lab and use Cute serum on a body part.",
		"goal": "mutate",
		"reward_cash": 0,
		"reward_vial": "majestic",
	},
	{
		"id": "parade",
		"title": "A proper showpiece",
		"brief": "Use Majestic serum until an animal is a Showpiece (Majestic ×3).",
		"goal": "committed",
		"tag": "Majestic",
		"amount": 3,
		"archetype": "Showpiece",
		"reward_cash": 10,
		"reward_vial": "scary",
	},
	{
		"id": "expand",
		"title": "Another enclosure",
		"brief": "Build a second pen and put an animal in it.",
		"goal": "pens",
		"amount": 2,
		"reward_cash": 0,
		"reward_perk": "open_longer",
		"reward_build": ["pen_large", "park_lamp"],
	},
	{
		"id": "fright",
		"title": "Fill the new paddock",
		"brief": "Use Scary serum until an animal is a Predator (Scary ×3).",
		"goal": "committed",
		"tag": "Scary",
		"amount": 3,
		"archetype": "Predator",
		"reward_cash": 10,
		"reward_vial": "weird",
		"reward_build": ["chimory"],
	},
	{
		"id": "odd",
		"title": "Something nobody's seen",
		"brief": "Use Weird serum until an animal is a Novelty (Weird ×3).",
		"goal": "committed",
		"tag": "Weird",
		"amount": 3,
		"archetype": "Novelty",
		"reward_cash": 10,
		"reward_vial": "bulky",
	},
	{
		"id": "till",
		"title": "Keep the till ringing",
		"brief": "Earn $40 from guest tickets.",
		"goal": "tickets",
		"amount": 40,
		"reward_cash": 0,
		"reward_perk": "ticket_booth",
		"reward_build": ["park_snack"],
	},
	{
		"id": "heft",
		"title": "Built like a tank",
		"brief": "Use Bulky serum until an animal is Tanky (Bulky ×3).",
		"goal": "committed",
		"tag": "Bulky",
		"amount": 3,
		"archetype": "Tanky",
		"reward_cash": 5,
		"reward_vial": "gross",
	},
	{
		"id": "ick",
		"title": "A little icky",
		"brief": "Use Gross serum on a tail or coat.",
		"goal": "tag",
		"tag": "Gross",
		"amount": 1,
		"reward_cash": 5,
	},
	{
		"id": "stay",
		"title": "Stay a while",
		"brief": "Keep three pens stocked at once.",
		"goal": "pens",
		"amount": 3,
		"reward_cash": 0,
		"reward_vial": "linger",
		"reward_build": ["pen_gallery"],
	},
	{
		"id": "fame",
		"title": "Face of the park",
		"brief": "Earn $80 from guest tickets.",
		"goal": "tickets",
		"amount": 80,
		"reward_cash": 0,
		"reward_vial": "poster",
		"reward_build": ["park_poster"],
	},
	{
		"id": "mix",
		"title": "Impossible animal",
		"brief": "Use Weird serum until a Novelty is Weird ×4.",
		"goal": "committed",
		"tag": "Weird",
		"amount": 4,
		"archetype": "Novelty",
		"reward_cash": 0,
		"reward_vial": "chimera",
	},
	{
		"id": "king",
		"title": "Apex of the chain",
		"brief": "Use Scary serum until a Predator is Scary ×4.",
		"goal": "committed",
		"tag": "Scary",
		"amount": 4,
		"archetype": "Predator",
		"reward_cash": 0,
		"reward_vial": "apex",
	},
	{
		"id": "draw",
		"title": "Word of mouth",
		"brief": "Keep three pens stocked so the crowds hear about you.",
		"goal": "pens",
		"amount": 3,
		"reward_cash": 0,
		"reward_perk": "crowd_pull",
	},
]

var index: int = 0
var mutated: bool = false
var ready_to_claim: bool = false


func _ready() -> void:
	Events.placement_succeeded.connect(_on_world_changed)
	Events.creature_mutated.connect(_on_mutated)
	Events.money_changed.connect(_on_money)
	Events.zoo_hours_changed.connect(_on_hours_changed)
	call_deferred("evaluate")


func reset() -> void:
	index = 0
	mutated = false
	ready_to_claim = false
	evaluate()
	Events.quest_changed.emit()


func snapshot() -> Dictionary:
	return {
		"index": index,
		"mutated": mutated,
		"ready_to_claim": ready_to_claim,
	}


func apply_state(data: Dictionary) -> void:
	index = int(data.get("index", 0))
	mutated = bool(data.get("mutated", false))
	ready_to_claim = bool(data.get("ready_to_claim", false))
	Events.quest_changed.emit()


func current() -> Dictionary:
	if index < 0 or index >= QUESTS.size():
		return {}
	return QUESTS[index]


func is_finished() -> bool:
	return index >= QUESTS.size()


func has_claimed(quest_id: String) -> bool:
	if quest_id.is_empty():
		return false
	for i in range(mini(index, QUESTS.size())):
		if str(QUESTS[i].get("id", "")) == quest_id:
			return true
	return false


func title_of(quest_id: String) -> String:
	for quest in QUESTS:
		if str(quest.get("id", "")) == quest_id:
			return str(quest.get("title", quest_id))
	return ""


func reward_text(quest: Dictionary = {}) -> String:
	if quest.is_empty():
		quest = current()
	if quest.is_empty():
		return ""
	var bits: PackedStringArray = PackedStringArray()
	var cash: int = int(quest.get("reward_cash", 0))
	if cash > 0:
		bits.append("$%d" % cash)
	var vial_id: String = str(quest.get("reward_vial", ""))
	if not vial_id.is_empty():
		var vial: Dictionary = GeneTree.get_vial(vial_id)
		var vial_name: String = str(vial.get("name", vial_id))
		bits.append("%s unlocked" % vial_name)
	var perk_id: String = str(quest.get("reward_perk", ""))
	if perk_id == GeneTree.PERK_OPEN_LONGER:
		bits.append("Open longer")
	elif perk_id == GeneTree.PERK_TICKET_BOOTH:
		bits.append("Ticket booth")
	elif perk_id == GeneTree.PERK_CROWD_PULL:
		bits.append("Crowd pull")
	elif not perk_id.is_empty():
		bits.append(perk_id.capitalize())
	for build_id in quest.get("reward_build", []):
		var item: Dictionary = BuildCatalog.get_item(str(build_id))
		var item_name: String = str(item.get("name", build_id))
		bits.append("%s unlocked" % item_name)
	if bits.is_empty():
		return "None"
	return "  ·  ".join(bits)


func progress_text() -> String:
	if is_finished():
		return "Board's clear."
	var quest := current()
	match str(quest.get("goal", "")):
		"place_pen":
			return "Pens: %d / 1" % _pen_count()
		"place_animal":
			return "Animals: %d / 1" % _animal_count()
		"mutate":
			return "Mutated" if mutated else "No mutation yet"
		"tag":
			var tag: String = str(quest.get("tag", ""))
			var need: int = int(quest.get("amount", 1))
			return "%s: %d / %d" % [tag, _best_tag(tag), need]
		"committed":
			return _committed_progress(quest)
		"pens":
			var need_pens: int = int(quest.get("amount", 2))
			return "Stocked pens: %d / %d" % [_stocked_pens(), need_pens]
		"tickets":
			var need_cash: int = int(quest.get("amount", 0))
			return "Tickets: $%d / $%d" % [WalletService.tickets_earned, need_cash]
		"zoo_open":
			return "Zoo open" if _zoo_is_open() else "Zoo still closed"
		_:
			return ""


func evaluate() -> void:
	var was_ready := ready_to_claim
	ready_to_claim = (not is_finished()) and _goal_met(current())
	if was_ready != ready_to_claim:
		Events.quest_changed.emit()


func claim() -> bool:
	if is_finished() or not ready_to_claim:
		return false
	var quest := current()
	var cash: int = int(quest.get("reward_cash", 0))
	if cash > 0:
		WalletService.add_cash(cash, false, "Quest reward")
	var vial_id: String = str(quest.get("reward_vial", ""))
	if not vial_id.is_empty():
		GeneTree.unlock_vial(vial_id)
	var perk_id: String = str(quest.get("reward_perk", ""))
	if not perk_id.is_empty():
		GeneTree.grant_zoo_perk(perk_id)
	index += 1
	ready_to_claim = false
	evaluate()
	Events.quest_changed.emit()
	return true


func _on_world_changed(_item_id: String = "") -> void:
	evaluate()


func _on_mutated(_animal: Node, _slot: String) -> void:
	mutated = true
	evaluate()


func _on_money(_amount: int) -> void:
	evaluate()


func _on_hours_changed(_is_open: bool) -> void:
	evaluate()


func _goal_met(quest: Dictionary) -> bool:
	if quest.is_empty():
		return false
	match str(quest.get("goal", "")):
		"place_pen":
			return _pen_count() >= 1
		"place_animal":
			return _animal_count() >= 1
		"mutate":
			return mutated
		"tag":
			return _best_tag(str(quest.get("tag", ""))) >= int(quest.get("amount", 1))
		"committed":
			return _has_committed(quest)
		"pens":
			return _stocked_pens() >= int(quest.get("amount", 2))
		"tickets":
			return WalletService.tickets_earned >= int(quest.get("amount", 0))
		"zoo_open":
			return _zoo_is_open()
		_:
			return false


func _zoo_is_open() -> bool:
	if get_tree() == null:
		return false
	var street := get_tree().get_first_node_in_group("street") as Street
	return street != null and street.is_open


func _pen_count() -> int:
	if get_tree() == null:
		return 0
	return get_tree().get_nodes_in_group("pens").size()


func _animal_count() -> int:
	if get_tree() == null:
		return 0
	return get_tree().get_nodes_in_group("animals").size()


func _stocked_pens() -> int:
	if get_tree() == null:
		return 0
	var n: int = 0
	for node in get_tree().get_nodes_in_group("pens"):
		var pen := node as Pen
		if pen != null and pen.occupant_count() > 0:
			n += 1
	return n


func _best_tag(tag: String) -> int:
	if tag.is_empty() or get_tree() == null:
		return 0
	var best: int = 0
	for node in get_tree().get_nodes_in_group("animals"):
		var animal := node as Animal
		if animal == null:
			continue
		var tags: Dictionary = animal.get_stats().get("tags", {})
		best = maxi(best, int(tags.get(tag, 0)))
	return best


func _committed_progress(quest: Dictionary) -> String:
	var tag: String = str(quest.get("tag", ""))
	var need: int = int(quest.get("amount", 1))
	var want_arch: String = str(quest.get("archetype", ""))
	var best_n: int = 0
	var best_arch := "—"
	for node in _animals():
		var stats: Dictionary = node.get_stats()
		var n: int = int(stats.get("tags", {}).get(tag, 0))
		var arch: String = str(stats.get("archetype", "Unspecialized"))
		if n > best_n or (n == best_n and arch == want_arch):
			best_n = n
			best_arch = arch
	return "%s ×%d / %d  ·  %s (need %s)" % [tag, best_n, need, best_arch, want_arch]


func _has_committed(quest: Dictionary) -> bool:
	var tag: String = str(quest.get("tag", ""))
	var need: int = int(quest.get("amount", 1))
	var want_arch: String = str(quest.get("archetype", ""))
	for node in _animals():
		var stats: Dictionary = node.get_stats()
		if int(stats.get("tags", {}).get(tag, 0)) < need:
			continue
		if str(stats.get("archetype", "")) == want_arch:
			return true
	return false


func _animals() -> Array[Animal]:
	var found: Array[Animal] = []
	if get_tree() == null:
		return found
	for node in get_tree().get_nodes_in_group("animals"):
		var animal := node as Animal
		if animal != null and is_instance_valid(animal):
			found.append(animal)
	return found
