class_name SteeringAgent
extends SteeringBehavior


signal animation_completed
signal state_changed(from_state: int, to_state: int)

@export var state_time: float = 0.3
@export var focus_radius: float = 512.0
@export var focus_offset := Vector2.ZERO
# Animation
var _frames: Array[Vector2i]
var _frame_time: float = 0.0
var _loop := false
var _repeat_animation: int = 1
var _current_frame: int = 0
var _play_animation := false
var _animate_elapsed_time: float = 0.0
# State
var _state: int = -1
var _state_timer: Timer
var _activity_timer: Timer
#
var _area2d_focus: Area2D
var _focus_list: Array[Node2D] = []
@onready var sprite_2d: Sprite2D = $Sprite2D

var is_active: bool:
	get:
		return not _activity_timer.is_stopped()

var focus: bool:
	get:
		return _area2d_focus.monitoring
	set(value):
		_area2d_focus.monitoring = value
		if not value:
			_focus_list.clear()

var focus_list: Array[Node2D]:
	get:
		return _focus_list


# Called when the node enters the scene tree for the first time.
func _ready():
	_area2d_focus = Area2D.new()
	_area2d_focus.collision_layer = collision_layer
	_area2d_focus.collision_mask = collision_mask
	var collision_shape := CollisionShape2D.new()
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = focus_radius
	collision_shape.shape = circle_shape
	_area2d_focus.add_child(collision_shape)
	add_child(_area2d_focus)
	_area2d_focus.position += focus_offset
	_area2d_focus.body_entered.connect(_on_area2d_focus_body_entered)
	_area2d_focus.body_exited.connect(_on_area2d_focus_body_exited)
	_area2d_focus.area_entered.connect(_on_area2d_focus_area_entered)
	_area2d_focus.area_exited.connect(_on_area2d_focus_area_exited)
	
	focus = false
	
	_activity_timer = Timer.new()
	_activity_timer.name = "ActivityTimer"
	add_child(_activity_timer)
	_activity_timer.one_shot = true
	_activity_timer.autostart = false
	_activity_timer.timeout.connect(_on_activity_timer_timeout)
	
	_state_timer = Timer.new()
	_state_timer.name = "StateTimer"
	add_child(_state_timer)
	_state_timer.wait_time = state_time
	_state_timer.one_shot = true
	_state_timer.autostart = false
	_state_timer.timeout.connect(_on_state_timer_timeout)
	_state_timer.start()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _play_animation:
		_animate(delta)


func animation(frames: Array[Vector2i] = [], frame_time: float = 0.0, loop := false, repeat: int = 1) -> void:
	if frame_time == 0.0 or frames.size() == 0:
		_play_animation = false
		return
	
	_frames = frames
	_frame_time = frame_time
	_loop = loop
	_repeat_animation = repeat
	_current_frame = 0
	_play_animation = true


func frame(frame_coords: Vector2i) -> void:
	_play_animation = false
	sprite_2d.frame_coords = frame_coords


func activity(wait_time: float) -> void:
	_activity_timer.wait_time = wait_time
	_activity_timer.start()


func get_position_at_radius(radius: float, same_quadrant := false) -> Vector2:
	var angle := randf_range(0.0, TAU) # TAU is a constant equal to 2 * PI
	var x := radius * cos(angle)
	var y := radius * sin(angle)
	
	if same_quadrant:
		if (global_position.x > 0 and x < 0) or (global_position.x < 0 and x > 0):
			x = -x
		if (global_position.y > 0 and y < 0) or (global_position.y < 0 and y > 0):
			y = -y
	
	return Vector2(x, y)


func receive_event(_what: int = 0, _data: Variant = null) -> void:
	pass


func _animate(delta: float) -> void:
	var prev_frame := sprite_2d.frame_coords
	sprite_2d.frame_coords = _frames[_current_frame]
	_animate_elapsed_time += delta
	if _animate_elapsed_time > _frame_time:
		_current_frame += 1
		if _current_frame >= _frames.size():
			_current_frame = 0
			if not _loop:
				_repeat_animation -= 1
				if _repeat_animation == 0:
					_play_animation = false
					animation_completed.emit()
					_process_animation(_animate_elapsed_time)
					sprite_2d.frame_coords = prev_frame
		
		_animate_elapsed_time = 0.0


func _on_activity_timer_timeout() -> void:
	_process_activity()


func _on_state_timer_timeout() -> void:
	if _state < 0:
		return
	
	var old_state := _state
	_process_state(_state, _state_timer.wait_time)
	
	if old_state != _state:
		state_changed.emit(old_state, _state)
	
	_state_timer.start()


func _on_area2d_focus_body_entered(body: Node2D) -> void:
	if not body in _focus_list:
		_focus_list.append(body)
	
	_focus_enter(body)


func _on_area2d_focus_body_exited(body: Node2D) -> void:
	_focus_left(body)


func _on_area2d_focus_area_entered(body: Node2D) -> void:
	if not body in _focus_list:
		_focus_list.append(body)
	
	_focus_enter(body)


func _on_area2d_focus_area_exited(body: Node2D) -> void:
	_focus_left(body)


func _process_animation(_elapsed_time: float) -> void:
	pass


func _process_activity() -> void:
	pass


func _process_state(_current_state: int, _wait_time: float) -> void:
	pass


func _focus_enter(_body: Node2D) -> void:
	pass


func _focus_left(_body: Node2D) -> void:
	pass
