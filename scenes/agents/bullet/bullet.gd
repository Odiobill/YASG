extends SteeringAgent


signal collided(bullet: SteeringAgent)


@export var spawn_distance: float = 0.0
@export var target_distance: float = 512.0
@export var wall_layer: int = 128
var _destination: Vector2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	
	var frames: PackedVector2Array = []
	for x in 6:
		frames.append(Vector2(x, 0))
	
	animation(frames, 0.1, true)
	
	var forward_direction := velocity.normalized()
	_destination = global_position + forward_direction * target_distance
	global_position = global_position + forward_direction * spawn_distance


func _get_steering() -> Vector2:
	var steering := arrive_to(_destination, 8.0, 32.0)
	if steering == Vector2.ZERO:
		queue_free()
	
	return steering


func _process_collisions(collisions: Array[KinematicCollision2D]) -> void:
	for collision in collisions:
		var collider = collision.get_collider()
		var explode := false
		if collider is SteeringAgent:
			explode = true
			collider.receive_event()
			collided.emit(self)
		elif collider.collision_layer == wall_layer:
			explode = true
			if collider.has_meta("wall_receiver"):
				var node: Node2D = collider.get_meta("wall_receiver")
				node.emit_signal(collider.get_meta("wall_signal"), collider)
			#collider.receive_water()
		
		if explode:
			queue_free()
