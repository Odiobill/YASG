class_name Spider
extends SteeringAgent


signal bitten


enum State
{
	IDLE,
	WANDER,
	HUNT,
}

const FRAME_IDLE := Vector2(0, 0)

@export var wander_circle_distance: float = 256.0
@export var wander_circle_radius: float = 32.0
@export var angle_change_range: float = 0.3
@export var donut_outer_radius: float = 0.0
var _frames_move: PackedVector2Array
var _target: SnakeBody


# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	
	for x in 4:
		_frames_move.append(Vector2(x, 0))
	
	_to_state(State.WANDER)


func die() -> void:
	AudioManager.audio("sfx_spider_death").play()
	queue_free()


func _get_steering() -> Vector2:
	match _state:
		State.IDLE:
			return Vector2.ZERO
		
		State.WANDER:
			return \
				wander(wander_circle_distance, wander_circle_radius, angle_change_range) \
				+ circle_constrain(donut_outer_radius, 3.0)
	
		State.HUNT:
			return \
				(wander(wander_circle_distance, wander_circle_radius, angle_change_range) + \
				arrive_to(_target.global_position, 16.0) * 2.0 \
				) / 3.0
	
	return Vector2.ZERO


func _process_state(state: State, _wait_time: float) -> void:
	match state:
		State.IDLE:
			if not is_active:
				_to_state(State.WANDER)
		
		State.WANDER:
			var list := focus_list
			var snake: Snake = null
			if list.size() > 0:
				for node: Node2D in list:
					if is_instance_valid(node) and node is SnakeHead:
						snake = node.get_parent() as Snake
				if snake != null:
					_target = snake.body_parts.pick_random()
					_to_state(State.HUNT)
					return
			
			if not is_active:
				_to_state(State.IDLE)
		
		State.HUNT:
			if _target.global_position.distance_to(global_position) < 32:
				bitten.emit()
				_target.damage()
				_to_state(State.IDLE)


func _to_state(state: State) -> void:
	match state:
		State.IDLE:
			frame(FRAME_IDLE)
			activity(2.0 + randf_range(-0.5, 0.5))
			focus = false
		
		State.WANDER:
			animation(_frames_move, 0.1, true)
			activity(3.0 + randf_range(-1.0, 2.0))
			focus = true
		
		State.HUNT:
			animation(_frames_move, 0.1, true)
			focus = false
	
	_state = state
