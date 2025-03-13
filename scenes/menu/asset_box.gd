class_name AssetBox
extends VBoxContainer


# Called when the node enters the scene tree for the first time.
const SNEK_FONT := preload("res://scenes/menu/fonts/TitanOne-Regular.ttf")
const SNEK_ICON := preload("res://scenes/menu/images/snek.png")
const SNEK_P_ID := "279c909f348e533da5808898f87f9a14bb2c3dfbbacccd631d927a3f"
const VIPER_FONT := preload("res://scenes/menu/fonts/TitanOne-Regular.ttf")
const VIPER_ICON := preload("res://scenes/menu/images/viper.png")
const VIPER_P_ID := "caff93803e51c7b97bf79146790bfa3feb0d0b856ef16113b391b997"
const SNAKE_P_ID := "4b839eb0c2757e3795b181f5884323e163ce2b40d04aab6e04468069"
const STAR_FULL := preload("res://scenes/menu/images/ui_star_full.png")
const STAR_EMPTY := preload("res://scenes/menu/images/ui_star_empty.png")

@export_range(1, 7) var skill_max_stars: int = 5
@export var game_scene: PackedScene
@export var hide_distance: float
var _show_position: Vector2
@onready var texture_rect: TextureRect = $TextureRect
@onready var label_name: Label = $TextureRect/LabelName
@onready var efficiency: HBoxContainer = $Efficiency
@onready var agility: HBoxContainer = $Agility
@onready var resistance: HBoxContainer = $Resistance


var asset: Dictionary:
	get:
		return asset
	set(value):
		if value.size() == 0 or not value.has("snake"):
			texture_rect.texture = null
			label_name.text = ""
			efficiency.visible = false
			agility.visible = false
			resistance.visible = false
		else:
			position = Vector2(_show_position.x, _show_position.y - hide_distance)
			
			if value.policyId == SNEK_P_ID:
				texture_rect.texture = SNEK_ICON
				label_name.add_theme_font_override("font", SNEK_FONT)
				label_name.add_theme_font_size_override("font_size", 32)
				label_name.text = "SNEK"
			elif value.policyId == VIPER_P_ID:
				texture_rect.texture = VIPER_ICON
				label_name.add_theme_font_override("font", SNEK_FONT)
				label_name.add_theme_font_size_override("font_size", 32)
				label_name.text = "VIPER"
			elif value.policyId == SNAKE_P_ID:
				texture_rect.texture = value["image"]
				label_name.remove_theme_font_override("font")
				label_name.remove_theme_font_size_override("font_size")
				label_name.text = "YASG " + str(value["snake"]["serial"])
			
			efficiency.visible = true
			agility.visible = true
			resistance.visible = true
			texture_stars(agility, calculate_agility(value["snake"]))
			texture_stars(efficiency, calculate_efficacy(value["snake"]))
			texture_stars(resistance, calculate_resistance(value["snake"]))
			var tween := get_tree().create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "position", _show_position, 0.3)
		
		asset = value


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_show_position = position
	asset = {}


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass


func calculate_agility(skills: Dictionary) -> float:
	var value: float = 0.0
	
	if skills.has("collect_amount"):
		value += skills["collect_amount"]
	
	if skills.has("steering_angle"):
		value += skills["steering_angle"]
	
	if skills.has("wander_power"):
		value += skills["wander_power"]
	
	return value / 3


func calculate_efficacy(skills: Dictionary) -> float:
	var value: float = 0.0
	
	if skills.has("fill_amount"):
		value += skills["fill_amount"]
	
	if skills.has("food_growth"):
		value += skills["food_growth"]
	
	if skills.has("food_health"):
		value += skills["food_health"]
	
	return value / 3


func calculate_resistance(skills: Dictionary) -> float:
	var value: float = 0.0
	
	if skills.has("wander_drain"):
		value += skills["wander_drain"]
	
	if skills.has("dry_resistance"):
		value += skills["dry_resistance"]
	
	if skills.has("collision_drain"):
		value += skills["collision_drain"]
	
	return value / 3


func texture_stars(container: HBoxContainer, value: float, max_value: float = 1.0) -> void:
	value = clamp(value, 0, max_value)
	var textures: Array[TextureRect] = []
	for child in container.get_children():
		if child is TextureRect:
			textures.append(child)
	var full_stars := int(round(value / max_value * textures.size()))
	for i in textures.size():
		textures[i].texture = STAR_FULL if i < full_stars else STAR_EMPTY


func range_to_stars(value: float, max_stars: int, max_value: float = 1.0, full_star := "★", empty_star := "☆") -> String:
	var stars: String = ""
	
	# Ensure value is within valid range
	value = clamp(value, 0, max_value)
	
	# Calculate the number of full stars based on the value proportion
	var full_stars := int(round(value / max_value * max_stars))
	
	# Ensure full_stars is within the valid range
	full_stars = clamp(full_stars, 0, max_stars)
	
	# Create the stars string by manually concatenating
	for i in range(full_stars):
		stars += " " + full_star
	for i in range(max_stars - full_stars):
		stars += " " + empty_star
	
	return stars.strip_edges()
