class_name SnakeHead
extends SnakeBody


@export var wheel_base: float = 100
@export var steering_angle: float = 25
@export var min_power: float = 700
@export var max_power: float = 900
@export var friction: float = -55
@export var drag: float = -0.06
@export var slip_speed: float = 400
@export var traction_fast: float = 2.5
@export var traction_slow: float = 10

var _acceleration := Vector2.ZERO
var _steer_direction: float


func _physics_process(delta):
	if freeze:
		return
	
	_acceleration = Vector2.ZERO
	_get_input()
	_apply_friction(delta)
	_calculate_steering(delta)
	velocity += _acceleration * delta
	move_and_slide()


func _apply_friction(delta):
	if _acceleration == Vector2.ZERO and velocity.length() < 50:
		velocity = Vector2.ZERO
	var friction_force = velocity * friction * delta
	var drag_force = velocity * velocity.length() * drag * delta
	_acceleration += drag_force + friction_force


func _get_input():
	var turn = Input.get_axis("left", "right")
	_steer_direction = turn * deg_to_rad(steering_angle)
	if Input.is_action_pressed("accelerate"):
		_acceleration = transform.x * max_power
	else:
		_acceleration = transform.x * min_power


func _calculate_steering(delta):
	var rear_wheel: Vector2 = position - transform.x * wheel_base / 2.0
	var front_wheel: Vector2 = position + transform.x * wheel_base / 2.0
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(_steer_direction) * delta
	var new_heading := rear_wheel.direction_to(front_wheel)
	var traction := traction_slow
	if velocity.length() > slip_speed:
		traction = traction_fast
	var d := new_heading.dot(velocity.normalized())
	if d > 0:
		velocity = lerp(velocity, new_heading * velocity.length(), traction * delta)
	rotation = new_heading.angle()
