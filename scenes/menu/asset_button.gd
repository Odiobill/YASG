class_name AssetButton
extends Button


signal asset_selected(asset: Dictionary)

const SNEK_FONT := preload("res://scenes/menu/fonts/TitanOne-Regular.ttf")
const SNEK_ICON := preload("res://scenes/menu/images/snek.png")
const SNEK_P_ID := "279c909f348e533da5808898f87f9a14bb2c3dfbbacccd631d927a3f"
const VIPER_FONT := preload("res://scenes/menu/fonts/TitanOne-Regular.ttf")
const VIPER_ICON := preload("res://scenes/menu/images/viper.png")
const VIPER_P_ID := "caff93803e51c7b97bf79146790bfa3feb0d0b856ef16113b391b997"
const SNAKE_P_ID := "4b839eb0c2757e3795b181f5884323e163ce2b40d04aab6e04468069"

@export var layer_0: Array[Texture2D]
@export var layer_1: Array[Texture2D]
@export var layer_2: Array[Texture2D]
@export var layer_3: Array[Texture2D]
@export var layer_4: Array[Texture2D]
@export var layer_5: Array[Texture2D]
@export var game_scene: PackedScene
var asset: Dictionary = {}
@onready var texture_rect: TextureRect = $TextureRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if asset.size() == 0:
		return
	
	match asset["policyId"]:
		SNEK_P_ID:
			texture_rect.texture = SNEK_ICON
			add_theme_font_override("font", SNEK_FONT)
			add_theme_font_size_override("font_size", 32)
			text = "SNEK"
		VIPER_P_ID:
			texture_rect.texture = VIPER_ICON
			add_theme_font_override("font", SNEK_FONT)
			add_theme_font_size_override("font_size", 32)
			text = "VIPER"
		SNAKE_P_ID:
			var layers := [ layer_0, layer_1, layer_2, layer_3, layer_4, layer_5 ]
			var indeces := _get_image_layers(asset["snake"]["serial"])
			var textures: Array[Texture2D] = []
			for i in range(1, layers.size()):
				textures.append(layers[i][indeces[i]])
			var image := ImageTexture.create_from_image(combine_textures(textures))
			texture_rect.texture = image
			asset["image"] = image
			text = "YASG " + str(asset["snake"]["serial"])


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass


func combine_textures(textures: Array[Texture2D]) -> Image:
	if textures.is_empty():
		return null
	
	var image_size := textures[0].get_size()
	var combined_image := Image.create(int(image_size.x), int(image_size.y), false, Image.FORMAT_RGBA8)
	combined_image.fill(Color.TRANSPARENT)
	
	for texture in textures:
		var image := texture.get_image()
		
		combined_image.blend_rect(image, Rect2(Vector2.ZERO, image_size), Vector2.ZERO)
	
	return combined_image


func _get_image_layers(image_number: int) -> Array[int]:
	# Convert image number to zero-based index
	var index := image_number - 1
	
	# Define the number of textures in each layer
	var layer_textures := [layer_0.size(), layer_1.size(), layer_2.size(), layer_3.size(), layer_4.size(), layer_5.size()]
	
	# Initialize an array to store the layer indices
	var layers: Array[int] = []
	
	# Calculate the index for each layer
	for i in range(layer_textures.size()):
		# Calculate the multiplier for the current layer
		var multiplier: int = 1
		for j in range(i + 1, layer_textures.size()):
			multiplier *= layer_textures[j]
		
		# Calculate the current layer index
		var layer_index: int = (index / multiplier) % layer_textures[i]
		layers.append(layer_index)
	
	return layers


func _on_pressed() -> void:
	ConfigfileHandler.set_value("wallet", "asset", asset, false)
	
	AudioManager.audio("bgm_menu").stop()
	get_tree().change_scene_to_packed(game_scene)


func _on_mouse_entered() -> void:
	grab_focus()


func _on_focus_entered() -> void:
	AudioManager.audio("sfx_asset_selected").play()
	asset_selected.emit(asset)
