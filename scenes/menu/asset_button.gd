class_name AssetButton
extends Button


signal asset_pressed(asset: Dictionary)


const SNEK_FONT := preload("res://scenes/menu/fonts/TitanOne-Regular.ttf")
const SNEK_ICON := preload("res://scenes/menu/images/snek.png")
const SNEK_P_ID := "279c909f348e533da5808898f87f9a14bb2c3dfbbacccd631d927a3f"

const CHANG_ICON := preload("res://icon.svg")
const CHANG_P_ID := "17ac801d2ce81747e038d69bc0ccc861dcaad0d10750df4a3897b66d"

var asset: Dictionary = {}
@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if asset.size() == 0:
		return
	
	if asset["policyId"] == SNEK_P_ID:
		texture_rect.texture = SNEK_ICON
		add_theme_font_override("font", SNEK_FONT)
		add_theme_font_size_override("font_size", 32)
		text = "SNEK"
		label.text = ""
	elif asset["policyId"] == CHANG_P_ID:
		texture_rect.texture = CHANG_ICON
		text = "CHANG"
		#label.text = str(int(asset.assetName.right(4)))
		label.text = ""


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass


func _on_pressed() -> void:
	asset_pressed.emit(asset)
