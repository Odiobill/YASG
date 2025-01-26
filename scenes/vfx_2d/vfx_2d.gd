class_name Vfx2D
extends Sprite2D


@export var duration: float = 0.4
@export var loop := false
@export var cooldown: float = 0.0
@export var hide_on_cooldown := true
@export var play_on_start := false
@export var hide_on_stop := true
@export var reverse := false
@export var frame_rotation: float = 0
var _is_playing := false
var _is_cooldown := false
var _elapsed_time: float
var _frame_time: float
var _start_rotation: float


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var size := texture.get_size()
	hframes = int(size.x / floor(size.y))
	_frame_time = duration / hframes
	vframes = 1
	visible = not hide_on_stop
	
	if play_on_start:
		play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	if not _is_playing or duration <= 0 or texture == null:
		return
	
	_elapsed_time += delta
	
	if _is_cooldown:
		if _elapsed_time > cooldown:
			_is_cooldown = false
			visible = true
			frame = hframes - 1 if reverse else 0
		return
	
	if _elapsed_time > _frame_time:
		_elapsed_time = 0
		
		var next_frame := frame + (-1 if reverse else 1)
		if next_frame == hframes or next_frame < 0:
			if not loop:
				stop()
				return
			
			if cooldown > 0:
				_is_cooldown = true
				if hide_on_cooldown:
					_hide()
				return
			
			next_frame = hframes - 1 if reverse else 0
		
		if frame_rotation != 0:
			rotate(deg_to_rad(frame_rotation))
		
		frame = next_frame


func play(start_frame: int = -1):
	if frame_rotation > 0:
		_start_rotation = rotation
	
	if start_frame >= 0:
		frame = start_frame
	else:
		frame = hframes - 1 if reverse else 0
	_elapsed_time = 0
	
	visible = true
	_is_playing = true


func stop():
	_is_playing = false
	
	if frame_rotation > 0:
		rotation = _start_rotation
	
	if hide_on_stop:
		_hide()


func _hide():
	visible = not hide_on_stop
