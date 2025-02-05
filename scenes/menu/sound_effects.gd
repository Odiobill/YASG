extends Node


@export var mouse_entered_sound: String
@export var focus_entered_sound: String
@export var pressed_sound: String


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var parent: Node = get_parent()
	if parent is Button:
		var button := parent as Button
		if mouse_entered_sound != "":
			button.mouse_entered.connect(_focus_entered)
		if focus_entered_sound != "":
			button.focus_entered.connect(_focus_entered)
		if pressed_sound != "":
			button.pressed.connect(_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass


func _mouse_entered() -> void:
	var sound := AudioManager.audio(mouse_entered_sound)
	if sound != null:
		sound.play()


func _focus_entered() -> void:
	var sound := AudioManager.audio(focus_entered_sound)
	if sound != null:
		sound.play()


func _pressed() -> void:
	var sound := AudioManager.audio(pressed_sound)
	if sound != null:
		sound.play()
