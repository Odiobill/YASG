class_name ShooterComponent
extends Node


@export var bullet_scene: PackedScene
@export var bullet_range: float
@export var bullet_speed: float
@export var bullet_source: CharacterBody2D
@export var bullets_per_second: float
@export var spawn_distance: float
@export var collision_vfx_scene: PackedScene
@export var collision_texture: Texture2D
var _timer: Timer
@onready var progress_bar: TextureProgressBar = $"../CanvasLayer/VBoxContainerUI/HBoxContainer/Container2/TextureProgressBarShot"


var can_shoot: bool:
	get:
		return _timer.is_stopped()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_timer = Timer.new()
	_timer.autostart = false
	_timer.one_shot = true
	#_timer.wait_time = bullets_per_second
	add_child(_timer)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass


func shoot(distance: float = 0.0, speed: float = 0.0) -> void:
	if bullet_source and can_shoot:
		var tween := get_tree().create_tween()
		tween.tween_property(progress_bar, "value", 0.0, 0.1)
		tween.finished.connect(func():
			var new_tween := get_tree().create_tween()
			new_tween.tween_property(progress_bar, "value", 1.0, bullets_per_second - 0.1)
		)
		
		if distance == 0.0:
			distance = bullet_range
		
		if speed == 0.0:
			speed = bullet_speed
		
		var bullet: SteeringAgent = bullet_scene.instantiate() as SteeringAgent
		bullet.global_position = bullet_source.global_position
		bullet.global_rotation = bullet_source.global_rotation
		bullet.velocity = bullet_source.velocity
		bullet.spawn_distance = spawn_distance
		bullet.target_distance = distance
		bullet.max_speed = speed
		
		bullet.collided.connect(_on_bullet_collided)
		
		add_child(bullet)
		_timer.start(bullets_per_second)


func _on_bullet_collided(bullet: SteeringAgent) -> void:
	var vfx: Vfx2D = collision_vfx_scene.instantiate() as Vfx2D
	vfx.texture = collision_texture
	vfx.global_position = bullet.global_position
	vfx.global_rotation = bullet.global_rotation
	vfx.play_on_start = true
	vfx.duration = 1.0
	add_child(vfx)
	
	await get_tree().create_timer(vfx.duration + 0.1).timeout
	vfx.queue_free()
