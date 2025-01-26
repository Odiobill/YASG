class_name SteeringBehavior
extends CharacterBody2D


@export var max_speed: float = 1000.0
@export var rotation_speed: float = 50.0
@export var freeze := false
var _wander_angle: float = 0.0 # This stores the current angle for wandering


# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _physics_process(delta) -> void:
	if freeze:
		return
	
	velocity = _limit_velocity(_get_steering())
	move_and_slide()
	
	if rotation_speed > 0 and velocity.length() > 0.1:
		rotation = lerp_angle(rotation, velocity.angle(), rotation_speed * delta)
	
	var collisions: Array[KinematicCollision2D] = []
	for i: int in get_slide_collision_count():
		collisions.append(get_slide_collision(i))
	_process_collisions(collisions)

	_process_exit(delta)


func arrive_to(target_position: Vector2, distance_threshold: float = 0.0, slow_radius: float = 0.0) -> Vector2:
	var target_distance := global_position.distance_to(target_position)
	if target_distance < distance_threshold:
		return Vector2.ZERO
	
	var desired_velocity := (target_position - global_position).normalized() * max_speed
	if target_distance < slow_radius:
		desired_velocity *= target_distance / slow_radius
	
	return desired_velocity


func flee(scary: Array[Vector2], flee_radius: float, stop_distance: float) -> Vector2:
	var desired_velocity := Vector2.ZERO
	
	for point in scary:
		var distance_to_point := global_position.distance_to(point)
		if distance_to_point < flee_radius:
			var flee_force = (global_position - point).normalized() * max(stop_distance - distance_to_point, 0)
			desired_velocity += flee_force
	
	return desired_velocity


func circle_constrain(radius: float, force_multiplier: float = 1.0, stay_inside := true, origin := Vector2.ZERO) -> Vector2:
	var desired_velocity := Vector2.ZERO
	
	var to_origin_position := global_position - origin
	var distance_from_origin := to_origin_position.length()
	
	if stay_inside:
		if distance_from_origin > radius:
			desired_velocity -= to_origin_position.normalized() * (distance_from_origin - radius)
	else:
		if distance_from_origin < radius:
			desired_velocity += to_origin_position.normalized() * (radius - distance_from_origin)
	
	desired_velocity *= force_multiplier
	
	return desired_velocity


func wander(wander_circle_distance: float = 256.0, wander_circle_radius: float = 32.0, angle_change_range: float = 0.3) -> Vector2:
	var forward_direction := velocity.normalized()
	var wander_circle_donut_position := global_position + forward_direction * wander_circle_distance
	
	# Add a small random angle change to the wander angle for more erratic movement
	_wander_angle += randf_range(-angle_change_range, angle_change_range)
	var wander_offset = Vector2(cos(_wander_angle), sin(_wander_angle)) * wander_circle_radius
	var wander_target = wander_circle_donut_position + wander_offset
	
	# Calculate the steering force towards the wander target
	var desired_velocity = (wander_target - global_position).normalized() * max_speed
		
	return desired_velocity


func nodes_to_positions(nodes: Array[Node2D]) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for node: Node2D in nodes:
		points.append(node.global_position)
	
	return points


func _limit_velocity(desired_velocity: Vector2) -> Vector2:
	if desired_velocity.length() > max_speed:
		desired_velocity = desired_velocity.normalized() * max_speed
	
	return desired_velocity


func _get_steering() -> Vector2:
	return Vector2.ZERO


func _process_collisions(_collisions: Array[KinematicCollision2D]) -> void:
	pass


func _process_exit(_delta) -> void:
	pass
