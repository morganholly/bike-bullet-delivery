extends Node

# Configuration
@export var grid_size: float = 5.0  # Size of each grid cell
@export var max_height: float = 2.0  # Maximum height above ground for valid spawn
@export var min_height: float = 0.1  # Minimum height above ground for valid spawn
@export var check_radius: float = 1.0  # Radius to check around spawn point
@export var show_debug_visualization: bool = true  # Whether to show debug visualization
@export var debug_mode: bool = true  # Enable detailed debug logging
@export var use_all_collision_layers: bool = true  # Use all collision layers for ground detection
@export var force_valid_points: bool = true  # Force some points to be valid even if they fail checks
@export var max_height_difference: float = 2.0

# Cache for valid spawn points
var valid_spawn_points: Array[Vector3] = []
var is_initialized: bool = false
var debug_markers: Array[Node3D] = []  # Store debug visualization markers

# Collision masks - using bit flags for proper masking
const BUILDING_MASK = 1 << 2  # Layer 3 (0-based index)
const VEHICLE_MASK = 1 << 3   # Layer 4 (0-based index)
const GROUND_MASK = 1 << 0    # Layer 1 (0-based index)
const ALL_MASK = 0xFFFFFFFF   # All layers

func _ready():
	# Initializing spawn area detection system...
	reinitialize_spawn_points()

func _process(_delta):
	# Update debug visualization if enabled
	if show_debug_visualization and is_initialized:
		update_debug_visualization()

func reinitialize_spawn_points():
	# Clear existing points
	valid_spawn_points.clear()
	
	# Get level bounds
	var level_bounds = _get_level_bounds()
	# Level bounds: " + str(level_bounds)
	
	# Create spawn grid
	_create_spawn_grid(level_bounds)
	
	# If no valid points found, force some
	if valid_spawn_points.size() == 0:
		# No valid points found, forcing some valid points
		_force_valid_points(10)
	
	# Spawn area detection system initialized with " + str(valid_spawn_points.size()) + " valid points

func _force_valid_points(num_forced_points: int):
	# Created " + str(num_forced_points) + " forced valid points
	pass

func _get_level_bounds() -> Dictionary:
	var static_bodies = get_tree().get_nodes_in_group("StaticBody")
	# Found " + str(static_bodies.size()) + " static bodies
	
	if static_bodies.size() == 0:
		# No static bodies found, trying to get bounds from level
		var level = get_tree().get_first_node_in_group("Level")
		if level:
			return {"min": Vector3(-100, 0, -100), "max": Vector3(100, 0, 100)}
	
	# Still no bounds found, using default area
	return {"min": Vector3(-100, 0, -100), "max": Vector3(100, 0, 100)}

func _create_spawn_grid(bounds: Dictionary):
	var min_pos = bounds["min"]
	var max_pos = bounds["max"]
	# Level bounds: min=" + str(min_pos) + ", max=" + str(max_pos)
	
	# Creating spawn grid from " + str(min_pos) + " to " + str(max_pos)
	var point_count = 0
	var valid_count = 0
	
	# Checked " + str(point_count) + " points, found " + str(valid_count) + " valid spawn points

func _is_valid_spawn_point(point: Vector3) -> bool:
	# Check for ground
	var ground = _get_ground_at_point(point)
	if not ground:
		# No ground found at point " + str(point)
		return false
	
	# Check height
	var ground_height = ground.global_position.y
	if abs(point.y - ground_height) > max_height_difference:
		# Height check failed at point " + str(point) + ", ground height: " + str(ground_height)
		return false
	
	# Check for collisions
	var collisions = _get_collisions_at_point(point)
	if collisions.size() > 0:
		# Collision check failed at point " + str(point) + ", found " + str(collisions.size()) + " collisions
		return false
	
	# Check for roof
	if _has_roof_at_point(point):
		# Roof check failed at point " + str(point)
		return false
	
	# Found valid spawn point at " + str(point)
	return true

func _create_debug_visualization():
	# Created debug visualization with " + str(debug_markers.size()) + " markers
	pass

func _toggle_debug_visualization():
	show_debug_visualization = !show_debug_visualization
	# Debug visualization " + ("enabled" if show_debug_visualization else "disabled")

func get_random_spawn_point() -> Vector3:
	if valid_spawn_points.size() == 0:
		push_error("No valid spawn points available")
		return Vector3.ZERO
		
	return valid_spawn_points[randi() % valid_spawn_points.size()]

func get_spawn_point_near(position: Vector3, max_distance: float = 20.0) -> Vector3:
	if valid_spawn_points.size() == 0:
		push_error("No valid spawn points available")
		return Vector3.ZERO
		
	# Find closest valid spawn point within max_distance
	var closest_point = valid_spawn_points[0]
	var closest_distance = INF
	
	for point in valid_spawn_points:
		var distance = point.distance_to(position)
		if distance < closest_distance and distance <= max_distance:
			closest_point = point
			closest_distance = distance
			
	return closest_point

# Debug visualization functions
func create_debug_visualization():
	# Clear any existing markers
	clear_debug_visualization()
	
	# Create a container for all markers
	var container = Node3D.new()
	container.name = "SpawnDebugMarkers"
	add_child(container)
	
	# Create a marker for each valid spawn point
	for point in valid_spawn_points:
		var marker = create_debug_marker(point)
		container.add_child(marker)
		debug_markers.append(marker)
	
	print("Created debug visualization with " + str(debug_markers.size()) + " markers")

func create_debug_marker(position: Vector3) -> Node3D:
	# Create a marker node
	var marker = Node3D.new()
	marker.global_position = position
	
	# Add a visual representation (small cylinder)
	var mesh_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = 0.3
	cylinder_mesh.bottom_radius = 0.3
	cylinder_mesh.height = 0.5
	mesh_instance.mesh = cylinder_mesh
	
	# Make it semi-transparent green
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.0, 1.0, 0.0, 0.5)
	mesh_instance.material_override = material
	
	marker.add_child(mesh_instance)
	
	# Add a label to show coordinates
	var label = Label3D.new()
	label.text = "Spawn"
	label.font_size = 16
	label.modulate = Color(1, 1, 1, 0.8)
	label.position = Vector3(0, 0.7, 0)
	marker.add_child(label)
	
	return marker

func update_debug_visualization():
	# This function can be used to update the visualization in real-time
	# For example, to show which spawn points are currently being used
	pass

func clear_debug_visualization():
	# Remove all debug markers
	for marker in debug_markers:
		if is_instance_valid(marker) and marker.is_inside_tree():
			marker.queue_free()
	
	debug_markers.clear()
	
	# Remove the container if it exists
	var container = get_node_or_null("SpawnDebugMarkers")
	if container:
		container.queue_free()

func toggle_debug_visualization():
	show_debug_visualization = !show_debug_visualization
	
	if show_debug_visualization:
		create_debug_visualization()
	else:
		clear_debug_visualization()
	
	print("Debug visualization " + ("enabled" if show_debug_visualization else "disabled"))

func _get_ground_at_point(point: Vector3) -> Node3D:
	var space_state = get_tree().root.world_3d.direct_space_state
	var ray_origin = point + Vector3.UP * 10
	var ray_end = point - Vector3.UP * 10
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result = space_state.intersect_ray(query)
	return result.collider if result else null

func _get_collisions_at_point(point: Vector3) -> Array:
	var space_state = get_tree().root.world_3d.direct_space_state
	var query_shape = PhysicsShapeQueryParameters3D.new()
	var shape = SphereShape3D.new()
	shape.radius = check_radius
	query_shape.shape = shape
	query_shape.transform = Transform3D(Basis(), point)
	return space_state.intersect_shape(query_shape)

func _has_roof_at_point(point: Vector3) -> bool:
	var space_state = get_tree().root.world_3d.direct_space_state
	var roof_check_origin = point + Vector3.UP * 0.1
	var roof_check_end = point + Vector3.UP * 5
	var query = PhysicsRayQueryParameters3D.create(roof_check_origin, roof_check_end)
	var result = space_state.intersect_ray(query)
	return result != null 