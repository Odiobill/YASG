class_name SnakeBody
extends SteeringBehavior


@export var distance_threshold: float = 4.0
@export var slow_radius: float = 96.0
@export var target: SnakeBody
@export var follower_target: Node2D
@export var follower_line_to: Node2D
@export var line: Line2D
@export var line_x: int = 62
@export var line_y: int = 20
@export var line_width: int = 2
@export var line_height: int = 24
@export var line_textures: Array[Texture2D]
@export var sprite_2d: Sprite2D


var skin: int:
	get:
		return sprite_2d.frame
	set(value):
		sprite_2d.frame = value
		
		if line:
			print("Setting line for " + name)
			#var texture := sprite_2d.texture
			#@warning_ignore('integer_division') var width: int = texture.get_width() / sprite_2d.hframes
			##var height: int = texture.get_height() / sprite_2d.vframes
			#var frame_x: int = sprite_2d.frame * width
			#var frame_y: int = 0
			#
			#var old_image := texture.get_image()
			##var new_image := Image.create(width, height, false, old_image.get_format())
			#var new_image := Image.create(line_width, line_height, false, old_image.get_format())
			#new_image.blit_rect(old_image, Rect2(frame_x + line_x, frame_y + line_y, line_width, line_height), Vector2.ZERO)
			#
			#var new_texture := ImageTexture.create_from_image(new_image)
			line.texture = line_textures[value]


func damage():
	var color := self_modulate
	var tween := get_tree().create_tween()
	tween.tween_property(sprite_2d, "self_modulate", Color.RED, 0.5)
	tween.tween_property(sprite_2d, "self_modulate", color, 0.4)


func _process_exit(_delta):
	if target and line:
		line.set_point_position(1, to_local(target.follower_line_to.global_position))


func _get_steering() -> Vector2:
	if target == null:
		return Vector2.ZERO
	
	return arrive_to(target.follower_target.global_position, distance_threshold, slow_radius)
