class_name FollowCamera
extends Camera2D


var _rng := RandomNumberGenerator.new()
@export var speed: float
@export var target: Node2D
@export var zoom_step: float = 0.02
#@export var mouse_zoom := false
#@export var zoom_change: float = 0.01


var current_zoom: float:
	get:
		return zoom.x


# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if target:
		#global_position = target.global_position
		global_position = lerp(global_position, target.global_position, speed * delta)


func shake_camera(intensity: float, duration: float = 0.5) -> void:
	var shake_intensity = clamp(intensity, 0.0, 1.0)
	var shake_duration = max(duration, 0.0)
	var shake_time = 0.0
	
	while shake_time < shake_duration:
		var delta = get_process_delta_time()
		shake_time += delta
		var decay = 1.0 - (shake_time / shake_duration)  # Linear decay
		offset = Vector2(
			(_rng.randf_range(-1, 1) * shake_intensity * decay) * 10.0,
			(_rng.randf_range(-1, 1) * shake_intensity * decay) * 10.0
		)
		await get_tree().create_timer(delta).timeout
	offset = Vector2.ZERO


#func _input(event: InputEvent) -> void:
	#if mouse_zoom and event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT:
			#global_position = get_global_mouse_position()
		#elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			#zoom = Vector2(zoom.x - zoom_change, zoom.y - zoom_change)
		#elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			#zoom = Vector2(zoom.x + zoom_change, zoom.y + zoom_change)


func zoom_to(zoom_amount: Vector2, destination: Vector2, duration: float) -> void:
	var old_target := target
	target = null
	var tween := get_tree().create_tween()
	tween.parallel().tween_property(self, "zoom", zoom_amount, duration)
	tween.parallel().tween_property(self, "global_position", destination, duration)
	tween.finished.connect(func():
		target = old_target
	)


func zoom_out(shake_intensity: float = 0.0, shake_duration: float = 0.5) -> void:
	zoom = Vector2(zoom.x - zoom_step, zoom.y - zoom_step)
	
	if shake_intensity > 0.0:
		shake_camera(shake_intensity, shake_duration)
