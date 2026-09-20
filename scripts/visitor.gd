extends Area2D
class_name Visitor

## Park guest. Families, goths, tourists, creators, thrill-seekers, and the
## camera operator use dedicated sprites; everyone else uses the generic
## patron with a type tint.
## Interest drains until they see a new exhibit; boredom sends them home,
## and remaining interest is what their ticket is worth.

enum State { ENTER, WANDER, LOOK, HAIL, WAIT }

const DISPLAY_HEIGHT: float = 51.0
const CHILD_HEIGHT: float = 42.0
const MAX_INTEREST: float = 22.0
const VIEW_BONUS: float = 14.0
const DECAY_IDLE: float = 0.58
const DECAY_BORED: float = 1.45
const DECAY_EMPTY: float = 2.05
const TICKET_MAX: int = 2
## Planet Zoo: unhappy guests stop spending. Below this interest ratio, $0.
const TICKET_PAY_FLOOR: float = 0.28
const GOTH_SCARE_RANGE: float = 300.0
const MOOD_SIZE: float = 22.0
const CREATOR_CLIP_CASH: int = 3
const CREATOR_HYPE_SECONDS: float = 18.0
const PANIC_SPEED: float = 138.0
const TEX_CHILD_BOY: Texture2D = preload("res://art/visitors/child_boy.png")
const TEX_CHILD_GIRL: Texture2D = preload("res://art/visitors/child_girl.png")
const TEX_PARENT_MUM: Texture2D = preload("res://art/visitors/parent_mum.png")
const TEX_PARENT_DAD: Texture2D = preload("res://art/visitors/parent_dad.png")
const TEX_GOTH_GIRL: Texture2D = preload("res://art/visitors/goth_girl.png")
const TEX_GOTH_GUY: Texture2D = preload("res://art/visitors/goth_guy.png")
const TEX_TOURIST_GIRL: Texture2D = preload("res://art/visitors/tourist_girl.png")
const TEX_TOURIST_GUY: Texture2D = preload("res://art/visitors/tourist_guy.png")
const TEX_CREATOR_GIRL: Texture2D = preload("res://art/visitors/creator_girl.png")
const TEX_CREATOR_GUY: Texture2D = preload("res://art/visitors/creator_guy.png")
const TEX_THRILL_GIRL: Texture2D = preload("res://art/visitors/thrill_girl.png")
const TEX_THRILL_GUY: Texture2D = preload("res://art/visitors/thrill_guy.png")
const TEX_CAMERA_MAN: Texture2D = preload("res://art/visitors/camera_man.png")
const TEX_PATRON: Texture2D = preload("res://art/visitors/patron.png")
const TalkFont := preload("res://art/ui/fonts/Acme-Regular.ttf")
const ZooFx := preload("res://scripts/fx.gd")
const USED_HEIGHTS := {
	"res://art/visitors/child_boy.png": 344.0,
	"res://art/visitors/child_girl.png": 334.0,
	"res://art/visitors/goth_girl.png": 329.0,
	"res://art/visitors/goth_guy.png": 334.0,
	"res://art/visitors/parent_dad.png": 319.0,
	"res://art/visitors/parent_mum.png": 334.0,
	"res://art/visitors/patron.png": 304.0,
	"res://art/visitors/tourist_girl.png": 342.0,
	"res://art/visitors/tourist_guy.png": 342.0,
	"res://art/visitors/creator_girl.png": 348.0,
	"res://art/visitors/creator_guy.png": 348.0,
	"res://art/visitors/thrill_girl.png": 341.0,
	"res://art/visitors/thrill_guy.png": 347.0,
	"res://art/visitors/camera_man.png": 342.0,
}

static var _used_height: Dictionary = {}

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
var _via: Vector2 = Vector2.ZERO
var _has_via: bool = false
var _snack_used: bool = false
var _merch_paid: bool = false
var _thought_time: float = 0.0
var _thought_key: String = ""
var _thought_line: String = ""
var _mood_time: float = 0.0
var _mood_persist: bool = false
var _mood_bob: float = 0.0
var _gait_phase: float = 0.0
var _body_scale: float = 1.0
var _draw_height: float = DISPLAY_HEIGHT
var _rest_pos: Vector2 = Vector2(0.0, -DISPLAY_HEIGHT * 0.5)
var _shadow_base: Vector2 = Vector2(0.42, 0.42)
var _flee_time: float = 0.0
var _panic: bool = false
var _goth_said: bool = false
var _creator_boosted: bool = false
var _sight_paid: Dictionary = {}

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _shadow: Sprite2D = $Shadow
@onready var _hit: CollisionShape2D = $CollisionShape2D
@onready var _overhead: Node2D = $Overhead
@onready var _mood: Sprite2D = $Overhead/Mood
@onready var _bubble: PanelContainer = $Overhead/Bubble
@onready var _talk: Label = $Overhead/Bubble/Talk
@onready var _tail: Polygon2D = $Overhead/Tail


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
	_gait_phase = randf() * TAU
	if _street != null:
		_target = _street.gate_point()
	_apply_look()
	_style_talk()


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
	payout *= _approval_factor()
	if _seen_poster or _near_poster_stand():
		payout *= GeneTree.poster_multiplier()
	if visitor_id == "children" and _seen_scary() >= TraitLibrary.CHILD_CRY_SCARY:
		payout *= 0.5
	return maxi(1, int(round(payout)))


func _approval_factor() -> float:
	if not is_inside_tree():
		return 1.0
	var score: int = TraitLibrary.visitor_approval(visitor_id, _party_seen_tags())
	return clampf(1.0 + float(clampi(score, -4, 4)) * 0.125, 0.5, 1.5)


func _seen_scary() -> int:
	if not is_inside_tree():
		return 0
	return int(_party_seen_tags().get("Scary", 0))


func _near_poster_stand() -> bool:
	if not is_inside_tree():
		return false
	return GridService.nearest_prop("park_poster", position, 180.0) != Vector2.INF


func on_roar() -> void:
	if visitor_id == "thrill":
		interest = minf(MAX_INTEREST, interest + 4.0)
		_set_mood(GuestMoodArt.spark())
		_say(GuestTalk.blurt("roar_thrill", get_instance_id()))
		return
	if visitor_id == "children" or _party_has_kind("children"):
		interest = maxf(0.0, interest - 6.0)
		if visitor_id == "children":
			_set_mood(GuestMoodArt.tear())
			_say(GuestTalk.blurt("roar_kid", get_instance_id()))
		else:
			_set_mood(GuestMoodArt.bang())
			_say(GuestTalk.blurt("roar_parent", get_instance_id()))
		if interest <= MAX_INTEREST * TICKET_PAY_FLOOR:
			hail()
	else:
		interest = maxf(0.0, interest - 2.0)


func is_leader() -> bool:
	return family_leader == null or family_leader == self or not is_instance_valid(family_leader)


func is_family_party() -> bool:
	if family_id < 0:
		return false
	return _party_has_kind("parents") or _party_has_kind("children")


func is_creator_crew() -> bool:
	return visitor_id == "creators" or visitor_id == "camera" or _party_has_kind("creators")


func likes_exhibit(tags: Dictionary) -> bool:
	for tag in TraitLibrary.loved_tags_for(visitor_id, is_family_party()):
		if int(tags.get(tag, 0)) > 0:
			return true
	return false


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
	_pay_merch()
	if not _panic:
		var voice: String = "family" if is_family_party() else visitor_id
		var speaker := _family_speaker()
		if speaker != null and is_instance_valid(speaker):
			speaker._say(GuestTalk.line(voice, "leaving", "", speaker.get_instance_id()))
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
	_via = Vector2.ZERO
	_has_via = false
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
	var found: Array[Visitor] = []
	if family_id < 0:
		found.append(self)
		return found
	if _street != null:
		return _street.family_of(self)
	var root := get_parent()
	if root == null:
		found.append(self)
		return found
	for child in root.get_children():
		var guest := child as Visitor
		if guest != null and is_instance_valid(guest) and guest.family_id == family_id:
			found.append(guest)
	if found.is_empty():
		found.append(self)
	return found


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
	var is_family: bool = is_family_party()
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
	var is_family: bool = is_family_party()
	var voice: String = "family" if is_family else _crew_voice()
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


func _crew_voice() -> String:
	if is_creator_crew():
		return "creators"
	return visitor_id


func _party_title(is_family: bool) -> String:
	if is_family:
		return "A family"
	if is_creator_crew():
		return "A content creator"
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
	if is_creator_crew():
		return "Content creator — a liked clip sends extra guests"
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
			return "Goth — send them home if they spook families"
		"creators":
			return "Content creator — a liked clip sends extra guests"
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
	var key: String = "%s|%s|%s" % [voice, beat, hook]
	if key != _thought_key:
		_thought_key = key
		_thought_line = GuestTalk.line(voice, beat, hook, get_instance_id())
	return _thought_line


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
		global_position + Vector2(-20.0, -_draw_height),
		Vector2(40.0, _draw_height)
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
	var from := position
	_tick_thought(delta)
	_use_park_props()
	var steer: bool = true
	if _state == State.ENTER or _state == State.WANDER or _state == State.LOOK:
		_tick_goth_scare(delta)
		_tick_mating_scare(delta)
		_notice_exhibits()
		_drain_interest(delta)
		if interest <= 0.0:
			hail()
			steer = false
	if visitor_id == "camera" and is_leader() and not _leaving \
			and _state != State.HAIL and _state != State.WAIT:
		hail()
		steer = false
	if steer:
		if not is_leader() and _state != State.HAIL and _state != State.WAIT:
			_follow_leader(delta)
		else:
			match _state:
				State.ENTER:
					_move_toward(_target, delta)
					if position.distance_to(_target) <= 4.0:
						_state = State.WANDER
						_pick_wander_target()
				State.WANDER:
					_move_toward(_target, delta)
					if position.distance_to(_target) <= 6.0:
						if _flee_time > 0.0:
							_pick_wander_target()
						else:
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
	_animate_gait(delta, position.distance_squared_to(from) > 0.08)


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
		var look_arch: String = ""
		var herd := _look_pen.living_animals()
		if not herd.is_empty():
			look_arch = str(herd[0].get_stats().get("archetype", ""))
		if look_arch == "Novelty":
			rate *= 0.85
	if GridService.has_bench(GridService.world_to_cell(position)):
		rate *= 0.62
	if visitor_id == "children" and _seen_scary() >= TraitLibrary.CHILD_CRY_SCARY:
		rate *= 1.35
	interest = maxf(0.0, interest - rate * delta)


func is_scaring() -> bool:
	return visitor_id == "goths" and not _leaving and _state != State.HAIL and _state != State.WAIT


func _tick_goth_scare(delta: float) -> void:
	if visitor_id == "goths" or _leaving or _panic:
		return
	if _state == State.HAIL or _state == State.WAIT:
		return
	var goth := _nearest_scaring_goth()
	if goth == null:
		_goth_said = false
		_flee_time = maxf(0.0, _flee_time - delta)
		return
	if _family_spooks_from_goths():
		_panic_from_goth()
		return
	if visitor_id == "tourists":
		interest = maxf(0.0, interest - 2.6 * delta)
		if not _goth_said:
			_goth_said = true
			_set_mood(GuestMoodArt.sweat())
			_say(GuestTalk.blurt("tourist_goth", get_instance_id()))
		if interest <= MAX_INTEREST * TICKET_PAY_FLOOR:
			hail()


func _tick_mating_scare(_delta: float) -> void:
	if visitor_id != "parents" or _leaving or _panic:
		return
	if _state == State.HAIL or _state == State.WAIT:
		return
	if _nearest_courting_pen() == null:
		return
	_set_mood(GuestMoodArt.bang(), true)
	_say(GuestTalk.blurt("parent_mate", get_instance_id()))
	_bolt_home()


func _nearest_courting_pen() -> Pen:
	if not is_inside_tree():
		return null
	var best: Pen = null
	var best_d: float = GOTH_SCARE_RANGE + 0.01
	for node in get_tree().get_nodes_in_group("pens"):
		var pen := node as Pen
		if pen == null or not pen.is_courting():
			continue
		var d: float = _distance_to_rect(pen.world_rect())
		if d <= GOTH_SCARE_RANGE and d < best_d:
			best_d = d
			best = pen
	return best


func _panic_from_goth() -> void:
	if _panic:
		return
	for mate in party():
		if mate == null or not is_instance_valid(mate):
			continue
		mate._stamp_goth_panic()
	var lead := _leader()
	if lead != null and lead != self:
		lead._bolt_home()
		return
	_bolt_home()


func _stamp_goth_panic() -> void:
	_panic = true
	_speed = maxf(_speed, PANIC_SPEED)
	_flee_time = 3.0
	if visitor_id == "children":
		_set_mood(GuestMoodArt.tear(), true)
	else:
		_set_mood(GuestMoodArt.bang(), true)
		_say(GuestTalk.blurt("parent_goth", get_instance_id()))


func _bolt_home() -> void:
	_panic = true
	_speed = maxf(_speed, PANIC_SPEED)
	if _street != null:
		hail()
		return
	_leaving = true
	_state = State.HAIL
	_target = position + Vector2(0.0, 240.0)


func _family_spooks_from_goths() -> bool:
	return visitor_id == "parents" or visitor_id == "children" \
		or _party_has_kind("parents") or _party_has_kind("children")


func _nearest_scaring_goth() -> Visitor:
	if not is_inside_tree():
		return null
	var spots: Array[Vector2] = []
	for mate in party():
		if mate != null and is_instance_valid(mate):
			spots.append(mate.global_position)
	if spots.is_empty():
		spots.append(global_position)
	var best: Visitor = null
	var best_d: float = GOTH_SCARE_RANGE + 0.01
	for node in get_tree().get_nodes_in_group("visitors"):
		var other := node as Visitor
		if other == null or other == self or not is_instance_valid(other):
			continue
		if not other.is_scaring():
			continue
		for spot in spots:
			var d: float = spot.distance_to(other.global_position)
			if d <= GOTH_SCARE_RANGE and d < best_d:
				best_d = d
				best = other
				break
	return best


func _post_creator_clip() -> void:
	if visitor_id != "creators" or _creator_boosted:
		return
	_creator_boosted = true
	if _street != null:
		_street.add_hype(CREATOR_HYPE_SECONDS)
	WalletService.add_cash(CREATOR_CLIP_CASH, false, "Creator clip")
	Events.creator_posted.emit(CREATOR_CLIP_CASH)
	ZooFx.burst(self, ZooFx.Kind.GOLD, Vector2(0.0, -36.0))
	_set_mood(GuestMoodArt.spark())
	_say(GuestTalk.blurt("creator_clip", get_instance_id()))
	_popup_hype()


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
		if GridService.nearest_prop("park_poster", pen.world_rect().get_center(), 180.0) != Vector2.INF:
			_seen_poster = true
		var quality: float = pen.enjoyment_factor() * pen.occupancy_factor()
		interest = minf(MAX_INTEREST, interest + VIEW_BONUS * quality)
		var tags: Dictionary = pen.exhibit_tags()
		_mood_from_tags(tags)
		var liked: bool = visitor_id == "creators" and likes_exhibit(tags)
		if _can_talk():
			if visitor_id == "creators" and not liked:
				_say(GuestTalk.line("creators", "film", "", get_instance_id()))
			elif visitor_id != "creators":
				_say(party_thought())
		_pay_sight_bonus(pen, tags, signature)
		if liked:
			_post_creator_clip()


func _move_toward(target: Vector2, delta: float) -> void:
	var dest := target
	if _has_via:
		if position.distance_to(_via) <= 10.0:
			_has_via = false
			dest = target
		else:
			dest = _via
	elif GridService.has_any_path():
		var nxt := _path_next(target)
		if nxt != Vector2.INF:
			_via = nxt
			_has_via = true
			dest = nxt
	var dist: float = _speed * delta
	if _panic:
		dist *= 1.4
	elif _flee_time > 0.0:
		dist *= 1.55
	var step := _steer_step(position, dest, dist)
	if step.distance_squared_to(position) <= 0.0001:
		var nxt := _path_next(target)
		if nxt != Vector2.INF:
			_via = nxt
			_has_via = true
			step = _steer_step(position, nxt, dist)
	if step.distance_squared_to(position) <= 0.0001:
		if _state == State.ENTER and _street != null:
			_has_via = false
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
		"goths":
			if randf() < 0.5:
				tex = TEX_GOTH_GIRL
				look_path = "res://art/visitors/goth_girl.png"
			else:
				tex = TEX_GOTH_GUY
				look_path = "res://art/visitors/goth_guy.png"
		"tourists":
			if randf() < 0.5:
				tex = TEX_TOURIST_GIRL
				look_path = "res://art/visitors/tourist_girl.png"
			else:
				tex = TEX_TOURIST_GUY
				look_path = "res://art/visitors/tourist_guy.png"
		"creators":
			if randf() < 0.5:
				tex = TEX_CREATOR_GIRL
				look_path = "res://art/visitors/creator_girl.png"
			else:
				tex = TEX_CREATOR_GUY
				look_path = "res://art/visitors/creator_guy.png"
		"thrill":
			if randf() < 0.5:
				tex = TEX_THRILL_GIRL
				look_path = "res://art/visitors/thrill_girl.png"
			else:
				tex = TEX_THRILL_GUY
				look_path = "res://art/visitors/thrill_guy.png"
		"camera":
			tex = TEX_CAMERA_MAN
			look_path = "res://art/visitors/camera_man.png"
		_:
			look_path = "res://art/visitors/patron.png"
	_sprite.texture = tex
	_draw_height = CHILD_HEIGHT if visitor_id == "children" else DISPLAY_HEIGHT
	if tex.get_height() > 0:
		var used_h: float = _texture_used_height(tex)
		_body_scale = _draw_height / used_h
		_sprite.centered = true
		# Pivot near the head so a walk sway reads as stepping, not hovering.
		_sprite.offset = Vector2(0.0, float(tex.get_height()) * 0.32)
		_rest_pos = Vector2(0.0, -_draw_height * 0.82)
		_sprite.scale = Vector2(_body_scale, _body_scale)
		_sprite.position = _rest_pos
		_sprite.rotation = 0.0
	if visitor_id in ["children", "parents", "goths", "tourists", "creators", "thrill", "camera"]:
		_sprite.modulate = Color.WHITE
	else:
		_sprite.modulate = fill_color.lerp(Color.WHITE, 0.18)
	if _hit != null:
		_hit.position = Vector2(0.0, -_draw_height * 0.4)
		var circle := _hit.shape as CircleShape2D
		if circle != null:
			circle.radius = _draw_height * 0.32
	_layout_shadow()


func draw_height() -> float:
	return _draw_height


func _layout_shadow() -> void:
	if _shadow == null:
		_shadow = get_node_or_null("Shadow") as Sprite2D
	if _shadow == null:
		return
	_shadow.texture = ZooFx.ground_shadow_tex()
	_shadow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_shadow.z_index = -1
	_shadow.centered = true
	_shadow.position = Vector2(0.0, 2.0)
	var fit: float = _draw_height / DISPLAY_HEIGHT
	_shadow_base = Vector2(0.46 * fit, 0.38 * fit)
	_shadow.scale = _shadow_base
	_shadow.modulate = Color(1, 1, 1, 1)
	_shadow.visible = true


func _texture_used_height(tex: Texture2D) -> float:
	var key: String = tex.resource_path
	if USED_HEIGHTS.has(key):
		return float(USED_HEIGHTS[key])
	if key.is_empty():
		key = str(tex.get_instance_id())
	if _used_height.has(key):
		return float(_used_height[key])
	var used: float = float(tex.get_height())
	var img: Image = tex.get_image()
	if img != null:
		if img.is_compressed():
			img.decompress()
		var rect: Rect2i = img.get_used_rect()
		if rect.size.y > 0:
			used = float(rect.size.y)
	_used_height[key] = used
	return used


func _steer_step(from: Vector2, to: Vector2, dist: float) -> Vector2:
	var direct := from.move_toward(to, dist)
	if GridService.is_guest_walkable(direct):
		return direct
	var along_x := Vector2(to.x, from.y)
	var along_y := Vector2(from.x, to.y)
	var first := along_x if absf(to.x - from.x) >= absf(to.y - from.y) else along_y
	var second := along_y if first == along_x else along_x
	for slide_to in [first, second]:
		var slid := from.move_toward(slide_to, dist)
		if slid.distance_squared_to(from) > 0.0001 and GridService.is_guest_walkable(slid):
			return slid
	return from


func _path_next(goal: Vector2) -> Vector2:
	var start := GridService.world_to_cell(position)
	var end := GridService.world_to_cell(goal)
	if start == end:
		return Vector2.INF
	var dist: Dictionary = {start: 0}
	var came: Dictionary = {start: start}
	var open: Array[Vector2i] = [start]
	var dirs: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	var best: Vector2i = start
	var best_goal: int = 1_000_000
	while not open.is_empty():
		var pick: int = 0
		var pick_cost: int = int(dist[open[0]])
		for i in range(1, open.size()):
			var cost_i: int = int(dist[open[i]])
			if cost_i < pick_cost:
				pick_cost = cost_i
				pick = i
		var cur: Vector2i = open[pick]
		open.remove_at(pick)
		if cur == end:
			best = end
			break
		var goal_d: int = absi(cur.x - end.x) + absi(cur.y - end.y)
		if goal_d < best_goal:
			best_goal = goal_d
			best = cur
		for d in dirs:
			var nxt: Vector2i = cur + d
			if not _cell_ok(nxt):
				continue
			var nd: int = int(dist[cur]) + _step_cost(nxt)
			if dist.has(nxt) and nd >= int(dist[nxt]):
				continue
			dist[nxt] = nd
			came[nxt] = cur
			if not open.has(nxt):
				open.append(nxt)
	if not came.has(best) or best == start:
		return Vector2.INF
	var cursor: Vector2i = best
	while came[cursor] != start:
		cursor = came[cursor]
	return GridService.cell_center(cursor)


func _step_cost(cell: Vector2i) -> int:
	if GridService.has_path(cell) or GridService.has_lamp(cell) or GridService.has_bench(cell):
		return 1
	if GridService.is_area_in_world(cell, Vector2i.ONE) and GridService.has_any_path():
		return 5
	return 1


func _cell_ok(cell: Vector2i) -> bool:
	if cell == GridService.world_to_cell(position):
		return true
	return GridService.is_guest_cell_walkable(cell)


func _pick_wander_target() -> void:
	_has_via = false
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
	if visitor_id == "children" and _seen_scary() >= TraitLibrary.CHILD_CRY_SCARY:
		_look_time *= 0.45
		_set_mood(GuestMoodArt.tear(), true)
		_say(GuestTalk.blurt("too_scary", get_instance_id()))


func _follow_leader(delta: float) -> void:
	var lead := _leader()
	if lead == null or not is_instance_valid(lead) or lead == self:
		family_leader = null
		if visitor_id == "camera" and not _leaving:
			hail()
			return
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


func _pay_merch() -> void:
	if _merch_paid or visitor_id != "tourists":
		return
	if int(_party_seen_tags().get("Majestic", 0)) <= 0:
		return
	_merch_paid = true
	WalletService.add_cash(1, false, "Souvenir")
	_set_mood(GuestMoodArt.spark())
	_say(GuestTalk.blurt("souvenir", get_instance_id()))


func _use_park_props() -> void:
	if not _snack_used:
		var snack := GridService.nearest_prop("park_snack", position, 42.0)
		if snack != Vector2.INF:
			_snack_used = true
			WalletService.add_cash(1, false, "Snack stand")
			_say(GuestTalk.blurt("snack", get_instance_id()))
			ZooFx.burst(self, ZooFx.Kind.STEAM, Vector2(0.0, -_draw_height * 0.35))
	if GridService.has_bench(GridService.world_to_cell(position)) and _state == State.LOOK:
		_look_time = maxf(_look_time, 0.8)


func _say(line: String) -> void:
	if not _can_talk():
		return
	var text := line.strip_edges()
	if text.is_empty():
		return
	_ensure_talk()
	if _talk == null or _bubble == null:
		return
	_talk.text = text
	_bubble.visible = true
	if _tail != null:
		_tail.visible = true
	_thought_time = 2.7
	_layout_bubble.call_deferred()


func _can_talk() -> bool:
	return _family_speaker() == self


func _family_speaker() -> Visitor:
	var members: Array[Visitor] = party()
	if members.size() <= 1:
		return self
	var parent_speaker: Visitor = null
	for mate in members:
		if mate == null or not is_instance_valid(mate):
			continue
		if mate.visitor_id != "parents":
			continue
		if mate.is_leader():
			return mate
		if parent_speaker == null:
			parent_speaker = mate
	if parent_speaker != null:
		return parent_speaker
	var lead := _leader()
	return lead if lead != null else self


func _ensure_talk() -> void:
	if _talk == null:
		_talk = get_node_or_null("Overhead/Bubble/Talk") as Label
	if _bubble == null:
		_bubble = get_node_or_null("Overhead/Bubble") as PanelContainer
	if _tail == null:
		_tail = get_node_or_null("Overhead/Tail") as Polygon2D
	if _mood == null:
		_mood = get_node_or_null("Overhead/Mood") as Sprite2D
	if _overhead == null:
		_overhead = get_node_or_null("Overhead") as Node2D
	_style_talk()


func _style_talk() -> void:
	if _talk == null:
		return
	_talk.add_theme_font_override("font", TalkFont)
	_talk.add_theme_font_size_override("font_size", 10)
	_talk.add_theme_color_override("font_color", Color(0.11, 0.09, 0.063, 1))
	_talk.custom_minimum_size = Vector2(48.0, 0.0)
	_talk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_talk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _layout_bubble() -> void:
	if _bubble == null or _talk == null:
		return
	var min_size: Vector2 = _bubble.get_combined_minimum_size()
	_bubble.size = Vector2(clampf(min_size.x, 36.0, 92.0), min_size.y)
	_bubble.position = Vector2(-_bubble.size.x * 0.5, -_bubble.size.y - 5.0)


func _set_mood(tex: Texture2D, persist: bool = false) -> void:
	_ensure_talk()
	if _mood == null or tex == null:
		return
	_mood.texture = tex
	_mood.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var wide: float = maxf(float(tex.get_width()), 1.0)
	var mood_scale: float = MOOD_SIZE / wide
	_mood.scale = Vector2(mood_scale, mood_scale)
	_mood.visible = true
	_mood_persist = persist
	_mood_time = 8.0 if persist else 2.8


func _mood_from_tags(tags: Dictionary) -> void:
	if _panic:
		return
	var family: bool = is_family_party()
	if (visitor_id == "children" or family) and int(tags.get("Scary", 0)) >= TraitLibrary.CHILD_CRY_SCARY:
		_set_mood(GuestMoodArt.tear(), true)
		return
	for tag in TraitLibrary.loved_tags_for(visitor_id, family):
		if int(tags.get(tag, 0)) > 0:
			_set_mood(GuestMoodArt.heart())
			return
	for tag in TraitLibrary.hated_tags_for(visitor_id, family):
		if int(tags.get(tag, 0)) > 0:
			_set_mood(GuestMoodArt.tear())
			return


func _pay_sight_bonus(pen: Pen, tags: Dictionary, signature: String) -> void:
	var speaker := _family_speaker()
	if speaker == null or not is_instance_valid(speaker):
		speaker = self
	if speaker._sight_paid.has(signature):
		return
	speaker._sight_paid[signature] = true
	var family: bool = is_family_party()
	var cash: int = TraitLibrary.sight_bonus(speaker.visitor_id, tags, family)
	if cash <= 0:
		return
	var look: String = str(pen.living_animals()[0].get_stats().get("archetype", "exhibit")) if not pen.living_animals().is_empty() else "exhibit"
	var who: String = "Family" if family else TraitLibrary.visitor_display_name(speaker.visitor_id)
	WalletService.add_cash(cash, false, "%s liked a %s" % [who, look])
	speaker._mood_from_tags(tags)
	speaker._popup_cash(cash)
	ZooFx.burst(speaker, ZooFx.Kind.GOLD, Vector2(0.0, -speaker.draw_height() * 0.45))


func _popup_cash(amount: int) -> void:
	if amount <= 0:
		return
	var label := Label.new()
	label.text = "+$%d" % amount
	label.z_index = 24
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", TalkFont)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.28, 0.72, 0.32, 1))
	label.add_theme_color_override("font_outline_color", Color(0.06, 0.16, 0.07, 0.85))
	label.add_theme_constant_override("outline_size", 5)
	add_child(label)
	label.position = Vector2(-20.0, -_draw_height - 22.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 30.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.18)
	tween.chain().tween_callback(label.queue_free)


func _popup_hype() -> void:
	var label := Label.new()
	label.text = "Engagement"
	label.z_index = 24
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", TalkFont)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.78, 0.28, 0.72, 1))
	label.add_theme_color_override("font_outline_color", Color(0.18, 0.05, 0.16, 0.85))
	label.add_theme_constant_override("outline_size", 5)
	add_child(label)
	label.position = Vector2(-34.0, -_draw_height - 40.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 28.0, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_delay(0.22)
	tween.chain().tween_callback(label.queue_free)


func _tick_thought(delta: float) -> void:
	_thought_time -= delta
	if _thought_time <= 0.0:
		if _bubble != null:
			_bubble.visible = false
		if _tail != null:
			_tail.visible = false
	if _mood != null and _mood.visible:
		_mood_bob += delta * 5.2
		_mood.position = Vector2(16.0, -20.0 + sin(_mood_bob) * 2.2)
		if not _mood_persist:
			_mood_time -= delta
			if _mood_time <= 0.0:
				_mood.visible = false
	if _overhead != null:
		_overhead.position = Vector2(0.0, -_draw_height - 8.0)


func _animate_gait(delta: float, moving: bool) -> void:
	if _sprite == null:
		return
	if moving:
		var cadence: float = clampf(_speed * 0.09, 4.0, 7.4)
		if visitor_id == "children":
			cadence *= 1.18
		if _panic:
			cadence *= 1.45
		_gait_phase += delta * cadence
		var step: float = sin(_gait_phase)
		# sin² bounce: two footfalls per cycle, smooth troughs instead of a tick.
		var bounce: float = step * step
		_sprite.position = _rest_pos + Vector2(0.0, -bounce * 2.4)
		_sprite.rotation = step * 0.075
		var squash: float = 1.0 + bounce * 0.035
		var stretch: float = 1.0 - bounce * 0.03
		_sprite.scale = Vector2(_body_scale * squash, _body_scale * stretch)
		if _shadow != null:
			_shadow.scale = Vector2(_shadow_base.x * (1.0 + bounce * 0.1), _shadow_base.y * (1.0 - bounce * 0.16))
			_shadow.modulate = Color(1, 1, 1, 1.0 - bounce * 0.2)
	else:
		_gait_phase += delta * 1.7
		var idle: float = sin(_gait_phase)
		_sprite.position = _sprite.position.lerp(_rest_pos + Vector2(0.0, idle * 0.7), clampf(delta * 9.0, 0.0, 1.0))
		_sprite.rotation = lerp_angle(_sprite.rotation, idle * 0.02, clampf(delta * 8.0, 0.0, 1.0))
		var breathe: float = 1.0 + idle * 0.018
		var rest := Vector2(_body_scale, _body_scale * breathe)
		_sprite.scale = _sprite.scale.lerp(rest, clampf(delta * 8.0, 0.0, 1.0))
		if _shadow != null:
			_shadow.scale = _shadow.scale.lerp(_shadow_base, clampf(delta * 8.0, 0.0, 1.0))
			_shadow.modulate = _shadow.modulate.lerp(Color(1, 1, 1, 1), clampf(delta * 8.0, 0.0, 1.0))
