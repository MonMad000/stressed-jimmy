extends Node2D

@onready var interaction_prompt: Node2D = $InteractionPromptText
@onready var interaction_area: Area2D = $InteractionArea

var player_inside := false
var blink_timer := 0.0
var blink_interval := 0.35


func _ready() -> void:
	interaction_prompt.visible = false
	
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	if player_inside:
		blink_timer += delta
		
		if blink_timer >= blink_interval:
			blink_timer = 0.0
			interaction_prompt.visible = not interaction_prompt.visible


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	
	player_inside = true
	blink_timer = 0.0
	interaction_prompt.visible = true
	_play_prompt_pop()


func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	
	player_inside = false
	interaction_prompt.visible = false


func _play_prompt_pop() -> void:
	var original_position := interaction_prompt.position
	
	interaction_prompt.position = original_position + Vector2(0, 2)
	
	var tween := create_tween()
	tween.tween_property(
		interaction_prompt,
		"position",
		original_position,
		0.08
	)
