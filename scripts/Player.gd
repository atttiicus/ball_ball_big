class_name Player
extends Ball

signal split_requested
signal mass_ejected(pos: Vector2, dir: Vector2, food_mass: float, color: Color)

var is_dead: bool = false
var joystick: TouchJoystick = null

var last_move_dir: Vector2 = Vector2.RIGHT
var launch_velocity: Vector2 = Vector2.ZERO
var merge_timer: float = 0.0

# 吐出质量计数器（时间窗口限流）
var _eject_count: int = 0
var _eject_window_timer: float = 0.0

func _ready() -> void:
	if ball_color == Color.WHITE:
		ball_color = Color(0.2, 0.6, 1.0)
	if ball_name.is_empty():
		ball_name = "Player"
	mass = PI * GameConfig.PLAYER_SPAWN_RADIUS * GameConfig.PLAYER_SPAWN_RADIUS
	super._ready()
	got_eaten.connect(_on_got_eaten)
	# 炸弹强制分裂：复用 split_requested 通道，Main 统一处理
	split_forced.connect(func(): emit_signal("split_requested"))
	add_to_group("player_cells")
	_setup_joystick()


func _setup_joystick() -> void:
	joystick = TouchJoystick.new()
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)
	canvas.add_child(joystick)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# 吐出质量计数器重置
	_eject_window_timer += delta
	if _eject_window_timer >= GameConfig.PLAYER_EJECT_WINDOW:
		_eject_window_timer = 0.0
		_eject_count = 0

	if Input.is_action_just_pressed("split") and radius >= GameConfig.PLAYER_MIN_SPLIT_RADIUS:
		emit_signal("split_requested")

	if Input.is_action_just_pressed("eject_mass"):
		_try_eject()

	# 分裂后的惯性飞出阶段
	if launch_velocity.length() > 10.0:
		move_and_collide(launch_velocity * delta)
		launch_velocity = launch_velocity.lerp(Vector2.ZERO, GameConfig.PLAYER_SPLIT_LAUNCH_DECEL * delta)
		clamp_to_world()
		merge_timer = maxf(0.0, merge_timer - delta)
		return

	if DisplayServer.is_touchscreen_available() and joystick and joystick.direction != Vector2.ZERO:
		_move_by_dir(joystick.direction, delta)
	else:
		_move_keyboard(delta)

	clamp_to_world()
	merge_timer = maxf(0.0, merge_timer - delta)


func _move_keyboard(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("move_up"):    dir.y -= 1
	if Input.is_action_pressed("move_down"):  dir.y += 1
	if Input.is_action_pressed("move_left"):  dir.x -= 1
	if Input.is_action_pressed("move_right"): dir.x += 1

	if dir != Vector2.ZERO:
		last_move_dir = dir.normalized()
	velocity = dir.normalized() * get_speed() if dir != Vector2.ZERO else Vector2.ZERO
	if dir != Vector2.ZERO:
		move_and_collide(velocity * delta)


func _move_by_dir(dir: Vector2, delta: float) -> void:
	if dir != Vector2.ZERO:
		last_move_dir = dir.normalized()
	velocity = dir.normalized() * get_speed()
	move_and_collide(velocity * delta)


func can_merge_with(other: Player) -> bool:
	return merge_timer <= 0.0 and other.merge_timer <= 0.0


func _try_eject() -> void:
	if radius < GameConfig.PLAYER_EJECT_MIN_RADIUS:
		return
	if _eject_count >= GameConfig.PLAYER_EJECT_MAX:
		return
	var eject_mass: float = mass / GameConfig.PLAYER_EJECT_MASS_RATIO
	var min_mass: float = GameConfig.PLAYER_EJECT_MIN_RADIUS * GameConfig.PLAYER_EJECT_MIN_RADIUS * PI
	if mass - eject_mass < min_mass:
		return
	# 扣除质量
	_apply_mass(mass - eject_mass)
	_eject_count += 1
	# 从球的边缘发射，方向为当前移动方向
	var spawn_pos: Vector2 = global_position + last_move_dir * (radius + GameConfig.FOOD_RADIUS + 2.0)
	emit_signal("mass_ejected", spawn_pos, last_move_dir, eject_mass, ball_color)


func _on_got_eaten(_by: Ball) -> void:
	if is_dead:
		return
	is_dead = true
	remove_from_group("player_cells")
	if SoundManager:
		SoundManager.play_die()
	queue_free()
