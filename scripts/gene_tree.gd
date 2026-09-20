extends Node

## Vial catalog, shop stock, and zoo perk flags. Autoloaded as "GeneTree".
## New serums unlock from quests, then charges are bought with cash.

const VIAL_KIND_TAG := "tag"
const VIAL_KIND_EXOTIC := "exotic"
const VIAL_KIND_PERK := "perk"

const PERK_LINGER := "linger"
const PERK_POSTER := "poster_child"
const PERK_TICKET_BOOTH := "ticket_booth"
const PERK_CROWD_PULL := "crowd_pull"
const PERK_MORE_PARKING := "more_parking"
const PERK_MORE_ADS := "more_ads"

const VIALS: Array[Dictionary] = [
	{
		"id": "cute",
		"name": "Cute serum",
		"kind": VIAL_KIND_TAG,
		"shop_cost": 25,
		"tag": "Cute",
		"rarity_min": 0,
		"hint": "Soft and round. Kids flock to it.",
	},
	{
		"id": "majestic",
		"name": "Majestic serum",
		"kind": VIAL_KIND_TAG,
		"shop_cost": 35,
		"tag": "Majestic",
		"rarity_min": 0,
		"hint": "Horse, lion, zebra. Tourists stop and stare.",
	},
	{
		"id": "weird",
		"name": "Weird serum",
		"kind": VIAL_KIND_TAG,
		"shop_cost": 35,
		"tag": "Weird",
		"rarity_min": 0,
		"hint": "Lizards, frogs, tiny T. rex arms. Odd, not pretty.",
	},
	{
		"id": "scary",
		"name": "Scary serum",
		"kind": VIAL_KIND_TAG,
		"shop_cost": 35,
		"tag": "Scary",
		"rarity_min": 0,
		"hint": "Gorilla, claws, fire. Thrill-seekers pay extra.",
	},
	{
		"id": "bulky",
		"name": "Bulky serum",
		"kind": VIAL_KIND_TAG,
		"shop_cost": 40,
		"tag": "Bulky",
		"rarity_min": 0,
		"hint": "Turtle, elephant, hide. A crowd that does not spook.",
	},
	{
		"id": "gross",
		"name": "Gross serum",
		"kind": VIAL_KIND_TAG,
		"shop_cost": 40,
		"tag": "Gross",
		"rarity_min": 0,
		"hint": "Tentacles and toad spots. Goths love the ick.",
	},
	{
		"id": "apex",
		"name": "Apex serum",
		"kind": VIAL_KIND_EXOTIC,
		"shop_cost": 120,
		"tag": "Scary",
		"rarity_min": 2,
		"pool": ["lion", "trex", "fire", "scorpion"],
	},
	{
		"id": "chimera",
		"name": "Chimera serum",
		"kind": VIAL_KIND_EXOTIC,
		"shop_cost": 120,
		"tag": "Weird",
		"rarity_min": 2,
		"pool": ["gorilla", "frog", "tentacle", "lizard", "slime"],
	},
	{
		"id": "linger",
		"name": "Linger",
		"kind": VIAL_KIND_PERK,
		"shop_cost": 60,
		"perk_id": PERK_LINGER,
		"hint": "Guests stay longer at this exhibit and lose interest more slowly.",
	},
	{
		"id": "poster",
		"name": "Poster child",
		"kind": VIAL_KIND_PERK,
		"shop_cost": 70,
		"perk_id": PERK_POSTER,
		"hint": "Guests who see this animal pay 25% more on their ticket.",
	},
]

var unlocked: Dictionary = {} # vial id -> true
var stock: Dictionary = {} # vial id -> int
var zoo_perks: PackedStringArray = PackedStringArray()


func _ready() -> void:
	reset()


func reset() -> void:
	unlocked.clear()
	stock.clear()
	zoo_perks = PackedStringArray()
	unlock_vial("cute", 1)


func get_vial(vial_id: String) -> Dictionary:
	for vial in VIALS:
		if str(vial.get("id", "")) == vial_id:
			return vial
	return {}


func stock_of(vial_id: String) -> int:
	return int(stock.get(vial_id, 0))


func is_vial_unlocked(vial_id: String) -> bool:
	return bool(unlocked.get(vial_id, false))


func is_usable_vial(vial_id: String) -> bool:
	return is_vial_unlocked(vial_id) and stock_of(vial_id) > 0


func unlocked_shop_vials() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for vial in VIALS:
		if is_vial_unlocked(str(vial.get("id", ""))):
			found.append(vial)
	return found


func can_buy_vial(vial_id: String) -> bool:
	if not is_vial_unlocked(vial_id):
		return false
	var vial := get_vial(vial_id)
	if vial.is_empty():
		return false
	return WalletService.can_afford(int(vial.get("shop_cost", 0)))


func unlock_vial(vial_id: String, charges: int = 0) -> void:
	if get_vial(vial_id).is_empty():
		return
	unlocked[vial_id] = true
	if charges > 0:
		add_stock(vial_id, charges)
	else:
		Events.vials_changed.emit(stock.duplicate())


func grant_zoo_perk(perk_id: String) -> void:
	if perk_id.is_empty() or zoo_perks.has(perk_id):
		return
	zoo_perks.append(perk_id)


func buy_vial(vial_id: String) -> bool:
	if not is_vial_unlocked(vial_id):
		return false
	var vial := get_vial(vial_id)
	if vial.is_empty():
		return false
	if not WalletService.spend(int(vial.get("shop_cost", 0)), str(vial.get("name", "serum"))):
		return false
	add_stock(vial_id, 1)
	return true


func consume_vial(vial_id: String) -> bool:
	if stock_of(vial_id) <= 0:
		return false
	stock[vial_id] = stock_of(vial_id) - 1
	Events.vials_changed.emit(stock.duplicate())
	return true


func add_stock(vial_id: String, amount: int = 1) -> void:
	stock[vial_id] = stock_of(vial_id) + amount
	Events.vials_changed.emit(stock.duplicate())


func has_zoo_perk(perk_id: String) -> bool:
	return zoo_perks.has(perk_id)


func ticket_multiplier() -> float:
	return 1.15 if has_zoo_perk(PERK_TICKET_BOOTH) else 1.0


func poster_multiplier() -> float:
	return 1.25


func visitor_cap() -> int:
	var cap: int = 16
	if has_zoo_perk(PERK_MORE_PARKING):
		cap += 8
	return cap


func spawn_time_scale() -> float:
	var scale: float = 1.0
	if has_zoo_perk(PERK_CROWD_PULL):
		scale *= 0.7
	if has_zoo_perk(PERK_MORE_ADS):
		scale *= 0.62
	return scale


func snapshot() -> Dictionary:
	return {
		"unlocked": unlocked.keys(),
		"stock": stock.duplicate(),
		"zoo_perks": Array(zoo_perks),
	}


func apply_state(data: Dictionary) -> void:
	unlocked.clear()
	stock.clear()
	zoo_perks = PackedStringArray()
	for vial_id in data.get("unlocked", []):
		unlocked[str(vial_id)] = true
	var stored: Dictionary = data.get("stock", {})
	for vial_id in stored:
		stock[str(vial_id)] = int(stored[vial_id])
	for perk_id in data.get("zoo_perks", []):
		var perk := str(perk_id)
		if not perk.is_empty() and not zoo_perks.has(perk):
			zoo_perks.append(perk)
	if unlocked.is_empty():
		unlock_vial("cute", 1)
	else:
		Events.vials_changed.emit(stock.duplicate())
