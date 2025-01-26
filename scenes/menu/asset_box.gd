class_name AssetBox
extends VBoxContainer


# Called when the node enters the scene tree for the first time.
const SNEK_FONT := preload("res://scenes/menu/fonts/TitanOne-Regular.ttf")
const SNEK_ICON := preload("res://scenes/menu/images/snek.png")
const SNEK_P_ID := "279c909f348e533da5808898f87f9a14bb2c3dfbbacccd631d927a3f"

const CHANG_ICON := preload("res://icon.svg")
const CHANG_P_ID := "17ac801d2ce81747e038d69bc0ccc861dcaad0d10750df4a3897b66d"
const CHANG_MULT: float = 200.0

@export_range(1, 7) var skill_max_stars: int = 5
@export_range(1, 7) var rarity_max_stars: int = 3
@export var game_scene: PackedScene
@export var hide_distance: float
@onready var texture_rect: TextureRect = $TextureRect
@onready var label_name: Label = $TextureRect/LabelName
@onready var label_rarity: Label = $LabelRarity
@onready var label_agility: Label = $LabelAgility
@onready var label_efficacy: Label = $LabelEfficacy
@onready var label_attack: Label = $LabelAttack
@onready var button_play: Button = $VBoxContainer/ButtonPlay


var asset: Dictionary:
	get:
		return asset
	set(value):
		if value.size() == 0 or not value.has("snake"):
			texture_rect.texture = null
			label_rarity.text = ""
			label_name.text = ""
			label_agility.text = ""
			label_efficacy.text = ""
			label_attack.text = ""
			button_play.visible = false
		else:
			var start_position := position
			var tween := get_tree().create_tween()
			tween.set_ease(Tween.EASE_IN)
			tween.tween_property(self, "position", Vector2(position.x, position.y - hide_distance), 0.2)
			await get_tree().create_timer(0.2).timeout
			
			if value.policyId == SNEK_P_ID:
				texture_rect.texture = SNEK_ICON
				label_name.add_theme_font_override("font", SNEK_FONT)
				label_name.add_theme_font_size_override("font_size", 32)
				label_name.text = "SNEK"
				label_rarity.text = range_to_stars(0.0, rarity_max_stars)
			elif value.policyId == CHANG_P_ID:
				texture_rect.texture = CHANG_ICON
				label_name.remove_theme_font_override("font")
				label_name.remove_theme_font_size_override("font_size")
				label_name.text = "CHANG"
				label_rarity.text = range_to_stars(0.0, rarity_max_stars)
			
			label_agility.text = "AGILITY: " + range_to_stars(calculate_agility(value["snake"]), skill_max_stars) + " "
			label_efficacy.text = "EFFICACY: " + range_to_stars(calculate_efficacy(value["snake"]), skill_max_stars) + " "
			label_attack.text = "ATTACK: " + range_to_stars(calculate_attack(value["snake"]), skill_max_stars) + " "
			button_play.visible = true
			
			tween = get_tree().create_tween()
			tween.set_ease(Tween.EASE_IN)
			tween.tween_property(self, "position", start_position, 0.2)
		
		asset = value


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	asset = {}


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass


func calculate_agility(skills: Dictionary) -> float:
	var value: float = 0.0
	
	if skills.has("steering_angle"):
		value += skills["steering_angle"]
	
	if skills.has("wander_power"):
		value += skills["wander_power"]
	
	if skills.has("sprint_power"):
		value += skills["sprint_power"]
	
	return value / 3


func calculate_efficacy(skills: Dictionary) -> float:
	var value: float = 0.0
	
	if skills.has("collect_rate"):
		value += skills["collect_rate"]
	
	if skills.has("part_size"):
		value += skills["part_size"]
	
	if skills.has("part_capacity"):
		value += skills["part_capacity"]
	
	if skills.has("part_bonus"):
		value += skills["part_bonus"]
	
	if skills.has("wander_drain"):
		value += skills["wander_drain"]
	
	if skills.has("sprint_drain"):
		value += skills["sprint_drain"]
	
	if skills.has("food_bonus"):
		value += skills["food_bonus"]
	
	return value / 7


func calculate_attack(skills: Dictionary) -> float:
	var value: float = 0.0
	
	if skills.has("shot_rate"):
		value += skills["shot_rate"]
	
	if skills.has("shot_speed"):
		value += skills["shot_speed"]
	
	if skills.has("shot_distance"):
		value += skills["shot_distance"]
	
	return value / 3


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


func _on_button_play_pressed() -> void:
	ConfigfileHandler.set_value("wallet", "asset", asset, false)
	
	get_tree().change_scene_to_packed(game_scene)
