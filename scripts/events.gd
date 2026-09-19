extends Node

## Global signal bus, autoloaded as "Events".
##
## Keeps build mode, animals, and the HUD decoupled from each other — nobody
## needs a direct reference to anybody else, they just listen for signals.

signal animal_selected(animal: Node)
signal visitor_selected(visitor: Node)
signal pen_selected(pen: Node)
signal money_changed(amount: int)
signal vials_changed(stock: Dictionary)
signal quest_changed
signal creature_mutated(animal: Node, slot: String)
signal build_tool_changed(item_id: String)
signal placement_rejected(reason: String)
signal placement_succeeded(item_id: String)
signal zoo_hours_changed(is_open: bool)
