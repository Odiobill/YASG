extends Control

@export_multiline var text: String = "Insert your long text here..."  # The text to scroll
@export var scroll_speed: float = 50.0  # Pixels per second
@export var fade_time: float = 1.0
#@export var wait_time: float = 1.0
@export var target_node: Control  # Node where the text should be drawn
@export var border_offset: int = 256
@export var fade_color: Color = Color.BLACK
@export var next_scene: PackedScene
var _text_height: float = 0.0
var _text_position: float = 0.0
var _tween: Tween
#var _time_elapsed: float = 0.0
@onready var color_rect: ColorRect = $ColorRect


func _ready() -> void:
	if not target_node:
		push_error("Target node is not set! Assign a Control node (like RichTextLabel).")
		return
	
	_tween = get_tree().create_tween()
	_tween.set_ease(Tween.EASE_IN)
	_tween.tween_property(color_rect, "color", Color.TRANSPARENT, fade_time)
	
	if target_node is RichTextLabel:
		target_node.text = text
	
	_text_height = target_node.size.y + border_offset
	_text_position = size.y
	
	target_node.set_position(Vector2(0, _text_position))


func _process(delta: float) -> void:
	if _tween.is_running():
		return
		
	#if _time_elapsed < wait_time:
		#_time_elapsed += delta
		#return
	
	if Input.is_action_pressed("fire"):
		_tween = get_tree().create_tween()
		_tween.set_ease(Tween.EASE_IN)
		_tween.tween_property(color_rect, "color", fade_color, fade_time)
		_tween.finished.connect(func():
			get_tree().change_scene_to_packed(next_scene)
		)

	_text_position -= scroll_speed * delta
	if target_node:
		target_node.set_position(Vector2(target_node.position.x, _text_position))
	
	if _text_position + _text_height + border_offset < 0:
		_text_position = size.y + border_offset
