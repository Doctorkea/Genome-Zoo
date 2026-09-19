extends Node

## Vial catalog, shop stock, and zoo perk flags. Autoloaded as "GeneTree".
## New serums unlock from quests, then charges are bought with cash.

const VIAL_KIND_TAG := "tag"
const VIAL_KIND_EXOTIC := "exotic"
const VIAL_KIND_PERK := "perk"

const PERK_LINGER := "linger"
const PERK_POSTER := "poster_child"
const PERK_OPEN_LONGER := "open_longer"
const PERK_TICKET_BOOTH := "ticket_booth"
const PERK_CROWD_PULL := "crowd_pull"

const VIALS: Array[Dictionary] = [
	{
		"id": "cute",
		"name": "Cute serum",
		"kind": VIAL_KIND_TAG,
		"shop_cost": 15,
		"tag": "Cute",
		"rarity_min": 0,
	},
	{
		"id": "silly",
		"name": "Silly serum",
		"kind": VIAL_KIND_TAG,
		"shop_cost": 25,
		"tag": "Silly",
		"rarity_min": 0,
	},
	{
		"id": "scary",
		"name": "Scary serum",
		"kind": VIAL_KIND_TAG,
		"shop_cost": 20,
		"tag": "Scary",
		"rarity_min": 0,
	},
	{
		"id": "gross",
		"name": "Gross serum",
		"kind": VIAL_KIND_TAG,
		"shop_cost": 25,
		"tag": "Gross",
		"rarity_min": 0,
	},
	{
		"id": "majestic",
		"name": "Majestic serum",
		"kind": VIAL_KIND_TAG,
		"shop_cost": 20,
		"tag": "Majestic",
		"rarity_min": 0,
	},
	{
		"id": "elegant",
		"name": "Elegant serum",
		"kind": VIAL_KIND_TAG,
		"shop_cost": 25,
		"tag": "Elegant",
		"rarity_min": 0,
	},
	{
		"id": "weird",
		"name": "Weird serum",
		"kind": VIAL_KIND_TAG,
		"shop_cost": 20,
		"tag": "Weird",
		"rarity_min": 0,
	},
	{
		"id": "bulky",
		"name": "Bulky serum",
		"kind": VIAL_KIND_TAG,
		"shop_cost": 25,
		"tag": "Bulky",
		"rarity_min": 0,
	},
	{
		"id": "apex",
		"name": "Apex serum",
		"kind": VIAL_KIND_EXOTIC,
		"shop_cost": 90,
		"tag": "Scary",
		"rarity_min": 2,
		"pool": ["lion", "trex", "fire", "scorpion"],
	},
	{
		"id": "chimera",
		"name": "Chimera serum",
		"kind": VIAL_KIND_EXOTIC,
		"shop_cost": 85,
		"tag": "Weird",
		"rarity_min": 2,
		"pool": ["gorilla", "frog", "tentacle", "lizard", "slime"],
	},
	{
		"id": "linger",
		"name": "Linger",
		"kind": VIAL_KIND_PERK,
		"shop_cost": 30,
		"perk_id": PERK_LINGER,
	},
	{
		"id": "poster",
		"name": "Poster child",
		"kind": VIAL_KIND_PERK,
		"shop_cost": 35,
		"perk_id": PERK_POSTER,
	},
]

var unlocked: Dictionary = {} # vial id -> true
var stock: Dictionary = {} # vial id -> int
var zoo_perks: PackedStringArray = PackedStringArray()


func _ready() -> void:
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
	if not WalletService.spend(int(vial.get("shop_cost", 0))):
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
	return 1.25 if has_zoo_perk(PERK_TICKET_BOOTH) else 1.0


func visitor_cap() -> int:
	return 22 if has_zoo_perk(PERK_OPEN_LONGER) else 16


func spawn_time_scale() -> float:
	return 0.7 if has_zoo_perk(PERK_CROWD_PULL) else 1.0
