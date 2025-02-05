extends SteeringAgent


@export var wander_circle_distance: float = 256.0
@export var wander_circle_radius: float = 32.0
@export var angle_change_range: float = 0.3
@export var donut_inner_radius: float = 0.0
@export var donut_outer_radius: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready():
	animation([ Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0) ], 0.2, true)


func _get_steering() -> Vector2:
	return \
		wander(wander_circle_distance, wander_circle_radius, angle_change_range) \
		+ circle_constrain(donut_outer_radius, 3.0) \
		+ circle_constrain(donut_inner_radius, 3.0, false)
