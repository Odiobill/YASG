class_name Snake
extends Node2D


signal size_changed(size: int)

@export var grow_scale_add := Vector2.ZERO
var body_parts: Array[SnakeBody] = []
var _skin: int = 0
@onready var head: SnakeHead = $Head
@onready var tail: SnakeTail = $PartsContainer/Tail


var skin: int:
	get:
		return _skin
	set(value):
		_skin = value
		
		head.skin = _skin
		for part in body_parts:
			part.skin = _skin


# Called when the node enters the scene tree for the first time.
func _ready():
	body_parts = [ tail ]


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(_delta):
	#if Input.is_action_just_pressed("_tmp"):
		#grow()


func grow() -> void:
	var part: SnakeBody = tail.grow()
	part.skin = _skin
	body_parts.append(part)
	scale += grow_scale_add
	size_changed.emit(body_parts.size())
