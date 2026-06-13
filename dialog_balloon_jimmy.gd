extends Control

@export var min_bubble_size: Vector2 = Vector2(48, 18)
@export var tail_space: float = 14.0
@export var tail_vertical_ratio: float = 0.5

@onready var bubble: PanelContainer = $Bubble
@onready var text_label: Label = $Bubble/Margin/TextLabel
@onready var tail: Polygon2D = $Tail


func _ready() -> void:
	bubble.position = Vector2.ZERO
	_refresh_balloon()


func set_text(new_text: String) -> void:
	text_label.text = new_text
	call_deferred("_refresh_balloon")


func _refresh_balloon() -> void:
	await get_tree().process_frame
	
	var bubble_min_size: Vector2 = bubble.get_combined_minimum_size()
	
	bubble.size.x = max(bubble_min_size.x, min_bubble_size.x)
	bubble.size.y = max(bubble_min_size.y, min_bubble_size.y)
	
	bubble.position = Vector2.ZERO
	
	# Cola simple hacia la derecha, pegada al borde del globo.
	var tail_height: float = 10.0
	var tail_width: float = 12.0
	var tail_y: float = bubble.size.y * tail_vertical_ratio
	
	tail.position = Vector2(bubble.size.x - 1.0, tail_y)
	tail.polygon = PackedVector2Array([
		Vector2(0, -tail_height * 0.5),
		Vector2(tail_width, 0),
		Vector2(0, tail_height * 0.5)
	])
	
	size = Vector2(
		bubble.size.x + tail_width,
		bubble.size.y
	)
