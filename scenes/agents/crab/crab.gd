extends SteeringAgent


signal catched(crab: SteeringAgent)


enum State
{
	IDLE,
	WANDER,
	GOTO,
	SCOUT,
	HUNT,
	RETRIEVE,
	EAT,
	FLEE,
}

@export var wander_circle_distance: float = 256.0
@export var wander_circle_radius: float = 32.0
@export var angle_change_range: float = 0.3
@export var donut_inner_radius: float = 0.0
@export var donut_outer_radius: float = 0.0
@export var scout_position_radius: float = 0.0
@export var retrieve_position_radius: float = 0.0
@export_range(0.0, 1.0) var hunt_chance: float = 0.5
@export_range(0, 10) var hunt_retries: int = 3
@export var hunt_range: float = 512.0
@export var eat_amount: float = 8.0
@export_range(0.0, 1.0) var eat_until: float = 0.7
@export var flee_distance: float
@export var consumable: Consumable
@export var prey_image_coords := Vector2i(0, 1)
var _goto_position: Vector2
var _goto_state: State
var _hunt_target: Node2D
var _hunt_tries: int = 0
var _hunt_elapsed_time: float = 0.0
var _flee_from_nodes: Array[Node2D]
@onready var sprite_prey: Sprite2D = $Sprite2DPrey


var fish: Node2D:
	get:
		return _hunt_target


# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	
	sprite_prey.visible = false
	_to_state(State.IDLE)


func _get_steering() -> Vector2:
	match _state:
		State.IDLE:
			return Vector2.ZERO
		
		State.WANDER:
			return \
				wander(wander_circle_distance, wander_circle_radius, angle_change_range) \
				+ circle_constrain(donut_outer_radius, 3.0) \
				+ circle_constrain(donut_inner_radius, 3.0, false)
		
		State.GOTO:
			return (wander(
				wander_circle_distance,
				wander_circle_radius,
				angle_change_range
			) + arrive_to(_goto_position, 48.0, 128.0) * 2) / 3
		
		State.SCOUT:
			return Vector2.ZERO
		
		State.HUNT:
			return arrive_to(_hunt_target.global_position, 16.0, 64.0) if is_instance_valid(_hunt_target) else Vector2.ZERO
		
		State.EAT:
			return Vector2.ZERO
		
		State.FLEE:
			var positions := nodes_to_positions(_flee_from_nodes)
			return (wander(
				wander_circle_distance,
				wander_circle_radius,
				angle_change_range
			) + flee(positions, 512.0, 768.0) * 2) / 3
	
	return Vector2.ZERO


func _process_state(state: State, wait_time: float) -> void:
	match state:
		State.IDLE:
			if not is_active:
				if randf_range(0.0, 1.0) < hunt_chance:
					# Go hunting
					_goto_position = global_position.normalized() * scout_position_radius
					_goto_state = State.SCOUT
					_to_state(State.GOTO)
				else:
					_to_state(State.WANDER)
		
		State.WANDER:
			if not is_active:
				_to_state(State.IDLE)
		
		State.GOTO:
			if global_position.distance_to(_goto_position) < 64.0:
				# Arrived to target
				if _goto_state == State.SCOUT:
					# Gone hunting
					_hunt_tries = 0
					global_rotation = Vector2.ZERO.angle_to(global_position)
					_to_state(State.SCOUT)
				elif _goto_state == State.EAT:
					_to_state(State.EAT)
				else:
					_to_state(State.IDLE)
		
		State.SCOUT:
			if not is_active:
				var list := focus_list
				if list.size() > 0:
					var reacheable: Array[Node2D] = []
					for node: Node2D in list:
						if is_instance_valid(node) and node.get_meta("crab_wants", false) as bool:
							if node.global_position.distance_to(global_position) < hunt_range:
								reacheable.append(node)
					if reacheable.size() > 0:
						if reacheable.size() > 1:
							reacheable.shuffle()
						_hunt_target = reacheable[0]
						_hunt_elapsed_time = 0.0
						_to_state(State.HUNT)
					else:
						_check_scout_try_again()
				else:
					_check_scout_try_again()
		
		State.HUNT:
			_hunt_elapsed_time += wait_time
			if _hunt_target and is_instance_valid(_hunt_target):
				if _hunt_target.global_position.distance_to(global_position) < 50.0:
					_to_state(State.RETRIEVE)
				elif _hunt_elapsed_time > 30.0:
					_goto_position = global_position.normalized() * scout_position_radius
					_goto_state = State.SCOUT
					_to_state(State.GOTO)
			else:
				_goto_position = global_position.normalized() * scout_position_radius
				_goto_state = State.SCOUT
				_to_state(State.GOTO)
		
		State.RETRIEVE:
			if is_instance_valid(_hunt_target):
				sprite_prey.texture = _hunt_target.sprite_2d.texture
				sprite_prey.hframes = _hunt_target.sprite_2d.hframes
				sprite_prey.vframes = _hunt_target.sprite_2d.vframes
				sprite_prey.frame_coords = prey_image_coords
				sprite_prey.visible = true
				catched.emit(self)
				
				_goto_position = get_position_at_radius(retrieve_position_radius, true)
				_goto_state = State.EAT
			else:
				_goto_position = get_position_at_radius(scout_position_radius, true)
				_goto_state = State.SCOUT
			
			_hunt_target = null
			_to_state(State.GOTO)
		
		State.EAT:
			if not is_active:
				consumable.visible = true
				consumable.monitorable = true
				consumable.monitoring = true
				consumable.global_position = global_position
				sprite_prey.visible = false
				
				var list := focus_list
				if list.size() > 0:
					_flee_from_nodes = []
					for node: Node2D in list:
						if is_instance_valid(node):
							if node.get_meta("crab_fears", false) as bool or node is SnakeBody:
								_flee_from_nodes.append(node)
					if _flee_from_nodes.size() > 0:
						_to_state(State.FLEE)
						return
				
				var eat_until_value: float = consumable.max_value * eat_until
				consumable.consume(eat_amount)
				if consumable.value > eat_until_value:
					_to_state(State.EAT)
				else:
					consumable = null
					_to_state(State.IDLE)
		State.FLEE:
			if not is_active:
				_to_state(State.IDLE)


func _to_state(state: State) -> void:
	match state:
		State.IDLE:
			frame(Vector2i.ZERO)
			activity(1.0 + randf_range(-0.3, 0.3))
		
		State.WANDER:
			animation([ Vector2(0, 0), Vector2(1, 0), Vector2(0, 0), Vector2(1, 0),Vector2(2, 0), Vector2(3, 0),], 0.1, true)
			focus = false
			activity(7.0 + randf_range(-2.0, 3.0))
		
		State.GOTO:
			animation([ Vector2(0, 0), Vector2(1, 0), Vector2(0, 0), Vector2(1, 0),Vector2(2, 0), Vector2(3, 0),], 0.1, true)
		
		State.SCOUT:
			frame(Vector2i.ZERO)
			focus = true
			activity(5.0 + randf_range(-2.0, 3.0))
		
		State.HUNT:
			animation([ Vector2(0, 0), Vector2(1, 0), Vector2(0, 0), Vector2(1, 0),Vector2(2, 0), Vector2(3, 0),], 0.1, true)
			focus = false
		
		State.RETRIEVE:
			focus = false
		
		State.EAT:
			frame(Vector2i.ZERO)
			focus = true
			activity(1.0 + randf_range(-0.5, 0.5))
		
		State.FLEE:
			animation([ Vector2(0, 0), Vector2(1, 0), Vector2(0, 0), Vector2(1, 0),Vector2(2, 0), Vector2(3, 0),], 0.1, true)
			focus = false
			activity(7.0 + randf_range(-1.0, 1.0))
	
	_state = state


func _check_scout_try_again() -> void:
	_hunt_tries += 1
	if _hunt_tries >= hunt_retries:
		_to_state(State.WANDER)
	else:
		_to_state(State.SCOUT) # implicitly set the same state to reset the activity_timer
