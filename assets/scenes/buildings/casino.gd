extends Node2D

@export var building_title: String = "CASINO"
@export var building_action: String = "PRESS E TO PLAY CRAPS"
@export var building_reward: String = "REWARD: +1 RISK - CHANCE: CASH"

@export var blink_interval: float = 0.35
@export var prompt_pop_pixels: float = 2.0
@export var prompt_pop_duration: float = 0.08

@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_prompt: Node2D = $InteractionPromptText
@onready var run_state = get_tree().current_scene.get_node("RunState")
@onready var hud = get_tree().current_scene.get_node("HUD")
@export var min_bet: int = 10
@export var bet_step: int = 10
@export var starting_bet: int = 0
var current_bet: int = 0
var point: int = 0
var round_active := false

var player_inside := false
var in_craps_mode := false

var blink_timer := 0.0
var prompt_base_position := Vector2.ZERO

var is_rolling := false
@export var dice_animation_duration: float = 0.55
@export var dice_animation_step: float = 0.07

func _ready() -> void:
	prompt_base_position = interaction_prompt.position
	interaction_prompt.visible = false
	
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	if not player_inside:
		return
	
	if not in_craps_mode:
		_update_prompt_blink(delta)
		
		if Input.is_action_just_pressed("interact"):
			enter_craps_mode()
	else:
		if is_rolling:
			return
		
		if Input.is_action_just_pressed("bet_up"):
			increase_bet()
		
		if Input.is_action_just_pressed("bet_down"):
			decrease_bet()
		
		if Input.is_action_just_pressed("interact"):
			roll_craps()
		
		if Input.is_action_just_pressed("cancel"):
			exit_craps_mode()


func enter_craps_mode() -> void:
	in_craps_mode = true
	interaction_prompt.visible = false
	
	point = 0
	round_active = false
	current_bet = starting_bet
	
	hud.show_craps_screen()
	hud.reset_craps_display(current_bet)


func exit_craps_mode() -> void:
	in_craps_mode = false
	
	if player_inside:
		interaction_prompt.visible = true
		hud.set_active_building(self, building_title, building_action, building_reward)
	else:
		hud.clear_active_building(self)


func _update_prompt_blink(delta: float) -> void:
	blink_timer += delta
	
	if blink_timer >= blink_interval:
		blink_timer = 0.0
		interaction_prompt.visible = not interaction_prompt.visible


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	
	player_inside = true
	in_craps_mode = false
	blink_timer = 0.0
	
	interaction_prompt.position = prompt_base_position
	interaction_prompt.visible = true
	
	hud.active_building = self
	hud.show_building_info_no_progress(building_title, building_action, building_reward)
	
	_play_prompt_pop()


func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	
	player_inside = false
	in_craps_mode = false
	blink_timer = 0.0
	
	interaction_prompt.position = prompt_base_position
	interaction_prompt.visible = false
	
	hud.clear_active_building(self)


func _play_prompt_pop() -> void:
	interaction_prompt.position = prompt_base_position + Vector2(0, prompt_pop_pixels)
	
	var tween := create_tween()
	tween.tween_property(
		interaction_prompt,
		"position",
		prompt_base_position,
		prompt_pop_duration
	)
func roll_craps() -> void:
	if is_rolling:
		return
	
	if not round_active:
		if current_bet < min_bet:
			hud.set_craps_status("MIN BET $" + str(min_bet))
			hud.flash_craps_status()
			return
		
		if not run_state.spend_cash(current_bet):
			hud.set_craps_status("NO CASH")
			hud.flash_craps_status()
			return
		
		round_active = true
	
	var final_die_one := randi_range(1, 6)
	var final_die_two := randi_range(1, 6)
	
	await animate_dice_roll(final_die_one, final_die_two)
	
	var total := final_die_one + final_die_two
	
	hud.set_dice_faces(final_die_one, final_die_two)
	hud.set_craps_roll_text(final_die_one, final_die_two)
	
	if point == 0:
		resolve_first_roll(total)
	else:
		resolve_point_roll(total)

func animate_dice_roll(final_die_one: int, final_die_two: int) -> void:
	is_rolling = true
	hud.set_craps_status("ROLLING...")
	
	var elapsed := 0.0
	
	while elapsed < dice_animation_duration:
		var random_die_one := randi_range(1, 6)
		var random_die_two := randi_range(1, 6)
		
		hud.set_dice_faces(random_die_one, random_die_two)
		
		await get_tree().create_timer(dice_animation_step).timeout
		elapsed += dice_animation_step
	
	hud.set_dice_faces(final_die_one, final_die_two)
	is_rolling = false
	
func resolve_first_roll(total: int) -> void:
	if total == 7 or total == 11:
		win_craps("YOU WIN! +$" + str(current_bet * 2))
		return
	
	if total == 2 or total == 3 or total == 12:
		lose_craps("YOU LOSE! -$" + str(current_bet))
		return
	
	point = total
	hud.set_craps_point(point)
	hud.set_craps_status("POINT " + str(point))

func resolve_point_roll(total: int) -> void:
	if total == point:
		win_craps("YOU WIN! +$" + str(current_bet * 2))
		return
	
	if total == 7:
		lose_craps("YOU LOSE! -$" + str(current_bet))
		return
	
	hud.set_craps_status("ROLL AGAIN")


func win_craps(message: String) -> void:
	run_state.add_cash(current_bet * 2)
	finish_craps_round(message)


func lose_craps(message: String) -> void:
	finish_craps_round(message)


func finish_craps_round(message: String) -> void:
	run_state.add_risk(1)
	
	hud.set_craps_status(message)
	hud.flash_craps_status()
	
	point = 0
	round_active = false
	current_bet = 0
	
	hud.set_craps_point(0)
	hud.set_craps_bet_value(current_bet)

func get_risk_reward_message() -> String:
	if run_state.risk >= run_state.max_risk:
		return ""
	
	return "RISK +1"

func increase_bet() -> void:
	if round_active:
		return
	
	var next_bet := current_bet + bet_step
	
	if next_bet > run_state.cash:
		return
	
	current_bet = next_bet
	hud.set_craps_bet_value(current_bet)


func decrease_bet() -> void:
	if round_active:
		return
	
	current_bet = max(current_bet - bet_step, 0)
	hud.set_craps_bet_value(current_bet)
