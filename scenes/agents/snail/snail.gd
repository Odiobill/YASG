extends SteeringAgent


signal crashed(snail: SteeringAgent)


enum State
{
	HIDDEN,
	HIDE,
	SHOW,
	MOVE,
	DIE,
}

#const FRAME_HIDDEN := Vector2(9, 2)
#const FRAME_DEATH := Vector2(4, 1)
const FRAME_HIDDEN := Vector2(3, 2)
const FRAME_DEATH := Vector2(3, 1)

@export var destination_point := Vector2.ZERO
@export var wander_circle_distance: float = 512.0
@export var wander_circle_radius: float = 32.0
@export var angle_change_range: float = 0.2
@export var target_max_distance: float = 24.0
var _frames_hide: PackedVector2Array
var _frames_show: PackedVector2Array
var _frames_move: PackedVector2Array
var _frames_die: PackedVector2Array

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	
	#if origin_position != Vector2.ZERO:
		#global_position = origin_position
	#
	_frames_hide = []
	#for x in 10:
	for x in 4:
		_frames_hide.append(Vector2(x, 2))
	
	_frames_show = []
	#for x in 10:
	for x in 4:
		_frames_show.append(Vector2(x, 2))
	_frames_show.reverse()
	
	_frames_move = []
	#for x in 20:
	for x in 4:
		_frames_move.append(Vector2(x, 0))
	
	_frames_die = []
	#for x in 5:
	for x in 4:
		_frames_die.append(Vector2(x, 1))
	
	_to_state(State.HIDDEN)


func receive_event(_what: int = 0, _data: Variant = null) -> void:
	if _state != State.DIE:
		_to_state(State.HIDE)


func _to_state(state: State) -> void:
	match state:
		State.HIDDEN:
			frame(FRAME_HIDDEN)
			activity(3.0 + randf_range(-1.5, 1.5))
		
		State.SHOW:
			animation(_frames_show, 0.1)
			activity(1.0)
		
		State.MOVE:
			animation(_frames_move, 0.1, true)
			activity(3.0)
		
		State.HIDE:
			animation(_frames_hide, 0.1)
			activity(2.0)
	
		State.DIE:
			animation(_frames_die, 0.1)
			activity(0.5)
			collision_layer = 0
			collision_mask = 0
		
	_state = state


func _process_state(state: State, _wait_time: float) -> void:
	match state:
		State.HIDDEN:
			if not is_active:
				_to_state(State.SHOW)
		
		State.SHOW:
			if not is_active:
				_to_state(State.MOVE)
		
		State.MOVE:
			if not is_active:
				if global_position.distance_to(destination_point) < target_max_distance:
					_to_state(State.HIDE)
				else:
					activity(2.0)
		
		State.HIDE:
			if not is_active:
				if global_position.distance_to(destination_point) < target_max_distance:
					activity(60.0)
				else:
					_to_state(State.HIDDEN)
		
		State.DIE:
			if not is_active:
				crashed.emit(self)


func _get_steering() -> Vector2:
	match _state:
		State.MOVE:
			return \
				(wander(wander_circle_distance, wander_circle_radius, angle_change_range) + \
				arrive_to(destination_point, 32.0) * 2.0 \
				) / 3.0
	
	return Vector2.ZERO


func _process_collisions(collisions: Array[KinematicCollision2D]) -> void:
	for collision in collisions:
		var collider = collision.get_collider()
		if collider is SnakeHead:
			_to_state(State.DIE)
			break
