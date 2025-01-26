extends SubViewport


@onready var camera_2d: Camera2D = $Camera2D
#@onready var sprite_2d: Sprite2D = $Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera_2d.global_position = Vector2.ZERO
	#pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
