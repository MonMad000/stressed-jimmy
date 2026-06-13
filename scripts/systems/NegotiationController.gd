extends Node
class_name NegotiationController

@export var target_debt: int = 500
@export var opponent_profile: int = NegotiationEngine.OpponentProfile.NORMAL
@export var attempt_time_cost_seconds: int = 10

const DEAL_RANK_PAID_CLEAN: String = "PAID CLEAN"
const DEAL_RANK_SMALL_DODGE: String = "SMALL DODGE"
const DEAL_RANK_GOOD_DODGE: String = "GOOD DODGE"
const DEAL_RANK_BIG_DODGE: String = "BIG DODGE"
const DEAL_RANK_CRAZY_DEAL: String = "CRAZY DEAL"

var current_cash_offer: int = 0
var current_objects_offer: int = 0
var current_bluff_offer: int = 0
var use_luck: bool = false

var current_debt_id: int = -1
var current_creditor_name: String = "ROCCO"

var is_finished: bool = false
var last_result: Dictionary = {}


func reset_negotiation(
	new_target_debt: int,
	new_profile: int = NegotiationEngine.OpponentProfile.NORMAL,
	new_debt_id: int = -1,
	new_creditor_name: String = "ROCCO"
) -> void:
	target_debt = new_target_debt
	opponent_profile = new_profile
	current_debt_id = new_debt_id
	current_creditor_name = new_creditor_name
	
	current_cash_offer = 0
	current_objects_offer = 0
	current_bluff_offer = 0
	use_luck = false
	
	is_finished = false
	last_result = {}


func set_offer(cash_amount: int, objects_amount: int, bluff_amount: int, wants_luck: bool) -> void:
	current_cash_offer = max(cash_amount, 0)
	current_objects_offer = max(objects_amount, 0)
	current_bluff_offer = max(bluff_amount, 0)
	use_luck = wants_luck


func submit_offer(run_state: Node) -> Dictionary:
	if is_finished:
		return {
			"result": "FINISHED",
			"message": "NEGOTIATION CLOSED."
		}
	
	if not _can_submit_offer(run_state):
		return {
			"result": "INVALID",
			"message": "NOT ENOUGH RESOURCES."
		}
	
	run_state.current_time_seconds += attempt_time_cost_seconds
	
	var result: Dictionary = NegotiationEngine.evaluate_offer(
		target_debt,
		current_cash_offer,
		current_objects_offer,
		current_bluff_offer,
		use_luck,
		run_state.risk,
		opponent_profile
	)
	
	result = _add_deal_reward_data(result)
	last_result = result
	
	if bool(result["used_luck"]):
		run_state.use_risk(1)
	
	match str(result["result"]):
		"ACCEPT":
			_apply_accept(run_state, result)
			run_state.add_score(int(result["score_reward"]))
		
		"REJECT":
			is_finished = true
		
		"COUNTER":
			pass
	
	return result


func _can_submit_offer(run_state: Node) -> bool:
	if current_cash_offer > run_state.cash:
		return false
	
	if current_objects_offer > run_state.objects:
		return false
	
	if current_bluff_offer > run_state.bluff:
		return false
	
	if use_luck and run_state.risk <= 0:
		return false
	
	return true


func _apply_accept(run_state: Node, result: Dictionary) -> void:
	run_state.spend_cash(int(result["cash_offered"]))
	
	for i in range(int(result["objects_offered"])):
		run_state.use_object(1)
	
	if bool(result["uses_bluff"]):
		for i in range(int(result["bluff_offered"])):
			run_state.use_bluff(1)
	
	var future_debt: int = int(result.get("future_debt", 0))
	
	if current_debt_id >= 0:
		_apply_accept_to_real_debt(run_state, future_debt)
	else:
		_apply_accept_to_placeholder_debt(run_state, result)
	
	is_finished = true
	
func _apply_accept_to_real_debt(run_state: Node, future_debt: int) -> void:
	run_state.resolve_debt(current_debt_id)
	
	if future_debt > 0:
		run_state.add_debt(
			current_creditor_name,
			future_debt,
			run_state.current_day + 1,
			run_state.day_start_time_seconds
		)
	
	run_state.refresh_total_debt()


func _apply_accept_to_placeholder_debt(run_state: Node, result: Dictionary) -> void:
	var deferred_debt: int = 0
	
	if bool(result["uses_bluff"]):
		deferred_debt = int(result["remaining_debt"])
	
	run_state.total_debt = deferred_debt
func _get_cash_saved_today(result: Dictionary) -> int:
	var debt_amount: int = int(result["target_debt"])
	var cash_offered: int = int(result["cash_offered"])
	
	return max(debt_amount - cash_offered, 0)


func _get_future_debt(result: Dictionary) -> int:
	if not bool(result["uses_bluff"]):
		return 0
	
	return int(result["remaining_debt"])


func _get_deal_rank(cash_saved_today: int, debt_amount: int) -> String:
	if debt_amount <= 0:
		return DEAL_RANK_PAID_CLEAN
	
	if cash_saved_today <= 0:
		return DEAL_RANK_PAID_CLEAN
	
	var save_ratio: float = float(cash_saved_today) / float(debt_amount)
	
	if save_ratio <= 0.25:
		return DEAL_RANK_SMALL_DODGE
	
	if save_ratio <= 0.50:
		return DEAL_RANK_GOOD_DODGE
	
	if save_ratio <= 0.75:
		return DEAL_RANK_BIG_DODGE
	
	return DEAL_RANK_CRAZY_DEAL


func _get_score_reward(deal_rank: String) -> int:
	match deal_rank:
		DEAL_RANK_PAID_CLEAN:
			return 25
		
		DEAL_RANK_SMALL_DODGE:
			return 100
		
		DEAL_RANK_GOOD_DODGE:
			return 250
		
		DEAL_RANK_BIG_DODGE:
			return 400
		
		DEAL_RANK_CRAZY_DEAL:
			return 700
		
		_:
			return 0


func _add_deal_reward_data(result: Dictionary) -> Dictionary:
	if str(result["result"]) != "ACCEPT":
		result["cash_saved_today"] = 0
		result["future_debt"] = 0
		result["deal_rank"] = ""
		result["score_reward"] = 0
		return result
	
	var debt_amount: int = int(result["target_debt"])
	var cash_saved_today: int = _get_cash_saved_today(result)
	var future_debt: int = _get_future_debt(result)
	var deal_rank: String = _get_deal_rank(cash_saved_today, debt_amount)
	var score_reward: int = _get_score_reward(deal_rank)
	
	result["cash_saved_today"] = cash_saved_today
	result["future_debt"] = future_debt
	result["deal_rank"] = deal_rank
	result["score_reward"] = score_reward
	
	return result
