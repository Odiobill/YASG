extends Node


const FILE_PATH = "user://settings.ini"

var _config := ConfigFile.new()
var _cache := {}


var config: Dictionary:
	get:
		return _cache


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !FileAccess.file_exists(FILE_PATH):
		_defaults()
		_config.save(FILE_PATH)
	
	_config.load(FILE_PATH)
	_defaults()
	for section in _config.get_sections():
		_cache[section] = _load_section(section)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass


func get_value(section: String, key: String) -> Variant:
	if _cache.has(section) and _cache[section].has(key):
		return _cache[section][key]
	
	return null


func set_value(section: String, key: String, value, save := true):
	if save:
		_config.set_value(section, key, value)
		
	if not _cache.has(section):
		_cache[section] = {}
	_cache[section][key] = value
	
	if save:
		_config.save(FILE_PATH)


func erase_section(section: String) -> void:
	_config.erase_section(section)
	_cache.erase(section)
	
	_config.save(FILE_PATH)


func _defaults():
	_config.set_value("project", "snake_nft_uid", "8709b7b6-9e50-456d-904f-4feab5d58f9c")
	if not _config.has_section_key("audio", "volume_master"):
		_config.set_value("audio", "volume_master", 1.0)
	if not _config.has_section_key("audio", "volume_bgm"):
		_config.set_value("audio", "volume_bgm", 1.0)
	if not _config.has_section_key("audio", "volume_sfx"):
		_config.set_value("audio", "volume_sfx", 1.0)


func _load_section(section: String) -> Dictionary:
	var settings := {}
	for key in _config.get_section_keys(section):
		settings[key] = _config.get_value(section, key)
	
	return settings
