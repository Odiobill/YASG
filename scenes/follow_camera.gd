class_name FollowCamera
extends Camera2D


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


func zoom_out() -> void:
	zoom = Vector2(zoom.x - zoom_step, zoom.y - zoom_step)
