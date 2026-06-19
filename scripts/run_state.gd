extends Node2D

const DEBT_STATUS_ACTIVE: String = "ACTIVE"
const DEBT_STATUS_RESOLVED: String = "RESOLVED"

var cash: int = 550
var total_debt: int = 500
var score: int = 0
var current_day: int = 1

var objects: int = 1
var bluff: int = 1
var risk: int = 1

@export var max_risk: int = 2

# Sistema mínimo de deudas individuales.
var debts: Array[Dictionary] = []
var next_debt_id: int = 1

# Tiempo interno en segundos de juego.
var current_time_seconds: int = (18 * 60 * 60) + (40 * 60)

# 60 significa:
# 1 segundo real = 60 segundos de juego = 1 minuto de juego.
@export var game_seconds_per_real_second: float = 60.0

var day_start_time_seconds: int = 18 * 60 * 60
var day_end_time_seconds: int = 24 * 60 * 60

var time_accumulator: float = 0.0


func _ready() -> void:
	initialize_starting_debt()
	#debug_print_debts()


func _process(delta: float) -> void:
	advance_time(delta)


# ============================================================
# TIEMPO
# ============================================================

func advance_time(delta: float) -> void:
	time_accumulator += delta * game_seconds_per_real_second
	
	if time_accumulator >= 1.0:
		var seconds_to_add: int = int(time_accumulator)
		current_time_seconds += seconds_to_add
		time_accumulator -= seconds_to_add
	
	if current_time_seconds >= day_end_time_seconds:
		end_day()


func end_day() -> void:
	current_day += 1
	current_time_seconds = day_start_time_seconds
	time_accumulator = 0.0


func format_time(total_seconds: int) -> String:
	var hours: int = total_seconds / 3600
	var minutes: int = (total_seconds % 3600) / 60
	var seconds: int = total_seconds % 60
	
	return "%02d:%02d:%02d" % [hours, minutes, seconds]


# ============================================================
# RECURSOS
# ============================================================

func add_cash(amount: int) -> void:
	cash += amount


func spend_cash(amount: int) -> bool:
	if cash < amount:
		return false
	
	cash -= amount
	return true


func add_object(amount: int = 1) -> void:
	objects += amount


func use_object(amount: int = 1) -> bool:
	if objects < amount:
		return false
	
	objects -= amount
	return true


func add_bluff(amount: int = 1) -> void:
	bluff += amount


func use_bluff(amount: int = 1) -> bool:
	if bluff < amount:
		return false
	
	bluff -= amount
	return true


func add_risk(amount: int = 1) -> void:
	risk = min(risk + amount, max_risk)


func use_risk(amount: int = 1) -> bool:
	if risk < amount:
		return false
	
	risk -= amount
	return true


func add_score(amount: int) -> void:
	score += max(amount, 0)


func reset_score() -> void:
	score = 0


# ============================================================
# DEUDAS INDIVIDUALES
# ============================================================

func initialize_starting_debt() -> void:
	if not debts.is_empty():
		refresh_total_debt()
		return
	
	if total_debt <= 0:
		return
	
	add_debt(
		"ROCCO",
		total_debt,
		current_day,
		current_time_seconds
	)


func create_debt(
	creditor_name: String,
	amount: int,
	due_day: int,
	due_time_seconds: int
) -> Dictionary:
	var debt: Dictionary = {
		"id": next_debt_id,
		"creditor_name": creditor_name,
		"amount": max(amount, 0),
		"due_day": due_day,
		"due_time_seconds": due_time_seconds,
		"status": DEBT_STATUS_ACTIVE
	}
	
	next_debt_id += 1
	
	return debt


func add_debt(
	creditor_name: String,
	amount: int,
	due_day: int,
	due_time_seconds: int
) -> int:
	if amount <= 0:
		return -1
	
	var debt: Dictionary = create_debt(
		creditor_name,
		amount,
		due_day,
		due_time_seconds
	)
	
	debts.append(debt)
	refresh_total_debt()
	
	print("NEW DEBT: ", debt)
	
	return int(debt["id"])


func resolve_debt(debt_id: int) -> bool:
	for debt in debts:
		if int(debt["id"]) == debt_id:
			debt["status"] = DEBT_STATUS_RESOLVED
			refresh_total_debt()
			
			print("RESOLVED DEBT ID: ", debt_id)
			
			return true
	
	return false


func get_active_debts() -> Array[Dictionary]:
	var active_debts: Array[Dictionary] = []
	
	for debt in debts:
		if str(debt["status"]) == DEBT_STATUS_ACTIVE:
			active_debts.append(debt)
	
	return active_debts


func get_due_debts_now() -> Array[Dictionary]:
	var due_debts: Array[Dictionary] = []
	
	for debt in debts:
		if str(debt["status"]) != DEBT_STATUS_ACTIVE:
			continue
		
		var due_day: int = int(debt["due_day"])
		var due_time: int = int(debt["due_time_seconds"])
		
		if due_day < current_day:
			due_debts.append(debt)
			continue
		
		if due_day == current_day and due_time <= current_time_seconds:
			due_debts.append(debt)
	
	return due_debts


func refresh_total_debt() -> void:
	var total: int = 0
	
	for debt in debts:
		if str(debt["status"]) == DEBT_STATUS_ACTIVE:
			total += int(debt["amount"])
	
	total_debt = total


func debug_print_debts() -> void:
	print("")
	print("=== DEBTS ===")
	
	for debt in debts:
		print(debt)
	
	print("Total debt: ", total_debt)

func get_active_debt_by_creditor(creditor_name: String) -> Dictionary:
	for debt in debts:
		if str(debt["status"]) != DEBT_STATUS_ACTIVE:
			continue
		
		if str(debt["creditor_name"]) == creditor_name:
			return debt
	
	return {}
