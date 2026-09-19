extends Node

## Cash spent on pens, animals, and vial charges.
## Ticket revenue comes from visitors still interested in the zoo.
## Autoloaded as "WalletService".

const ZooFx := preload("res://scripts/fx.gd")
const LEDGER_MAX: int = 5

@export var starting_money: int = 80
@export var tick_seconds: float = 6.0
const UPKEEP_PER_PEN: int = 1

var money: int = 0
var tickets_earned: int = 0
var last_payout: int = 0
var last_upkeep: int = 0
var ledger: Array[Dictionary] = []

@onready var _timer: Timer = Timer.new()


func _ready() -> void:
	reset()
	_timer.wait_time = tick_seconds
	_timer.autostart = true
	add_child(_timer)
	_timer.timeout.connect(_on_tick)


func reset() -> void:
	money = starting_money
	tickets_earned = 0
	last_payout = 0
	last_upkeep = 0
	ledger.clear()
	_record(starting_money, "Starting cash")
	Events.money_changed.emit(money)


func _on_tick() -> void:
	collect_tickets()


func collect_tickets() -> int:
	var payout: int = 0
	var payers: Array[Visitor] = []
	if get_tree() != null:
		for node in get_tree().get_nodes_in_group("visitors"):
			var guest := node as Visitor
			if guest == null:
				continue
			var value: int = guest.ticket_value()
			payout += value
			if value > 0 and payers.size() < 5:
				payers.append(guest)
	last_payout = payout
	last_upkeep = _upkeep_due()
	var net: int = payout - last_upkeep
	if payout > 0:
		tickets_earned += payout
		_record(payout, "Guest tickets")
	if last_upkeep > 0:
		_record(-last_upkeep, "Pen upkeep")
	if net != 0:
		money = maxi(0, money + net)
		Events.money_changed.emit(money)
	elif last_upkeep > 0:
		Events.money_changed.emit(money)
	for guest in payers:
		if guest != null and is_instance_valid(guest):
			ZooFx.burst(guest, ZooFx.Kind.GOLD, Vector2(0.0, -36.0))
	return net


func _upkeep_due() -> int:
	if not _zoo_is_open():
		return 0
	return stocked_pen_count() * UPKEEP_PER_PEN


func stocked_pen_count() -> int:
	if get_tree() == null:
		return 0
	var n: int = 0
	for node in get_tree().get_nodes_in_group("pens"):
		var pen := node as Pen
		if pen != null and pen.occupant_count() > 0:
			n += 1
	return n


func _zoo_is_open() -> bool:
	if get_tree() == null:
		return false
	for node in get_tree().get_nodes_in_group("street"):
		var street := node as Street
		if street != null:
			return street.is_open
	return false


func add_cash(amount: int, tickets: bool = false, reason: String = "") -> void:
	if amount <= 0:
		return
	money += amount
	if tickets:
		tickets_earned += amount
	_record(amount, reason if not reason.is_empty() else "Cash in")
	Events.money_changed.emit(money)


func snapshot() -> Dictionary:
	return {
		"money": money,
		"tickets_earned": tickets_earned,
	}


func apply_state(data: Dictionary) -> void:
	money = int(data.get("money", starting_money))
	tickets_earned = int(data.get("tickets_earned", 0))
	last_payout = 0
	last_upkeep = 0
	ledger.clear()
	Events.money_changed.emit(money)


func can_afford(cost: int) -> bool:
	return money >= cost


func spend(cost: int, reason: String = "Purchase") -> bool:
	if not can_afford(cost):
		return false
	money -= cost
	_record(-cost, reason)
	Events.money_changed.emit(money)
	return true


func _record(delta: int, reason: String) -> void:
	if delta == 0:
		return
	var line: String = reason.strip_edges()
	if line.is_empty():
		line = "Cash" if delta > 0 else "Purchase"
	ledger.push_front({"delta": delta, "reason": line})
	while ledger.size() > LEDGER_MAX:
		ledger.pop_back()


func last_tick_summary() -> String:
	if last_payout <= 0 and last_upkeep <= 0:
		return "No tickets or upkeep yet."
	if last_upkeep <= 0:
		return "Last collection: guest tickets +$%d." % last_payout
	if last_payout <= 0:
		return "Last collection: pen upkeep −$%d." % last_upkeep
	var net: int = last_payout - last_upkeep
	if net >= 0:
		return "Last collection: tickets +$%d, upkeep −$%d (net +$%d)." % [
			last_payout, last_upkeep, net
		]
	return "Last collection: tickets +$%d, upkeep −$%d (net −$%d)." % [
		last_payout, last_upkeep, -net
	]
