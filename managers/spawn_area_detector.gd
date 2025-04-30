extends Node

# State tracking
enum SpawnDetectorState {
	UNINITIALIZED,
	INITIALIZING,
	READY,
	FAILED
}

# Current state
var current_state: SpawnDetectorState = SpawnDetectorState.UNINITIALIZED

# Configuration
@export var grid_size: float = 5.0  # Size of each grid cell
@export var max_height: float = 2.0  # Maximum height above ground for valid spawn
@export var min_height: float = 0.1  # Minimum height above ground for valid spawn
@export var check_radius: float = 100  # Reduced radius to check around spawn point
@export var show_debug_visualization: bool = true  # Whether to show debug visualization
@export var debug_mode: bool = false  # Enable detailed debug logging
@export var use_all_collision_layers: bool = false  # Only use ground layer for ground detection
@export var force_valid_points: bool = true  # Force some points to be valid even if they fail checks
@export var max_height_difference: float = 5.0  # Increased height difference tolerance
@export var roof_check_height: float = 3.0  # Height to check for roofs
@export var roof_check_radius: float = 1.0  # Radius to check for roofs

# Cache for valid spawn points
var valid_spawn_points: Array[Vector3] = []
var is_initialized: bool = false
var debug_markers: Array[Node3D] = []  # Store debug visualization markers

# Collision masks - using bit flags for proper masking
const BUILDING_MASK = 1 << 0  # Layer 1 (Normal Geo) for buildings and ground
const VEHICLE_MASK = 1 << 5   # Layer 6 (SmallVehicle)
const GROUND_MASK = 1 << 0    # Layer 1 (Normal Geo)
const ALL_MASK = 0xFFFFFFFF   # All layers

func _ready():
	await initialize()

func _process(_delta):
	if show_debug_visualization and is_initialized:
		update_debug_visualization()

func initialize() -> void:
	print("SpawnAreaDetector: Starting initialization")
	current_state = SpawnDetectorState.INITIALIZING
	
	valid_spawn_points.clear()
	
	var level_bounds = _get_level_bounds()
	print("SpawnAreaDetector: Level bounds: ", level_bounds)
	
	_create_spawn_grid(level_bounds)
	print("SpawnAreaDetector: Created grid with ", valid_spawn_points.size(), " valid points")
	
	if valid_spawn_points.size() > 0:
		current_state = SpawnDetectorState.READY
		is_initialized = true
		print("SpawnAreaDetector: Successfully initialized with ", valid_spawn_points.size(), " points")
	else:
		current_state = SpawnDetectorState.FAILED
		print("SpawnAreaDetector: Failed to find any valid points")

func is_ready() -> bool:
	return current_state == SpawnDetectorState.READY

func _get_level_bounds() -> Dictionary:
	print("SpawnAreaDetector: Getting level bounds")
	var static_bodies = get_tree().get_nodes_in_group("StaticBody")
	print("SpawnAreaDetector: Found ", static_bodies.size(), " static bodies")
	
	# Start with a smaller area around the player
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		var pos = player.global_position
		print("SpawnAreaDetector: Using player position for bounds: ", pos)
		return {
			"min": Vector3(pos.x - 300, -10, pos.z - 300),
			"max": Vector3(pos.x + 300, 10, pos.z + 300)
		}
	
	# Fallback to a small area around origin
	print("SpawnAreaDetector: No player found, using default bounds")
	return {"min": Vector3(-300, -10, -300), "max": Vector3(300, 10, 300)}

func _create_spawn_grid(bounds: Dictionary):
	print("SpawnAreaDetector: Creating spawn grid")
	var min_pos = bounds["min"]
	var max_pos = bounds["max"]
	var total_points = 0
	var valid_points = 0
	
	# Print collision layer information
	var space_state = get_tree().root.world_3d.direct_space_state
	print("SpawnAreaDetector: Available collision layers:")
	for i in range(32):
		var layer_name = ProjectSettings.get_setting("layer_names/3d_physics/layer_" + str(i + 1))
		if layer_name:
			print("Layer ", i + 1, ": ", layer_name)
	
	for x in range(int(min_pos.x), int(max_pos.x), int(grid_size)):
		for z in range(int(min_pos.z), int(max_pos.z), int(grid_size)):
			total_points += 1
			var point = Vector3(x, 0, z)
			
			if _is_valid_spawn_point(point):
				valid_points += 1
				valid_spawn_points.append(point)
	
	print("SpawnAreaDetector: Checked ", total_points, " points, found ", valid_points, " valid points")

func _is_valid_spawn_point(point: Vector3) -> bool:
	if debug_mode:
		pass
		#print("SpawnAreaDetector: Checking point: ", point)
	
	# Check for ground
	var ground = _get_ground_at_point(point)
	if not ground:
		if debug_mode:
			print("SpawnAreaDetector: No ground found at point: ", point)
		return false
	
	# Check height
	var ground_height = ground.global_position.y
	if abs(point.y - ground_height) > max_height_difference:
		if debug_mode:
			print("SpawnAreaDetector: Height difference too large at point: ", point, " ground height: ", ground_height)
		return false
	
	# Check for collisions (excluding ground)
	var collisions = _get_collisions_at_point(point)
	var filtered_collisions = collisions.filter(func(collision):
		return collision.collider != ground
	)
	
	if filtered_collisions.size() > 0:
		if debug_mode:
			print("SpawnAreaDetector: Collision found at point: ", point)
		return false
	
	# Check for roof with more lenient parameters
	if _has_roof_at_point(point):
		if debug_mode:
			print("SpawnAreaDetector: Roof found at point: ", point)
		return false
	
	if debug_mode:
		print("SpawnAreaDetector: Point is valid: ", point)
	return true

func _get_ground_at_point(point: Vector3) -> Node3D:
	var space_state = get_tree().root.world_3d.direct_space_state
	var ray_origin = point + Vector3.UP * 10
	var ray_end = point - Vector3.UP * 10
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	
	# Use ground mask for ground detection
	query.collision_mask = GROUND_MASK
	var result = space_state.intersect_ray(query)
	
	if result:
		if debug_mode:
			print("SpawnAreaDetector: Found ground at point: ", point)
			print("SpawnAreaDetector: Ground object: ", result.collider.name)
			print("SpawnAreaDetector: Ground position: ", result.position)
		return result.collider
	
	if debug_mode:
		print("SpawnAreaDetector: No ground found at point: ", point)
	return null

func _get_collisions_at_point(point: Vector3) -> Array:
	var space_state = get_tree().root.world_3d.direct_space_state
	var query_shape = PhysicsShapeQueryParameters3D.new()
	var shape = SphereShape3D.new()
	shape.radius = check_radius
	query_shape.shape = shape
	query_shape.transform = Transform3D(Basis(), point)
	query_shape.collision_mask = ALL_MASK & ~GROUND_MASK  # Check all layers except ground
	
	return space_state.intersect_shape(query_shape)

func _has_roof_at_point(point: Vector3) -> bool:
	var space_state = get_tree().root.world_3d.direct_space_state
	var roof_check_origin = point
	var roof_check_end = point + Vector3.UP * roof_check_height
	var query = PhysicsRayQueryParameters3D.create(roof_check_origin, roof_check_end)
	query.collision_mask = BUILDING_MASK
	
	var result = space_state.intersect_ray(query)
	if result:
		# Only consider it a roof if the hit point is significantly above the ground
		# and the normal is pointing downward
		var hit_height = result.position.y - point.y
		var is_downward_normal = result.normal.y < -0.5  # Normal pointing mostly downward
		
		if debug_mode:
			print("SpawnAreaDetector: Roof check at point ", point)
			print("SpawnAreaDetector: Hit height: ", hit_height)
			print("SpawnAreaDetector: Normal: ", result.normal)
			print("SpawnAreaDetector: Is downward normal: ", is_downward_normal)
		
		# Consider it a roof if it's more than 1 unit above the point and pointing downward
		return hit_height > 1.0 and is_downward_normal
	
	return false

func get_spawn_point() -> Vector3:
	if not is_ready():
		print("Spawn detector not ready")
		return Vector3.ZERO
	
	if valid_spawn_points.size() == 0:
		print("No valid spawn points available")
		return Vector3.ZERO
	
	return _get_random_spawn_point()

func get_spawn_point_near(position: Vector3, min_distance: float = 5.0, max_distance: float = 15.0) -> Vector3:
	if not is_ready():
		print("Spawn detector not ready")
		return Vector3.ZERO
	
	if valid_spawn_points.size() == 0:
		print("No valid spawn points available")
		return Vector3.ZERO
	
	var valid_points = valid_spawn_points.filter(func(point):
		var distance = point.distance_to(position)
		return distance >= min_distance and distance <= max_distance
	)
	
	if valid_points.size() == 0:
		print("No points found within distance range ", min_distance, " to ", max_distance)
		return _get_random_spawn_point()
	
	return valid_points[randi() % valid_points.size()]

func get_spawn_point_away(position: Vector3, min_distance: float = 20.0, max_distance: float = 30.0) -> Vector3:
	if not is_ready():
		return Vector3.ZERO
	
	if valid_spawn_points.size() == 0:
		return Vector3.ZERO
	
	var valid_points = valid_spawn_points.filter(func(point):
		var distance = point.distance_to(position)
		return distance >= min_distance and distance <= max_distance
	)
	
	if valid_points.size() == 0:
		return _get_random_spawn_point()
	
	# Sort by distance and pick from the furthest ones
	valid_points.sort_custom(func(a, b):
		return a.distance_to(position) > b.distance_to(position)
	)
	
	# Take the furthest 25% of points
	var furthest_points = valid_points.slice(0, valid_points.size() * 0.25)
	return furthest_points[randi() % furthest_points.size()]

func _get_random_spawn_point() -> Vector3:
	return valid_spawn_points[randi() % valid_spawn_points.size()]

# Debug visualization functions
func create_debug_visualization():
	clear_debug_visualization()
	
	var container = Node3D.new()
	container.name = "SpawnDebugMarkers"
	add_child(container)
	
	for point in valid_spawn_points:
		var marker = create_debug_marker(point)
		container.add_child(marker)
		debug_markers.append(marker)

func create_debug_marker(position: Vector3) -> Node3D:
	var marker = Node3D.new()
	marker.global_position = position
	
	var mesh_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = 0.3
	cylinder_mesh.bottom_radius = 0.3
	cylinder_mesh.height = 0.5
	mesh_instance.mesh = cylinder_mesh
	
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.0, 1.0, 0.0, 0.5)
	mesh_instance.material_override = material
	
	marker.add_child(mesh_instance)
	
	var label = Label3D.new()
	label.text = "Spawn"
	label.font_size = 16
	label.modulate = Color(1, 1, 1, 0.8)
	label.position = Vector3(0, 0.7, 0)
	marker.add_child(label)
	
	return marker

func update_debug_visualization():
	pass

func clear_debug_visualization():
	for marker in debug_markers:
		if is_instance_valid(marker) and marker.is_inside_tree():
			marker.queue_free()
	
	debug_markers.clear()
	
	var container = get_node_or_null("SpawnDebugMarkers")
	if container:
		container.queue_free()

func toggle_debug_visualization():
	show_debug_visualization = !show_debug_visualization
	
	if show_debug_visualization:
		create_debug_visualization()
	else:
		clear_debug_visualization() 
