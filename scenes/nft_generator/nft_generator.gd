extends Control


@export var project_uid: String = "60cebe88-2175-47e4-870d-da870b753920"
@export var layer_0: Array[Texture2D]
@export var layer_1: Array[Texture2D]
@export var layer_2: Array[Texture2D]
@export var layer_3: Array[Texture2D]
@export var layer_4: Array[Texture2D]
@export var layer_5: Array[Texture2D]
@export var wait: float = 3.0
@export var start: int = 1
@export var amount: int = 0
@onready var nmkr: NMKR = $NMKR
@onready var texture_rect: TextureRect = $TextureRect
@onready var label_current: Label = $LabelCurrent


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#draw_random()
	generate()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(_delta: float) -> void:
	#if Input.is_action_just_released("fire"):
		#draw_random()


func generate() -> void:
	var current: int = 0
	var total: int = \
		layer_0.size() * \
		layer_1.size() * \
		layer_2.size() * \
		layer_3.size() * \
		layer_4.size() * \
		layer_5.size()
	var count: int = 0
	
	for l0 in layer_0:
		for l1 in layer_1:
			for l2 in layer_2:
				for l3 in layer_3:
					for l4 in layer_4:
						for l5 in layer_5:
							current += 1
							
							if current >= start:
								count += 1
								if amount > 0 and count > amount:
									return
								
								label_current.text = str(current) + " / " + str(total)
								var textures: Array[Texture2D] = [l0, l1, l2, l3, l4, l5]
								var image := ImageTexture.create_from_image(combine_textures(textures))
								texture_rect.texture = image
								
								await upload_nft(image, current)
								await get_tree().create_timer(wait).timeout


func draw_random() -> void:
	var textures: Array[Texture2D] = []
	textures.append(layer_0.pick_random())
	textures.append(layer_1.pick_random())
	textures.append(layer_2.pick_random())
	textures.append(layer_3.pick_random())
	textures.append(layer_4.pick_random())
	textures.append(layer_5.pick_random())
	
	var image := ImageTexture.create_from_image(combine_textures(textures))
	texture_rect.texture = image
	#upload_nft(image, 1)


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


func image_to_base64(image: ImageTexture) -> String:
	return Marshalls.raw_to_base64(image.get_image().save_png_to_buffer())


func upload_nft(image: ImageTexture, index: int) -> void:
	var schema: Dictionary = {
		"tokenname": "Snake_" + "%05d" % index,
		"displayname": "YASG Snake #" + "%05d" % index,
		"description": "A snake that you can use to play YASG",
		"previewImageNft": {
			"mimetype": "image/png",
			"fileFromBase64": image_to_base64(image),
			#"fileFromsUrl": "string",
			#"fileFromIPFS": "string"
		},
		#"subfiles": [
			#{
				#"subfile": {
					#"mimetype": "string",
					#"fileFromBase64": "string",
					#"fileFromsUrl": "string",
					#"fileFromIPFS": "string"
				#},
				#"description": "string",
				#"metadataPlaceholder": [
					#{
						#"name": "string",
						#"value": "string"
					#}
				#]
			#}
		#],
		"metadataPlaceholder": [
			{
				"name": "collect_amount",
				"value": "%.01f" % randf_range(0.0, 1.0)
			},
			{
				"name": "collision_drain",
				"value": "%.01f" % randf_range(0.0, 1.0)
			},
			{
				"name": "dry_resistance",
				"value": "%.01f" % randf_range(0.0, 1.0)
			},
			{
				"name": "fill_amount",
				"value": "%.01f" % randf_range(0.0, 1.0)
			},
			{
				"name": "food_growth",
				"value": "%.01f" % randf_range(0.0, 1.0)
			},
			{
				"name": "food_health",
				"value": "%.01f" % randf_range(0.0, 1.0)
			},
			{
				"name": "steering_angle",
				"value": "%.01f" % randf_range(0.0, 1.0)
			},
			{
				"name": "wander_drain",
				"value": "%.01f" % randf_range(0.0, 1.0)
			},
			{
				"name": "wander_power",
				"value": "%.01f" % randf_range(0.0, 1.0)
			},
		],
		#"metadataOverride": "string",
		#"metadataOverrideCip68": "string",
		#"priceInLovelace": 0,
		#"isBlocked": true
	}
	await nmkr.upload_nft(project_uid, schema)
