class_name Snake
extends Node2D


signal size_changed(size: int)

@export var grow_scale_add := Vector2.ZERO
var body_parts: Array[SnakeBody] = []
@onready var head: SnakeHead = $Head
@onready var tail: SnakeTail = $PartsContainer/Tail


# Called when the node enters the scene tree for the first time.
func _ready():
	body_parts = [ tail ]


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(_delta):
	#if Input.is_action_just_pressed("_tmp"):
		#grow()


func grow() -> void:
	var part: SnakeBody = tail.grow()
	body_parts.append(part)
	scale += grow_scale_add
	size_changed.emit(body_parts.size())
