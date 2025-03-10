class_name GameController
extends Node2D


const SCENE_MENU := "res://scenes/menu/menu.tscn"
const SCENE_CREDITS := "res://scenes/credits/credits.tscn"

@export var follow_camera: FollowCamera
@export var terrain: TerrainController
@export var animal_spawn_rate: float
@export var level_max_time: float = 240.0
@export_range(0.0, 1.0) var level_drain_increase: float
@export_range(0.0, 1.0) var min_health: float
@export var part_size: float
@export var part_capacity: float
@export var snake: Snake
@export_group("Snake")
@export var steering_angle: float
@export var steering_angle_maxdiff: float
@export var collect_amount: float
@export var collect_amount_maxdiff: float
@export var fill_amount: float = 1.0
@export var fill_amount_maxdiff: float = 2.0
@export var wander_power: float
@export var wander_power_maxdiff: float
@export var wander_drain: float
@export var wander_drain_maxdiff: float
@export var dry_resistance: float
@export var dry_resistance_maxdiff: float
@export var collision_drain: float
@export var collision_drain_maxdiff: float
@export var food_growth: float
@export var food_growth_maxdiff: float
@export var food_health: float
@export var food_health_maxdiff: float
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
@export var snail_spawn_radius: float
@export var snail_arrival_radius: float
@export_group("Spiders")
@export var spider_scene: PackedScene
@export var spider_spawn_light_level: int
@export_range(0.0, 1.0) var spider_spawn_light_chance: float
@export var spider_spawn_light_distance: float
@export var spider_spawn_hard_level: int
@export_range(0.0, 1.0) var spider_spawn_hard_chance: float
@export var spider_max_radius: float
var _fishes_container: Node2D
var _crabs_container: Node2D
var _seagulls_container: Node2D
var _snails_container: Node2D
var _spiders_container: Node2D
var _animals_time: float = 0.0
var _fish_index: int
var _crab_index: int
var _snail_index: int
var _spider_index: int
var _bar_health_size: float
var _min_health: float
var _level_time: float
var _level: int
var _lakes_completed: int
var _game_ended := false
@onready var label_level: Label = $CanvasLayer/VBoxContainerIntro/LabelLevel
@onready var label_animals: Label = $CanvasLayer/VBoxContainerIntro/LabelAnimals
@onready var label_animal: Label = $CanvasLayer/VBoxContainerIntro/LabelAnimal
@onready var label_hints: Label = $CanvasLayer/VBoxContainerIntro/LabelHints
@onready var label_hint: Label = $CanvasLayer/VBoxContainerIntro/LabelHint
@onready var bar_health: ProgressBar = $CanvasLayer/ControlUI/CenterContainerHealth/ProgressBar
@onready var bar_growth: ProgressBar = $CanvasLayer/ControlUI/CenterContainerGrowth/ProgressBar
@onready var label_time: Label = $CanvasLayer/ControlUI/LabelTime
@onready var label_lakes: Label = $CanvasLayer/ControlUI/LabelLakes
@onready var color_rect: ColorRect = $CanvasLayer/ColorRect
@onready var vfx_death_snail: Vfx2D = $VfxDeathSnail
@onready var panel_pause: Panel = $CanvasLayer/PanelPause
@onready var check_button_full_screen: CheckButton = $CanvasLayer/PanelPause/MarginContainer/VBoxContainer/CheckButtonFullScreen


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


var show_ui: bool:
	set(value):
		label_time.visible = value
		label_lakes.visible = value
		bar_growth.visible = value
		bar_health.visible = value


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	color_rect.visible = false
	panel_pause.hide()
	
	var asset = ConfigfileHandler.get_value("wallet", "asset")
	if asset:
		update_values(asset)
	apply_values()
	_min_health = health * min_health
	
	_snails_container = Node2D.new()
	_snails_container.name = "Snails"
	add_child(_snails_container)
	_snail_index = -1
	
	_spiders_container = Node2D.new()
	_spiders_container.name = "Spiders"
	add_child(_spiders_container)
	_spider_index = -1
	
	_bar_health_size = bar_health.custom_minimum_size.x
	
	growth = 0.0
	terrain.food_spawned.connect(_food_spawned)
	terrain.food_eaten.connect(_food_eaten)
	terrain.lake_completed.connect(_lake_completed)
	terrain.level_completed.connect(_level_completed)
	
	follow_camera.target = snake.head
	
	AudioManager.audio("bgm_game").play()
	level_intro(1)
	#for i in range(1, 6):
		#for coords in terrain.levels[i]:
			#terrain.spawn_lake(coords, i, i, true)
			#terrain.level = i
	#terrain.level = 6
	#level_intro(6)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _game_ended:
		if color_rect.visible:
			return
		
		if Input.is_action_pressed("fire"):
			if _level > 5:
				next_scene(SCENE_CREDITS, Color.WHITE)
			else:
				next_scene(SCENE_MENU, Color.BLACK)
		
		return
	
	if snake.head.freeze:
		return
	
	_level_time += delta
	if _level_time > level_max_time:
		_game_over("YOU RUN OUT OF TIME")
	elif health <= 0:
		_game_over("YOU RUN OUT OF WATER")
	
	if _game_ended:
		return
	
	if Input.is_action_just_pressed("pause"):
		toggle_pause()
	
	if panel_pause.visible:
		return
	
	var mins := "%02d" % int((level_max_time - _level_time) / 60)
	var secs := "%02d" % (int(level_max_time - _level_time) % 60)
	var mils := "%02d" % int(((level_max_time - _level_time) - int(level_max_time - _level_time)) * 100)
	label_time.text = mins + ":" + secs + ":" + mils
	if level_max_time - _level_time < 60.0:
		label_time.add_theme_color_override("font_color", Color.RED)
	elif level_max_time - _level_time < 120.0:
		label_time.add_theme_color_override("font_color", Color.YELLOW)
	
	#var healthy := health / max_health > min_health
	var healthy := health > _min_health
	var drain := wander_drain * delta
	var lake_points := terrain.lake_points(snake.head.global_position, fill_amount if healthy else 0.0)
	if healthy or lake_points > 0.0:
		health += lake_points * collect_amount * delta
	health -= drain + terrain.distance_points(snake.head.global_position) / dry_resistance
	
	_animals_time += delta
	if _animals_time > animal_spawn_rate:
		_animals_time = 0.0
		_respawn_fishes()


func toggle_pause():
	if panel_pause.visible:
		panel_pause.hide()
		Engine.time_scale = 1.0
	else:
		panel_pause.show()
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			check_button_full_screen.button_pressed = true
		
		Engine.time_scale = 0.0


func next_scene(path: String, color: Color) -> void:
	color_rect.color = Color.TRANSPARENT
	color_rect.visible = true
	AudioManager.audio("bgm_game").stop()
	
	var tween := get_tree().create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(color_rect, "color", color, 1.0)
	
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file(path)


func update_values(asset: Dictionary) -> void:
	if not asset.has("snake"):
		return
	
	for skill in asset["snake"].keys():
		match skill:
			"skin":
				snake.skin = asset["snake"][skill]
			
			"steering_angle":
				steering_angle += steering_angle_maxdiff * asset["snake"][skill]
			
			"collect_amount":
				collect_amount += collect_amount_maxdiff * asset["snake"][skill]
			
			"fill_amount":
				fill_amount += fill_amount_maxdiff * asset["snake"][skill]
			
			"wander_power":
				wander_power += wander_power_maxdiff * asset["snake"][skill]
			
			"wander_drain":
				wander_drain -= wander_drain_maxdiff * asset["snake"][skill]
			
			"dry_resistance":
				dry_resistance += dry_resistance_maxdiff * asset["snake"][skill]
			
			"collision_drain":
				collision_drain -= collision_drain_maxdiff * asset["snake"][skill]
			
			"food_growth":
				food_growth += food_growth_maxdiff * asset["snake"][skill]
			
			"food_health":
				food_health += food_health_maxdiff * asset["snake"][skill]


func apply_values() -> void:
	snake.head.steering_angle = steering_angle
	snake.head.min_power = wander_power
	#snake.head.max_power = sprint_power
	
	bar_health.max_value = part_capacity
	bar_health.value = part_capacity


func level_intro(level: int) -> void:
	snake.head.velocity = Vector2.ZERO
	snake.head.freeze = true
	_animals_time = 0
	_level_labels()
	show_ui = false
	terrain.can_spawn_food = false
	_level_time = 0.0
	wander_drain *= (level - 1) * level_drain_increase + 1
	label_time.remove_theme_color_override("font_color")
	
	match level:
		1:
			_lakes_completed = 3
			await _level_intro(level, "FISH", "STAY AWAY FROM SALTY WATER AND BARREN TERRAIN")
			
			_spawn_fishes()
		
		2:
			_lakes_completed = 0
			await _level_intro(level, "SNAIL, SPIDER", "SNAILS MAY CARRY SPIDER EGGS")
		
		3:
			_lakes_completed = 0
			_remove_spiders()
			_remove_snails()
			await _level_intro(level, "SEAGULL", "SEAGULLS LIKE MEATY FOODS")
			_spawn_seagulls()
		
		4:
			_lakes_completed = 0
			_remove_spiders()
			await _level_intro(level, "CRAB", "FISH IS RICH IN PROTEIN")
			_spawn_crabs()
		
		5:
			_lakes_completed = 0
			await _level_intro(level, "MORE SPIDERS", "DON'T GIVE UP, ALMOST THERE!")
		
		6:
			await _level_intro(level)
	
	label_lakes.text = "Level " + str(level) + " - " + str(_lakes_completed) + "/6"
	_level = level


func _level_labels(level: String = "", animal: String = "", hint: String = "") -> void:
	label_level.text = level
	label_animal.text = animal
	label_hint.text = hint
	
	label_animals.visible = level != ""
	label_hints.visible = level != ""


func _level_intro(level: int, animal: String = "", hint: String = "") -> void:
	var current_zoom := follow_camera.current_zoom
	follow_camera.target = null
	follow_camera.global_position = snake.head.global_position
	follow_camera.zoom = Vector2(0.7, 0.7)
	await get_tree().create_timer(1.0).timeout
	#_remove_snails()
	
	_level_labels("LEVEL " + str(level) if level < 6 else "", animal, hint)
	
	follow_camera.zoom_to(Vector2(0.07, 0.07), Vector2.ZERO, 1.0)
	await get_tree().create_timer(1.0).timeout
	
	if level > 5:
		terrain.level = level
		_game_over("CONGRATULATIONS, ISLAND RESTORED")
		return
	
	await terrain.switch_level(level, 1.0 if level < 2 else 0.5)
	await get_tree().create_timer(2.0).timeout
	
	follow_camera.zoom_to(Vector2(current_zoom, current_zoom), snake.head.global_position, 1.0)
	await get_tree().create_timer(1.0).timeout
	
	follow_camera.target = snake.head
	snake.head.freeze = false
	_level_time = 0.0
	_level_labels()
	show_ui = true
	terrain.can_spawn_food = true


func _game_over(text: String) -> void:
	label_level.text = text
	label_hint.text = "PRESS SPACE TO CONTINUE"
	
	snake.head.velocity = Vector2.ZERO
	snake.head.freeze = true
	_animals_time = 0
	show_ui = false
	_game_ended = true


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


func _spawn_snail(target: Consumable) -> void:
	_snail_index += 1
	var snail: Snail = snail_scene.instantiate() as Snail
	snail.name = "Snail" + str(_snail_index)
	snail.global_position = Vector2.ZERO
	snail.look_at(target.global_position)
	snail.destination_point = target.global_position
	snail.crashed.connect(_snail_crashed)
	snail.sleeping.connect(_snail_sleeping)
	_snails_container.add_child(snail)


func _spawn_spider(snail: Snail) -> void:
	_spider_index += 1
	var spider: Spider = spider_scene.instantiate() as Spider
	spider.name = "Spider" + str(_spider_index)
	spider.global_position = snail.global_position
	spider.look_at(snake.head.global_position)
	spider.donut_outer_radius = spider_max_radius
	spider.bitten.connect(_bite_received)
	_spiders_container.add_child(spider)


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


func _respawn_fishes() -> void:
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


func _remove_spiders() -> void:
	for spider in _spiders_container.get_children():
		spider.queue_free()


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
	consumable.expire_time = terrain.food_expire_time
	for meta in fish.get_meta_list():
		consumable.set_meta(meta, fish.get_meta(meta))
	consumable.set_meta("seagull_wants", true)
	consumable.catched.connect(terrain._on_food_eaten)
	consumable.global_position = crab.global_position
	consumable.monitorable = false
	consumable.monitoring = false
	consumable.visible = false
	terrain.add_child(consumable)
	crab.consumable = consumable
	
	fish.queue_free()


func _snail_crashed(snail: SteeringAgent) -> void:
	health -= collision_drain
	var consumable := terrain.consumable_scene.instantiate() as Consumable
	consumable.setup(
		-collision_drain,
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
	
	follow_camera.shake_camera(0.3)
	
	vfx_death_snail.global_position = snail.global_position
	vfx_death_snail.play()
	AudioManager.audio("sfx_snail_crashed").play()
	snail.queue_free()


func _snail_sleeping(snail: Snail) -> void:
	if snake.head.global_position.distance_to(snail.global_position) < spider_spawn_light_distance:
		if _level == spider_spawn_light_level and randf_range(0.0, 1.0) < spider_spawn_light_chance:
			_spawn_spider(snail)
			vfx_death_snail.global_position = snail.global_position
			vfx_death_snail.play()
			AudioManager.audio("sfx_snail_crashed").play()
			snail.die()
		elif _level == spider_spawn_hard_level and randf_range(0.0, 1.0) < spider_spawn_hard_chance:
			_spawn_spider(snail)


func _food_spawned(food: Consumable) -> void:
	AudioManager.audio("sfx_food_spawned").play()
	
	if _level >= spider_spawn_light_level:
		_spawn_snail(food)


func _food_eaten(value: float) -> void:
	health += value * food_health
	growth += value * food_growth
	if growth >= part_capacity:
		if snake.body_parts.size() < 15:
			growth = 0.0
			snake.grow()
			bar_health.max_value = max_health
			bar_health.custom_minimum_size.x = _bar_health_size * snake.body_parts.size()
			follow_camera.zoom_out(0.7, 0.7)
		
		bar_health.value = max_health
		AudioManager.audio("sfx_snake_upgraded").play()
	else:
		AudioManager.audio("sfx_food_eaten").play()


func _bite_received() -> void:
	health -= collision_drain
	AudioManager.audio("sfx_spider_bite").play()


func _lake_completed() -> void:
	_lakes_completed += 1
	label_lakes.text = "Level " + str(_level) + " - " + str(_lakes_completed) + "/6"


func _level_completed(level: int) -> void:
	AudioManager.audio("sfx_level_completed").play()
	level_intro(level + 1)


func _on_check_button_full_screen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_button_resume_pressed() -> void:
	toggle_pause()


func _on_button_quit_pressed() -> void:
	toggle_pause()
	next_scene(SCENE_MENU, Color.BLACK)
