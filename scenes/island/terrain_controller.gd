class_name TerrainController
extends Node2D


signal food_spawned(food: Consumable)
signal food_eaten(value: float)
signal lake_completed
signal level_completed(level: int)


@export var farm_tilemap: TileMapLayer
@export var level_tilemaps: Array[TileMapLayer]
@export var dry_tilemaps: Array[TileMapLayer]
@export var lake_tilemaps: Array[TileMapLayer]
@export var lake_target_tilemap: TileMapLayer
@export var lake_sizes: Array[float]
@export var water_per_size: float = 0.5
@export var levels: Array[PackedVector2Array]
@export var level_barren_ranges: Array[float]
@export var salty_water_range: float
@export var lake_layer: int
@export var lake_mask: int
@export var cell_offset: Vector2
@export var hit_water: float
@export var consumable_scene: PackedScene
@export var food_texture: Texture2D
@export var food_columns: int = 5
@export var food_rows: int = 2
@export var food_spawn_rate: float = 5.0
@export var food_expire_time: float = 60.0
@export var food_value: float = 10.0
@export var food_border_distance: float = 100.0
@export var can_spawn_food := false
var _lake_cells: Array
var _lakes: Array[Dictionary]
var _lakes_container: Node2D
var _lakes_completed: int
var _spawn_timer: Timer
var _sfx_water_take: AudioStreamPlayer
var _sfx_water_drop: AudioStreamPlayer
@onready var vfx_lake: Vfx2D = $Vfx2DLake
@onready var vfx_food: Vfx2D = $Vfx2DFood
@onready var water_bar: ProgressBar = $ProgressBar


var level: int = 0:
	get:
		return level
	set(value):
		_lakes_completed = 0
		if value > 1:
			level_tilemaps[value - 2].visible = false
		level = value


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_sfx_water_take = AudioManager.audio("sfx_water_taken")
	_sfx_water_drop = AudioManager.audio("sfx_water_deployed")
	
	water_bar.visible = false
	_spawn_timer = Timer.new()
	_spawn_timer.name = "SpawnTimer"
	add_child(_spawn_timer)
	_spawn_timer.one_shot = false
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_spawn_timer.start(food_spawn_rate)
	
	_lakes_container = Node2D.new()
	_lakes_container.name = "Lakes"
	add_child(_lakes_container)
	
	_lake_cells = []
	for tilemap in lake_tilemaps:
		var cells := tilemap.get_used_cells()
		_lake_cells.append(cells)
	
	for coords in levels[0]:
		spawn_lake(coords, 1, 1, true)
	
	
	#draw_lake(6, Vector2i(5, -9))
	#draw_lake(6, Vector2i(11, 0))
	#draw_lake(6, Vector2i(5, 9))
	#draw_lake(6, Vector2i(-5, 9))
	#draw_lake(6, Vector2i(-11, 0))
	#draw_lake(6, Vector2i(-5, -9))
	#
	#draw_lake(5, Vector2i(0, 18))
	#draw_lake(5, Vector2i(15, 9))
	#draw_lake(5, Vector2i(15, -9))
	#draw_lake(5, Vector2i(0, -18))
	#draw_lake(5, Vector2i(-15, -9))
	#draw_lake(5, Vector2i(-15, 9))
	#
	#draw_lake(4, Vector2i(11, -19))
	#draw_lake(4, Vector2i(22, 0))
	#draw_lake(4, Vector2i(11, 19))
	#draw_lake(4, Vector2i(-11, 19))
	#draw_lake(4, Vector2i(-22, 0))
	#draw_lake(4, Vector2i(-11, -19))
	#
	#draw_lake(3, Vector2i(0, -28))
	#draw_lake(3, Vector2i(23, -14))
	#draw_lake(3, Vector2i(23, 14))
	#draw_lake(3, Vector2i(0, 28))
	#draw_lake(3, Vector2i(-23, 14))
	#draw_lake(3, Vector2i(-23, -14))
	#
	#draw_lake(2, Vector2i(16, -24))
	#draw_lake(2, Vector2i(29, 0))
	#draw_lake(2, Vector2i(16, 24))
	#draw_lake(2, Vector2i(-16, 24))
	#draw_lake(2, Vector2i(-29, 0))
	#draw_lake(2, Vector2i(-16, -24))
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass


func spawn_lake(coords: Vector2i, size: int = 0, max_level: int = -1, completed := false) -> Vector2:
	var body := StaticBody2D.new()
	body.name = "Lake" + str(_lakes.size())
	var collision_shape := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = lake_sizes[size]
	collision_shape.shape = shape
	body.add_child(collision_shape)
	body.collision_layer = lake_layer
	body.collision_mask = lake_mask
	body.global_position = draw_lake(size, coords, completed)
	#body.set_meta("wall_receiver", self)
	#body.set_meta("wall_signal", "lake_hitten")
	var progress_bar := ProgressBar.new()
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = water_bar.custom_minimum_size
	progress_bar.theme = water_bar.theme
	if completed:
		progress_bar.visible = false
	body.add_child(progress_bar)
	_lakes_container.add_child(body)
	
	if completed:
		max_level = size
	elif max_level < 0:
		max_level = lake_sizes.size() - 1
	var lake: Dictionary = {
		"body": body,
		"completed": completed,
		"coords": coords,
		"level": 0,
		"max_level": max_level,
		"progress_bar": progress_bar,
		"shape": shape,
		"water": 0.0,
	}
	_lakes.append(lake)
	update_water_bar(_lakes.size() - 1)
	
	return body.global_position


func spawn_food(min_radius: float = -1.0) -> void:
	var consumable := consumable_scene.instantiate() as Consumable
	var images: PackedVector2Array = []
	for x in food_columns:
		for y in food_rows:
			images.append(Vector2(x, y))
	
	consumable.setup(food_value, images, food_texture, food_columns, food_rows, range(0, images.size()).pick_random())
	if min_radius < 0.0:
		min_radius = level_barren_ranges[level]
	var max_radius := level_barren_ranges[0]
	var where := get_position_at_radius(randf_range(min_radius, max_radius))
	consumable.global_position = where
	consumable.can_consume = false
	consumable.expire_time = food_expire_time
	consumable.catched.connect(_on_food_eaten)
	add_child(consumable)
	food_spawned.emit(consumable)
	
	var tween := get_tree().create_tween()
	tween.tween_property(consumable, "scale", Vector2.ONE, 1).from(Vector2.ZERO)
	tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func draw_lake(size: int, coords: Vector2i, completed := false) -> Vector2:
	for cell in _lake_cells[size]:
		var layer := lake_tilemaps[size] if completed else dry_tilemaps[size]
		var tile := layer.get_cell_atlas_coords(cell)
		lake_target_tilemap.set_cell(coords + cell, 0, tile)
	
	return lake_tilemaps[size].to_global(lake_tilemaps[size].map_to_local(coords) + cell_offset)


func upgrade_lake(i: int) -> void:
	if not _lakes[i]["completed"]:
		if _lakes[i]["level"] < _lakes[i]["max_level"]:
			_lakes[i]["level"] += 1
			_lakes[i]["shape"].radius = lake_sizes[_lakes[i]["level"]]
			_lakes[i]["water"] = 0.0
			update_water_bar(i)
		else:
			_lakes[i]["completed"] = true
			_lakes[i]["progress_bar"].visible = false
			_lakes_completed += 1
			lake_completed.emit()
			if _lakes_completed == levels[level].size():
				level_completed.emit(level)
		
		vfx_lake.global_position = draw_lake(_lakes[i]["level"], _lakes[i]["coords"], _lakes[i]["completed"])
		vfx_lake.play()
		AudioManager.audio("sfx_lake_upgraded").play()


func lake_points(subject: Vector2, fill: float = 0.0) -> float:
	var points: float = 0.0
	for i in range(_lakes.size()):
		var distance := subject.distance_to(_lakes[i]["body"].global_position)
		
		if distance < _lakes[i].shape.radius * 1.1:
			if _lakes[i]["completed"]:
				points += distance / _lakes[i].shape.radius
				
				if not _sfx_water_take.playing:
					_sfx_water_take.play()
			elif fill > 0.0:
				var diff: float = distance / _lakes[i].shape.radius
				points -= diff
				_lakes[i]["water"] += diff * fill
				
				if not _sfx_water_drop.playing:
					_sfx_water_drop.play()
				
				if _lakes[i]["water"] > _lakes[i].shape.radius * water_per_size:
					upgrade_lake(i)
				else:
					update_water_bar(i)
	
	return points


func distance_points(subject: Vector2) -> float:
	var distance := subject.distance_to(Vector2.ZERO)
	if distance > salty_water_range:
		return distance - salty_water_range
	elif distance < level_barren_ranges[level]:
		return level_barren_ranges[level] - distance
	
	return 0.0


func update_water_bar(i: int) -> void:
	_lakes[i]["progress_bar"].max_value = lake_sizes[_lakes[i]["level"]] * water_per_size
	_lakes[i]["progress_bar"].value = _lakes[i]["water"]
	_lakes[i]["progress_bar"].global_position = _lakes[i].body.global_position
	_lakes[i]["progress_bar"].global_position.x -=  water_bar.size.x / 2
	_lakes[i]["progress_bar"].global_position.y -=  water_bar.size.y / 2


func switch_level(new_level: int, duration: float = 1.0) -> void:
	level = new_level
	
	for coords in levels[new_level]:
		vfx_lake.global_position = spawn_lake(coords, 0, new_level)
		vfx_lake.play()
		AudioManager.audio("sfx_lake_reveal").play()
		await get_tree().create_timer(duration).timeout


func get_position_at_radius(radius: float) -> Vector2:
	var angle := randf_range(0.0, TAU) # TAU is a constant equal to 2 * PI
	var x := radius * cos(angle)
	var y := radius * sin(angle)
	
	return Vector2(x, y)


func _on_spawn_timer_timeout() -> void:
	if can_spawn_food:
		spawn_food()


func _on_food_eaten(consumable: Consumable) -> void:
	food_eaten.emit(consumable.value)
	
	vfx_food.global_position = consumable.global_position
	vfx_food.play()
	consumable.queue_free()
