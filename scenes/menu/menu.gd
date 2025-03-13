extends Control


signal confirmed(result: bool)
signal verification_completed(result: int)


enum VerificationResult
{
	SUCCESS,
	CANCEL,
	FAILURE,
}

const HANDLE_P_ID := "f0ff48bbb7bbe9d59a40f1ce90e9e9d0ff5002ec48f232b49ca0fb9a"
const ASSET_BUTTON := preload("res://scenes/menu/asset_button.tscn")

@export var sprites: Array[Sprite2D]
@export var animation_min_time: float = 3.0
@export var animation_max_time: float = 10.0
@export var animation_min_speed: float = 0.1
@export var animation_max_speed: float = 0.2
@export var verification_check_time: int = 7
@export var policy_ids: PackedStringArray
@export var asset_box: AssetBox
@export var title_distance: float
var _config_wallet := ""
var _verification_address := ""
var _verification_uid := ""
var _verification_timer: Timer
var _asset_buttons: Array[AssetButton] = []
var _animations: Array[Dictionary] = []
var _volumeMaster: float
var _volumeBgm: float
var _volumeSfx: float
@onready var nmkr: NMKR = $NMKR
@onready var label_title: Label = $TextureRect/LabelTitle
@onready var color_rect: ColorRect = $ColorRect
@onready var panel_confirm: Panel = $PanelConfirm
@onready var panel_settings: Panel = $PanelSettings
@onready var panel_verify: Panel = $PanelVerify
@onready var panel_error: Panel = $PanelError
@onready var panel_click_shield: Panel = $PanelClickShield
@onready var button_settings: Button = $VBoxContainer/ButtonSettings
@onready var button_close_settings: Button = $PanelSettings/VBoxContainer/HBoxContainerSettings/ButtonCloseSettings
@onready var button_verify: Button = $VBoxContainer/ButtonVerify
@onready var button_quit: Button = $VBoxContainer/ButtonQuit
@onready var button_address: Button = $PanelVerify/VBoxContainer/HBoxContainerAddress/ButtonAddress
@onready var button_yes: Button = $PanelConfirm/VBoxContainer/HBoxContainer/ButtonYes
@onready var button_no: Button = $PanelConfirm/VBoxContainer/HBoxContainer/ButtonNo
@onready var label_amount: Label = $PanelVerify/VBoxContainer/LabelAmount
@onready var label_address: Label = $PanelVerify/VBoxContainer/LabelAddress
@onready var label_wallet: Label = $VBoxContainerWallet/LabelWallet
@onready var container_wallet: VBoxContainer = $VBoxContainerWallet
@onready var h_slider_master: HSlider = $PanelSettings/VBoxContainer/HBoxContainerSettings/HSliderMaster
@onready var h_slider_music: HSlider = $PanelSettings/VBoxContainer/HBoxContainerSettings/HSliderMusic
@onready var h_slider_effects: HSlider = $PanelSettings/VBoxContainer/HBoxContainerSettings/HSliderEffects
@onready var check_button_full_screen: CheckButton = $CheckButtonFullScreen


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_volumeMaster = ConfigfileHandler.get_value("audio", "volume_master")
	h_slider_master.value = _volumeMaster
	_volumeBgm = ConfigfileHandler.get_value("audio", "volume_bgm")
	h_slider_music.value = _volumeBgm
	_volumeSfx = ConfigfileHandler.get_value("audio", "volume_sfx")
	h_slider_effects.value = _volumeSfx
	
	check_button_full_screen.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN 
	
	color_rect.visible = true
	color_rect.color = Color.BLACK
	var label_position := label_title.position
	label_title.position.y -= title_distance
	panel_click_shield.visible = false
	
	#AudioManager.bus_volume("bgm", 0.1)
	_verification_timer = Timer.new()
	_verification_timer.autostart = false
	_verification_timer.one_shot = true
	_verification_timer.timeout.connect(_on_verification_timer_timeout)
	add_child(_verification_timer)
	
	nmkr.error.connect(_on_nmkr_error)
	
	_update_verify_button()
	
	panel_settings.visible = false
	panel_confirm.visible = false
	panel_verify.visible = false
	
	for sprite: Sprite2D in sprites:
		_animations.append({
			"sprite": sprite,
			"time_max": randf_range(animation_min_time, animation_max_time),
			"time_elapsed": 0.0,
		})
	
	var tween := get_tree().create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(color_rect, "color", Color.TRANSPARENT, 1.5)
	tween.finished.connect(func(): color_rect.visible = false )
	
	await get_tree().create_timer(0.5).timeout
	tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label_title, "position", label_position, 1.0)
	tween.finished.connect(func(): AudioManager.audio("bgm_menu").play())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for i in _animations.size():
		_animations[i]["time_elapsed"] += delta
		if _animations[i]["time_elapsed"] > _animations[i]["time_max"]:
			_animations[i]["time_elapsed"] = 0.0
			_animations[i]["time_max"] = randf_range(animation_min_time, animation_max_time)
			
			_animate(
				_animations[i]["sprite"],
				_animations[i]["sprite"].hframes * randf_range(animation_min_speed, animation_max_speed)
			)


func confirm() -> bool:
	panel_click_shield.visible = true
	panel_confirm.visible = true
	var result: bool = await confirmed
	
	panel_confirm.visible = false
	panel_click_shield.visible = false
	return result


func get_snake_stats(asset: Dictionary) -> Dictionary:
	var stats: Dictionary = {}
	
	if asset["policyId"] == asset_box.SNEK_P_ID:
		stats["skin"] = 0
	elif asset["policyId"] == asset_box.VIPER_P_ID:
		stats["skin"] = 1
	elif asset["policyId"] == asset_box.SNAKE_P_ID:
		var nft_number := int(asset["assetName"].right(5))
		stats["serial"] = nft_number
		stats["skin"] = _skin_index(nft_number) + 2
		var metadata: Dictionary = asset["metadata"]["721"][asset["policyId"]][asset["assetName"]]
		for key in metadata.keys():
			if key in [
				"collect_amount",
				"collision_drain",
				"dry_resistance",
				"fill_amount",
				"food_growth",
				"food_health",
				"steering_angle",
				"wander_drain",
				"wander_power",
			]:
				stats[key] = float(metadata[key])

	return stats


func _string_to_hex(input: String) -> String:
	var hex_string = ""
	for character in input:
		hex_string += "%02X" % character.unicode_at(0)
	return hex_string


func _animate(sprite: Sprite2D, time: float) -> void:
	var tween := get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT_IN)
	tween.tween_property(sprite, "frame", sprite.hframes - 1, time)
	await get_tree().create_timer(time + time / sprite.hframes).timeout
	
	sprite.frame = 0


func _update_verify_button() -> void:
	var config_wallet = ConfigfileHandler.get_value("wallet", "stake_address")
	if config_wallet:
		_config_wallet = str(config_wallet)
		button_verify.text = "FORGET WALLET"
		
		_update_wallet()
	else:
		_config_wallet = ""
		button_verify.text = "VERIFY WALLET"


func _skin_index(image_number: int) -> int:
	var index = image_number - 1
	var layer_textures = [5, 5, 5, 6, 6, 3]
	
	# Calculate the multiplier for the skin layer (Layer 1)
	var skin_multiplier = 1
	for i in range(2, layer_textures.size()):
		skin_multiplier *= layer_textures[i]
	
	# Calculate the skin index
	var skin_index = (index / skin_multiplier) % layer_textures[1]
	
	return skin_index


func _update_wallet() -> void:
	if _asset_buttons.size() > 0:
		for assetButton in _asset_buttons:
			assetButton.queue_free()
		_asset_buttons.clear()
	
	if _config_wallet.length() > 0:
		label_wallet.text = "LOADING WALLET...\n\nPLEASE WAIT...\n"
		
		var os := OS.get_name()
		if os in [ "HTML5", "Web" ]:
			nmkr.accept_gzip = false

		var foundHandle := ""
		
		var assets := await nmkr.get_all_assets_in_wallet(_config_wallet)
		for asset in assets:
			if not asset.has("assetName"):
				continue
			
			var hex := _string_to_hex(asset["assetName"])
			asset["policyId"] = asset["unit"].left(asset["unit"].length() - hex.length())
			
			if asset["unit"].begins_with(HANDLE_P_ID):
				if foundHandle != "":
					continue
				foundHandle = "$" + asset["assetName"].to_upper().left(14)
			elif policy_ids.has(asset["policyId"]):
				if asset["policyId"] not in [ asset_box.SNEK_P_ID, asset_box.VIPER_P_ID ]:
					var metadata := await nmkr.get_metadata_for_token(asset["policyId"], asset["assetNameInHex"])
					asset["metadata"] = metadata
				
				asset["snake"] = get_snake_stats(asset)
				
				var button := ASSET_BUTTON.instantiate() as AssetButton
				button.asset = asset
				button.asset_selected.connect(_handle_asset_selected)
				_asset_buttons.append(button)
				container_wallet.add_child(button)
		
		label_wallet.text = foundHandle if foundHandle != "" else \
			_config_wallet.left(7) + \
			"......." + \
			_config_wallet.right(7)
	else:
		label_wallet.text = "PLEASE VERIFY WALLET"


func _handle_asset_selected(asset: Dictionary) -> void:
	asset_box.asset = asset


func _quit() -> void:
	AudioManager.audio("bgm_menu").stop()
	color_rect.visible = true
	var tween := get_tree().create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(color_rect, "color", Color.BLACK, 1.0)
	tween.finished.connect(func():
		get_tree().quit()
	)


func _handle_verify_button() -> void:
	if _config_wallet.length() > 0:
		var result := await confirm()
		
		if result:
			ConfigfileHandler.erase_section("wallet")
			_update_verify_button()
	else:
		panel_verify.visible = true
		button_address.disabled = true
		var wallet_validation := await nmkr.get_wallet_validation_address()
		
		_verification_address = wallet_validation["address"]
		_verification_uid = wallet_validation["validationUId"]
		button_address.disabled = false
		button_address.text = \
			_verification_address.left(7) \
			+ "......." \
			+ _verification_address.right(7)
		label_amount.text = str(wallet_validation["lovelace"] / 1000000.0) + " ADA"
		
		_verification_timer.start(verification_check_time)
		
		var verification_result: VerificationResult = await verification_completed
		
		if verification_result == VerificationResult.SUCCESS:
			_update_verify_button()
		
		panel_verify.visible = false


func _on_verification_timer_timeout() -> void:
	var validation := await nmkr.check_wallet_validation(_verification_uid)
	
	if validation:
		if validation.has("stakeAddress") and validation["stakeAddress"].length() > 5:
			ConfigfileHandler.set_value("wallet", "stake_address", validation["stakeAddress"])
			verification_completed.emit(VerificationResult.SUCCESS)
		else:
			_verification_timer.start(verification_check_time)
	else:
		verification_completed.emit(VerificationResult.FAILURE)


func _on_button_quit_mouse_entered() -> void:
	button_quit.grab_focus()


func _on_button_quit_pressed() -> void:
	var result := await confirm()
	
	if result:
		_quit()


func _on_button_address_pressed() -> void:
	DisplayServer.clipboard_set(_verification_address)
	
	label_address.text = "COPIED TO CLIPBOARD!"
	var tween := get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT_IN)
	tween.tween_property(button_address, "scale", Vector2.ZERO, 0.2)
	tween.tween_property(button_address, "scale", Vector2.ONE, 0.2)


func _on_button_cancel_pressed() -> void:
	verification_completed.emit(VerificationResult.CANCEL)


func _on_button_verify_mouse_entered() -> void:
	button_verify.grab_focus()


func _on_button_verify_pressed() -> void:
	_handle_verify_button()


func _on_button_yes_pressed() -> void:
	confirmed.emit(true)


func _on_button_yes_mouse_entered() -> void:
	button_yes.grab_focus()


func _on_button_no_mouse_entered() -> void:
	button_no.grab_focus()


func _on_button_no_pressed() -> void:
	confirmed.emit(false)


func _on_button_settings_mouse_entered() -> void:
	button_settings.grab_focus()


func _on_button_settings_pressed() -> void:
	panel_settings.visible = true


func _on_h_slider_master_value_changed(value: float) -> void:
	AudioManager.bus_volume("Master", value)
	_volumeMaster = value


func _on_h_slider_music_value_changed(value: float) -> void:
	AudioManager.bus_volume("BGM", value)
	_volumeBgm = value


func _on_h_slider_effects_value_changed(value: float) -> void:
	AudioManager.bus_volume("SFX", value)
	_volumeSfx = value


func _on_button_close_settings_mouse_entered() -> void:
	button_close_settings.grab_focus()


func _on_button_close_settings_pressed() -> void:
	ConfigfileHandler.set_value("audio", "volume_master", _volumeMaster)
	ConfigfileHandler.set_value("audio", "volume_bgm", _volumeBgm)
	ConfigfileHandler.set_value("audio", "volume_sfx", _volumeSfx)
	
	panel_settings.visible = false


func _on_check_button_full_screen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_nmkr_error(error) -> void:
	push_error(error)
	panel_click_shield.show()
	panel_error.show()


func _on_button_error_pressed() -> void:
	_quit()
