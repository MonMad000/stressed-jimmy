extends CanvasLayer

@onready var run_state = $"../RunState"

# ============================================================
# PANEL IZQUIERDO - STATS
# ============================================================

@onready var debt_value: Label = $HUDRoot/BottomPanel/Columns/StatsPanel/StatsMargin/StatsRows/DebtRow/DebtValue
@onready var cash_value: Label = $HUDRoot/BottomPanel/Columns/StatsPanel/StatsMargin/StatsRows/CashRow/CashValue
@onready var day_value: Label = $HUDRoot/BottomPanel/Columns/StatsPanel/StatsMargin/StatsRows/DayRow/DayValue
@onready var score_value: Label = $HUDRoot/BottomPanel/Columns/StatsPanel/StatsMargin/StatsRows/ScoreRow/ScoreValue
@onready var time_value: Label = $HUDRoot/BottomPanel/Columns/StatsPanel/StatsMargin/StatsRows/ClockBox/TimeValue


# ============================================================
# PANEL CENTRAL - RECURSOS FIJOS
# ============================================================

@onready var cash_resource_label: Label = $HUDRoot/BottomPanel/Columns/NegotiationPanel/NegotiationMargin/NegotiationRows/ResourcesRow/CashResourceLabel
@onready var object_resource_label: Label = $HUDRoot/BottomPanel/Columns/NegotiationPanel/NegotiationMargin/NegotiationRows/ResourcesRow/ObjectResourceLabel
@onready var bluff_resource_label: Label = $HUDRoot/BottomPanel/Columns/NegotiationPanel/NegotiationMargin/NegotiationRows/ResourcesRow/BluffResourceLabel
@onready var risk_resource_label: Label = $HUDRoot/BottomPanel/Columns/NegotiationPanel/NegotiationMargin/NegotiationRows/ResourcesRow/RiskResourceLabel


# ============================================================
# PANEL CENTRAL - PANTALLAS
# ============================================================

@onready var empty_screen: Control = $HUDRoot/BottomPanel/Columns/NegotiationPanel/NegotiationMargin/NegotiationRows/Screens/EmptyScreen
@onready var building_info_screen: Control = $HUDRoot/BottomPanel/Columns/NegotiationPanel/NegotiationMargin/NegotiationRows/Screens/BuildingInfoScreen
@onready var craps_screen: Control = $HUDRoot/BottomPanel/Columns/NegotiationPanel/NegotiationMargin/NegotiationRows/Screens/CrapsScreen
@onready var negotiation_screen: Control = $HUDRoot/BottomPanel/Columns/NegotiationPanel/NegotiationMargin/NegotiationRows/Screens/NegotiationScreen


# ============================================================
# BUILDING INFO SCREEN
# ============================================================

@onready var building_title: Label = $HUDRoot/BottomPanel/Columns/NegotiationPanel/NegotiationMargin/NegotiationRows/Screens/BuildingInfoScreen/BuildingTitle
@onready var building_action: Label = $HUDRoot/BottomPanel/Columns/NegotiationPanel/NegotiationMargin/NegotiationRows/Screens/BuildingInfoScreen/BuildingAction
@onready var building_reward: Label = $HUDRoot/BottomPanel/Columns/NegotiationPanel/NegotiationMargin/NegotiationRows/Screens/BuildingInfoScreen/BuildingReward
@onready var progress_border: Panel = $HUDRoot/BottomPanel/Columns/NegotiationPanel/NegotiationMargin/NegotiationRows/Screens/BuildingInfoScreen/ProgressBorder
@onready var progress_text: Label = $HUDRoot/BottomPanel/Columns/NegotiationPanel/NegotiationMargin/NegotiationRows/Screens/BuildingInfoScreen/ProgressBorder/ProgressText


# ============================================================
# CRAPS SCREEN
# ============================================================

@export var dice_sheet: Texture2D

@onready var die_one: TextureRect = $HUDRoot/BottomPanel/Columns/NegotiationPanel/NegotiationMargin/NegotiationRows/Screens/CrapsScreen/DiceBox/DieOne
@onready var die_two: TextureRect = $HUDRoot/BottomPanel/Columns/NegotiationPanel/NegotiationMargin/NegotiationRows/Screens/CrapsScreen/DiceBox/DieTwo
@onready var craps_roll_text: Label = $HUDRoot/BottomPanel/Columns/NegotiationPanel/NegotiationMargin/NegotiationRows/Screens/CrapsScreen/CrapsRollText
@onready var craps_status_text: Label = $HUDRoot/BottomPanel/Columns/NegotiationPanel/NegotiationMargin/NegotiationRows/Screens/CrapsScreen/CrapsStatusText
@onready var pot_value: Label = $HUDRoot/BottomPanel/Columns/NegotiationPanel/NegotiationMargin/NegotiationRows/Screens/CrapsScreen/PotPanel/Panel/PotValue
@onready var point_label: Label = $HUDRoot/BottomPanel/Columns/NegotiationPanel/NegotiationMargin/NegotiationRows/Screens/CrapsScreen/PotPanel/Point


# ============================================================
# NEGOTIATION SCREEN
# ============================================================

@onready var opponent_message: Label = $HUDRoot/BottomPanel/Columns/NegotiationPanel/NegotiationMargin/NegotiationRows/Screens/NegotiationScreen/OpponentMessage
@onready var offer_value: Label = $HUDRoot/BottomPanel/Columns/NegotiationPanel/NegotiationMargin/NegotiationRows/Screens/NegotiationScreen/OfferValue
@onready var offer_hint: Label = $HUDRoot/BottomPanel/Columns/NegotiationPanel/NegotiationMargin/NegotiationRows/Screens/NegotiationScreen/OptionsLabel

# ============================================================
# PANEL DERECHO - CONTEXTOS
# ============================================================
@export var debt_marker_scene: PackedScene
@onready var debts_screen: Control = $HUDRoot/BottomPanel/Columns/ContextPanel/ContextScreens/DebtsScreen
@onready var craps_rules_screen: Control = $HUDRoot/BottomPanel/Columns/ContextPanel/ContextScreens/CrapsRulesScreen
@onready var debt_markers_container: Control = $HUDRoot/BottomPanel/Columns/ContextPanel/ContextScreens/DebtsScreen/RadarArea/DebtMarkers
@onready var debt_radar_footer: Label = $HUDRoot/BottomPanel/Columns/ContextPanel/ContextScreens/DebtsScreen/DebtRadarFooter

# ============================================================
# BUILDING ACTIVE SYSTEM
# ============================================================

var active_building: Node = null
var nearby_buildings: Array = []
var debt_markers_by_id: Dictionary = {}

# ============================================================
# GODOT LIFECYCLE
# ============================================================

func _ready() -> void:
	show_empty_screen()
	update_hud()
	
	# Solo para que los dados no queden vacíos si entrás al CrapsScreen.
	set_dice_faces(5, 4)


func _process(_delta: float) -> void:
	update_hud()


# ============================================================
# HUD GENERAL
# ============================================================

func update_hud() -> void:
	update_left_panel()
	update_center_resources()
	update_debt_radar()

func update_left_panel() -> void:
	debt_value.text = "$" + str(run_state.total_debt)
	cash_value.text = "$" + str(run_state.cash)
	score_value.text = str(run_state.score)
	day_value.text = str(run_state.current_day)
	time_value.text = run_state.format_time(run_state.current_time_seconds)


func update_center_resources() -> void:
	cash_resource_label.text = "CASH " + str(run_state.cash)
	object_resource_label.text = "OBJ " + str(run_state.objects)
	bluff_resource_label.text = "BLUFF " + str(run_state.bluff)
	risk_resource_label.text = "RISK " + str(run_state.risk)


# ============================================================
# SCREEN SWITCHING
# ============================================================

func hide_all_center_screens() -> void:
	empty_screen.visible = false
	building_info_screen.visible = false
	craps_screen.visible = false
	negotiation_screen.visible = false


func show_empty_screen() -> void:
	hide_all_center_screens()
	
	empty_screen.visible = true
	
	progress_border.visible = true
	progress_text.visible = true
	set_building_progress(0.0)
	
	show_debts_context()


func show_building_info(title: String, action: String, reward: String) -> void:
	hide_all_center_screens()
	
	building_info_screen.visible = true
	
	building_title.text = title
	building_action.text = action
	building_reward.text = reward
	
	progress_border.visible = true
	progress_text.visible = true
	set_building_progress(0.0)
	
	show_debts_context()


func show_building_info_no_progress(title: String, action: String, reward: String) -> void:
	hide_all_center_screens()
	
	building_info_screen.visible = true
	
	building_title.text = title
	building_action.text = action
	building_reward.text = reward
	
	progress_border.visible = false
	progress_text.visible = false
	
	show_debts_context()


func show_craps_screen() -> void:
	hide_all_center_screens()
	
	craps_screen.visible = true
	
	show_craps_rules_context()


func show_negotiation_screen() -> void:
	hide_all_center_screens()
	
	negotiation_screen.visible = true
	
	show_debts_context()


# ============================================================
# BUILDING INFO PROGRESS
# ============================================================

func set_building_progress(value: float) -> void:
	var total_blocks: int = 16
	var progress: float = clampf(value, 0.0, 100.0) / 100.0
	var filled_blocks: int = int(round(progress * total_blocks))
	var empty_blocks: int = total_blocks - filled_blocks
	
	progress_text.text = " █".repeat(filled_blocks) + " ░".repeat(empty_blocks)


# ============================================================
# BUILDING ACTIVE SYSTEM
# ============================================================

func set_active_building(building: Node, title: String, action: String, reward: String) -> void:
	_remove_nearby_building(building)
	
	nearby_buildings.append({
		"node": building,
		"title": title,
		"action": action,
		"reward": reward
	})
	
	_set_active_from_entry(nearby_buildings[nearby_buildings.size() - 1])


func clear_active_building(building: Node) -> void:
	var was_active: bool = active_building == building
	
	_remove_nearby_building(building)
	
	if not was_active:
		return
	
	if nearby_buildings.is_empty():
		active_building = null
		show_empty_screen()
		return
	
	_set_active_from_entry(nearby_buildings[nearby_buildings.size() - 1])


func _remove_nearby_building(building: Node) -> void:
	for i in range(nearby_buildings.size() - 1, -1, -1):
		var entry: Dictionary = nearby_buildings[i]
		
		if entry["node"] == building:
			nearby_buildings.remove_at(i)


func _set_active_from_entry(entry: Dictionary) -> void:
	active_building = entry["node"]
	
	show_building_info(
		str(entry["title"]),
		str(entry["action"]),
		str(entry["reward"])
	)
	
	set_building_progress(0.0)


# ============================================================
# PANEL DERECHO
# ============================================================

func show_debts_context() -> void:
	debts_screen.visible = true
	craps_rules_screen.visible = false


func show_craps_rules_context() -> void:
	debts_screen.visible = false
	craps_rules_screen.visible = true


# ============================================================
# CRAPS
# ============================================================

func set_dice_faces(first_die: int, second_die: int) -> void:
	die_one.texture = create_die_texture(first_die)
	die_two.texture = create_die_texture(second_die)


func create_die_texture(face_value: int) -> AtlasTexture:
	var clamped_value: int = clampi(face_value, 1, 6)
	var face_index: int = clamped_value - 1
	
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = dice_sheet
	atlas_texture.region = Rect2(face_index * 16, 0, 16, 16)
	
	return atlas_texture


func set_craps_roll_text(first_die: int, second_die: int) -> void:
	var total: int = first_die + second_die
	craps_roll_text.text = "ROLL " + str(first_die) + " + " + str(second_die) + " = " + str(total)


func set_craps_status(text: String) -> void:
	craps_status_text.text = text


func reset_craps_display(bet_amount: int) -> void:
	set_dice_faces(1, 1)
	craps_roll_text.text = "ROLL -- + -- = --"
	set_craps_bet_value(bet_amount)
	set_craps_point(0)
	set_craps_status("PRESS E TO ROLL")


func flash_craps_status(times: int = 3, interval: float = 0.12) -> void:
	for i in range(times):
		craps_status_text.visible = false
		await get_tree().create_timer(interval).timeout
		
		craps_status_text.visible = true
		await get_tree().create_timer(interval).timeout


func set_craps_bet_value(amount: int) -> void:
	pot_value.text = "$" + str(amount)


func set_craps_point(value: int) -> void:
	if value <= 0:
		point_label.text = "POINT NONE"
	else:
		point_label.text = "POINT " + str(value)


# ============================================================
# NEGOTIATION
# ============================================================

func set_opponent_message(text: String) -> void:
	opponent_message.text = text


func set_offer_text(cash_amount: int, objects_amount: int, bluff_amount: int, luck_enabled: bool) -> void:
	var text: String = "I OFFER $" + str(cash_amount)
	
	if objects_amount > 0:
		text += " + OBJ " + str(objects_amount)
	
	if bluff_amount > 0:
		text += " + BLUFF " + str(bluff_amount)
	
	if luck_enabled:
		text += " + LUCK"
	
	offer_value.text = text


func set_offer_hint(text: String) -> void:
	offer_hint.text = text


func reset_negotiation_display(target_debt: int) -> void:
	show_negotiation_screen()
	set_opponent_message("I WANT MY $" + str(target_debt) + " BACK!")
	set_offer_text(0, 0, 0, false)
	set_offer_hint("[W/S] CASH  [O] OBJ  [B] BLUFF  [L] LUCK")

func update_debt_radar() -> void:
	if not debts_screen.visible:
		return
	
	if debt_marker_scene == null:
		return
	
	var active_debts: Array[Dictionary] = run_state.get_active_debts()
	var visible_debt_ids: Array[int] = []
	
	active_debts.sort_custom(_sort_debts_by_due_time)
	
	for debt in active_debts:
		var debt_id: int = int(debt["id"])
		visible_debt_ids.append(debt_id)
		
		var marker: DebtMarker = _get_or_create_debt_marker(debt)
		var target_position: Vector2 = _get_debt_marker_position(debt)
		
		marker.position = marker.position.lerp(target_position, 0.18)
		
		var is_alert: bool = _is_debt_in_alert_zone(debt)
		marker.set_alert(is_alert)
		
		var time_text: String = _get_debt_time_text(debt)
		marker.setup(
		debt_id,
		str(debt["creditor_name"]),
		int(debt["amount"])
	)
	
	_remove_unused_debt_markers(visible_debt_ids)
	
	debt_radar_footer.text = "TOTAL $" + str(run_state.total_debt)
func _get_or_create_debt_marker(debt: Dictionary) -> DebtMarker:
	var debt_id: int = int(debt["id"])
	
	if debt_markers_by_id.has(debt_id):
		return debt_markers_by_id[debt_id]
	
	var marker: DebtMarker = debt_marker_scene.instantiate() as DebtMarker
	debt_markers_container.add_child(marker)
	
	marker.size = Vector2(48, 16)
	marker.custom_minimum_size = Vector2(48, 16)
	
	marker.setup(
		debt_id,
		str(debt["creditor_name"]),
		int(debt["amount"]),
		_get_debt_time_text(debt)
	)
	
	debt_markers_by_id[debt_id] = marker
	
	return marker


func _remove_unused_debt_markers(visible_debt_ids: Array[int]) -> void:
	var ids_to_remove: Array[int] = []
	
	for debt_id in debt_markers_by_id.keys():
		if not visible_debt_ids.has(int(debt_id)):
			ids_to_remove.append(int(debt_id))
	
	for debt_id in ids_to_remove:
		var marker: Node = debt_markers_by_id[debt_id]
		marker.queue_free()
		debt_markers_by_id.erase(debt_id)

func _get_debt_marker_position(debt: Dictionary) -> Vector2:
	var radar_height: float = debt_markers_container.size.y
	var radar_width: float = debt_markers_container.size.x
	
	var top_y: float = 4.0
	var bottom_y: float = max(radar_height - 34.0, top_y)
	
	var seconds_until_due: int = _get_seconds_until_debt_due(debt)
	var radar_window_seconds: int = 24 * 60 * 60
	
	var progress: float = 1.0 - clampf(
		float(seconds_until_due) / float(radar_window_seconds),
		0.0,
		1.0
	)
	
	var y: float = lerpf(top_y, bottom_y, progress)
	
	var marker_width: float = 48.0
	var x: float = radar_width - marker_width - 2.0
	
	x = max(x, 0.0)
	
	return Vector2(x, y)
	
func _get_absolute_seconds(day: int, seconds: int) -> int:
	return (day - 1) * 24 * 60 * 60 + seconds


func _get_seconds_until_debt_due(debt: Dictionary) -> int:
	var debt_day: int = int(debt["due_day"])
	var debt_time: int = int(debt["due_time_seconds"])
	
	var current_absolute_seconds: int = _get_absolute_seconds(
		run_state.current_day,
		run_state.current_time_seconds
	)
	
	var debt_absolute_seconds: int = _get_absolute_seconds(
		debt_day,
		debt_time
	)
	
	return debt_absolute_seconds - current_absolute_seconds
	
func _get_debt_time_text(debt: Dictionary) -> String:
	var debt_day: int = int(debt["due_day"])
	var debt_time: int = int(debt["due_time_seconds"])
	
	if debt_day < run_state.current_day:
		return "NOW"
	
	if debt_day == run_state.current_day and debt_time <= run_state.current_time_seconds:
		return "NOW"
	
	if debt_day == run_state.current_day:
		return _format_hour_minute(debt_time)
	
	return "D" + str(debt_day)


func _format_hour_minute(total_seconds: int) -> String:
	var hours: int = total_seconds / 3600
	var minutes: int = (total_seconds % 3600) / 60
	
	return "%02d:%02d" % [hours, minutes]
	
func _is_debt_in_alert_zone(debt: Dictionary) -> bool:
	var seconds_until_due: int = _get_seconds_until_debt_due(debt)
	
	return seconds_until_due <= 2 * 60 * 60


func _sort_debts_by_due_time(a: Dictionary, b: Dictionary) -> bool:
	var a_abs: int = _get_absolute_seconds(
		int(a["due_day"]),
		int(a["due_time_seconds"])
	)
	
	var b_abs: int = _get_absolute_seconds(
		int(b["due_day"]),
		int(b["due_time_seconds"])
	)
	
	return a_abs < b_abs
