extends Node

## First-run coach marks. Autoloaded as "TutorialService".

enum Step { PENS, ANIMALS, OPEN, DNA, DONE }

var step: int = Step.PENS
var seen: bool = false


func reset() -> void:
	step = Step.PENS
	seen = false
	Events.tutorial_changed.emit()


func skip() -> void:
	step = Step.DONE
	seen = true
	Events.tutorial_changed.emit()


func is_active() -> bool:
	return step < Step.DONE and not seen


func copy() -> String:
	match step:
		Step.PENS:
			return "Open Pens and place a paddock on the grass."
		Step.ANIMALS:
			return "Open Animals and drop a creature inside the pen."
		Step.OPEN:
			return "Open the zoo so guests can arrive."
		Step.DNA:
			return "Select the animal and open the DNA Lab."
		_:
			return ""


func on_pen_placed() -> void:
	if step == Step.PENS:
		step = Step.ANIMALS
		Events.tutorial_changed.emit()


func on_animal_placed() -> void:
	if step == Step.ANIMALS:
		step = Step.OPEN
		Events.tutorial_changed.emit()


func on_zoo_opened() -> void:
	if step == Step.OPEN:
		step = Step.DNA
		Events.tutorial_changed.emit()


func on_lab_opened() -> void:
	if step == Step.DNA:
		step = Step.DONE
		seen = true
		Events.tutorial_changed.emit()


func snapshot() -> Dictionary:
	return {"step": step, "seen": seen}


func apply_state(data: Dictionary) -> void:
	step = int(data.get("step", Step.DONE))
	seen = bool(data.get("seen", true))
	Events.tutorial_changed.emit()
