@tool
extends Node3D


var recalc_area: bool = true
@export var min_y: float = -10:
	set(value):
		min_y = value
		recalc_area = true
@export var max_y: float = 10:
	set(value):
		max_y = value
		recalc_area = true
@export var min_x: float = -100:
	set(value):
		min_x = value
		recalc_area = true
@export var max_x: float = 100:
	set(value):
		max_x = value
		recalc_area = true
@export var min_z: float = -100:
	set(value):
		min_z = value
		recalc_area = true
@export var max_z: float = 100:
	set(value):
		max_z = value
		recalc_area = true


@onready var collision_shape_3d: CollisionShape3D = $"Valid Area/CollisionShape3D"


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		if recalc_area:
			recalc_area = false
			
			var avg_y: float = (max_y + min_y) / 2
			var width_y: float = abs(max_y - min_y)
			
			var avg_x: float = (max_x + min_x) / 2
			var width_x: float = abs(max_x - min_x)
			
			var avg_z: float = (max_z + min_z) / 2
			var width_z: float = abs(max_z - min_z)
			
			collision_shape_3d.position = Vector3(avg_x, avg_y, avg_z)
			collision_shape_3d.shape.size = Vector3(width_x, width_y, width_z)


@export var scene: PackedScene
@export var num_items: int = 100
var current_num_items: int = 0
@export var height_up_check: float = 200
