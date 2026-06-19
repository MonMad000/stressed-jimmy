extends Node

@onready var run_state = $"../RunState"
@onready var hud = $"../HUD"
@onready var negotiation_controller: NegotiationController = $"../NegotiationController"

var is_negotiating: bool = false

var cash_step: int = 50
var current_cash_offer: int = 0
var current_objects_offer: int = 0
var current_bluff_offer: int = 0
var use_luck: bool = false
var input_lock_time: float = 0.0
var start_lock_time: float = 0.0

func start_negotiation(
	target_debt: int = 500,
	profile: int = NegotiationEngine.OpponentProfile.NORMAL,
	debt_id: int = -1,
	creditor_name: String = "ROCCO"
) -> void:
	if not can_start_negotiation():
		return
	
	is_negotiating = true
	input_lock_time = 0.15
	
	current_cash_offer = 0
	current_objects_offer = 0
	current_bluff_offer = 0
	use_luck = false
	
	negotiation_controller.reset_negotiation(
		target_debt,
		profile,
		debt_id,
		creditor_name
	)
	
	hud.show_negotiation_screen()
	hud.set_opponent_message("I WANT MY $" + str(target_debt) + " BACK!")
	hud.set_offer_hint("[W/S] CASH  [O] OBJ  [B] BLUFF  [L] LUCK")
	
	_update_offer_display()

func _ready() -> void:
	pass
	#start_negotiation(500, NegotiationEngine.OpponentProfile.NORMAL)
func _process(_delta: float) -> void:
	if start_lock_time > 0.0:
		start_lock_time -= _delta
	if not is_negotiating:
		return
	if input_lock_time > 0.0:
		input_lock_time -= _delta
		return
	if Input.is_action_just_pressed("bet_up"):
		_increase_cash_offer()
	
	if Input.is_action_just_pressed("bet_down"):
		_decrease_cash_offer()
	
	if Input.is_action_just_pressed("offer_object"):
		_toggle_object_offer()
	
	if Input.is_action_just_pressed("offer_bluff"):
		_toggle_bluff_offer()
	
	if Input.is_action_just_pressed("offer_luck"):
		_toggle_luck_offer()
	
	if Input.is_action_just_pressed("interact"):
		print("INTERACT DETECTED INSIDE NEGOTIATION")
		_submit_offer()
	
	if Input.is_action_just_pressed("cancel"):
		_end_negotiation("MAYBE LATER.")


func _increase_cash_offer() -> void:
	current_cash_offer += cash_step
	
	if current_cash_offer > run_state.cash:
		current_cash_offer = run_state.cash
	
	_update_offer_display()


func _decrease_cash_offer() -> void:
	current_cash_offer -= cash_step
	
	if current_cash_offer < 0:
		current_cash_offer = 0
	
	_update_offer_display()


func _toggle_object_offer() -> void:
	if current_objects_offer > 0:
		current_objects_offer = 0
	else:
		if run_state.objects > 0:
			current_objects_offer = 1
	
	_update_offer_display()


func _toggle_bluff_offer() -> void:
	if current_bluff_offer > 0:
		current_bluff_offer = 0
	else:
		if run_state.bluff > 0:
			current_bluff_offer = 1
	
	_update_offer_display()


func _toggle_luck_offer() -> void:
	if run_state.risk <= 0:
		use_luck = false
	else:
		use_luck = not use_luck
	
	_update_offer_display()


func _submit_offer() -> void:
	print("SUBMIT OFFER CALLED")
	print("Offer cash: ", current_cash_offer)
	print("Offer obj: ", current_objects_offer)
	print("Offer bluff: ", current_bluff_offer)
	print("Use luck: ", use_luck)
	negotiation_controller.set_offer(
		current_cash_offer,
		current_objects_offer,
		current_bluff_offer,
		use_luck
	)
	
	var result: Dictionary = negotiation_controller.submit_offer(run_state)
	
	hud.set_opponent_message(str(result["message"]))
	
	if str(result["result"]) == "INVALID":
		return
	
	if str(result["result"]) == "ACCEPT":
		_end_negotiation(str(result["message"]))
		return
	
	if str(result["result"]) == "REJECT":
		_end_negotiation(str(result["message"]))
		return
	
	if str(result["result"]) == "COUNTER":
		use_luck = false
		_update_offer_display()


func _end_negotiation(final_message: String) -> void:
	print("END NEGOTIATION CALLED: ", final_message)
	
	is_negotiating = false
	start_lock_time = 0.25
	
	hud.set_opponent_message(final_message)
	hud.set_offer_hint("[E] TALK")
	
	# Por ahora no salimos automáticamente de la pantalla.
	# Dejamos el mensaje visible para leerlo.
	# Más adelante podemos volver al HUD normal con un delay.


func _update_offer_display() -> void:
	hud.set_offer_text(
		current_cash_offer,
		current_objects_offer,
		current_bluff_offer,
		use_luck
	)
	
func start_negotiation_for_creditor(
	creditor_name: String,
	profile: int = NegotiationEngine.OpponentProfile.NORMAL
) -> void:
	var debt: Dictionary = run_state.get_active_debt_by_creditor(creditor_name)
	
	if debt.is_empty():
		hud.show_negotiation_screen()
		hud.set_opponent_message("YOU DON'T OWE ME.")
		hud.set_offer_text(0, 0, 0, false)
		hud.set_offer_hint("[Q] LEAVE")
		is_negotiating = false
		return
	
	var debt_amount: int = int(debt["amount"])
	var debt_id: int = int(debt["id"])
	var real_creditor_name: String = str(debt["creditor_name"])
	
	start_negotiation(
		debt_amount,
		profile,
		debt_id,
		real_creditor_name
	)
func can_start_negotiation() -> bool:
	return not is_negotiating and start_lock_time <= 0.0
