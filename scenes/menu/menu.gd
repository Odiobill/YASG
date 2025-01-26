extends Control


signal confirmed(result: bool)
signal verification_completed(result: int)


enum VerificationResult
{
	SUCCESS,
	CANCEL,
	FAILURE,
}

const ASSET_BUTTON := preload("res://scenes/menu/asset_button.tscn")
@export var verification_check_time: int = 7
@export var policy_ids: PackedStringArray
@export var asset_box: AssetBox
@export var title_distance: float
var _config_wallet := ""
var _verification_address := ""
var _verification_uid := ""
var _verification_timer: Timer
var _assets: Array = []
var _asset_buttons: Array[AssetButton] = []
@onready var nmkr: NMKR = $NMKR
@onready var label_title: Label = $TextureRect/LabelTitle
@onready var color_rect: ColorRect = $ColorRect
@onready var panel_confirm: Panel = $PanelConfirm
@onready var panel_verify: Panel = $PanelVerify
@onready var button_verify: Button = $VBoxContainer/ButtonVerify
@onready var button_address: Button = $PanelVerify/VBoxContainer/HBoxContainerAddress/ButtonAddress
@onready var label_amount: Label = $PanelVerify/VBoxContainer/LabelAmount
@onready var label_address: Label = $PanelVerify/VBoxContainer/LabelAddress
@onready var label_wallet: Label = $VBoxContainerWallet/LabelWallet
@onready var container_wallet: VBoxContainer = $VBoxContainerWallet


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	color_rect.visible = true
	color_rect.color = Color.BLACK
	var label_position := label_title.position
	label_title.position.y -= title_distance
	
	_verification_timer = Timer.new()
	_verification_timer.autostart = false
	_verification_timer.one_shot = true
	_verification_timer.timeout.connect(_on_verification_timer_timeout)
	add_child(_verification_timer)

	_update_verify_button()
	
	panel_confirm.visible = false
	panel_verify.visible = false
	
	var tween := get_tree().create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(color_rect, "color", Color.TRANSPARENT, 1.5)
	tween.finished.connect(func(): color_rect.visible = false )
	
	await get_tree().create_timer(0.5).timeout
	tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label_title, "position", label_position, 1.0)
	tween.finished.connect(func(): AudioManager.play("MusicMenu") )

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass


func confirm() -> bool:
	panel_confirm.visible = true
	var result: bool = await confirmed
	
	panel_confirm.visible = false
	return result


func get_snake_stats(asset: Dictionary) -> Dictionary:
	var stats: Dictionary = {}
	
	if asset["policyId"] == asset_box.CHANG_P_ID:
		stats["steering_angle"] = 0.5
		stats["wander_drain"] = 0.5
		stats["sprint_power"] = 0.5
		stats["sprint_drain"] = 0.5
		stats["shot_rate"] = 0.5
		stats["shot_speed"] = 0.5
		stats["shot_drain"] = 0.5
		
	return stats


func _update_verify_button() -> void:
	var config_wallet = ConfigfileHandler.get_value("wallet", "stake_address")
	if config_wallet:
		_config_wallet = str(config_wallet)
		button_verify.text = "FORGET WALLET"
		
		_update_wallet()
	else:
		_config_wallet = ""
		button_verify.text = "VERIFY WALLET"


func _update_wallet() -> void:
	if _asset_buttons.size() > 0:
		for assetButton in _asset_buttons:
			assetButton.queue_free()
		_asset_buttons.clear()
	
	if _config_wallet.length() > 0: 
		label_wallet.text = "LOADING WALLET...\n\nPLEASE WAIT...\n"
		
		var foundChang := false
		_assets = []
		var assets := await nmkr.get_all_assets_in_wallet(_config_wallet)
		print(assets.size())
		var count: int = 0
		for asset in assets:
			count += 1
			print(str(count) + " " + asset["assetName"])
			#print("Found " + asset["policyId"])
			if policy_ids.has(asset["policyId"]):
				if asset["policyId"] not in [ asset_box.SNEK_P_ID, asset_box.CHANG_P_ID ]:
					var metadata := await nmkr.get_metadata_for_token(asset["policyId"], asset["assetNameInHex"])
					asset["metadata"] = metadata
				elif asset["policyId"] == asset_box.CHANG_P_ID:
					if foundChang:
						continue
					foundChang = true
				
				asset["snake"] = get_snake_stats(asset)
				_assets.append(asset)
				
				var button := ASSET_BUTTON.instantiate() as AssetButton
				button.asset = asset
				button.asset_pressed.connect(_handle_asset_pressed)
				_asset_buttons.append(button)
				container_wallet.add_child(button)
		
		label_wallet.text = \
			 _config_wallet.left(7) + \
			"......." + \
			_config_wallet.right(7)
	else:
		label_wallet.text = "PLEASE VERIFY WALLET"


func _handle_asset_pressed(asset: Dictionary) -> void:
	asset_box.asset = asset


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


func _on_button_quit_pressed() -> void:
	var result := await confirm()
	
	if result:
		get_tree().quit()
	else:
		print("Cancel")


func _on_button_address_pressed() -> void:
	DisplayServer.clipboard_set(_verification_address)
	
	label_address.text = "COPIED TO CLIPBOARD!"
	var tween := get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT_IN)
	tween.tween_property(button_address, "scale", Vector2.ZERO, 0.2)
	tween.tween_property(button_address, "scale", Vector2.ONE, 0.2)


func _on_button_cancel_pressed() -> void:
	verification_completed.emit(VerificationResult.CANCEL)


func _on_button_verify_pressed() -> void:
	_handle_verify_button()


func _on_button_yes_pressed() -> void:
	confirmed.emit(true)


func _on_button_no_pressed() -> void:
	confirmed.emit(false)
