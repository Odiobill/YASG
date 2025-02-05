extends Node


var _players: Dictionary = {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for node in get_children():
		if node is AudioStreamPlayer:
			audio(node.name, node as AudioStreamPlayer)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func audio(title: String, player: AudioStreamPlayer = null) -> AudioStreamPlayer:
	if player == null:
		if _players.has(title):
			return _players[title]
		return null
	else:
		_players[title] = player
		return player


func bus_volume(bus: String, volume: float):
	var index := AudioServer.get_bus_index(bus)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(volume))
