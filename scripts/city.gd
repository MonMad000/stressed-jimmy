extends Node2D

@export_range(0.0, 1.0, 0.01) var buildings_brightness: float = 0.78


func _ready() -> void:
	apply_city_brightness()


func apply_city_brightness() -> void:
	for building in get_children():
		apply_brightness_recursive(building, buildings_brightness)


func apply_brightness_recursive(node: Node, brightness: float) -> void:
	if node is Sprite2D:
		node.modulate = Color(brightness, brightness, brightness, 1.0)

	for child in node.get_children():
		apply_brightness_recursive(child, brightness)
