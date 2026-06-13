extends Node

@onready var run_state = $"../RunState"
@onready var negotiation_controller: NegotiationController = $"../NegotiationController"

var errors_found: int = 0


func _ready() -> void:
	run_all_negotiation_tests()


func run_all_negotiation_tests() -> void:
	errors_found = 0
	
	print("")
	print("====================================")
	print("=== NEGOTIATION BIG TEST STARTED ===")
	print("====================================")
	
	test_manual_cases()
	test_repeated_distribution_cases()
	test_resource_application_cases()
	test_luck_cases()
	test_impossible_resource_cases()
	
	print("")
	print("====================================")
	print("=== NEGOTIATION BIG TEST FINISHED ===")
	print("Errors found: ", errors_found)
	print("====================================")


func reset_run_state_for_test() -> void:
	run_state.cash = 1000
	run_state.objects = 2
	run_state.bluff = 2
	run_state.risk = 2
	run_state.total_debt = 500
	run_state.score = 0
	run_state.current_time_seconds = 0


func log_error(message: String, result: Dictionary = {}) -> void:
	errors_found += 1
	print("")
	print("!!! ERROR: ", message)
	if not result.is_empty():
		print(result)


func assert_condition(condition: bool, message: String, result: Dictionary = {}) -> void:
	if not condition:
		log_error(message, result)


# ============================================================
# TESTS MANUALES PUNTUALES
# ============================================================

func test_manual_cases() -> void:
	print("")
	print("=== MANUAL CASES ===")
	
	test_single_case(
		"FULL PAYMENT",
		500,
		500,
		0,
		0,
		false,
		NegotiationEngine.OpponentProfile.NORMAL
	)
	
	test_single_case(
		"PARTIAL WITHOUT BLUFF",
		500,
		350,
		0,
		0,
		false,
		NegotiationEngine.OpponentProfile.NORMAL
	)
	
	test_single_case(
		"PARTIAL WITH BLUFF",
		500,
		350,
		0,
		1,
		false,
		NegotiationEngine.OpponentProfile.NORMAL
	)
	
	test_single_case(
		"OBJECT + BLUFF",
		500,
		250,
		1,
		1,
		false,
		NegotiationEngine.OpponentProfile.NORMAL
	)
	
	test_single_case(
		"BAD OFFER VIOLENT",
		500,
		50,
		0,
		0,
		false,
		NegotiationEngine.OpponentProfile.VIOLENT
	)


func test_single_case(
	case_name: String,
	target_debt: int,
	cash_offer: int,
	objects_offer: int,
	bluff_offer: int,
	use_luck: bool,
	profile: int
) -> void:
	reset_run_state_for_test()
	
	negotiation_controller.reset_negotiation(target_debt, profile)
	negotiation_controller.set_offer(cash_offer, objects_offer, bluff_offer, use_luck)
	
	var result: Dictionary = negotiation_controller.submit_offer(run_state)
	
	print("")
	print("--- ", case_name, " ---")
	print(result)
	print("Cash: ", run_state.cash, " Debt: ", run_state.total_debt, " Obj: ", run_state.objects, " Bluff: ", run_state.bluff, " Risk: ", run_state.risk, " Score: ", run_state.score, " Time: ", run_state.current_time_seconds)
	validate_result_rules(result, target_debt)


# ============================================================
# TESTS DE DISTRIBUCIÓN
# ============================================================

func test_repeated_distribution_cases() -> void:
	print("")
	print("=== DISTRIBUTION CASES ===")
	
	repeated_case(
		"PARTIAL WITHOUT BLUFF SHOULD NEVER ACCEPT",
		100,
		500,
		350,
		0,
		0,
		false,
		NegotiationEngine.OpponentProfile.NORMAL
	)
	
	repeated_case(
		"PARTIAL WITH BLUFF NORMAL",
		100,
		500,
		350,
		0,
		1,
		false,
		NegotiationEngine.OpponentProfile.NORMAL
	)
	
	repeated_case(
		"PARTIAL WITH BLUFF SOFT",
		100,
		500,
		350,
		0,
		1,
		false,
		NegotiationEngine.OpponentProfile.SOFT
	)
	
	repeated_case(
		"PARTIAL WITH BLUFF VIOLENT",
		100,
		500,
		350,
		0,
		1,
		false,
		NegotiationEngine.OpponentProfile.VIOLENT
	)


func repeated_case(
	case_name: String,
	times: int,
	target_debt: int,
	cash_offer: int,
	objects_offer: int,
	bluff_offer: int,
	use_luck: bool,
	profile: int
) -> void:
	var accept_count: int = 0
	var counter_count: int = 0
	var reject_count: int = 0
	
	for i in range(times):
		reset_run_state_for_test()
		
		negotiation_controller.reset_negotiation(target_debt, profile)
		negotiation_controller.set_offer(cash_offer, objects_offer, bluff_offer, use_luck)
		
		var result: Dictionary = negotiation_controller.submit_offer(run_state)
		
		match str(result["result"]):
			"ACCEPT":
				accept_count += 1
			"COUNTER":
				counter_count += 1
			"REJECT":
				reject_count += 1
		
		validate_result_rules(result, target_debt)
	
	print("")
	print("--- ", case_name, " ---")
	print("ACCEPT: ", accept_count)
	print("COUNTER: ", counter_count)
	print("REJECT: ", reject_count)


# ============================================================
# TESTS DE APLICACIÓN DE RECURSOS
# ============================================================

func test_resource_application_cases() -> void:
	print("")
	print("=== RESOURCE APPLICATION CASES ===")
	
	# Pago completo debería consumir cash y cerrar deuda.
	run_until_accept_or_limit(
		"FULL PAYMENT RESOURCE TEST",
		500,
		500,
		0,
		0,
		false,
		NegotiationEngine.OpponentProfile.NORMAL,
		20
	)
	
	# Cash + Bluff debería consumir cash, bluff, y dejar deuda restante.
	run_until_accept_or_limit(
		"CASH + BLUFF RESOURCE TEST",
		500,
		400,
		0,
		1,
		false,
		NegotiationEngine.OpponentProfile.SOFT,
		20
	)
	
	# Cash + Object + Bluff debería consumir cash, object y bluff si acepta.
	run_until_accept_or_limit(
		"CASH + OBJECT + BLUFF RESOURCE TEST",
		500,
		250,
		1,
		1,
		false,
		NegotiationEngine.OpponentProfile.SOFT,
		20
	)


func run_until_accept_or_limit(
	case_name: String,
	target_debt: int,
	cash_offer: int,
	objects_offer: int,
	bluff_offer: int,
	use_luck: bool,
	profile: int,
	max_attempts: int
) -> void:
	print("")
	print("--- ", case_name, " ---")
	
	for i in range(max_attempts):
		reset_run_state_for_test()
		
		negotiation_controller.reset_negotiation(target_debt, profile)
		negotiation_controller.set_offer(cash_offer, objects_offer, bluff_offer, use_luck)
		
		var result: Dictionary = negotiation_controller.submit_offer(run_state)
		
		if str(result["result"]) == "ACCEPT":
			print("Accepted on try ", i + 1)
			print(result)
			print("Cash: ", run_state.cash, " Debt: ", run_state.total_debt, " Obj: ", run_state.objects, " Bluff: ", run_state.bluff, " Risk: ", run_state.risk, " Score: ", run_state.score, " Time: ", run_state.current_time_seconds)
			validate_accept_application(result)
			return
	
	print("No ACCEPT after ", max_attempts, " tries. This can happen with probability.")


func validate_accept_application(result: Dictionary) -> void:
	if str(result["result"]) != "ACCEPT":
		return
	
	var cash_offered: int = int(result["cash_offered"])
	var objects_offered: int = int(result["objects_offered"])
	var bluff_offered: int = int(result["bluff_offered"])
	var remaining_debt: int = int(result["remaining_debt"])
	var uses_bluff: bool = bool(result["uses_bluff"])
	var score_reward: int = int(result.get("score_reward", 0))
	
	assert_condition(
		run_state.cash == 1000 - cash_offered,
		"ACCEPT did not consume correct cash.",
		result
	)
	
	assert_condition(
		run_state.objects == 2 - objects_offered,
		"ACCEPT did not consume correct objects.",
		result
	)
	
	if uses_bluff:
		assert_condition(
			run_state.bluff == 2 - bluff_offered,
			"ACCEPT with Bluff did not consume Bluff.",
			result
		)
		
		assert_condition(
			run_state.total_debt == remaining_debt,
			"ACCEPT with Bluff did not defer remaining debt correctly.",
			result
		)
	else:
		assert_condition(
			run_state.bluff == 2,
			"ACCEPT without real Bluff consumed Bluff incorrectly.",
			result
		)
		
		assert_condition(
			run_state.total_debt == 0,
			"ACCEPT without Bluff should resolve debt to 0.",
			result
		)
	
	assert_condition(
		run_state.score == score_reward,
		"ACCEPT did not add correct score reward.",
		result
	)

# ============================================================
# TESTS DE LUCK
# ============================================================

func test_luck_cases() -> void:
	print("")
	print("=== LUCK CASES ===")
	
	var good_count: int = 0
	var bad_count: int = 0
	var none_count: int = 0
	
	for i in range(50):
		reset_run_state_for_test()
		
		negotiation_controller.reset_negotiation(
			500,
			NegotiationEngine.OpponentProfile.NORMAL
		)
		
		negotiation_controller.set_offer(
			250,
			0,
			1,
			true
		)
		
		var result: Dictionary = negotiation_controller.submit_offer(run_state)
		
		match str(result["luck_result"]):
			"GOOD":
				good_count += 1
			"BAD":
				bad_count += 1
			"NONE":
				none_count += 1
		
		assert_condition(
			bool(result["used_luck"]) == true,
			"Luck was requested but result says used_luck false.",
			result
		)
		
		assert_condition(
			run_state.risk == 1,
			"Luck did not consume exactly 1 Risk.",
			result
		)
	
	print("Luck GOOD: ", good_count)
	print("Luck BAD: ", bad_count)
	print("Luck NONE: ", none_count)


# ============================================================
# TESTS DE RECURSOS IMPOSIBLES
# ============================================================

func test_impossible_resource_cases() -> void:
	print("")
	print("=== IMPOSSIBLE RESOURCE CASES ===")
	
	reset_run_state_for_test()
	run_state.cash = 100
	
	negotiation_controller.reset_negotiation(500, NegotiationEngine.OpponentProfile.NORMAL)
	negotiation_controller.set_offer(500, 0, 0, false)
	
	var result_cash: Dictionary = negotiation_controller.submit_offer(run_state)
	print("Not enough cash result: ", result_cash)
	
	assert_condition(
		str(result_cash["result"]) == "INVALID",
		"Expected INVALID when offering more cash than available.",
		result_cash
	)
	
	reset_run_state_for_test()
	run_state.objects = 0
	
	negotiation_controller.reset_negotiation(500, NegotiationEngine.OpponentProfile.NORMAL)
	negotiation_controller.set_offer(0, 1, 0, false)
	
	var result_obj: Dictionary = negotiation_controller.submit_offer(run_state)
	print("Not enough object result: ", result_obj)
	
	assert_condition(
		str(result_obj["result"]) == "INVALID",
		"Expected INVALID when offering object without objects.",
		result_obj
	)
	
	reset_run_state_for_test()
	run_state.bluff = 0
	
	negotiation_controller.reset_negotiation(500, NegotiationEngine.OpponentProfile.NORMAL)
	negotiation_controller.set_offer(0, 0, 1, false)
	
	var result_bluff: Dictionary = negotiation_controller.submit_offer(run_state)
	print("Not enough bluff result: ", result_bluff)
	
	assert_condition(
		str(result_bluff["result"]) == "INVALID",
		"Expected INVALID when offering Bluff without Bluff.",
		result_bluff
	)
	
	reset_run_state_for_test()
	run_state.risk = 0
	
	negotiation_controller.reset_negotiation(500, NegotiationEngine.OpponentProfile.NORMAL)
	negotiation_controller.set_offer(100, 0, 1, true)
	
	var result_luck: Dictionary = negotiation_controller.submit_offer(run_state)
	print("Not enough risk/luck result: ", result_luck)
	
	assert_condition(
		str(result_luck["result"]) == "INVALID",
		"Expected INVALID when using Luck without Risk.",
		result_luck
	)


# ============================================================
# VALIDACIONES GENERALES
# ============================================================

func validate_result_rules(result: Dictionary, _target_debt: int) -> void:
	var result_type: String = str(result["result"])
	var remaining_debt: int = int(result.get("remaining_debt", 0))
	var uses_bluff: bool = bool(result.get("uses_bluff", false))
	
	# Regla importante:
	# Si queda deuda y no hay Bluff, no debería aceptar.
	if result_type == "ACCEPT" and remaining_debt > 0 and not uses_bluff:
		log_error(
			"ACCEPT happened with remaining debt and no Bluff. This should not happen.",
			result
		)
	
	# COUNTER debería traer counter_type útil.
	if result_type == "COUNTER":
		assert_condition(
			str(result.get("counter_type", "NONE")) != "NONE",
			"COUNTER came with counter_type NONE.",
			result
		)
	
	# REJECT no debería traer counter.
	if result_type == "REJECT":
		assert_condition(
			str(result.get("counter_type", "NONE")) == "NONE",
			"REJECT came with counter_type not NONE.",
			result
		)
