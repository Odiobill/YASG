extends SteeringAgent


enum State
{
	FLIGHT,
	LANDING,
	WALKING,
	SCOUT,
	EATING,
}

#const FRAME_LANDING := Vector2i(0, 1)
const FRAME_LANDING := Vector2i(0, 2)

@export var consumable_land_distance: float = 0.0
@export_range(0.0, 1.0) var consumable_min_value: float = 0.5
@export var origin_position := Vector2.ZERO
@export var constrain_radius: float
@export var wander_circle_distance: float = 512.0
@export var wander_circle_radius: float = 32.0
@export var angle_change_range: float = 0.2
@export var eat_amount: float = 8.0
@export_range(0.0, 1.0) var eat_until: float = 0.7
var _flap_frames: PackedVector2Array
var _walk_frames: PackedVector2Array
var _peck_frames: PackedVector2Array
var _target_consumable: Consumable
var _land_position: Vector2


# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	
	#if origin_position != Vector2.ZERO:
		#global_position = origin_position
	#
	_flap_frames = []
	#for x in 10:
	for x in 4:
		_flap_frames.append(Vector2(x, 0))
	
	_walk_frames = []
	#for x in 8:
	for x in 4:
		_walk_frames.append(Vector2(x, 1))
	
	_peck_frames = []
	#for x in 5:
	for x in 4:
		_peck_frames.append(Vector2(x, 2))
	
	_to_state(State.FLIGHT)


func receive_event(_what: int = 0, _data: Variant = null) -> void:
	print(name + " got shot")


func _get_steering() -> Vector2:
	match _state:
		State.FLIGHT:
			return \
				wander(wander_circle_distance, wander_circle_radius, angle_change_range) + \
				circle_constrain(constrain_radius, 3.0, true, origin_position)
		
		State.LANDING:
			return arrive_to(_land_position, 32.0)
		
		State.WALKING:
			if is_instance_valid(_target_consumable):
				return arrive_to(_target_consumable.global_position, 32.0, 128.0)
		
		State.EATING:
			return Vector2.ZERO
	
	return Vector2.ZERO


func _process_state(state: State, _wait_time: float) -> void:
	match state:
		State.FLIGHT:
			if not is_active:
				var list := focus_list
				if list.size() > 0:
					var reacheable: Array[Node2D] = []
					for node: Node2D in list:
						if is_instance_valid(node) and node is Consumable:
							if node.get_meta("seagull_wants", false) and (node.value < 0 or node.value > consumable_min_value * node.max_value):
								reacheable.append(node)
					if reacheable.size() > 0:
						if reacheable.size() > 1:
							reacheable.shuffle()
						_target_consumable = reacheable[0] as Consumable
						_land_position = get_position_at_radius(consumable_land_distance) + _target_consumable.global_position
						_to_state(State.LANDING)
					else:
						activity(3.0 + randf_range(-0.5, 0.5))
				else:
					activity(3.0 + randf_range(-0.5, 0.5))
		
		State.LANDING:
			if global_position.distance_to(_land_position) <= 48.0:
				_to_state(State.WALKING)
		
		State.WALKING:
			if not is_instance_valid(_target_consumable):
				_to_state(State.FLIGHT)
			elif global_position.distance_to(_target_consumable.global_position) <= 48.0:
				_to_state(State.EATING)
		
		State.EATING:
			var list := focus_list
			if list.size() > 0:
				var reacheable: Array[Node2D] = []
				for node: Node2D in list:
					if is_instance_valid(node) and node is SnakeHead:
						reacheable.append(node)
				if reacheable.size() > 0:
					_to_state(State.FLIGHT)
					return
			
			if not is_active and is_instance_valid(_target_consumable):
				var eat_until_value: float = _target_consumable.max_value * eat_until
				_target_consumable.consume(eat_amount)
				if _target_consumable.value > eat_until_value:
					activity(2.0 + randf_range(-0.5, 0.5))
				else:
					_target_consumable = null
					_to_state(State.FLIGHT)


func _to_state(state: State) -> void:
	match state:
		State.FLIGHT:
			animation(_flap_frames, 0.15, true)
			focus = true
			activity(3.0 + randf_range(-0.5, 0.5))
		
		State.LANDING:
			frame(FRAME_LANDING)
			focus = false
		
		State.WALKING:
			animation(_walk_frames, 0.15, true)
		
		State.EATING:
			animation(_peck_frames, 0.25, true, randi_range(2, 5))
			focus = true
			activity(2.0 + randf_range(-0.5, 0.5))
	
	_state = state
