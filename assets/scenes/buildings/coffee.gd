extends Node2D

@export var building_title: String = "COFFEE"
@export var building_action: String = "SMALL TALK"
@export var building_reward: String = "REWARD: +1 BLUFF"

@export var bluff_reward: int = 1
@export var time_cost_seconds: int = 20
@export var required_hold_seconds: float = 10.0

@export var blink_interval: float = 0.35
@export var prompt_pop_pixels: float = 2.0
@export var prompt_pop_duration: float = 0.08

@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_prompt: Node2D = $InteractionPromptText

@onready var run_state = get_tree().current_scene.get_node("RunState")
@onready var hud = get_tree().current_scene.get_node("HUD")

var player_inside := false
var progress := 0.0

var blink_timer := 0.0
var prompt_base_position := Vector2.ZERO


func _ready() -> void:
	prompt_base_position = interaction_prompt.position
	interaction_prompt.visible = false
	
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	if not player_inside:
		return
	
	_update_prompt_blink(delta)
	_update_interaction_progress(delta)


func _update_prompt_blink(delta: float) -> void:
	blink_timer += delta
	
	if blink_timer >= blink_interval:
		blink_timer = 0.0
		interaction_prompt.visible = not interaction_prompt.visible


func _update_interaction_progress(delta: float) -> void:
	if Input.is_action_pressed("interact"):
		# Mientras se mantiene E, dejamos visible el prompt para que no parpadee justo durante la acción.
		interaction_prompt.visible = true
		
		progress += delta / required_hold_seconds * 100.0
		progress = clampf(progress, 0.0, 100.0)
		hud.set_building_progress(progress)
		
		if progress >= 100.0:
			complete_interaction()
	else:
		if progress > 0.0:
			progress = 0.0
			hud.set_building_progress(progress)


func complete_interaction() -> void:
	run_state.add_bluff(bluff_reward)
	run_state.current_time_seconds += time_cost_seconds
	
	progress = 0.0
	hud.set_building_progress(progress)
	
	# Reiniciamos el parpadeo para que vuelva a sentirse activo.
	blink_timer = 0.0
	interaction_prompt.visible = true
	_play_prompt_pop()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	
	player_inside = true
	progress = 0.0
	blink_timer = 0.0
	
	interaction_prompt.position = prompt_base_position
	interaction_prompt.visible = true
	
	hud.set_active_building(self, building_title, building_action, building_reward)
	hud.set_building_progress(0.0)
	
	_play_prompt_pop()


func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	
	player_inside = false
	progress = 0.0
	blink_timer = 0.0
	
	interaction_prompt.position = prompt_base_position
	interaction_prompt.visible = false
	
	hud.set_building_progress(0.0)
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
