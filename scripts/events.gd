extends Node

## Global signal bus, autoloaded as "Events".
##
## Keeps build mode, animals, and the HUD decoupled from each other — nobody
## needs a direct reference to anybody else, they just listen for signals.

signal animal_selected(animal: Node)
signal mutagen_points_changed(points: int)
signal creature_mutated(animal: Node, slot: String)
