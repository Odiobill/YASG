extends Node


@export var audio: Array[AudioStreamPlayer]
var _players: Dictionary


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_players = {}
	for player in audio:
		_players[player.name] = player
		print(player.name)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func get_player(title: String) -> AudioStreamPlayer:
	print(title)
	if _players.has(title):
		return _players[title]
	
	return null


func play(title: String, player: AudioStreamPlayer = null) -> void:
	if _players.has(title):
		if player == null:
			player = _players[title]
		
		player.play()
