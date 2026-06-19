extends Node2D

@export var shark_name: String = "ROCCO"
@export var target_debt: int = 500
@export var opponent_profile: int = NegotiationEngine.OpponentProfile.NORMAL

@export var blink_interval: float = 0.35
@export var prompt_pop_pixels: float = 2.0
@export var prompt_pop_duration: float = 0.08

@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_prompt: Node2D = $InteractionPromptText

@onready var negotiation_manager = get_tree().current_scene.get_node("NegotiationManager")

var player_inside: bool = false
var blink_timer: float = 0.0
var prompt_base_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	prompt_base_position = interaction_prompt.position
	interaction_prompt.visible = false
	
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	if not player_inside:
		return
	
	_update_prompt_blink(delta)
	
	if Input.is_action_just_pressed("interact"):
		if not negotiation_manager.can_start_negotiation():
			return
		
		start_negotiation()


func start_negotiation() -> void:
	if not negotiation_manager.can_start_negotiation():
		return
	
	interaction_prompt.visible = false
	
	negotiation_manager.start_negotiation_for_creditor(
		shark_name,
		opponent_profile
	)


func _update_prompt_blink(delta: float) -> void:
	blink_timer += delta
	
	if blink_timer >= blink_interval:
		blink_timer = 0.0
		interaction_prompt.visible = not interaction_prompt.visible


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	
	player_inside = true
	blink_timer = 0.0
	
	interaction_prompt.position = prompt_base_position
	interaction_prompt.visible = true
	
	_play_prompt_pop()


func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	
	player_inside = false
	blink_timer = 0.0
	
	interaction_prompt.position = prompt_base_position
	interaction_prompt.visible = false


func _play_prompt_pop() -> void:
	interaction_prompt.position = prompt_base_position + Vector2(0, prompt_pop_pixels)
	
	var tween := create_tween()
	tween.tween_property(
		interaction_prompt,
		"position",
		prompt_base_position,
		prompt_pop_duration
	)
