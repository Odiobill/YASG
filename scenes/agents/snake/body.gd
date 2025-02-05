class_name SnakeBody
extends SteeringBehavior


@export var distance_threshold: float = 4.0
@export var slow_radius: float = 96.0
@export var target: SnakeBody
@export var follower_target: Node2D
@export var follower_line_to: Node2D
@export var line: Line2D
@onready var sprite_2d: Sprite2D = $Sprite2D


func damage():
	var color := self_modulate
	var tween := get_tree().create_tween()
	tween.tween_property(sprite_2d, "self_modulate", Color.RED, 0.5)
	tween.tween_property(sprite_2d, "self_modulate", color, 0.4)


func _process_exit(_delta):
	if target and line:
		line.set_point_position(1, to_local(target.follower_line_to.global_position))


func _get_steering() -> Vector2:
	if target == null:
		return Vector2.ZERO
	
	return arrive_to(target.follower_target.global_position, distance_threshold, slow_radius)
