class_name Bomb
extends Area2D

const RADIUS := 14.0
const RESPAWN_TIME := 18.0

var _active: bool = true
var _visual_scale: float = 1.0:
	set(v):
		_visual_scale = v
		queue_redraw()


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1  # 检测 Ball（layer=1）

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)

	body_entered.connect(_on_body_entered)

	# 入场动画
	_visual_scale = 0.0
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "_visual_scale", 1.0, 0.4)


func _draw() -> void:
	if not _active and _visual_scale <= 0.01:
		return
	var r := RADIUS * _visual_scale

	# 主体：深灰
	draw_circle(Vector2.ZERO, r, Color(0.18, 0.18, 0.18))

	# 危险环：橙红
	draw_arc(Vector2.ZERO, r * 0.92, 0.0, TAU, 36, Color(1.0, 0.35, 0.0), 2.5)

	# 感叹号
	var bar_h := r * 0.42
	draw_line(Vector2(0.0, -bar_h), Vector2(0.0, r * 0.05), Color(1.0, 0.85, 0.0), 2.5)
	draw_circle(Vector2(0.0, r * 0.28), 2.2, Color(1.0, 0.85, 0.0))

	# 闪烁提示（激活时）
	if _active:
		var pulse := absf(sin(Time.get_ticks_msec() * 0.003))
		var glow := Color(1.0, 0.4, 0.0, pulse * 0.35)
		draw_circle(Vector2.ZERO, r * 1.15, glow)


func _process(_delta: float) -> void:
	if _active:
		queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if not _active:
		return
	if not body is Ball:
		return
	var ball := body as Ball
	if ball.radius < Player.MIN_SPLIT_RADIUS:
		return

	_active = false
	# 爆炸特效
	if is_instance_valid(Ball.effects_node):
		EatEffect.spawn(Ball.effects_node, global_position, Color(1.0, 0.4, 0.0), RADIUS * 3.0)
	# 强制分裂目标球
	ball.emit_signal("split_forced")

	# 消失动画
	var tw := create_tween()
	tw.tween_property(self, "_visual_scale", 0.0, 0.2)

	# 延迟重生
	get_tree().create_timer(RESPAWN_TIME).timeout.connect(_respawn)


func _respawn() -> void:
	_active = true
	# 弹入动画
	_visual_scale = 0.0
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "_visual_scale", 1.0, 0.4)
