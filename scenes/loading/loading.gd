extends Control


const TEXT_SOLDOUT := "Unfortunately, there are no more YASG NFTs available for minting.\n\nPlease stay tuned for an upcoming season, or try to grab a current one on the secondary market."
const TEXT_ERROR := "Connection error,\n\nplease try again later..."

var _tween_panel: Tween
var _style_panel: StyleBoxFlat
@export var next_scene: PackedScene
@onready var button_game: Button = $VBoxContainer/HSplitContainer/ButtonGame
@onready var button_mint: Button = $VBoxContainer/HSplitContainer/ButtonMint
@onready var panel: Panel = $Panel
@onready var panel_message: Panel = $PanelMessage
@onready var panel_message_label: Label = $PanelMessage/Label
@onready var panel_message_button: Button = $PanelMessage/Button
@onready var nmkr: NMKR = $NMKR


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	panel_message.visible = false
	button_game.grab_focus()
	_style_panel = panel.get_theme_stylebox("panel") as StyleBoxFlat
	await get_tree().create_timer(1.0).timeout
	
	if _style_panel.bg_color != Color.TRANSPARENT:
		_tween_panel = get_tree().create_tween()
		_tween_panel.set_ease(Tween.EASE_OUT_IN)
		_tween_panel.tween_property(_style_panel, "bg_color", Color.TRANSPARENT, 1.0)
		_tween_panel.finished.connect(func(): panel.visible = false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass


func _message(text := "") -> void:
	if text.length() > 0:
		panel_message.visible = true
		panel_message_button.grab_focus()
		panel_message_label.text = text
	else:
		panel_message_label.text = ""
		panel_message.visible = false
		button_game.grab_focus()


func _on_button_game_pressed() -> void:
	button_mint.disabled = true
	if _tween_panel != null:
		_tween_panel.stop()
	
	panel.visible = true
	_style_panel.bg_color = Color.TRANSPARENT
	_tween_panel = get_tree().create_tween()
	_tween_panel.set_ease(Tween.EASE_OUT_IN)
	_tween_panel.tween_property(_style_panel, "bg_color", Color.BLACK, 1.0)
	_tween_panel.finished.connect(func(): get_tree().change_scene_to_packed(next_scene))
	print("Load Game")


func _on_button_mint_pressed() -> void:
	button_mint.disabled = true
	var uid: String = ConfigfileHandler.get_value("project", "snake_nft_uid")
	var nfts := await nmkr.get_counts(uid)
	if nfts.has("free") and nfts["free"] > 7:
		var payment_request := {
			"projectUid": uid,
			"paymentTransactionType": "nmkr_pay_random",
			"paymentgatewayParameters": {
				"mintNfts": {
					"countNfts": 1,
				},
			}
		}
		var payment_transaction := await nmkr.get_nmkr_pay_link(payment_request)
		if payment_transaction.has("nmkrPayUrl"):
			var url: String = payment_transaction["nmkrPayUrl"]
			if OS.get_name() == "HTML5":
				JavaScriptBridge.eval("window.open('" + url + "', '_blank').focus()")
			else:
				OS.shell_open(url)
		else:
			_message(TEXT_ERROR)
		
		button_mint.disabled = false
	else:
		_message(TEXT_SOLDOUT)


func _on_panel_message_button_pressed() -> void:
	_message()
