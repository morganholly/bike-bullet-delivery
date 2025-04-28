extends Node3D


# tuned by hand
var spring_inline_strength: float = 31
var spring_inline_damping: float = -360

@export var slide_grip_strength: float = 1

@export var turn_grip_strength: float = 1

var last_positions: Array[Vector3]
var last_distances: Array[float]
var forces: Array[Vector3]

@onready var rotate_random: Node3D = $rotate_random

@onready var raycast_1: RayCast3D = $rotate_random/raycast1
@onready var raycast_2: RayCast3D = $rotate_random/raycast2
@onready var raycast_3: RayCast3D = $rotate_random/raycast3
@onready var raycast_4: RayCast3D = $rotate_random/raycast4
@onready var raycast_5: RayCast3D = $rotate_random/raycast5
@onready var raycast_6: RayCast3D = $rotate_random/raycast6
@onready var raycast_7: RayCast3D = $rotate_random/raycast7
@onready var raycast_8: RayCast3D = $rotate_random/raycast8
@onready var raycast_9: RayCast3D = $rotate_random/raycast9
@onready var raycast_10: RayCast3D = $rotate_random/raycast10
@onready var raycast_11: RayCast3D = $rotate_random/raycast11
@onready var raycast_12: RayCast3D = $rotate_random/raycast12
@onready var raycast_13: RayCast3D = $rotate_random/raycast13
@onready var raycast_list: Array[RayCast3D] = [raycast_1, raycast_2, raycast_3, raycast_4, raycast_5, raycast_6, raycast_7, raycast_8, raycast_9, raycast_10, raycast_11, raycast_12, raycast_13]

@onready var marker_1: Marker3D = $rotate_random/raycast1/marker
@onready var marker_2: Marker3D = $rotate_random/raycast2/marker
@onready var marker_3: Marker3D = $rotate_random/raycast3/marker
@onready var marker_4: Marker3D = $rotate_random/raycast4/marker
@onready var marker_5: Marker3D = $rotate_random/raycast5/marker
@onready var marker_6: Marker3D = $rotate_random/raycast6/marker
@onready var marker_7: Marker3D = $rotate_random/raycast7/marker
@onready var marker_8: Marker3D = $rotate_random/raycast8/marker
@onready var marker_9: Marker3D = $rotate_random/raycast9/marker
@onready var marker_10: Marker3D = $rotate_random/raycast10/marker
@onready var marker_11: Marker3D = $rotate_random/raycast11/marker
@onready var marker_12: Marker3D = $rotate_random/raycast12/marker
@onready var marker_13: Marker3D = $rotate_random/raycast13/marker
@onready var marker_list: Array[Marker3D] = [marker_1, marker_2, marker_3, marker_4, marker_5, marker_6, marker_7, marker_8, marker_9, marker_10, marker_11, marker_12, marker_13]

@onready var marker_1_pz: Marker3D = $rotate_random/raycast1/marker_pz
@onready var marker_2_pz: Marker3D = $rotate_random/raycast2/marker_pz
@onready var marker_3_pz: Marker3D = $rotate_random/raycast3/marker_pz
@onready var marker_4_pz: Marker3D = $rotate_random/raycast4/marker_pz
@onready var marker_5_pz: Marker3D = $rotate_random/raycast5/marker_pz
@onready var marker_6_pz: Marker3D = $rotate_random/raycast6/marker_pz
@onready var marker_7_pz: Marker3D = $rotate_random/raycast7/marker_pz
@onready var marker_8_pz: Marker3D = $rotate_random/raycast8/marker_pz
@onready var marker_9_pz: Marker3D = $rotate_random/raycast9/marker_pz
@onready var marker_10_pz: Marker3D = $rotate_random/raycast10/marker_pz
@onready var marker_11_pz: Marker3D = $rotate_random/raycast11/marker_pz
@onready var marker_12_pz: Marker3D = $rotate_random/raycast12/marker_pz
@onready var marker_13_pz: Marker3D = $rotate_random/raycast13/marker_pz
@onready var marker_pz_list: Array[Marker3D] = [marker_1_pz, marker_2_pz, marker_3_pz, marker_4_pz, marker_5_pz, marker_6_pz, marker_7_pz, marker_8_pz, marker_9_pz, marker_10_pz, marker_11_pz, marker_12_pz, marker_13_pz]

@onready var marker_px: Marker3D = $marker_px
@onready var marker_pz: Marker3D = $marker_pz
@onready var marker_py: Marker3D = $marker_py

@onready var force_display_x: MeshInstance3D = $force_display_x
@onready var force_display_z: MeshInstance3D = $force_display_z
@onready var force_display_y: MeshInstance3D = $force_display_y
@onready var force_display_point: MeshInstance3D = $force_display_point


func _ready() -> void:
	for i in range(0, len(raycast_list)):
		last_positions.append(Vector3.ZERO)
		last_distances.append(1.0)
		forces.append(Vector3.ZERO)

func _input(event: InputEvent) -> void:
	pass

func update_forces(delta: float, desired_turn_delta: float) -> Vector3:
	var total_force: Vector3
	for i in range(0, len(raycast_list)):
		var rc = raycast_list[i]
		if rc.is_colliding():
			var rel_pos: Vector3 = rc.get_collision_point() - self.global_position
			var rel_dist: Vector3 = rel_pos - marker_list[i].position
			
			# inline force
			var inline_dist: float = rel_dist.dot(marker_list[i].position)
			var inline_delta: float = inline_dist - last_distances[i]
			var inline_force_scale: float = inline_dist * spring_inline_strength - inline_delta * spring_inline_damping
			
			var global_pos_delta = rc.get_collision_point() - last_positions[i]
			
			# slide force
			var slide_delta: float = global_pos_delta.dot(marker_px.global_position - self.global_position)
			var slide_force_scale: float = slide_grip_strength * slide_delta
			
			# turn force
			var forward_delta: float = global_pos_delta.dot(marker_pz_list[i].global_position - marker_list[i].global_position)
			var forward_delta_delta: float = desired_turn_delta - forward_delta
			var forward_force_scale: float = turn_grip_strength * forward_delta_delta
			
			total_force = inline_force_scale * (marker_list[i].global_position - self.global_position)
			forces[i] = total_force / 13
			
			last_positions[i] = rc.get_collision_point()
			last_distances[i] = inline_dist
		else:
			last_positions[i] = marker_list[i].global_position
			last_distances[i] = (marker_list[i].global_position - self.global_position).length()
			forces[i] = Vector3.ZERO
	var total_x = total_force.dot(marker_px.global_position - self.global_position)
	var total_z = total_force.dot(marker_pz.global_position - self.global_position)
	var total_y = total_force.dot(marker_py.global_position - self.global_position)
	force_display_x.position.x = total_x
	force_display_z.position.z = total_z
	force_display_y.position.y = total_y
	force_display_x.mesh.height = total_x * 2
	force_display_z.mesh.height = total_z * 2
	force_display_y.mesh.height = total_y * 2
	force_display_point.position = total_force
	return total_force

@onready var grip_area: Area3D = $grip_area

func area_forces(delta: float) -> void:
	if grip_area.has_overlapping_bodies():
		for body in grip_area.get_overlapping_bodies():
			pass


func _on_grip_area_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	var area_space: RID = PhysicsServer3D.area_get_space(grip_area.get_rid())
	var space_state: PhysicsDirectSpaceState3D = PhysicsServer3D.space_get_direct_state(area_space)
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.set_shape(body.shape_owner_get_owner(body_shape_index).shape)
	var collision_points: Array = space_state.collide_shape(query)

func _on_grip_area_body_shape_exited(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	var body_shape_owner = body.shape_find_owner(body_shape_index)
	var body_shape_node = body.shape_owner_get_owner(body_shape_owner)

@onready var collide_shape: CollisionShape3D = $collide_shape
@onready var shapecast: ShapeCast3D = $ShapeCast3D
@onready var collision_points: MultiMeshInstance3D = $collision_points

var center_force: Vector3

func shapecast_forces(delta: float) -> void:
	if shapecast.get_collision_count() > 0:
		collision_points.multimesh.instance_count = shapecast.get_collision_count()
		var count_scale = 1 / (delta * shapecast.get_collision_count())
		for i in range(shapecast.get_collision_count()):
			var local_pos = self.to_local(shapecast.get_collision_point(i))
			var length = local_pos.length()
			if length < 0:
				var diff = 1 - length
				center_force += 10 * count_scale * diff * shapecast.get_collision_normal(i)
