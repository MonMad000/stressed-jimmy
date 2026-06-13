extends Node
class_name NegotiationEngine

enum ResultType {
	ACCEPT,
	COUNTER,
	REJECT
}
enum CounterType {
	NONE,
	CASH,
	OBJECT,
	BLUFF
}
enum OpponentProfile {
	SOFT,
	NORMAL,
	HARD,
	VIOLENT
}
enum LuckResult {
	NONE,
	GOOD,
	BAD
}
const OBJECT_VALUE: int = 100
static func evaluate_offer(
	target_debt: int,
	cash_offered: int,
	objects_offered: int,
	bluff_offered: int,
	use_luck: bool,
	current_risk: int,
	opponent_profile: int = OpponentProfile.NORMAL
) -> Dictionary:
	var object_value :int= objects_offered * OBJECT_VALUE
	var paid_value :int= cash_offered + object_value
	var remaining_debt :int= max(target_debt - paid_value, 0)
	
	var uses_bluff : bool = bluff_offered > 0 and remaining_debt > 0
	
	var base_result := _get_base_result(
		target_debt,
		paid_value,
		remaining_debt,
		uses_bluff,
		opponent_profile
	)
	
	var final_result: int = base_result
	var luck_result: int = LuckResult.NONE

	if use_luck and current_risk > 0:
		var luck_data: Dictionary = _apply_luck(base_result)
		final_result = int(luck_data["result"])
		luck_result = int(luck_data["luck_result"])
	
	return _build_result(
		final_result,
		target_debt,
		cash_offered,
		objects_offered,
		bluff_offered,
		remaining_debt,
		uses_bluff,
		use_luck and current_risk > 0,
		luck_result,
		opponent_profile
	)


static func _get_base_result(
	target_debt: int,
	paid_value: int,
	remaining_debt: int,
	uses_bluff: bool,
	opponent_profile: int
) -> int:
	if target_debt <= 0:
		return ResultType.ACCEPT
	
	var coverage := float(paid_value) / float(target_debt)
	
	if remaining_debt <= 0:
		return _roll_profile_result(90, 10, 0,opponent_profile)
	
	if uses_bluff:
		if coverage >= 0.75:
			return _roll_profile_result(65, 30, 5,opponent_profile)
		
		if coverage >= 0.40:
			return _roll_profile_result(35, 45, 20,opponent_profile)
		
		return _roll_profile_result(10, 45, 45,opponent_profile)
	
	# Sin Bluff, una oferta parcial no puede ser aceptada.
	# El rival puede pedir más o rechazar, pero no perdona deuda.
	if coverage >= 0.75:
		return _roll_profile_result(0, 75, 25, opponent_profile)

	if coverage >= 0.40:
		return _roll_profile_result(0, 55, 45, opponent_profile)

	return _roll_profile_result(0, 30, 70, opponent_profile)


static func _roll_result(accept_chance: int, counter_chance: int, reject_chance: int) -> int:
	var roll := randi_range(1, 100)
	
	if roll <= accept_chance:
		return ResultType.ACCEPT
	
	if roll <= accept_chance + counter_chance:
		return ResultType.COUNTER
	
	return ResultType.REJECT
static func _roll_profile_result(
	accept_chance: int,
	counter_chance: int,
	reject_chance: int,
	opponent_profile: int
) -> int:
	var chances: Dictionary = _apply_profile_to_chances(
		accept_chance,
		counter_chance,
		reject_chance,
		opponent_profile
	)
	
	return _roll_result(
		int(chances["accept"]),
		int(chances["counter"]),
		int(chances["reject"])
	)

static func _apply_luck(base_result: int) -> Dictionary:
	var lucky: bool = randi_range(0, 1) == 1
	
	if lucky:
		return {
			"result": _improve_result(base_result),
			"luck_result": LuckResult.GOOD
		}
	
	return {
		"result": _worsen_result(base_result),
		"luck_result": LuckResult.BAD
	}


static func _build_result(
	result_type: int,
	target_debt: int,
	cash_offered: int,
	objects_offered: int,
	bluff_offered: int,
	remaining_debt: int,
	uses_bluff: bool,
	used_luck: bool,
	luck_result: int,
	opponent_profile: int
) -> Dictionary:
	var result_name: String = _get_result_name(result_type)

	var counter_data: Dictionary = _get_counter_data(
		result_type,
		target_debt,
		cash_offered,
		objects_offered,
		bluff_offered,
		remaining_debt,
		uses_bluff
	)

	var message: String = _get_message(
		result_type,
		remaining_debt,
		uses_bluff,
		counter_data
	)
	
	return {
		"result": result_name,
		"message": message,
		"target_debt": target_debt,
		"cash_offered": cash_offered,
		"objects_offered": objects_offered,
		"bluff_offered": bluff_offered,
		"remaining_debt": remaining_debt,
		"uses_bluff": uses_bluff,
		"used_luck": used_luck,
		"luck_result": _get_luck_result_name(luck_result),
		"opponent_profile": _get_profile_name(opponent_profile),
		"counter_type": counter_data["counter_type"],
		"counter_amount": counter_data["counter_amount"],
	}


static func _get_result_name(result_type: int) -> String:
	match result_type:
		ResultType.ACCEPT:
			return "ACCEPT"
		ResultType.COUNTER:
			return "COUNTER"
		ResultType.REJECT:
			return "REJECT"
		_:
			return "UNKNOWN"


static func _get_message(
	result_type: int,
	remaining_debt: int,
	uses_bluff: bool,
	counter_data: Dictionary
) -> String:
	match result_type:
		ResultType.ACCEPT:
			if uses_bluff:
				return "FINE. TOMORROW."
			
			return "DEAL."
		
		ResultType.COUNTER:
			return _get_counter_message(counter_data)
		
		ResultType.REJECT:
			return "GET LOST."
		
		_:
			return "..."
static func _get_counter_data(
	result_type: int,
	target_debt: int,
	cash_offered: int,
	objects_offered: int,
	bluff_offered: int,
	remaining_debt: int,
	uses_bluff: bool
) -> Dictionary:
	if result_type != ResultType.COUNTER:
		return {
			"counter_type": "NONE",
			"counter_amount": 0
		}
	
	if remaining_debt <= 0:
		return {
			"counter_type": "CASH",
			"counter_amount": 10
		}
	
	# Si Jimmy no ofreció Bluff, el rival puede pedir promesa para patear el resto.
	if bluff_offered <= 0:
		return {
			"counter_type": "BLUFF",
			"counter_amount": 1
		}
	
	# Si falta algo que un objeto puede cubrir razonablemente,
	# el rival puede pedir un objeto como garantía.
	if _should_counter_with_object(remaining_debt, objects_offered):
		return {
			"counter_type": "OBJECT",
			"counter_amount": 1
		}
	
	var suggested_cash: int = _get_suggested_cash_counter(remaining_debt)
	
	return {
		"counter_type": "CASH",
		"counter_amount": suggested_cash
	}
static func _should_counter_with_object(remaining_debt: int, objects_offered: int) -> bool:
	# Si ya ofreció objeto, no insistimos con otro por ahora.
	if objects_offered > 0:
		return false
	
	# Si la deuda restante está cerca del valor de un objeto,
	# pedir un objeto tiene sentido.
	if remaining_debt <= OBJECT_VALUE:
		return true
	
	# Si falta un poco más, también puede aceptar objeto como garantía parcial.
	if remaining_debt <= OBJECT_VALUE * 2:
		var roll: int = randi_range(1, 100)
		return roll <= 35
	
	return false
static func _get_suggested_cash_counter(remaining_debt: int) -> int:
	if remaining_debt <= 50:
		return 50
	
	if remaining_debt <= 150:
		return 100
	
	return 150
	
static func _get_counter_message(counter_data: Dictionary) -> String:
	var counter_type: String = str(counter_data["counter_type"])
	var counter_amount: int = int(counter_data["counter_amount"])
	
	match counter_type:
		"CASH":
			return "ADD $" + str(counter_amount) + "."
		
		"OBJECT":
			return "ADD OBJECT."
		
		"BLUFF":
			return "ADD BLUFF."
		
		_:
			return "NOT ENOUGH."
			
static func _apply_profile_to_chances(
	accept_chance: int,
	counter_chance: int,
	reject_chance: int,
	opponent_profile: int
) -> Dictionary:
	var accept: int = accept_chance
	var counter: int = counter_chance
	var reject: int = reject_chance
	
	match opponent_profile:
		OpponentProfile.SOFT:
			accept += 15
			reject -= 15
		
		OpponentProfile.NORMAL:
			pass
		
		OpponentProfile.HARD:
			accept -= 10
			reject += 10
		
		OpponentProfile.VIOLENT:
			accept -= 20
			counter -= 5
			reject += 25
	
	return _normalize_chances(accept, counter, reject)
static func _normalize_chances(
	accept_chance: int,
	counter_chance: int,
	reject_chance: int
) -> Dictionary:
	var accept: int = max(accept_chance, 0)
	var counter: int = max(counter_chance, 0)
	var reject: int = max(reject_chance, 0)
	
	var total: int = accept + counter + reject
	
	if total <= 0:
		return {
			"accept": 0,
			"counter": 0,
			"reject": 100
		}
	
	var normalized_accept: int = int(round(float(accept) / float(total) * 100.0))
	var normalized_counter: int = int(round(float(counter) / float(total) * 100.0))
	var normalized_reject: int = 100 - normalized_accept - normalized_counter
	
	return {
		"accept": normalized_accept,
		"counter": normalized_counter,
		"reject": normalized_reject
	}
	
static func _get_profile_name(opponent_profile: int) -> String:
	match opponent_profile:
		OpponentProfile.SOFT:
			return "SOFT"
		OpponentProfile.NORMAL:
			return "NORMAL"
		OpponentProfile.HARD:
			return "HARD"
		OpponentProfile.VIOLENT:
			return "VIOLENT"
		_:
			return "UNKNOWN"
			
static func _improve_result(result_type: int) -> int:
	match result_type:
		ResultType.REJECT:
			return ResultType.COUNTER
		
		ResultType.COUNTER:
			return ResultType.ACCEPT
		
		ResultType.ACCEPT:
			return ResultType.ACCEPT
		
		_:
			return result_type
			
static func _worsen_result(result_type: int) -> int:
	match result_type:
		ResultType.ACCEPT:
			return ResultType.COUNTER
		
		ResultType.COUNTER:
			return ResultType.REJECT
		
		ResultType.REJECT:
			return ResultType.REJECT
		
		_:
			return result_type
static func _get_luck_result_name(luck_result: int) -> String:
	match luck_result:
		LuckResult.NONE:
			return "NONE"
		
		LuckResult.GOOD:
			return "GOOD"
		
		LuckResult.BAD:
			return "BAD"
		
		_:
			return "UNKNOWN"
