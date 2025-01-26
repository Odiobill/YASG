class_name GameController
extends Node2D


@export var follow_camera: FollowCamera
@export var terrain: TerrainController
@export var animal_spawn_rate: float = 20.0
@export_group("Snake")
@export var snake: Snake
@export_range(0.0, 1.0) var min_health: float
@export var steering_angle: float
@export var steering_angle_maxdiff: float
@export var collect_amount: float
@export var collect_amount_maxdiff: float
@export var wander_power: float
@export var wander_power_maxdiff: float
@export var wander_drain: float
@export var wander_drain_maxdiff: float
@export var sprint_power: float
@export var sprint_power_maxdiff: float
@export var sprint_drain: float
@export var sprint_drain_maxdiff: float
@export var dry_resistance: float
@export var dry_resistance_maxdiff: float
@export var shot_rate: float
@export var shot_rate_maxdiff: float
@export var shot_speed: float
@export var shot_speed_maxdiff: float
@export var shot_distance: float
@export var shot_distance_maxdiff: float
@export var shot_drain: float
@export var shot_drain_maxdiff: float
@export var part_size: float
@export var part_size_maxdiff: float
@export var part_capacity: float
@export var part_capacity_maxdiff: float
@export var food_bonus: float
@export var food_bonus_maxdiff: float
@export_group("Fishes")
@export var fish_scene: PackedScene
@export var fish_count_start: int = 8
@export var fish_spawn_radius: float
@export var fish_min_radius: float = 0.0
@export var fish_max_radius: float = 0.0
@export_group("Crabs")
@export var crab_scene: PackedScene
@export var crab_count_start: int = 8
@export var crab_spawn_radius: float
@export var crab_min_radius: float = 0.0
@export var crab_max_radius: float = 0.0
@export var crab_scout_radius: float = 0.0
@export var crab_retrieve_radius: float = 0.0
@export_group("Seagulls")
@export var seagull_scene: PackedScene
@export var seagull_count_start: int = 8
@export var seagull_max_radius: float
@export_group("Snails")
@export var snail_scene: PackedScene
@export var snail_count_start: int = 8
@export var snail_spawn_radius: float
@export var snail_arrival_radius: float
var _fishes_container: Node2D
var _crabs_container: Node2D
var _seagulls_container: Node2D
var _snails_container: Node2D
var _elapsed_time: float = 0.0
var _fish_index: int
var _crab_index: int
var _snail_index: int
var _bar_health_size: float
@onready var shooter: ShooterComponent = $Shooter
@onready var label_level: Label = $CanvasLayer/VBoxContainerIntro/LabelLevel
@onready var label_description: Label = $CanvasLayer/VBoxContainerIntro/LabelDescription
@onready var label_animals: Label = $CanvasLayer/VBoxContainerIntro/LabelAnimals
@onready var label_animal: Label = $CanvasLayer/VBoxContainerIntro/LabelAnimal
@onready var label_hints: Label = $CanvasLayer/VBoxContainerIntro/LabelHints
@onready var label_hint: Label = $CanvasLayer/VBoxContainerIntro/LabelHint
@onready var bar_health: TextureProgressBar = $CanvasLayer/VBoxContainerUI/HBoxContainer/Container1/TextureProgressBarHealth
@onready var bar_growth: TextureProgressBar = $CanvasLayer/VBoxContainerUI/HBoxContainer/Container0/TextureProgressBarGrowth
@onready var bar_shot: TextureProgressBar = $CanvasLayer/VBoxContainerUI/HBoxContainer/Container2/TextureProgressBarShot


var max_health: float:
	get:
		return part_capacity * snake.body_parts.size()


var health: float:
	get:
		return bar_health.value
	set(value):
		bar_health.value = clampf(value, 0.0, max_health)


var growth: float:
	get:
		return bar_growth.value
	
	set(value):
		bar_growth.value = clampf(value, 0.0, part_size)


var show_bars: bool:
	set(value):
		bar_growth.visible = value
		bar_health.visible = value
		bar_shot.visible = value


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var asset = ConfigfileHandler.get_value("wallet", "asset")
	if asset:
		update_values(asset)
	apply_values()
	
	_snails_container = Node2D.new()
	_snails_container.name = "Snails"
	add_child(_snails_container)
	_snail_index = -1
	
	_bar_health_size = bar_health.custom_minimum_size.x
	
	shooter.bullet_source = snake.head
	
	growth = 0.0
	terrain.food_spawned.connect(_food_spawned)
	terrain.food_eaten.connect(_food_eaten)
	terrain.level_completed.connect(_level_completed)
	
	follow_camera.target = snake.head
	#follow_camera.zoom = Vector2(0.7, 0.7)
	level_intro(1)
	
	#_spawn_snails()
	#_spawn_crabs()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if snake.head.freeze:
		return

	var healthy := health / max_health > min_health
	var drain := (sprint_drain if Input.is_action_pressed("accelerate") and healthy else wander_drain) * delta
	var lake_points := terrain.lake_points(snake.head.global_position, healthy)
	if healthy or lake_points > 0.0:
		health += lake_points * collect_amount * delta
	health -= drain + terrain.distance_points(snake.head.global_position) / dry_resistance
	_elapsed_time += delta
	if _elapsed_time > animal_spawn_rate:
		_elapsed_time = 0.0
		_spawn_animals()
	
	if Input.is_action_just_pressed("fire") and shooter.can_shoot:
		if health / max_health > min_health:
			health -= shot_drain
			shooter.shoot()


func update_values(asset: Dictionary) -> void:
	if not asset.has("snake"):
		return
	
	for skill in asset["snake"].keys():
		match skill:
			"steering_angle":
				steering_angle += steering_angle_maxdiff * asset["snake"][skill]
			
			"collect_amount":
				collect_amount += collect_amount_maxdiff * asset["snake"][skill]
			
			"wander_power":
				wander_power += wander_power_maxdiff * asset["snake"][skill]
			
			"wander_drain":
				wander_drain -= wander_drain_maxdiff * asset["snake"][skill]
			
			"sprint_power":
				sprint_power += sprint_power_maxdiff * asset["snake"][skill]
			
			"sprint_drain":
				sprint_drain -= sprint_drain_maxdiff * asset["snake"][skill]
			
			"dry_resistance":
				dry_resistance += dry_resistance_maxdiff * asset["snake"][skill]
			
			"shot_rate":
				shot_rate -= shot_rate_maxdiff * asset["snake"][skill]
			
			"shot_speed":
				shot_speed += shot_speed_maxdiff * asset["snake"][skill]
			
			"shot_distance":
				shot_distance += shot_distance_maxdiff * asset["snake"][skill]
			
			"shot_drain":
				shot_drain -= shot_drain_maxdiff * asset["snake"][skill]
			
			"part_size":
				part_size -= part_size_maxdiff * asset["snake"][skill]
			
			"part_capacity":
				part_capacity += part_capacity_maxdiff * asset["snake"][skill]
			
			"food_bonus":
				food_bonus += food_bonus_maxdiff * asset["snake"][skill]


func apply_values() -> void:
	snake.head.steering_angle = steering_angle
	snake.head.min_power = wander_power
	snake.head.max_power = sprint_power
	
	shooter.bullet_range = shot_distance
	shooter.bullet_speed = shot_speed
	shooter.bullets_per_second = shot_rate
	
	bar_health.max_value = part_capacity
	bar_health.value = part_capacity


func level_intro(level: int) -> void:
	snake.head.velocity = Vector2.ZERO
	snake.head.freeze = true
	_elapsed_time = 0
	_level_labels()
	show_bars = false
	terrain.can_spawn_food = false
	
	match level:
		1:
			await _level_intro(level, "🐟 FISH, 🐌 SNAIL", "- STAY AWAY FROM SALTY WATER AND BARREN TERRAIN.\n- SNAILS ARE THE CURSE OF MANY FARMERS...")
			
			_spawn_fishes()
			#_spawn_snails()
			#_spawn_crabs()
		
		2:
			await _level_intro(level, "🐦 SEAGULL", "SEAGULLS SOMETIMES DROP SOMETHING WHEN HIT")
			
			_spawn_seagulls()
		
		3:
			await _level_intro(level, "🦀 CRAB", "FISH IS RICH IN PROTEIN")
			
			_spawn_crabs()


func _level_labels(level: String = "", description: String = "", animals: String = "", animal: String = "", hints: String = "", hint: String = "") -> void:
	label_level.text = level
	label_description.text = description
	label_animals.text = animals
	label_animal.text = animal
	label_hints.text = hints
	label_hint.text = hint


func _level_intro(level: int, animal: String, hint: String) -> void:
	var current_zoom := follow_camera.current_zoom
	follow_camera.target = null
	follow_camera.global_position = snake.head.global_position
	follow_camera.zoom = Vector2(0.7, 0.7)
	await get_tree().create_timer(1.0).timeout
	_remove_snails()
	
	_level_labels(
		"Level " + str(level),
		"ACTIVATE THE NEW LIFE-LAKES",
		"UNLOCKED ANIMALS:",
		animal,
		"HINTS:",
		hint
	)
	
	follow_camera.zoom_to(Vector2(0.0675, 0.0675), Vector2.ZERO, 1.0)
	await get_tree().create_timer(1.0).timeout
	await terrain.switch_level(level, 1.0 if level < 2 else 0.5)
	await get_tree().create_timer(2.0).timeout
	
	follow_camera.zoom_to(Vector2(current_zoom, current_zoom), snake.head.global_position, 1.0)
	await get_tree().create_timer(1.0).timeout
	
	follow_camera.target = snake.head
	snake.head.freeze = false
	_level_labels()
	show_bars = true
	terrain.can_spawn_food = true


func _spawn_fishes() -> void:
	_fishes_container = Node2D.new()
	_fishes_container.name = "Fishes"
	add_child(_fishes_container)
	for i in fish_count_start:
		var fish: SteeringAgent = fish_scene.instantiate() as SteeringAgent
		fish.name = "Fish" + str(i)
		fish.global_position = fish.get_position_at_radius(fish_spawn_radius, true)
		fish.global_rotation = randf_range(0.0, TAU)
		fish.donut_inner_radius = fish_min_radius
		fish.donut_outer_radius = fish_max_radius
		_fishes_container.add_child(fish)
	_fish_index = fish_count_start - 1


func _spawn_seagulls() -> void:
	_seagulls_container = Node2D.new()
	_seagulls_container.name = "Seagulls"
	add_child(_seagulls_container)
	for i in seagull_count_start:
		var seagull: SteeringAgent = seagull_scene.instantiate() as SteeringAgent
		seagull.name = "Seagull" + str(i)
		seagull.global_position = seagull.get_position_at_radius(seagull_max_radius, true)
		seagull.global_rotation = randf_range(0.0, TAU)
		seagull.constrain_radius = seagull_max_radius
		_seagulls_container.add_child(seagull)


#func _spawn_snails() -> void:
	#for i in snail_count_start:
		#var snail: SteeringAgent = snail_scene.instantiate() as SteeringAgent
		#snail.name = "Snail" + str(i)
		#snail.global_position = snail.get_position_at_radius(snail_spawn_radius, true)
		#snail.global_rotation = randf_range(0.0, TAU)
		#snail.destination_point = snail.get_position_at_radius(snail_arrival_radius, true)
		#_snails_container.add_child(snail)
	#_snail_index = snail_count_start - 1


func _spawn_snail(target: Consumable) -> void:
	_snail_index += 1
	var snail: SteeringAgent = snail_scene.instantiate() as SteeringAgent
	snail.name = "Snail" + str(_snail_index)
	snail.global_position = Vector2.ZERO
	snail.look_at(target.global_position)
	snail.destination_point = target.global_position
	snail.crashed.connect(_snail_crashed)
	_snails_container.add_child(snail)


func _spawn_crabs() -> void:
	_crabs_container = Node2D.new()
	_crabs_container.name = "Crabs"
	add_child(_crabs_container)
	for i in crab_count_start:
		var crab: SteeringAgent = crab_scene.instantiate() as SteeringAgent
		crab.name = "Crab" + str(i)
		crab.global_position = crab.get_position_at_radius(crab_spawn_radius, true)
		crab.global_rotation = randf_range(0.0, TAU)
		crab.donut_inner_radius = crab_min_radius
		crab.donut_outer_radius = crab_max_radius
		crab.scout_position_radius = crab_scout_radius
		crab.retrieve_position_radius = crab_retrieve_radius
		crab.catched.connect(_remove_fish)
		_crabs_container.add_child(crab)
	_crab_index = crab_count_start - 1


func _spawn_animals() -> void:
	if _fishes_container.get_children().size() < fish_count_start:
		_fish_index += 1
		var fish: SteeringAgent = fish_scene.instantiate() as SteeringAgent
		fish.name = "Fish" + str(_fish_index)
		fish.global_position = fish.get_position_at_radius(fish_spawn_radius, true)
		fish.global_rotation = randf_range(0.0, TAU)
		fish.donut_inner_radius = fish_min_radius
		fish.donut_outer_radius = fish_max_radius
		_fishes_container.add_child(fish)


func _remove_snails() -> void:
	for snail in _snails_container.get_children():
		snail.queue_free()


func _remove_fish(crab: SteeringAgent) -> void:
	var fish: Node2D = crab.fish
	var consumable = terrain.consumable_scene.instantiate() as Consumable
	consumable.setup(
		fish.get_meta("consumable_value", 0.0),
		fish.get_meta("consumable_images", []),
		fish.sprite_2d.texture,
		fish.sprite_2d.hframes,
		fish.sprite_2d.vframes
	)
	for meta in fish.get_meta_list():
		consumable.set_meta(meta, fish.get_meta(meta))
	consumable.catched.connect(terrain._on_food_eaten)
	consumable.global_position = crab.global_position
	consumable.monitorable = false
	consumable.monitoring = false
	consumable.visible = false
	consumable.set_meta("seagull_wants", true)
	terrain.add_child(consumable)
	crab.consumable = consumable
	
	fish.queue_free()


func _snail_crashed(snail: SteeringAgent) -> void:
	health -= shot_drain
	var consumable := terrain.consumable_scene.instantiate() as Consumable
	consumable.setup(
		-shot_drain,
		[ snail.FRAME_DEATH ],
		snail.sprite_2d.texture,
		snail.sprite_2d.hframes,
		snail.sprite_2d.vframes,
		0
	)
	consumable.global_position = snail.global_position
	consumable.can_consume = false
	consumable.expire_time = terrain.food_expire_time
	consumable.catched.connect(terrain._on_food_eaten)
	consumable.set_meta("seagull_wants", true)
	terrain.add_child(consumable)
	
	snail.queue_free()


func _food_spawned(food: Consumable) -> void:
	_spawn_snail(food)


func _food_eaten(value: float) -> void:
	health += value * food_bonus * 2
	growth += value * food_bonus
	if growth >= part_capacity:
		if snake.body_parts.size() < 10:
			growth = 0.0
			snake.grow()
			bar_health.max_value = max_health
			bar_health.custom_minimum_size.x = _bar_health_size * snake.body_parts.size()
			follow_camera.zoom_out()
		
		bar_health.value = max_health


func _level_completed(level: int) -> void:
	level_intro(level + 1)
