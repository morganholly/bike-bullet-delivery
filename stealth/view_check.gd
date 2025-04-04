extends Area3D


@export var max_sight_distance: float = 20
@export var angle_sensitivity: float = 0.5

var max_sight_dist_squared: float = 20
var dot_up_with: Vector3
var sighted_target: bool = false
var target: Node3D


func _ready() -> void:
	max_sight_dist_squared = max_sight_distance * max_sight_distance
	dot_up_with = Vector3(0, 1.6, -0.8).normalized()

func in_sight_range(point: Vector3) -> bool:
	if point.distance_squared_to(self.position) > max_sight_dist_squared:
		return false
	else:
		# gives more fov on sides than top
		var vec_to = (point - self.position).normalized()
		var dot_up = vec_to.dot(dot_up_with)
		var dot_down = vec_to.dot(dot_up_with * Vector3(1, -1, 1))
		return remap(remap(dot_up, -1, 1, 0, 1) * remap(dot_down, -1, 1, 0, 1), 0, 0.5, -1, 1) > remap(angle_sensitivity, 0, 1, -0.3, 0.9)

func set_target(target: Node3D):
	self.target = target
	sighted_target = target != null

func clear_target():
	self.target = null
	sighted_target = false
