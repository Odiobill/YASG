class_name SnakeTail
extends SnakeBody


@export var body_scene: PackedScene

var _parent: Node


# Called when the node enters the scene tree for the first time.
func _ready():
	global_position = target.follower_target.global_position
	
	_parent = get_parent()


func grow() -> SnakeBody:
	_parent.remove_child(self)
	
	var part := body_scene.instantiate() as SnakeBody
	part.global_position = global_position
	part.global_rotation = global_rotation
	part.target = target
	
	global_position = part.follower_target.global_position
	target = part

	_parent.call_deferred("add_child", part)
	_parent.call_deferred("add_child", self)
	return part
