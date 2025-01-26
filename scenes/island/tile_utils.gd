extends TileMapLayer


@export var tile: Vector2i
@export var terrain_set: int = -1
@export var terrain: int = 0
@export var min_radius: float = 0.0
@export var max_radius: float = 0.0
@export var alternative_tiles: Array[PackedVector2Array]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if max_radius > 0.0:
		var terrain_cells: Array[Vector2i] = []
		for x in range(max_radius + 10):
			for y in range(max_radius + 10):
				var tile_position := Vector2(x, y)
				if tile_position.length() <= max_radius and tile_position.length() >= min_radius:
					terrain_cells.append_array([
						Vector2i(x, y),
						Vector2i(-x - 1, y),
						Vector2i(x, -y - 1),
						Vector2i(-x - 1, -y - 1),
					])
		
		if terrain_set >= 0:
			set_cells_terrain_connect(terrain_cells, terrain_set, terrain)
		else:
			for cell in terrain_cells:
				set_cell(cell, 0, tile)
		
	if alternative_tiles.size() > 0:
		var used_cells := get_used_cells()
		for cell in used_cells:
			var atlas_tile := get_cell_atlas_coords(cell)
			for i in alternative_tiles.size():
				if atlas_tile == Vector2i(alternative_tiles[i][0]):
					set_cell(cell, 0, alternative_tiles[i][randi_range(0, alternative_tiles[i].size() - 1)])
					break


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
