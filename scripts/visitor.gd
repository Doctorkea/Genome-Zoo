extends Area2D
class_name Visitor

## Park guest. Parents and children use dedicated boy/girl sprites;
## everyone else uses the generic patron with a type tint.
## Interest drains until they see a new exhibit; boredom sends them home,
## and remaining interest is what their ticket is worth.

enum State { ENTER, WANDER, LOOK, HAIL, WAIT }

const DISPLAY_HEIGHT: float = 51.0
const MAX_INTEREST: float = 22.0
const VIEW_BONUS: float = 14.0
const DECAY_IDLE: float = 0.58
const DECAY_BORED: float = 1.45
const DECAY_EMPTY: float = 2.05
const TICKET_MAX: int = 4
## Planet Zoo: unhappy guests stop spending. Below this interest ratio, $0.
const TICKET_PAY_FLOOR: float = 0.28
const TEX_CHILD_BOY: Texture2D = preload("res://art/visitors/child_boy.png")
const TEX_CHILD_GIRL: Texture2D = preload("res://art/visitors/child_girl.png")
const TEX_PARENT_MUM: Texture2D = preload("res://art/visitors/parent_mum.png")
const TEX_PARENT_DAD: Texture2D = preload("res://art/visitors/parent_dad.png")
const TEX_PATRON: Texture2D = preload("res://art/visitors/patron.png")

var visitor_id: String = "tourists"
var fill_color: Color = Color.WHITE
var look_path: String = ""
var pickup_bay: int = -1
var interest: float = MAX_INTEREST
var family_id: int = -1
var family_offset: Vector2 = Vector2.ZERO
var family_leader: Visitor = null

var _state: int = State.ENTER
var _street: Street
var _target: Vector2 = Vector2.ZERO
var _speed: float = 68.0
var _seen: Dictionary = {}
var _leaving: bool = false
var _look_time: float = 0.0
var _look_pen: Pen = null
var _seen_poster: bool = false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _hit: CollisionShape2D = $CollisionShape2D


func setup(street: Street, kind: String, start: Vector2) -> void:
	_street = street
	visitor_id = kind
	fill_color = TraitLibrary.visitor_color(kind)
	position = start
	z_index = 3
	input_pickable = true
	interest = MAX_INTEREST
	add_to_group("visitors")
	_speed = randf_range(58.0, 82.0)
	if _street != null:
		_target = _street.gate_point()
	_apply_look()


func is_waiting() -> bool:
	return _state == State.WAIT


func is_paying() -> bool:
	return not _leaving and _state != State.HAIL and _state != State.WAIT


func has_seen(signature: String) -> bool:
	return _seen.has(signature)


func ticket_value() -> int:
	if not is_paying():
		return 0
	var ratio: float = interest / MAX_INTEREST
	if ratio <= TICKET_PAY_FLOOR:
		return 0
	var t: float = (ratio - TICKET_PAY_FLOOR) / (1.0 - TICKET_PAY_FLOOR)
	var payout: float = float(clampi(int(round(t * float(TICKET_MAX))), 1, TICKET_MAX))
	payout *= GeneTree.ticket_multiplier()
	if _seen_poster:
		payout *= 1.5
	return maxi(1, int(round(payout)))


func is_leader() -> bool:
	return family_leader == null or family_leader == self or not is_instance_valid(family_leader)


func is_leaving() -> bool:
	for mate in party():
		if mate != null and is_instance_valid(mate) and mate._leaving:
			return true
	return _leaving


func hail() -> void:
	if _state == State.HAIL or _state == State.WAIT:
		return
	var lead := _leader()
	if lead != null and lead != self:
		lead.hail()
		return
	if _street == null:
		crush()
		return
	_leaving = true
	var dest := _street.hail_visitor(self)
	go_to(dest)
	if _street != null:
		_street.hail_family(self, dest, pickup_bay)


func join_hail(point: Vector2, bay: int) -> void:
	if _state == State.HAIL or _state == State.WAIT:
		return
	_leaving = true
	pickup_bay = bay
	go_to(point + family_offset)


func go_to(point: Vector2) -> void:
	_target = point
	_state = State.HAIL


func board() -> void:
	queue_free()


func crush() -> void:
	if _street != null:
		_street.forget_visitor(self)
	queue_free()


func _leader() -> Visitor:
	if is_leader():
		return self
	return family_leader


func party() -> Array[Visitor]:
	if _street != null:
		return _street.family_of(self)
	var alone: Array[Visitor] = []
	alone.append(self)
	return alone


func party_center() -> Vector2:
	var members: Array[Visitor] = party()
	if members.is_empty():
		return global_position
	var acc := Vector2.ZERO
	var n: int = 0
	for mate in members:
		if mate != null and is_instance_valid(mate):
			acc += mate.global_position
			n += 1
	if n <= 0:
		return global_position
	return acc / float(n)


func party_span() -> float:
	var members: Array[Visitor] = party()
	var center := party_center()
	var span: float = 36.0
	for mate in members:
		if mate == null or not is_instance_valid(mate):
			continue
		span = maxf(span, center.distance_to(mate.global_position) + 24.0)
	return span


func inspect_party() -> Dictionary:
	var members: Array[Visitor] = party()
	var counts: Dictionary = {}
	var likes: PackedStringArray = PackedStringArray()
	var dislikes: PackedStringArray = PackedStringArray()
	var interest_sum: float = 0.0
	var living: int = 0
	for mate in members:
		if mate == null or not is_instance_valid(mate):
			continue
		living += 1
		interest_sum += mate.interest
		var kind: String = mate.visitor_id
		counts[kind] = int(counts.get(kind, 0)) + 1
		var spec: Dictionary = TraitLibrary.visitor_spec(kind)
		for tag in spec.get("loves", []):
			var word: String = str(tag)
			if not likes.has(word):
				likes.append(word)
		for tag in spec.get("hates", []):
			var word: String = str(tag)
			if not dislikes.has(word):
				dislikes.append(word)
		if str(spec.get("effect", "")) == "uniqueness" and not likes.has("Unusual exhibits"):
			likes.append("Unusual exhibits")
	var is_family: bool = family_id >= 0 and living > 1
	var interest_avg: float = interest_sum / float(maxi(living, 1))
	return {
		"title": _party_title(is_family),
		"kind": _party_kind_line(counts, is_family),
		"likes": likes,
		"dislikes": dislikes,
		"interest": interest_avg,
		"size": living,
		"family": is_family,
		"thought": party_thought(),
	}


func party_thought() -> String:
	var members: Array[Visitor] = party()
	var is_family: bool = family_id >= 0 and members.size() > 1
	var voice: String = "family" if is_family else visitor_id
	if is_leaving():
		return _thought_for(voice, "leaving", "")
	var exhibits: int = _exhibit_count() if is_inside_tree() else 0
	if exhibits <= 0:
		return _thought_for(voice, "empty", "")
	if _party_seen_count() <= 0:
		return _thought_for(voice, "arrive", _want_word())
	var counts: Dictionary = _party_seen_tags()
	var score: int = _party_zoo_score(counts)
	if _party_has_kind("children") and int(counts.get("Scary", 0)) >= TraitLibrary.CHILD_CRY_SCARY:
		return _thought_for(voice, "scared", "scary")
	var unseen: int = _party_unseen_left()
	var interest_sum: float = 0.0
	var living: int = 0
	for mate in members:
		if mate == null or not is_instance_valid(mate):
			continue
		living += 1
		interest_sum += mate.interest
	var ratio: float = interest_sum / (float(maxi(living, 1)) * MAX_INTEREST)
	var hook: String = _thought_hook(counts, score)
	if unseen <= 0 and ratio <= TICKET_PAY_FLOOR:
		return _thought_for(voice, "bored", hook)
	if unseen <= 0:
		return _thought_for(voice, "done" if score >= 0 else "done_bad", hook)
	if score > 0:
		return _thought_for(voice, "like", hook)
	if score < 0:
		return _thought_for(voice, "hate", hook)
	return _thought_for(voice, "wait", _want_word())


func _party_title(is_family: bool) -> String:
	if is_family:
		return "A family"
	match visitor_id:
		"tourists":
			return "A tourist"
		"goths":
			return "A goth"
		"creators":
			return "A content creator"
		"thrill":
			return "A thrill-seeker"
		"scientists":
			return "A scientist"
		"children":
			return "A child"
		"parents":
			return "A parent"
		_:
			return TraitLibrary.visitor_display_name(visitor_id)


func _party_kind_line(counts: Dictionary, is_family: bool) -> String:
	if is_family:
		var parents: int = int(counts.get("parents", 0))
		var kids: int = int(counts.get("children", 0))
		var bits: PackedStringArray = PackedStringArray()
		if parents > 0:
			bits.append("%d parent%s" % [parents, "" if parents == 1 else "s"])
		if kids > 0:
			bits.append("%d child%s" % [kids, "" if kids == 1 else "ren"])
		if bits.is_empty():
			return "A family out for the day"
		return "%s out together" % " and ".join(bits)
	var spec: Dictionary = TraitLibrary.visitor_spec(visitor_id)
	match visitor_id:
		"tourists":
			return "Tourist — here for a majestic photo"
		"goths":
			return "Goth — wants the weird and the grim"
		"creators":
			return "Content creator — hunting a clip"
		"thrill":
			return "Thrill-seeker — here for a scare"
		"scientists":
			return "Scientist — scoring how unusual the mix is"
		"children":
			return "A child on their own"
		"parents":
			return "A parent on their own"
		_:
			return str(spec.get("name", "Guest"))


func _thought_for(voice: String, beat: String, hook: String) -> String:
	var look: String = hook if not hook.is_empty() else "one"
	match beat:
		"leaving":
			match voice:
				"family":
					return "We're calling a car."
				"children":
					return "I want to go home."
				_:
					return "Calling a car."
		"empty":
			match voice:
				"family":
					return "The kids keep asking where the animals are."
				"children":
					return "Where are the animals?"
				"tourists":
					return "I came all this way for empty paddocks?"
				"goths":
					return "Empty cages. Almost atmospheric."
				"creators":
					return "Nothing to film yet."
				"thrill":
					return "Wake me when something's in a pen."
				"scientists":
					return "No specimens. Disappointing."
				"parents":
					return "Not much here for the kids yet."
				_:
					return "There's nothing in the pens."
		"arrive":
			match voice:
				"family":
					return "The kids want to see everything."
				"children":
					return "I wanna see a cute one!"
				"tourists":
					return "Hoping for something majestic."
				"goths":
					return "Show me the grim stuff."
				"creators":
					return "Hunting for a clip."
				"thrill":
					return "Looking for a scare."
				"scientists":
					return "Let's see how unusual this mix is."
				"parents":
					return "We'll follow the kids around."
				_:
					return "Let's see what they've got."
		"like":
			match voice:
				"family":
					return "The kids can't stop talking about the %s one." % look
				"children":
					return "The %s one is the BEST." % look
				"tourists":
					return "That's going on the postcard."
				"goths":
					return "Yes. Keep it weird."
				"creators":
					return "That's the clip."
				"thrill":
					return "That one actually looks dangerous."
				"scientists":
					return "A proper mix. Finally."
				"parents":
					return "The kids are having a good time."
				_:
					return "They're enjoying the %s." % look
		"hate":
			match voice:
				"family":
					return "The kids didn't like that. Too %s." % look
				"children":
					return "It's too %s. I don't like it." % look
				"tourists":
					return "Nothing majestic about that."
				"goths":
					return "Ugh. Too %s." % look
				"creators":
					return "Not filming that."
				"thrill":
					return "Too soft. Where's the bite?"
				"scientists":
					return "Too ordinary."
				"parents":
					return "Not sure this is a good one."
				_:
					return "Not a fan of the %s." % look
		"scared":
			match voice:
				"family":
					return "The kids are frightened. Too scary."
				"children":
					return "It's too scary. I want to go home."
				_:
					return "That exhibit is too scary."
		"bored":
			match voice:
				"family":
					return "The kids are bored. Time to go."
				"children":
					return "I'm bored."
				_:
					return "Nothing new. Not worth another ticket."
		"done":
			match voice:
				"family":
					return "We've seen the lot. Worth the trip."
				"tourists":
					return "Got the photos. Happy with that."
				_:
					return "We've seen it. Pretty good zoo."
		"done_bad":
			match voice:
				"family":
					return "We've seen the lot. The kids weren't impressed."
				_:
					return "We've seen it. Not our kind of zoo."
		"wait":
			match voice:
				"family":
					return "Still wandering. The kids want more."
				"children":
					return "Still looking for a cute one."
				"tourists":
					return "Still waiting for something majestic."
				"goths":
					return "Still hunting for something grim."
				"scientists":
					return "Still looking for something unusual."
				_:
					return "Still looking."
		_:
			return "Wondering about this zoo."


func _want_word() -> String:
	for mate in party():
		if mate == null or not is_instance_valid(mate):
			continue
		var spec: Dictionary = TraitLibrary.visitor_spec(mate.visitor_id)
		var loves: Array = spec.get("loves", [])
		if not loves.is_empty():
			return str(loves[0]).to_lower()
		if str(spec.get("effect", "")) == "uniqueness":
			return "unusual"
	return ""


func _thought_hook(counts: Dictionary, score: int) -> String:
	var loved: PackedStringArray = PackedStringArray()
	var hated: PackedStringArray = PackedStringArray()
	for mate in party():
		if mate == null or not is_instance_valid(mate):
			continue
		var spec: Dictionary = TraitLibrary.visitor_spec(mate.visitor_id)
		for tag in spec.get("loves", []):
			if int(counts.get(tag, 0)) > 0 and not loved.has(str(tag)):
				loved.append(str(tag))
		for tag in spec.get("hates", []):
			if int(counts.get(tag, 0)) > 0 and not hated.has(str(tag)):
				hated.append(str(tag))
	if score >= 0 and not loved.is_empty():
		return loved[0].to_lower()
	if not hated.is_empty():
		return hated[0].to_lower()
	if not loved.is_empty():
		return loved[0].to_lower()
	return ""


func _party_has_kind(kind: String) -> bool:
	for mate in party():
		if mate != null and is_instance_valid(mate) and mate.visitor_id == kind:
			return true
	return false


func _party_zoo_score(counts: Dictionary) -> int:
	var total: int = 0
	for mate in party():
		if mate == null or not is_instance_valid(mate):
			continue
		total += TraitLibrary.visitor_approval(mate.visitor_id, counts)
	return total


func _party_seen_count() -> int:
	var used: Dictionary = {}
	for mate in party():
		if mate == null or not is_instance_valid(mate):
			continue
		for sig in mate._seen.keys():
			used[sig] = true
	return used.size()


func _party_unseen_left() -> int:
	if not is_inside_tree():
		return 0
	var seen: Dictionary = {}
	for mate in party():
		if mate == null or not is_instance_valid(mate):
			continue
		for sig in mate._seen.keys():
			seen[sig] = true
	var n: int = 0
	for node in get_tree().get_nodes_in_group("pens"):
		var pen := node as Pen
		if pen == null:
			continue
		var signature := pen.exhibit_signature()
		if signature.is_empty() or seen.has(signature):
			continue
		n += 1
	return n


func _party_seen_tags() -> Dictionary:
	var counts: Dictionary = {}
	for tag in TraitLibrary.TAGS:
		counts[tag] = 0
	if not is_inside_tree():
		return counts
	var seen: Dictionary = {}
	for mate in party():
		if mate == null or not is_instance_valid(mate):
			continue
		for sig in mate._seen.keys():
			seen[sig] = true
	for node in get_tree().get_nodes_in_group("pens"):
		var pen := node as Pen
		if pen == null:
			continue
		var signature := pen.exhibit_signature()
		if signature.is_empty() or not seen.has(signature):
			continue
		for animal in pen.living_animals():
			if animal == null or not is_instance_valid(animal):
				continue
			var tags: Dictionary = animal.get_stats().get("tags", {})
			for tag in tags.keys():
				counts[tag] = int(counts.get(tag, 0)) + int(tags[tag])
	return counts


func overlaps_world_rect(world_rect: Rect2) -> bool:
	var body := Rect2(
		global_position + Vector2(-20.0, -DISPLAY_HEIGHT),
		Vector2(40.0, DISPLAY_HEIGHT)
	)
	return world_rect.intersects(body)


func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if not (event is InputEventMouseButton) or not event.pressed:
		return
	var mouse := event as InputEventMouseButton
	if mouse.button_index == MOUSE_BUTTON_LEFT:
		Events.visitor_selected.emit(self)
		get_viewport().set_input_as_handled()
	elif mouse.button_index == MOUSE_BUTTON_RIGHT:
		hail()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _state == State.ENTER or _state == State.WANDER or _state == State.LOOK:
		_notice_exhibits()
		_drain_interest(delta)
		if interest <= 0.0:
			hail()
			return
	if not is_leader() and _state != State.HAIL and _state != State.WAIT:
		_follow_leader(delta)
		return
	match _state:
		State.ENTER:
			_move_toward(_target, delta)
			if position.distance_to(_target) <= 4.0:
				_state = State.WANDER
				_pick_wander_target()
		State.WANDER:
			_move_toward(_target, delta)
			if position.distance_to(_target) <= 6.0:
				_start_look()
		State.LOOK:
			_look_time -= delta
			_face_pen()
			if _look_time <= 0.0:
				_pick_wander_target()
		State.HAIL:
			_move_toward(_target, delta)
			if position.distance_to(_target) <= 8.0:
				if pickup_bay >= 0:
					_state = State.WAIT
				else:
					board()
		State.WAIT:
			pass


func _drain_interest(delta: float) -> void:
	var rate: float = DECAY_IDLE
	if _exhibit_count() <= 0:
		rate = DECAY_EMPTY
	elif _unseen_left() <= 0:
		rate = DECAY_BORED
	if _state == State.LOOK and _look_pen != null and is_instance_valid(_look_pen) \
			and not _look_pen.exhibit_signature().is_empty():
		var quality: float = _look_pen.enjoyment_factor() * _look_pen.occupancy_factor()
		rate *= lerpf(0.52, 1.06, clampf((1.0 - quality) / 0.30, 0.0, 1.0))
		if _look_pen.has_animal_perk(GeneTree.PERK_LINGER):
			rate *= 0.55
	interest = maxf(0.0, interest - rate * delta)


func _exhibit_count() -> int:
	var n: int = 0
	for node in get_tree().get_nodes_in_group("pens"):
		var pen := node as Pen
		if pen != null and not pen.exhibit_signature().is_empty():
			n += 1
	return n


func _unseen_left() -> int:
	var n: int = 0
	for node in get_tree().get_nodes_in_group("pens"):
		var pen := node as Pen
		if pen == null:
			continue
		var signature := pen.exhibit_signature()
		if signature.is_empty() or _seen.has(signature):
			continue
		n += 1
	return n


func _notice_exhibits() -> void:
	for node in get_tree().get_nodes_in_group("pens"):
		var pen := node as Pen
		if pen == null:
			continue
		var signature := pen.exhibit_signature()
		if signature.is_empty() or _seen.has(signature):
			continue
		var look := pen.world_rect()
		if _distance_to_rect(look) > 56.0:
			continue
		_seen[signature] = true
		if pen.has_animal_perk(GeneTree.PERK_POSTER):
			_seen_poster = true
		var quality: float = pen.enjoyment_factor() * pen.occupancy_factor()
		interest = minf(MAX_INTEREST, interest + VIEW_BONUS * quality)


func _move_toward(target: Vector2, delta: float) -> void:
	var step := position.move_toward(target, _speed * delta)
	if not _is_walkable(step):
		if _state == State.ENTER and _street != null:
			_target = _street.gate_point()
		elif _state == State.WANDER:
			_pick_wander_target()
		return
	var cell := GridService.world_to_cell(step)
	if GridService.is_area_in_world(cell, Vector2i.ONE) and GridService.is_cell_occupied(cell):
		if _state == State.ENTER and _street != null:
			_target = _street.gate_point()
		elif _state == State.WANDER:
			_pick_wander_target()
		return
	if step.x < position.x - 0.2:
		_sprite.flip_h = true
	elif step.x > position.x + 0.2:
		_sprite.flip_h = false
	position = step


func _apply_look() -> void:
	if _sprite == null:
		_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _hit == null:
		_hit = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _sprite == null:
		return
	var tex: Texture2D = TEX_PATRON
	match visitor_id:
		"children":
			if randf() < 0.5:
				tex = TEX_CHILD_BOY
				look_path = "res://art/visitors/child_boy.png"
			else:
				tex = TEX_CHILD_GIRL
				look_path = "res://art/visitors/child_girl.png"
		"parents":
			if randf() < 0.5:
				tex = TEX_PARENT_MUM
				look_path = "res://art/visitors/parent_mum.png"
			else:
				tex = TEX_PARENT_DAD
				look_path = "res://art/visitors/parent_dad.png"
		_:
			look_path = "res://art/visitors/patron.png"
	_sprite.texture = tex
	if tex.get_height() > 0:
		var s: float = DISPLAY_HEIGHT / float(tex.get_height())
		_sprite.scale = Vector2(s, s)
		_sprite.position = Vector2(0.0, -DISPLAY_HEIGHT * 0.5)
	if visitor_id == "children" or visitor_id == "parents":
		_sprite.modulate = Color.WHITE
	else:
		_sprite.modulate = fill_color.lerp(Color.WHITE, 0.18)
	if _hit != null:
		_hit.position = Vector2(0.0, -DISPLAY_HEIGHT * 0.4)
		var circle := _hit.shape as CircleShape2D
		if circle != null:
			circle.radius = DISPLAY_HEIGHT * 0.32


func _is_walkable(point: Vector2) -> bool:
	if GridService.road_rect().has_point(point):
		return false
	var map := GridService.map_size()
	if point.x < 8.0 or point.x > map.x - 8.0 or point.y < 8.0:
		return false
	return point.y <= GridService.parking_rect().end.y - 2.0


func _pick_wander_target() -> void:
	if _street != null:
		_target = _street.wander_point(self)
		_look_pen = _street.pen_near(_target)
	else:
		_target = position
	_state = State.WANDER


func _start_look() -> void:
	_state = State.LOOK
	_look_time = randf_range(2.6, 5.4)
	if _look_pen == null and _street != null:
		_look_pen = _street.pen_near(position)
	if _look_pen != null and is_instance_valid(_look_pen) \
			and _look_pen.has_animal_perk(GeneTree.PERK_LINGER):
		_look_time *= 1.65


func _follow_leader(delta: float) -> void:
	var lead := _leader()
	if lead == null or not is_instance_valid(lead) or lead == self:
		family_leader = null
		_pick_wander_target()
		return
	_target = lead.position + family_offset
	_move_toward(_target, delta)


func _face_pen() -> void:
	if _look_pen == null or not is_instance_valid(_look_pen) or _sprite == null:
		return
	var toward: float = _look_pen.world_rect().get_center().x - position.x
	if toward < -2.0:
		_sprite.flip_h = true
	elif toward > 2.0:
		_sprite.flip_h = false


func _distance_to_rect(rect: Rect2) -> float:
	var closest := Vector2(
		clampf(position.x, rect.position.x, rect.end.x),
		clampf(position.y, rect.position.y, rect.end.y)
	)
	return position.distance_to(closest)
