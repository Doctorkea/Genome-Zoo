extends Node

## Cash spent on pens, animals, and vial charges.
## Ticket revenue comes from visitors still interested in the zoo.
## Autoloaded as "WalletService".

@export var starting_money: int = 100
@export var tick_seconds: float = 5.0

var money: int = 0
var tickets_earned: int = 0

@onready var _timer: Timer = Timer.new()


func _ready() -> void:
	money = starting_money
	_timer.wait_time = tick_seconds
	_timer.autostart = true
	add_child(_timer)
	_timer.timeout.connect(_on_tick)
	Events.money_changed.emit(money)


func _on_tick() -> void:
	collect_tickets()


func collect_tickets() -> int:
	var payout: int = 0
	if get_tree() != null:
		for node in get_tree().get_nodes_in_group("visitors"):
			var guest := node as Visitor
			if guest != null:
				payout += guest.ticket_value()
	if payout > 0:
		tickets_earned += payout
		money += payout
		Events.money_changed.emit(money)
	return payout


func add_cash(amount: int) -> void:
	if amount <= 0:
		return
	money += amount
	Events.money_changed.emit(money)


func can_afford(cost: int) -> bool:
	return money >= cost


func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	money -= cost
	Events.money_changed.emit(money)
	return true
