extends Control
class_name DebtMarker

@onready var marker_label: Label = $MarkerPanel/MarkerLabel
@onready var marker_panel: Panel = $MarkerPanel

var debt_id: int = -1


func setup(new_debt_id: int, creditor_name: String, amount: int, time_text: String = "") -> void:
	debt_id = new_debt_id
	
	var creditor_code: String = _get_creditor_code(creditor_name)
	
	if time_text == "":
		marker_label.text = creditor_code + " $" + str(amount)
	else:
		marker_label.text = creditor_code + " $" + str(amount) + " " + time_text


func set_alert(is_alert: bool) -> void:
	# Por ahora solo cambiamos visibilidad/estilo textual luego.
	# Más adelante podemos cambiar StyleBox o hacer blink.
	if is_alert:
		marker_label.text = "!" + marker_label.text
	else:
		if marker_label.text.begins_with("!"):
			marker_label.text = marker_label.text.substr(1)


func _get_creditor_code(creditor_name: String) -> String:
	var clean_name: String = creditor_name.strip_edges().to_upper()
	
	if clean_name.length() <= 3:
		return clean_name
	
	return clean_name.substr(0, 3)
