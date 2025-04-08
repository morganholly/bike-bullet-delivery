@tool

extends RigidBody3D

@onready var collision_polygon_3d_1: CollisionPolygon3D = $CollisionPolygon3D1
@onready var collision_polygon_3d_2: CollisionPolygon3D = $CollisionPolygon3D2
@onready var collision_polygon_3d_3: CollisionPolygon3D = $CollisionPolygon3D3
@onready var collision_polygon_3d_4: CollisionPolygon3D = $CollisionPolygon3D4
@onready var collision_polygon_3d_5: CollisionPolygon3D = $CollisionPolygon3D5
@onready var collision_polygon_3d_6: CollisionPolygon3D = $CollisionPolygon3D6
@onready var collision_polygon_3d_7: CollisionPolygon3D = $CollisionPolygon3D7
@onready var collision_polygon_3d_8: CollisionPolygon3D = $CollisionPolygon3D8

#@onready var csg_cylinder_3d: CSGCylinder3D = $CSGCylinder3D

@onready var is_ready: bool = true

@export var width: float = 1:
	set(value):
		width = value
		if is_ready:
			collision_polygon_3d_1.depth = value
			collision_polygon_3d_2.depth = value
			collision_polygon_3d_3.depth = value
			collision_polygon_3d_4.depth = value
			collision_polygon_3d_5.depth = value
			collision_polygon_3d_6.depth = value
			collision_polygon_3d_7.depth = value
			collision_polygon_3d_8.depth = value
			#csg_cylinder_3d.height = value

@export var rotate: float = 0:
	set(value):
		rotate = value
		if is_ready:
			collision_polygon_3d_1.rotation.z = value
			collision_polygon_3d_2.rotation.z = value + 0.5 * PI
			collision_polygon_3d_3.rotation.z = value + PI
			collision_polygon_3d_4.rotation.z = value + 1.5 * PI
			collision_polygon_3d_5.rotation.z = value + 0.25 * PI
			collision_polygon_3d_6.rotation.z = value + 0.75 * PI
			collision_polygon_3d_7.rotation.z = value + 1.25 * PI
			collision_polygon_3d_8.rotation.z = value + 1.75 * PI

@export var radius: float = 1:
	set(value):
		radius = value
		if is_ready:
			collision_polygon_3d_1.scale = Vector3(value, value, value)
			collision_polygon_3d_2.scale = Vector3(value, value, value)
			collision_polygon_3d_3.scale = Vector3(value, value, value)
			collision_polygon_3d_4.scale = Vector3(value, value, value)
			collision_polygon_3d_5.scale = Vector3(value, value, value)
			collision_polygon_3d_6.scale = Vector3(value, value, value)
			collision_polygon_3d_7.scale = Vector3(value, value, value)
			collision_polygon_3d_8.scale = Vector3(value, value, value)
			collision_polygon_3d_1.position = value * Vector3( 1,      0,     0)
			collision_polygon_3d_2.position = value * Vector3( 0,      1,     0)
			collision_polygon_3d_3.position = value * Vector3(-1,      0,     0)
			collision_polygon_3d_4.position = value * Vector3( 0,     -1,     0)
			collision_polygon_3d_5.position = value * Vector3 (0.707,  0.707, 0)
			collision_polygon_3d_6.position = value * Vector3(-0.707,  0.707, 0)
			collision_polygon_3d_7.position = value * Vector3(-0.707, -0.707, 0)
			collision_polygon_3d_8.position = value * Vector3( 0.707, -0.707, 0)
			#csg_cylinder_3d.radius = value

func _ready() -> void:
	width = width
	rotate = rotate
	radius = radius
