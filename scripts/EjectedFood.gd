class_name EjectedFood
extends Food

var _velocity: Vector2 = Vector2.ZERO
const DECEL := 5.0


func _process(delta: float) -> void:
	if _velocity.length() > 5.0:
		position += _velocity * delta
		_velocity = _velocity.lerp(Vector2.ZERO, DECEL * delta)
		queue_redraw()
