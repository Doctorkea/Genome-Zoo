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
		"id": "splice",
		"title": "Tweak the DNA",
		"brief": "Open the DNA Lab and click a serum onto a body part.",
		"goal": "mutate",
		"reward_cash": 0,
		"reward_vial": "majestic",
		"reward_charges": 3,
	},
	{
		"id": "parade",
		"title": "A proper showpiece",
		"brief": "Turn one animal into a Showpiece — Majestic on the head, coat, and tail.",
		"goal": "committed",
		"tag": "Majestic",
		"amount": 3,
		"archetype": "Showpiece",
		"reward_cash": 10,
		"reward_vial": "scary",
		"reward_charges": 2,
	},
	{
		"id": "expand",
		"title": "Another enclosure",
		"brief": "Build a second pen and put an animal in it.",
		"goal": "pens",
		"amount": 2,
		"reward_cash": 0,
		"reward_perk": "open_longer",
	},
	{
		"id": "fright",
		"title": "Fill the new paddock",
		"brief": "Make a Scary animal — stack Scary until it is a Predator.",
		"goal": "committed",
		"tag": "Scary",
		"amount": 3,
		"archetype": "Predator",
		"reward_cash": 10,
		"reward_vial": "weird",
		"reward_charges": 2,
	},
	{
		"id": "odd",
		"title": "Something nobody's seen",
		"brief": "Make a Weird animal — stack Weird until it is a Novelty.",
		"goal": "committed",
		"tag": "Weird",
		"amount": 3,
		"archetype": "Novelty",
		"reward_cash": 10,
		"reward_vial": "silly",
		"reward_charges": 1,
	},
	{
		"id": "till",
		"title": "Keep the till ringing",
		"brief": "Earn $40 from guest tickets.",
		"goal": "tickets",
		"amount": 40,
		"reward_cash": 0,
		"reward_perk": "ticket_booth",
	},
	{
		"id": "grace",
		"title": "On their toes",
		"brief": "Stack Elegant until an animal is Nimble.",
		"goal": "committed",
		"tag": "Elegant",
		"amount": 2,
		"archetype": "Nimble",
		"reward_cash": 5,
		"reward_vial": "elegant",
		"reward_charges": 2,
	},
	{
		"id": "heft",
		"title": "Built like a tank",
		"brief": "Keep an animal Tanky with plenty of Bulky.",
		"goal": "committed",
		"tag": "Bulky",
		"amount": 3,
		"archetype": "Tanky",
		"reward_cash": 5,
		"reward_vial": "bulky",
		"reward_charges": 2,
	},
	{
		"id": "ick",
		"title": "A little icky",
		"brief": "Put Gross on a creature — tail or coat works.",
		"goal": "tag",
		"tag": "Gross",
		"amount": 1,
		"reward_cash": 5,
		"reward_vial": "gross",
		"reward_charges": 2,
	},
	{
		"id": "stay",
		"title": "Stay a while",
		"brief": "Keep three pens stocked at once.",
		"goal": "pens",
		"amount": 3,
		"reward_cash": 0,
		"reward_vial": "linger",
		"reward_charges": 1,
	},
	{
		"id": "fame",
		"title": "Face of the park",
		"brief": "Earn $80 from guest tickets.",
		"goal": "tickets",
		"amount": 80,
		"reward_cash": 0,
		"reward_vial": "poster",
		"reward_charges": 1,
	},
	{
		"id": "mix",
		"title": "Impossible animal",
		"brief": "Push Weird high enough that a Novelty looks chimeric.",
		"goal": "committed",
		"tag": "Weird",
		"amount": 4,
		"archetype": "Novelty",
		"reward_cash": 0,
		"reward_vial": "chimera",
		"reward_charges": 1,
	},
	{
		"id": "king",
		"title": "Apex of the chain",
		"brief": "A Predator stacked to Scary ×4.",
		"goal": "committed",
		"tag": "Scary",
		"amount": 4,
		"archetype": "Predator",
		"reward_cash": 0,
		"reward_vial": "apex",
		"reward_charges": 1,
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
		var charges: int = int(quest.get("reward_charges", 0))
		if charges > 0:
			bits.append("%s unlocked + %d charge" % [vial_name, charges])
		else:
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
		WalletService.add_cash(cash)
	var vial_id: String = str(quest.get("reward_vial", ""))
	if not vial_id.is_empty():
		GeneTree.unlock_vial(vial_id, int(quest.get("reward_charges", 0)))
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
		_:
			return false


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
