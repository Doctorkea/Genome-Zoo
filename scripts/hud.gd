extends Control

## Game HUD: top resource plaque, bottom build dock, right exhibit card,
## DNA Lab workbench (strand + card), vial shop, and a single active quest.

const FILL_GOOD := Color(0.247, 0.478, 0.29, 1)
const FILL_BAD := Color(0.769, 0.271, 0.212, 1)
const TAG_BAR_MAX: int = 6
const INK := Color(0.11, 0.09, 0.063, 1)
const MUTED := Color(0.42, 0.36, 0.26, 1)
const QuestBadges := preload("res://scripts/quest_badge_art.gd")
const ZooFx := preload("res://scripts/fx.gd")

@onready var _wallet_label: Label = %WalletLabel
@onready var _wallet_drip: Label = %WalletDrip
@onready var _hours_label: Label = %HoursLabel
@onready var _hours_button: Button = %ZooHoursButton
@onready var _hours_scrim: ColorRect = %HoursScrim
@onready var _hours_panel: PanelContainer = %HoursPanel
@onready var _hours_title: Label = %HoursTitle
@onready var _hours_copy: Label = %HoursCopy
@onready var _hours_confirm: Button = %HoursConfirm
@onready var _stats_home: Control = %Body
@onready var _stats_panel: PanelContainer = %StatsPanel
@onready var _pen_panel: PanelContainer = %PenPanel
@onready var _pen_title: Label = %PenTitle
@onready var _pen_detail: Label = %PenDetail
@onready var _guest_panel: PanelContainer = %GuestPanel
@onready var _guest_thumb_viewport: SubViewport = %GuestThumbViewport
@onready var _guest_thumb_camera: Camera2D = %GuestThumbCamera
@onready var _guest_name: Label = %GuestName
@onready var _guest_kind: Label = %GuestKind
@onready var _guest_likes: VBoxContainer = %GuestLikes
@onready var _guest_dislikes: VBoxContainer = %GuestDislikes
@onready var _guest_thought: Label = %GuestThought
@onready var _stats_name_label: Label = %StatsName
@onready var _stats_archetype_label: Label = %StatsArchetype
@onready var _audience_toggle: Button = %AudienceToggle
@onready var _audience_list: VBoxContainer = %AudienceList
@onready var _looks_toggle: Button = %LooksToggle
@onready var _looks_lead: VBoxContainer = %LooksLead
@onready var _looks_list: VBoxContainer = %LooksList
@onready var _stats_parts_label: Label = %StatsParts
@onready var _stats_perks: Label = %StatsPerks
@onready var _thumb_viewport: SubViewport = %ThumbViewport
@onready var _thumb_camera: Camera2D = %ThumbCamera
@onready var _edit_dna_btn: Button = %EditDNA
@onready var _deselect_btn: Button = %Deselect
@onready var _lab_scrim: ColorRect = %LabScrim
@onready var _lab_panel: PanelContainer = %LabPanel
@onready var _lab_card_host: Control = %LabCardHost
@onready var _lab_slots: Container = %LabSlots
@onready var _lab_hint: Label = %LabHint
@onready var _lab_subject: Label = %LabSubject
@onready var _dna_strand: DnaStrand = %DnaStrand
@onready var _shop_scrim: ColorRect = %ShopScrim
@onready var _shop_panel: PanelContainer = %ShopPanel
@onready var _shop_stock: Label = %ShopStock
@onready var _shop_hint: Label = %ShopHint
@onready var _shop_list: VBoxContainer = %ShopList
@onready var _vial_row: Container = %VialRow
@onready var _quest_scrim: ColorRect = %QuestScrim
@onready var _quest_panel: PanelContainer = %QuestPanel
@onready var _quest_badge: TextureRect = %QuestBadge
@onready var _quest_status_icon: TextureRect = %QuestStatusIcon
@onready var _quest_name: Label = %QuestName
@onready var _quest_brief: Label = %QuestBrief
@onready var _quest_progress: Label = %QuestProgress
@onready var _quest_reward: Label = %QuestReward
@onready var _claim_quest: Button = %ClaimQuest
@onready var _catalog_ribbon: PanelContainer = %CatalogRibbon
@onready var _catalog_row: Container = %CatalogRow
@onready var _cat_pens: Button = %CatPens
@onready var _cat_animals: Button = %CatAnimals
@onready var _cat_paths: Button = %CatPaths
@onready var _cat_park: Button = %CatPark
@onready var _dock: Control = %Dock
@onready var _coach_panel: PanelContainer = %CoachPanel
@onready var _coach_copy: Label = %CoachCopy
@onready var _coach_hide_eye: TextureButton = %CoachHideEye
@onready var _show_hint_btn: Button = %ShowQuestHint
@onready var _pause_scrim: ColorRect = %PauseScrim

var _selected_animal: Animal = null
var _selected_pen: Pen = null
var _selected_guest: Visitor = null
var _build_mode: BuildMode = null
var _active_lab_slot: String = ""
var _slot_buttons: Dictionary = {} # slot -> Button
var _tile_buttons: Dictionary = {} # item_id -> Button
var _open_category: String = ""
var _open_card_section: String = ""
var _quest_badge_kind: String = ""
var _quest_badge_tween: Tween
var _hours_closing: bool = false
var _quest_open: bool = false
var _hint_hidden: bool = false
var _paused: bool = false
var _mutation_busy: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thumb_viewport.world_2d = get_tree().root.world_2d
	_thumb_camera.make_current()
	GridService.apply_camera_limits(_thumb_camera)
	_guest_thumb_viewport.world_2d = get_tree().root.world_2d
	_guest_thumb_camera.make_current()
	GridService.apply_camera_limits(_guest_thumb_camera)
	_ink_paper_labels(_stats_panel)
	_ink_paper_labels(_pen_panel)
	_ink_paper_labels(_guest_panel)
	_ink_paper_labels(_lab_panel)
	_ink_paper_labels(_shop_panel)
	_ink_paper_labels(_quest_panel)
	_ink_paper_labels(_hours_panel)
	_style_paper_toggle(_audience_toggle)
	_style_paper_toggle(_looks_toggle)
	_build_lab_slots()
	Events.animal_selected.connect(_on_animal_selected)
	Events.visitor_selected.connect(_on_visitor_selected)
	Events.pen_selected.connect(_on_pen_selected)
	Events.money_changed.connect(_on_money_changed)
	Events.vials_changed.connect(_on_vials_changed)
	Events.quest_changed.connect(_on_quest_changed)
	Events.build_tool_changed.connect(_on_build_tool_changed)
	Events.placement_succeeded.connect(_on_placement_succeeded)
	Events.zoo_hours_changed.connect(_on_zoo_hours_changed)
	Events.tutorial_changed.connect(_refresh_coach)
	_on_money_changed(WalletService.money)
	_on_vials_changed(GeneTree.stock)
	_refresh_quest()
	_refresh_lab_tray()
	_refresh_hours()
	_wire_hint_eyes()
	_refresh_coach()
	set_process(false)


func _ink_paper_labels(root: Node) -> void:
	var ink := Color(0.11, 0.09, 0.063, 1)
	var muted := Color(0.42, 0.36, 0.26, 1)
	for node in root.find_children("*", "Label", true, false):
		var label := node as Label
		if label == null:
			continue
		if label.theme_type_variation == "PaperMuted":
			label.add_theme_color_override("font_color", muted)
		else:
			label.add_theme_color_override("font_color", ink)


func set_build_mode(build_mode: BuildMode) -> void:
	_build_mode = build_mode
	_refresh_catalog_selection()


func _street() -> Street:
	return get_tree().get_first_node_in_group("street") as Street


func _on_zoo_hours_changed(_is_open: bool) -> void:
	_refresh_hours()


func _on_toggle_zoo_hours() -> void:
	var street := _street()
	if street != null and street.is_open:
		_show_hours_dialog(
			"Closing the zoo",
			"You're closing the zoo. Guests will leave.",
			"Close zoo",
			true
		)
		return
	var reason := "Need a pen with at least one animal."
	if street != null:
		reason = street.open_block_reason()
		if reason.is_empty() and street.set_open(true):
			_refresh_hours()
			return
	_show_hours_dialog("Can't open yet", reason, "OK", false)
	_refresh_hours()


func _show_hours_dialog(title: String, copy: String, confirm: String, closing: bool) -> void:
	_hours_closing = closing
	_hours_title.text = title
	_hours_copy.text = copy
	_hours_confirm.text = confirm
	_hours_scrim.visible = true
	_hours_panel.visible = true
	_sync_quest_popup()


func _on_dismiss_hours() -> void:
	_hours_closing = false
	_hours_scrim.visible = false
	_hours_panel.visible = false
	_sync_quest_popup()


func _on_confirm_hours() -> void:
	var closing: bool = _hours_closing
	_on_dismiss_hours()
	if closing:
		var street := _street()
		if street != null:
			street.set_open(false)
		_refresh_hours()


func _refresh_hours() -> void:
	var street := _street()
	var open: bool = street != null and street.is_open
	_hours_label.text = "Open" if open else "Closed"
	_hours_label.add_theme_color_override(
		"font_color",
		Color(0.35, 0.52, 0.28, 1) if open else Color(0.62, 0.28, 0.18, 1)
	)
	_hours_button.text = "Close zoo" if open else "Open zoo"
	if open:
		_hours_button.tooltip_text = "Close the gates. Guests will leave."
	elif street != null and street.has_exhibit():
		_hours_button.tooltip_text = "Open the gates. Guests start arriving."
	else:
		_hours_button.tooltip_text = "Need a pen with at least one animal."


func _on_cat_pens() -> void:
	_toggle_category(BuildCatalog.CAT_PENS)


func _on_cat_animals() -> void:
	_toggle_category(BuildCatalog.CAT_ANIMALS)


func _on_cat_paths() -> void:
	_toggle_category(BuildCatalog.CAT_PATHS)


func _on_cat_park() -> void:
	_toggle_category(BuildCatalog.CAT_PARK)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			_dismiss_open_menu()


func _dismiss_open_menu() -> void:
	var hovered: Control = get_viewport().gui_get_hovered_control()
	if _hours_panel.visible and not _is_on_panel(hovered, _hours_panel):
		_on_dismiss_hours()
		_eat_world_click(hovered)
		return
	if _shop_panel.visible and not _is_on_panel(hovered, _shop_panel):
		_on_close_shop()
		_eat_world_click(hovered)
		return
	if _catalog_ribbon.visible and not _is_on_panel(hovered, _dock):
		_close_catalog()
		_eat_world_click(hovered)


func _is_on_panel(hovered: Control, root: Control) -> bool:
	return hovered != null and (hovered == root or root.is_ancestor_of(hovered))


func _eat_world_click(hovered: Control) -> void:
	if hovered == null or hovered.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		get_viewport().set_input_as_handled()


func _toggle_category(category: String) -> void:
	if _open_category == category:
		_close_catalog()
		if _build_mode != null:
			_build_mode.clear_tool()
		return
	if _build_mode != null:
		_build_mode.clear_tool()
	_open_category = category
	_catalog_ribbon.visible = true
	_rebuild_catalog()
	_cat_pens.set_pressed_no_signal(category == BuildCatalog.CAT_PENS)
	_cat_animals.set_pressed_no_signal(category == BuildCatalog.CAT_ANIMALS)
	_cat_paths.set_pressed_no_signal(category == BuildCatalog.CAT_PATHS)
	_cat_park.set_pressed_no_signal(category == BuildCatalog.CAT_PARK)
	_sync_quest_popup()


func _clear_catalog_tiles() -> void:
	for child in _catalog_row.get_children():
		_catalog_row.remove_child(child)
		child.queue_free()
	_tile_buttons.clear()


func _close_catalog() -> void:
	_open_category = ""
	_catalog_ribbon.visible = false
	_cat_pens.set_pressed_no_signal(false)
	_cat_animals.set_pressed_no_signal(false)
	_cat_paths.set_pressed_no_signal(false)
	_cat_park.set_pressed_no_signal(false)
	_clear_catalog_tiles()
	_sync_quest_popup()


func _rebuild_catalog() -> void:
	_clear_catalog_tiles()
	for item in BuildCatalog.items_for(_open_category):
		var tile := _make_catalog_tile(item)
		_catalog_row.add_child(tile)
		_tile_buttons[str(item.get("id", ""))] = tile
	_refresh_catalog_selection()


func _make_catalog_tile(item: Dictionary) -> Button:
	var cost: int = int(item.get("cost", 0))
	var btn := Button.new()
	btn.toggle_mode = true
	btn.custom_minimum_size = Vector2(112, 88)
	btn.text = "%s\n%s\n$%d" % [
		str(item.get("name", "?")),
		str(item.get("blurb", "")),
		cost,
	]
	btn.tooltip_text = "%s — $%d" % [item.get("name", "?"), cost]
	btn.pressed.connect(_on_catalog_tile_pressed.bind(str(item.get("id", ""))))
	_paint_tile(btn, item)
	return btn


func _paint_tile(btn: Button, item: Dictionary) -> void:
	var cost: int = int(item.get("cost", 0))
	var can_buy := WalletService.can_afford(cost)
	btn.modulate = Color.WHITE if can_buy else Color(1, 1, 1, 0.45)
	if can_buy:
		btn.tooltip_text = "%s — $%d" % [item.get("name", "?"), cost]
	else:
		btn.tooltip_text = "Need $%d for a %s." % [cost, item.get("name", "item")]


func _on_catalog_tile_pressed(item_id: String) -> void:
	var item: Dictionary = BuildCatalog.get_item(item_id)
	if item.is_empty():
		return
	var cost: int = int(item.get("cost", 0))
	if not WalletService.can_afford(cost):
		_refresh_catalog_selection()
		return
	if _build_mode != null:
		_build_mode.set_item(item_id)
	_close_catalog()


func _on_build_tool_changed(_item_id: String) -> void:
	_refresh_catalog_selection()


func _on_placement_succeeded(_item_id: String) -> void:
	_refresh_catalog_tiles()
	_refresh_quest()
	_refresh_hours()


func _refresh_catalog_tiles() -> void:
	for item_id in _tile_buttons:
		var btn: Button = _tile_buttons[item_id]
		var item: Dictionary = BuildCatalog.get_item(str(item_id))
		if is_instance_valid(btn) and not item.is_empty():
			_paint_tile(btn, item)
	_refresh_catalog_selection()


func _refresh_catalog_selection() -> void:
	var selected: String = _build_mode.current_item_id if _build_mode != null else ""
	for item_id in _tile_buttons:
		var btn: Button = _tile_buttons[item_id]
		if is_instance_valid(btn):
			btn.set_pressed_no_signal(str(item_id) == selected)


func _on_money_changed(amount: int) -> void:
	_wallet_label.text = "$%d" % amount
	if _wallet_drip != null:
		var net: int = WalletService.last_payout - WalletService.last_upkeep
		if WalletService.last_payout > 0 or WalletService.last_upkeep > 0:
			if net >= 0:
				_wallet_drip.text = "+$%d" % net
				_wallet_drip.add_theme_color_override("font_color", FILL_GOOD)
			else:
				_wallet_drip.text = "−$%d" % (-net)
				_wallet_drip.add_theme_color_override("font_color", FILL_BAD)
		else:
			_wallet_drip.text = ""
	_refresh_shop()
	_refresh_quest()
	_refresh_catalog_tiles()


func _on_vials_changed(_stock: Dictionary) -> void:
	_refresh_shop()
	_refresh_lab_tray()


func _on_quest_changed() -> void:
	_refresh_quest()
	_refresh_shop()
	_refresh_lab_tray()
	_refresh_coach()


func _refresh_shop() -> void:
	var unlocked: Array[Dictionary] = GeneTree.unlocked_shop_vials()
	_shop_stock.text = _bench_summary(unlocked)
	_fill_shop_list(_shop_list, unlocked)


func _fill_shop_list(host: Container, unlocked: Array[Dictionary]) -> void:
	for child in host.get_children():
		child.queue_free()
	if unlocked.is_empty():
		var empty := Label.new()
		empty.theme_type_variation = "PaperMuted"
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.text = "Unlock a serum on the gene tree first."
		host.add_child(empty)
		return
	for vial in unlocked:
		host.add_child(_make_shop_row(vial))


func _bench_summary(unlocked: Array[Dictionary]) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for vial in unlocked:
		var vial_id: String = str(vial.get("id", ""))
		var count: int = GeneTree.stock_of(vial_id)
		if count > 0:
			parts.append("%s ×%d" % [vial.get("name", vial_id), count])
	if parts.is_empty():
		return "On the bench: nothing yet"
	return "On the bench: %s" % ", ".join(parts)


func _make_shop_row(vial: Dictionary) -> Control:
	var vial_id: String = str(vial.get("id", ""))
	var cost: int = int(vial.get("shop_cost", 0))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var name_label := Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.theme_type_variation = "PaperLabel"
	name_label.text = "%s  ×%d" % [vial.get("name", vial_id), GeneTree.stock_of(vial_id)]
	var buy := Button.new()
	buy.text = "Buy %s ($%d)" % [vial.get("name", "serum"), cost]
	buy.disabled = not GeneTree.can_buy_vial(vial_id)
	if buy.disabled:
		buy.tooltip_text = "Need $%d for %s." % [cost, vial.get("name", "that serum")]
	buy.pressed.connect(_on_buy_vial.bind(vial_id))
	row.add_child(name_label)
	row.add_child(buy)
	return row


func _refresh_lab_tray() -> void:
	if _vial_row == null:
		return
	for child in _vial_row.get_children():
		child.queue_free()
	for vial in GeneTree.unlocked_shop_vials():
		var chip := VialChip.new()
		var vial_id: String = str(vial.get("id", ""))
		chip.setup(vial_id)
		chip.pressed.connect(_on_vial_clicked.bind(vial_id))
		_vial_row.add_child(chip)
		_paint_vial_chip(chip, vial)


func _refresh_quest() -> void:
	QuestBoard.evaluate()
	_refresh_quest_badge()
	if QuestBoard.is_finished():
		_quest_name.text = "That's the board"
		_quest_brief.text = "Keep mutating and selling tickets."
		_quest_progress.text = QuestBoard.progress_text()
		_quest_reward.text = "Reward: —"
		_claim_quest.disabled = true
		_claim_quest.text = "All claimed"
		_refresh_coach()
		return
	var quest: Dictionary = QuestBoard.current()
	_quest_name.text = str(quest.get("title", "Quest"))
	_quest_brief.text = str(quest.get("brief", ""))
	_quest_progress.text = QuestBoard.progress_text()
	_quest_reward.text = "Reward: %s" % QuestBoard.reward_text(quest)
	_claim_quest.disabled = not QuestBoard.ready_to_claim
	_claim_quest.text = "Claim reward" if QuestBoard.ready_to_claim else "Not yet"
	_refresh_coach()


func _refresh_quest_badge() -> void:
	var kind := ""
	if not QuestBoard.is_finished():
		kind = "reward" if QuestBoard.ready_to_claim else "quest"
	_apply_quest_badge(_quest_badge, kind)
	_apply_quest_badge(_quest_status_icon, kind)
	_pulse_quest_badge(kind)


func _apply_quest_badge(icon: TextureRect, kind: String) -> void:
	if icon == null:
		return
	icon.visible = not kind.is_empty()
	if kind == "reward":
		icon.texture = QuestBadges.ribbon()
		icon.tooltip_text = "Reward ready to claim"
		icon.set_meta("kind", "reward")
	elif kind == "quest":
		icon.texture = QuestBadges.exclaim()
		icon.tooltip_text = "You have a quest"
		icon.set_meta("kind", "quest")
	else:
		icon.texture = null
		icon.tooltip_text = ""
		icon.set_meta("kind", "")


func _pulse_quest_badge(kind: String) -> void:
	if _quest_badge == null:
		return
	if kind == _quest_badge_kind and (kind.is_empty() or _quest_badge_tween != null):
		return
	if _quest_badge_tween != null:
		_quest_badge_tween.kill()
		_quest_badge_tween = null
	_quest_badge.scale = Vector2.ONE
	_quest_badge_kind = kind
	if kind.is_empty():
		return
	var amp: float = 1.14 if kind == "reward" else 1.07
	var tw := create_tween()
	tw.set_loops()
	tw.tween_property(_quest_badge, "scale", Vector2(amp, amp), 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_quest_badge, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_quest_badge_tween = tw


func _on_animal_selected(animal: Node) -> void:
	var typed := animal as Animal
	if typed == null:
		return
	_on_close_guest()
	_selected_animal = typed
	_on_close_pen()
	_stats_panel.visible = true
	set_process(true)
	_refresh_inspect()
	if _lab_panel.visible:
		_refresh_lab_header()
		_refresh_lab_hint()


func _on_visitor_selected(visitor: Node) -> void:
	var typed := visitor as Visitor
	if typed == null or not is_instance_valid(typed):
		return
	_on_deselect()
	_on_close_pen()
	_selected_guest = typed
	if not typed.tree_exiting.is_connected(_on_guest_leaving):
		typed.tree_exiting.connect(_on_guest_leaving)
	_guest_panel.visible = true
	set_process(true)
	_refresh_guest()


func _process(_delta: float) -> void:
	if _selected_guest != null and is_instance_valid(_selected_guest):
		_follow_guest_thumbnail()
		_refresh_guest_thought()
	elif _selected_animal != null and is_instance_valid(_selected_animal):
		_follow_thumbnail()
	else:
		if _selected_guest != null:
			_on_close_guest()
		if _selected_animal == null:
			set_process(false)


func _refresh_inspect() -> void:
	if _selected_animal == null:
		return
	var stats: Dictionary = _selected_animal.get_stats()
	_stats_name_label.text = stats.get("name", "Unnamed")
	_stats_archetype_label.text = str(stats.get("archetype", "Unspecialized"))
	var tags: Dictionary = stats.get("tags", {})
	_refresh_audience(tags)
	_refresh_looks(tags)
	_stats_parts_label.text = ", ".join(stats.get("parts", []))
	var perk_names: PackedStringArray = PackedStringArray()
	for perk in stats.get("perks", []):
		match str(perk):
			GeneTree.PERK_LINGER:
				perk_names.append("Linger")
			GeneTree.PERK_POSTER:
				perk_names.append("Poster child")
			_:
				perk_names.append(str(perk).capitalize())
	if _stats_perks != null:
		_stats_perks.text = "Grafts: %s" % (", ".join(perk_names) if not perk_names.is_empty() else "none")
	_follow_thumbnail()


func _follow_thumbnail() -> void:
	if not is_instance_valid(_selected_animal):
		return
	var view: Vector2 = Vector2(_thumb_viewport.size) / _thumb_camera.zoom
	_thumb_camera.global_position = GridService.clamp_camera_center(
		_selected_animal.global_position, view
	)


func _follow_guest_thumbnail() -> void:
	if _selected_guest == null or not is_instance_valid(_selected_guest):
		return
	var center: Vector2 = _selected_guest.party_center() + Vector2(0.0, -Visitor.DISPLAY_HEIGHT * 0.45)
	var span: float = _selected_guest.party_span()
	var zoom: float = clampf(150.0 / maxf(span * 2.0, 80.0), 0.75, 1.35)
	_guest_thumb_camera.zoom = Vector2(zoom, zoom)
	var view: Vector2 = Vector2(_guest_thumb_viewport.size) / _guest_thumb_camera.zoom
	_guest_thumb_camera.global_position = GridService.clamp_camera_center(center, view)


func _refresh_guest() -> void:
	if _selected_guest == null or not is_instance_valid(_selected_guest):
		_on_close_guest()
		return
	var card: Dictionary = _selected_guest.inspect_party()
	_guest_name.text = str(card.get("title", "Guest"))
	_guest_kind.text = str(card.get("kind", ""))
	_fill_guest_tags(_guest_likes, card.get("likes", PackedStringArray()), "Nothing in particular", FILL_GOOD)
	_fill_guest_tags(_guest_dislikes, card.get("dislikes", PackedStringArray()), "Nothing puts them off", FILL_BAD)
	_set_guest_thought(str(card.get("thought", "")))
	_follow_guest_thumbnail()


func _refresh_guest_thought() -> void:
	if _selected_guest == null or not is_instance_valid(_selected_guest) or _guest_thought == null:
		return
	var card: Dictionary = _selected_guest.inspect_party()
	_set_guest_thought(str(card.get("thought", "")))


func _set_guest_thought(line: String) -> void:
	var text: String = line.strip_edges()
	if text.is_empty():
		_guest_thought.text = "“…”"
		return
	if not text.begins_with("“"):
		text = "“%s”" % text
	_guest_thought.text = text


func _fill_guest_tags(box: Container, tags: Variant, empty_text: String, color: Color) -> void:
	_clear_box(box)
	var words: PackedStringArray = PackedStringArray()
	if tags is PackedStringArray:
		words = tags
	elif tags is Array:
		for tag in tags:
			words.append(str(tag))
	if words.is_empty():
		var empty := Label.new()
		empty.theme_type_variation = "PaperMuted"
		empty.add_theme_color_override("font_color", MUTED)
		empty.text = empty_text
		box.add_child(empty)
		return
	for tag in words:
		var label := Label.new()
		label.theme_type_variation = "PaperLabel"
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", color)
		label.text = str(tag)
		box.add_child(label)


func _on_close_guest() -> void:
	if _selected_guest != null and is_instance_valid(_selected_guest):
		if _selected_guest.tree_exiting.is_connected(_on_guest_leaving):
			_selected_guest.tree_exiting.disconnect(_on_guest_leaving)
	_selected_guest = null
	_guest_panel.visible = false
	if _selected_animal == null:
		set_process(false)


func _on_guest_leaving() -> void:
	if _selected_guest == null:
		return
	var next: Visitor = null
	for mate in _selected_guest.party():
		if mate != null and is_instance_valid(mate) and mate != _selected_guest and not mate.is_queued_for_deletion():
			next = mate
			break
	if next != null:
		_on_visitor_selected(next)
	else:
		_on_close_guest()


func _on_hail_guest() -> void:
	if _selected_guest != null and is_instance_valid(_selected_guest):
		_selected_guest.hail()
		_refresh_guest()


func _style_paper_toggle(button: Button) -> void:
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_NONE


func _on_toggle_audience() -> void:
	_set_card_section("audience" if _open_card_section != "audience" else "")


func _on_toggle_looks() -> void:
	_set_card_section("looks" if _open_card_section != "looks" else "")


func _set_card_section(section: String) -> void:
	_open_card_section = section
	var audience_open := section == "audience"
	var looks_open := section == "looks"
	_audience_list.visible = audience_open
	_looks_list.visible = looks_open
	_looks_lead.visible = not looks_open
	_audience_toggle.text = "Audience  %s" % ("▴" if audience_open else "▾")
	_looks_toggle.text = "Looks  %s" % ("▴" if looks_open else "▾")


func _refresh_audience(tags: Dictionary) -> void:
	for child in _audience_list.get_children():
		child.queue_free()
	var notes: Dictionary = TraitLibrary.crowd_notes(tags)
	var likes: Array = notes.get("likes", [])
	var dislikes: Array = notes.get("dislikes", [])
	if likes.is_empty() and dislikes.is_empty():
		_audience_list.add_child(_crowd_header("No strong opinions yet"))
		return
	if not likes.is_empty():
		_audience_list.add_child(_crowd_header("Likes"))
		for note in likes:
			_audience_list.add_child(_audience_row(note))
	if not dislikes.is_empty():
		_audience_list.add_child(_crowd_header("Dislikes"))
		for note in dislikes:
			_audience_list.add_child(_audience_row(note))


func _sentence_case(text: String) -> String:
	if text.is_empty():
		return text
	return text.substr(0, 1).to_upper() + text.substr(1)


func _crowd_header(text: String) -> Label:
	var header := Label.new()
	header.theme_type_variation = "PaperMuted"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", MUTED)
	header.text = text
	return header


func _audience_row(note: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var score: int = int(note.get("score", 0))
	var name_label := Label.new()
	name_label.custom_minimum_size = Vector2(108, 0)
	name_label.theme_type_variation = "PaperLabel"
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.text = str(note.get("name", "?"))
	if score > 0:
		name_label.add_theme_color_override("font_color", FILL_GOOD)
	elif score < 0:
		name_label.add_theme_color_override("font_color", FILL_BAD)
	else:
		name_label.add_theme_color_override("font_color", INK)
	var rule := Label.new()
	rule.theme_type_variation = "PaperMuted"
	rule.add_theme_color_override("font_color", MUTED)
	rule.text = "|"
	var reason := Label.new()
	reason.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reason.theme_type_variation = "PaperMuted"
	reason.add_theme_font_size_override("font_size", 12)
	reason.add_theme_color_override("font_color", MUTED)
	reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reason.text = _sentence_case(str(note.get("reason", "")))
	row.add_child(name_label)
	row.add_child(rule)
	row.add_child(reason)
	return row


func _refresh_looks(tags: Dictionary) -> void:
	_clear_box(_looks_lead)
	_clear_box(_looks_list)
	var lead: Dictionary = TraitLibrary.prominent_look(tags)
	if lead.is_empty():
		_looks_lead.add_child(_looks_empty())
	else:
		_looks_lead.add_child(_make_tag_meter(str(lead.get("name", "?")), int(lead.get("amount", 0))))
	for look in TraitLibrary.present_looks(tags):
		_looks_list.add_child(_make_tag_meter(str(look.get("name", "?")), int(look.get("amount", 0))))
	_set_card_section(_open_card_section)


func _clear_box(box: Container) -> void:
	for child in box.get_children():
		child.queue_free()


func _looks_empty() -> Label:
	var empty := Label.new()
	empty.theme_type_variation = "PaperMuted"
	empty.add_theme_color_override("font_color", MUTED)
	empty.text = "No looks yet"
	return empty


func _make_tag_meter(tag_name: String, amount: int) -> Control:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 3)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 8)
	var name_label := Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.theme_type_variation = "PaperLabel"
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", INK)
	name_label.text = tag_name
	var count_label := Label.new()
	count_label.theme_type_variation = "PaperLabel"
	count_label.add_theme_font_size_override("font_size", 16)
	count_label.add_theme_color_override("font_color", INK)
	count_label.text = str(amount)
	heading.add_child(name_label)
	heading.add_child(count_label)
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = TAG_BAR_MAX
	bar.value = amount
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 12)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.add_child(heading)
	block.add_child(bar)
	return block


func _on_pen_selected(pen: Node) -> void:
	var typed := pen as Pen
	if typed == null:
		return
	_on_deselect()
	_selected_pen = typed
	_pen_panel.visible = true
	_pen_title.text = "Pen"
	var stock: int = typed.occupant_count()
	var cap: int = typed.animal_capacity()
	var mix: String = ""
	if typed.trait_clash() >= 0.55:
		mix = " Conflicting looks. Guests enjoy this exhibit less."
	_pen_detail.text = "%d×%d paddock. %d / %d inside.%s" % [
		typed.footprint_cells.x,
		typed.footprint_cells.y,
		stock,
		cap,
		mix,
	]


func _on_close_pen() -> void:
	_selected_pen = null
	_pen_panel.visible = false


func _on_delete_animal() -> void:
	var animal := _selected_animal
	_on_deselect()
	if _build_mode != null:
		_build_mode.delete_animal(animal)


func _on_delete_pen() -> void:
	var pen := _selected_pen
	_on_close_pen()
	_on_deselect()
	if _build_mode != null:
		_build_mode.delete_pen(pen)


func _on_deselect() -> void:
	_selected_animal = null
	_stats_panel.visible = false
	_set_card_section("")
	_on_close_guest()
	_on_close_lab()


func _on_mutate_pressed() -> void:
	if _selected_animal == null:
		return
	_lab_scrim.visible = true
	_lab_panel.visible = true
	_dock_card(true)
	_refresh_lab_header()
	_active_lab_slot = ""
	_dna_strand.arm("")
	_refresh_slot_toggles()
	_refresh_lab_hint()
	_refresh_lab_tray()
	_refresh_shop()
	TutorialService.on_lab_opened()
	_sync_quest_popup()


func _on_close_lab() -> void:
	_lab_scrim.visible = false
	_lab_panel.visible = false
	_active_lab_slot = ""
	_dna_strand.arm("")
	_refresh_slot_toggles()
	_dock_card(false)
	_sync_quest_popup()


func _dock_card(in_lab: bool) -> void:
	var host: Control = _lab_card_host if in_lab else _stats_home
	if _stats_panel.get_parent() != host:
		_stats_panel.get_parent().remove_child(_stats_panel)
		host.add_child(_stats_panel)
		_restore_owner(_stats_panel)
	_edit_dna_btn.visible = not in_lab
	if _deselect_btn != null:
		_deselect_btn.visible = not in_lab


func _restore_owner(node: Node) -> void:
	node.owner = self
	for child in node.get_children():
		_restore_owner(child)


func _refresh_lab_header() -> void:
	if _selected_animal == null:
		_lab_subject.text = ""
		return
	_lab_subject.text = _selected_animal.creature_name


func _refresh_lab_hint() -> void:
	if _active_lab_slot.is_empty():
		_lab_hint.text = "Pick a body part, then click a vial."
		return
	var current := _current_index_for_slot(_active_lab_slot)
	var option: Dictionary = TraitLibrary.get_option(_active_lab_slot, current)
	_lab_hint.text = "Editing %s — now %s. Click a serum." % [
		TraitLibrary.slot_display_name(_active_lab_slot).to_lower(),
		option.get("name", "?"),
	]


func _build_lab_slots() -> void:
	for child in _lab_slots.get_children():
		child.queue_free()
	_slot_buttons.clear()
	var slots: Array[String] = TraitLibrary.LAB_SLOTS.duplicate()
	slots.append(TraitLibrary.COLOR_SLOT)
	for slot in slots:
		var btn := Button.new()
		btn.toggle_mode = true
		btn.text = TraitLibrary.slot_display_name(slot)
		btn.pressed.connect(_on_lab_slot_pressed.bind(slot))
		_lab_slots.add_child(btn)
		_slot_buttons[slot] = btn


func _on_lab_slot_pressed(slot: String) -> void:
	if _selected_animal == null:
		_refresh_slot_toggles()
		return
	_active_lab_slot = slot
	_dna_strand.arm(slot)
	_refresh_slot_toggles()
	_refresh_lab_hint()
	_refresh_lab_tray()


func _refresh_slot_toggles() -> void:
	for slot in _slot_buttons:
		var btn: Button = _slot_buttons[slot]
		if is_instance_valid(btn):
			btn.set_pressed_no_signal(slot == _active_lab_slot)


func _on_vial_dropped(vial_id: String) -> void:
	_apply_vial(vial_id)


func _on_vial_clicked(vial_id: String) -> void:
	_apply_vial(vial_id)


func _apply_vial(vial_id: String) -> void:
	var vial: Dictionary = GeneTree.get_vial(vial_id)
	if vial.is_empty():
		return
	var vial_name: String = str(vial.get("name", "serum"))
	if _selected_animal == null:
		_lab_hint.text = "Select an animal before using a vial."
		return
	if _mutation_busy:
		_lab_hint.text = "Wait for the smoke to clear."
		return
	if not GeneTree.is_usable_vial(vial_id):
		_lab_hint.text = "No %s left. Buy one from the vial shop." % vial_name
		return
	var kind: String = str(vial.get("kind", ""))
	if kind == GeneTree.VIAL_KIND_PERK:
		_apply_perk_vial(vial_id, vial)
		return
	if _active_lab_slot.is_empty():
		_lab_hint.text = "Pick a body part first."
		return
	var current := _current_index_for_slot(_active_lab_slot)
	var next_index: int = current
	var slot_name: String = TraitLibrary.slot_display_name(_active_lab_slot).to_lower()
	if kind == GeneTree.VIAL_KIND_EXOTIC:
		next_index = TraitLibrary.pick_other_from_ids(
			_active_lab_slot, current, vial.get("pool", [])
		)
		if next_index == current:
			_lab_hint.text = "This %s has no exotic form yet." % slot_name
			return
	else:
		var tag: String = str(vial.get("tag", ""))
		next_index = TraitLibrary.pick_other_with_tag(
			_active_lab_slot, current, tag, int(vial.get("rarity_min", 0))
		)
		if next_index == current:
			_lab_hint.text = "This %s has no %s form yet." % [slot_name, tag.to_lower()]
			return
	if not GeneTree.consume_vial(vial_id):
		return
	var animal: Animal = _selected_animal
	var slot: String = _active_lab_slot
	var index: int = next_index
	var animal_id: int = animal.get_instance_id()
	_mutation_busy = true
	_lab_hint.text = "The serum is taking."
	_refresh_lab_tray()
	ZooFx.conceal_change(animal.visuals, func() -> void:
		var node := instance_from_id(animal_id)
		if node is Animal:
			_finish_serum(node as Animal, slot, index)
		else:
			_mutation_busy = false
	)


func _apply_perk_vial(vial_id: String, vial: Dictionary) -> void:
	var perk_id: String = str(vial.get("perk_id", ""))
	var vial_name: String = str(vial.get("name", "graft"))
	if _selected_animal.has_perk(perk_id):
		_lab_hint.text = "%s already has %s." % [_selected_animal.creature_name, vial_name]
		return
	if _selected_animal.perks.size() >= Animal.MAX_PERKS:
		_lab_hint.text = "%s already has two grafts." % _selected_animal.creature_name
		return
	if not GeneTree.consume_vial(vial_id):
		return
	var animal: Animal = _selected_animal
	var animal_id: int = animal.get_instance_id()
	_mutation_busy = true
	_lab_hint.text = "The graft is taking."
	_refresh_lab_tray()
	ZooFx.conceal_change(animal.visuals, func() -> void:
		var node := instance_from_id(animal_id)
		if node is Animal:
			_finish_perk(node as Animal, perk_id, vial_name)
		else:
			_mutation_busy = false
	)


func _finish_serum(animal: Animal, slot: String, index: int) -> void:
	_mutation_busy = false
	if animal == null or not is_instance_valid(animal):
		return
	if slot == TraitLibrary.COLOR_SLOT:
		animal.visuals.set_skin(index)
	else:
		animal.visuals.set_part_shape(slot, index)
	Events.creature_mutated.emit(animal, slot)
	_refresh_inspect()
	_refresh_quest()
	_dna_strand.arm(slot)
	_refresh_lab_tray()
	var option: Dictionary = TraitLibrary.get_option(slot, index)
	_lab_hint.text = "%s is now %s." % [
		TraitLibrary.slot_display_name(slot),
		option.get("name", "?"),
	]


func _finish_perk(animal: Animal, perk_id: String, vial_name: String) -> void:
	_mutation_busy = false
	if animal == null or not is_instance_valid(animal):
		return
	animal.add_perk(perk_id)
	_lab_hint.text = "%s grafted onto %s." % [vial_name, animal.creature_name]
	_refresh_inspect()
	_refresh_lab_tray()


func _apply_slot(slot: String, index: int) -> void:
	if slot == TraitLibrary.COLOR_SLOT:
		_selected_animal.visuals.set_skin(index)
	else:
		_selected_animal.visuals.set_part_shape(slot, index)


func _current_index_for_slot(slot: String) -> int:
	if _selected_animal == null:
		return 0
	if slot == TraitLibrary.COLOR_SLOT:
		return _selected_animal.visuals.get_current_palette_index()
	return _selected_animal.visuals.get_current_index(slot)


func _on_open_quests() -> void:
	if _quest_open and _quest_panel.visible:
		_on_hide_quests()
		return
	_close_catalog()
	_quest_open = true
	_refresh_quest()
	_sync_quest_popup()


func _on_hide_quests() -> void:
	_quest_open = false
	_sync_quest_popup()


func _on_close_quests() -> void:
	_on_hide_quests()


func _on_hide_hint() -> void:
	_hint_hidden = true
	_refresh_coach()


func _on_show_hint() -> void:
	_hint_hidden = false
	_refresh_coach()


func _on_claim_quest() -> void:
	QuestBoard.claim()
	_refresh_quest()
	SaveService.save_from_tree()


func _on_open_shop() -> void:
	_shop_scrim.visible = true
	_shop_panel.visible = true
	_refresh_shop()
	_sync_quest_popup()


func _on_close_shop() -> void:
	_shop_scrim.visible = false
	_shop_panel.visible = false
	_shop_hint.text = ""
	_sync_quest_popup()


func _on_buy_vial(vial_id: String) -> void:
	var vial: Dictionary = GeneTree.get_vial(vial_id)
	if vial.is_empty():
		return
	var vial_name: String = str(vial.get("name", "serum"))
	var cost: int = int(vial.get("shop_cost", 0))
	if GeneTree.buy_vial(vial_id):
		_shop_hint.text = "%s added to the bench." % vial_name
	else:
		_shop_hint.text = "Need $%d for %s." % [cost, vial_name]
	_refresh_shop()
	_refresh_lab_tray()


func _paint_vial_chip(chip: VialChip, vial: Dictionary) -> void:
	chip.modulate = Color.WHITE
	var kind: String = str(vial.get("kind", ""))
	if kind == GeneTree.VIAL_KIND_PERK:
		chip.tooltip_text = "Click to graft %s." % vial.get("name", "perk")
		return
	var current := _current_index_for_slot(_active_lab_slot)
	if not TraitLibrary.vial_can_apply(vial, _active_lab_slot, current):
		chip.disabled = true
		chip.modulate = Color(1, 1, 1, 0.4)
		var tag: String = str(vial.get("tag", "that"))
		chip.tooltip_text = "This part has no %s form yet." % tag.to_lower()
	else:
		chip.tooltip_text = "Click to apply %s." % vial.get("name", "serum")


func _on_thumb_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse := event as InputEventMouseButton
	if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	if not _lab_panel.visible or _selected_animal == null:
		return
	var wrap: Control = %ThumbContainer
	var size: Vector2 = wrap.size
	if size.y <= 0.0:
		return
	var local: Vector2 = wrap.get_local_mouse_position()
	var t: float = local.y / size.y
	if t < 0.32:
		_on_lab_slot_pressed("head")
	elif t < 0.55:
		_on_lab_slot_pressed(TraitLibrary.COLOR_SLOT)
	elif t < 0.78:
		_on_lab_slot_pressed("front_legs" if local.x > size.x * 0.5 else "back_legs")
	else:
		_on_lab_slot_pressed("tail")


func _wire_hint_eyes() -> void:
	var eye: Texture2D = QuestBadges.eye()
	if _coach_hide_eye != null:
		_coach_hide_eye.texture_normal = eye
		_coach_hide_eye.tooltip_text = "Hide quest hint"
	if _show_hint_btn != null:
		_show_hint_btn.icon = eye
		_show_hint_btn.expand_icon = true
		_show_hint_btn.add_theme_constant_override("icon_max_width", 22)
		_show_hint_btn.tooltip_text = "Show quest hint"


func _quest_hint_copy() -> String:
	if TutorialService.is_active():
		return TutorialService.copy()
	if QuestBoard.is_finished():
		return ""
	return str(QuestBoard.current().get("brief", ""))


func _refresh_coach() -> void:
	if _coach_panel == null:
		return
	var line := _quest_hint_copy()
	if _coach_copy != null:
		_coach_copy.text = line
	var blocked: bool = _menu_blocks_popups()
	_coach_panel.visible = not line.is_empty() and not _hint_hidden and not blocked
	if _show_hint_btn != null:
		_show_hint_btn.visible = not line.is_empty() and _hint_hidden


func _menu_blocks_popups() -> bool:
	return _lab_panel.visible or _shop_panel.visible or _hours_panel.visible \
		or _paused or _catalog_ribbon.visible


func _sync_quest_popup() -> void:
	var show: bool = _quest_open and not _menu_blocks_popups()
	_quest_panel.visible = show
	_quest_scrim.visible = false
	_refresh_coach()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		handle_escape()
		get_viewport().set_input_as_handled()


func handle_escape() -> void:
	if _paused:
		_on_resume()
		return
	if _build_mode != null and not _build_mode.current_item_id.is_empty():
		_build_mode.clear_tool()
		return
	if _hours_panel.visible:
		_on_dismiss_hours()
		return
	if _quest_panel.visible:
		_on_close_quests()
		return
	if _shop_panel.visible:
		_on_close_shop()
		return
	if _lab_panel.visible:
		_on_close_lab()
		return
	_set_paused(true)


func _set_paused(want: bool) -> void:
	_paused = want
	get_tree().paused = want
	if _pause_scrim != null:
		_pause_scrim.visible = want
	Events.game_paused.emit(want)
	_sync_quest_popup()


func _on_resume() -> void:
	_set_paused(false)


func _on_pause_save() -> void:
	SaveService.save_from_tree()


func _on_pause_title() -> void:
	_set_paused(false)
	SaveService.return_to_title()


func _on_pause_quit() -> void:
	SaveService.save_from_tree()
	get_tree().quit()
