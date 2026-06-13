extends CharacterBody2D

enum State {
	RUN_SIDE,
	SIDE_IDLE,
	FRONT_IDLE,
	JUMP_SIDE,
	LAND_SIDE
}

@export var walk_speed: float = 85.0
@export var run_speed: float = 140.0
@export var walk_anim_speed: float = 1.0
@export var run_anim_speed: float = 1.6
@export var gravity: float = 420.0
@export var jump_velocity: float = -155.0
@export var time_to_front_idle: float = 1.2
@export var landing_time: float = 0.02

var was_in_air := false
var landing_timer := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var state: State = State.FRONT_IDLE
var last_right := true
var idle_timer := 0.0
var esta_en_suelo := false


func _ready() -> void:
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_set_state(State.FRONT_IDLE, true)


func _physics_process(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	var is_running := Input.is_action_pressed("run")

	var current_speed := run_speed if is_running else walk_speed

	# Movimiento horizontal
	velocity.x = dir * current_speed

	if landing_timer > 0.0:
		landing_timer -= delta
		sprite.flip_h = not last_right
		_set_state(State.LAND_SIDE)
	else:
		if dir != 0.0:
			_handle_movement(dir, is_running)
		else:
			_handle_idle(delta)

	# Gravedad / salto
	if esta_en_suelo:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
		elif velocity.y > 0.0:
			velocity.y = 10.0
	else:
		velocity.y += gravity * delta

	move_and_slide()

	var estaba_en_aire := was_in_air
	esta_en_suelo = _detectar_suelo()
	was_in_air = not esta_en_suelo

	if estaba_en_aire and esta_en_suelo:
		landing_timer = landing_time
		_set_state(State.LAND_SIDE, true)

	if not esta_en_suelo:
		_set_state(State.JUMP_SIDE)

	position.x = clamp(position.x, 8.0, 312.0)


func _detectar_suelo() -> bool:
	if is_on_floor():
		return true

	for i in get_slide_collision_count():
		var col := get_slide_collision(i)

		if col.get_normal().dot(Vector2.UP) > 0.5:
			return true

	return false


func _handle_movement(dir: float, is_running: bool) -> void:
	last_right = dir > 0.0
	idle_timer = 0.0

	sprite.flip_h = not last_right
	sprite.speed_scale = run_anim_speed+1 if is_running else walk_anim_speed

	_set_state(State.RUN_SIDE)


func _handle_idle(delta: float) -> void:
	idle_timer += delta

	if idle_timer < time_to_front_idle:
		sprite.flip_h = not last_right
		_set_state(State.SIDE_IDLE)
	else:
		sprite.flip_h = false
		_set_state(State.FRONT_IDLE)


func _set_state(new_state: State, force: bool = false) -> void:
	if not force and state == new_state:
		return

	state = new_state

	match state:
		State.RUN_SIDE:
			sprite.speed_scale = 1.0
			sprite.play("run_side")

		State.SIDE_IDLE:
			sprite.speed_scale = 1.0
			sprite.play("side_standby")

		State.FRONT_IDLE:
			sprite.speed_scale = 1.0
			sprite.play("front_standby")

		State.JUMP_SIDE:
			sprite.speed_scale = 1.0
			sprite.animation = "run_side"
			sprite.frame = 1
			sprite.frame_progress = 0.0
			sprite.stop()
			
		State.LAND_SIDE:
			sprite.speed_scale = 1.0
			sprite.animation = "side_standby"
			sprite.frame = 1
			sprite.frame_progress = 0.0
			sprite.stop()
