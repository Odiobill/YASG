class_name Consumable
extends Area2D


signal catched(consumable: Consumable)


@export var max_value: float
@export var can_consume := true
@export var images: PackedVector2Array
@export var expire_time: float = 0.0
var _value: float
var _sprite_texture: Texture2D
var _sprite_hframes: int
var _sprite_vframes: int
var _frame_index: int
var _expire_timer: Timer
@onready var sprite_2d: Sprite2D = $Sprite2D

var value: float:
	get:
		return _value


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_value = max_value
	
	if _sprite_texture:
		sprite_2d.texture = _sprite_texture
		sprite_2d.hframes = _sprite_hframes
		sprite_2d.vframes = _sprite_vframes
		sprite_2d.frame_coords = images[_frame_index]
	
	if expire_time > 0.0 and not can_consume:
		create_expire_timer()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass


func setup(_max_value: float, _images: PackedVector2Array, _texture: Texture2D, _hframes: int = 1, _vframes: int = 1, frame_index: int = 0) -> void:
	max_value = _max_value
	_value = max_value
	images = _images
	_sprite_texture = _texture
	_sprite_hframes = _hframes
	_sprite_vframes = _vframes
	_frame_index = frame_index


func create_expire_timer() -> void:
	_expire_timer = Timer.new()
	_expire_timer.one_shot = true
	_expire_timer.autostart = false
	_expire_timer.timeout.connect(_on_timer_timeout)
	add_child(_expire_timer)
	_expire_timer.start(expire_time)


func consume(amount: float) -> void:
	if not can_consume:
		return
	
	_value = clampf(_value - amount, 0.0, max_value)
	var amount_per_frame := max_value / images.size()
	var partial: float = 0.0
	var index: int = 0
	while partial < _value:
		partial += amount_per_frame
		index += 1
	sprite_2d.frame_coords = images[images.size() - index]
	
	if index == images.size() - 1 and expire_time > 0.0:
		create_expire_timer()


func _on_timer_timeout() -> void:
	var color := self_modulate
	var tween := get_tree().create_tween()
	for i in range(3):
		tween.tween_property(sprite_2d, "self_modulate", Color.TRANSPARENT, 0.4)
		tween.tween_property(sprite_2d, "self_modulate", color, 0.4)
	tween.tween_property(sprite_2d, "self_modulate", Color.TRANSPARENT, 0.4)
	tween.finished.connect(func():
		if is_instance_valid(self):
			queue_free()
	)


func _on_body_entered(body: Node2D) -> void:
	if body is SnakeHead:
		catched.emit(self)
	elif body is Snail and _expire_timer:
		if _expire_timer.time_left > 0:
			_expire_timer.stop()
			_expire_timer.timeout.emit()
