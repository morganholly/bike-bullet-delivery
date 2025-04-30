extends Node3D

# References to NPCs that will be mission targets
var boomguy: Node3D
var mission_targets = []

# Enemy spawning configuration
@export var spawn_timer_interval: float = 30.0  # Time between spawns in seconds
@export var max_enemies: int = 10  # Maximum number of enemies to have at once
@export var enemy_types: Array[PackedScene] = []  # Types of enemies to spawn
@export var fallback_spawn_points: Array[NodePath] = []  # Fallback spawn points if detector fails
@export var debug_spawn_info: bool = true  # Print detailed spawn information

# Spawn area detector reference
var spawn_detector: Node
var fallback_spawn_nodes: Array[Node3D] = []
var spawn_count: int = 0  # Count of enemies spawned

func _ready():
	# Connect to MissionManager signals for deliverable spawning
	MissionManager.request_spawn_deliverable.connect(_on_request_spawn_deliverable)
	
	# Give the scene a moment to initialize
	await get_tree().create_timer(2.0).timeout
	
	# Find NPCs in the scene to use as mission targets
	_find_mission_targets()
	
	# Create test missions
	_create_test_missions()
	
	# Initialize spawn area detector
	_setup_spawn_detector()
	
	# Setup fallback spawn points
	_setup_fallback_spawn_points()
	
	# Start enemy spawning timer
	_start_enemy_spawning()

func _setup_spawn_detector():
	# Check if spawn detector exists in the scene
	spawn_detector = get_node_or_null("/root/SpawnAreaDetector")
	
	# If not, create it
	if not spawn_detector:
		var spawn_detector_script = load("res://managers/spawn_area_detector.gd")
		spawn_detector = spawn_detector_script.new()
		spawn_detector.name = "SpawnAreaDetector"
		get_tree().root.add_child(spawn_detector)
	
	# Load enemy types if not set
	if enemy_types.size() == 0:
		enemy_types = [
			load("res://npcs/alien/Alien.tscn"),
			load("res://npcs/demon/demon.tscn"),
			load("res://npcs/zombie/zombie.tscn")
		]
	
	# Wait a moment for the spawn detector to initialize
	await get_tree().create_timer(1.0).timeout
	
	# Check if the spawn detector found any valid points
	if spawn_detector.valid_spawn_points.size() == 0:
		# Force reinitialization
		spawn_detector.reinitialize_spawn_points()
		
		# If still no points, we'll use fallback points
		if spawn_detector.valid_spawn_points.size() == 0:
			# Force reinitialization
			spawn_detector.reinitialize_spawn_points()

func _setup_fallback_spawn_points():
	# Convert NodePaths to actual nodes
	for path in fallback_spawn_points:
		var node = get_node_or_null(path)
		if node:
			fallback_spawn_nodes.append(node)
	
	# If no fallback points specified, create some default ones
	if fallback_spawn_nodes.size() == 0:
		# Create a container for fallback points
		var container = Node3D.new()
		container.name = "FallbackSpawnPoints"
		add_child(container)
		
		# Create some default fallback points around the level
		var default_points = [
			Vector3(0, 0, 0),
			Vector3(20, 0, 20),
			Vector3(-20, 0, -20),
			Vector3(20, 0, -20),
			Vector3(-20, 0, 20)
		]
		
		for i in range(default_points.size()):
			var point = Node3D.new()
			point.name = "FallbackPoint" + str(i)
			point.global_position = default_points[i]
			container.add_child(point)
			fallback_spawn_nodes.append(point)

func _start_enemy_spawning():
	# Create a timer for periodic spawning
	var spawn_timer = Timer.new()
	spawn_timer.name = "EnemySpawnTimer"
	spawn_timer.wait_time = spawn_timer_interval
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start()

func _on_spawn_timer_timeout():
	# Check if we've reached the maximum number of enemies
	var current_enemies = get_tree().get_nodes_in_group("Enemies").size()
	if current_enemies >= max_enemies:
		return
	
	# Get a spawn point
	var spawn_point = _get_spawn_point()
	if spawn_point == Vector3.ZERO:
		return
	
	# Choose a random enemy type
	var enemy_type = enemy_types[randi() % enemy_types.size()]
	
	# Spawn the enemy
	_spawn_enemy(enemy_type, spawn_point)

func _get_spawn_point() -> Vector3:
	# Try to get a point from the spawn detector
	if spawn_detector and spawn_detector.valid_spawn_points.size() > 0:
		var point = spawn_detector.get_random_spawn_point()
		return point
	
	# If no valid points from detector, use a fallback point
	if fallback_spawn_nodes.size() > 0:
		var fallback_node = fallback_spawn_nodes[randi() % fallback_spawn_nodes.size()]
		return fallback_node.global_position
	
	# If no fallback points, use a default position
	return Vector3(0, 0, 0)

func _spawn_enemy(enemy_scene: PackedScene, position: Vector3):
	# Create the enemy instance
	var enemy = enemy_scene.instantiate()
	
	# Set position
	enemy.global_position = position
	
	# Add to scene
	add_child(enemy)
	
	# Increment spawn count
	spawn_count += 1

func _input(event):
	# Add a key to manually trigger enemy spawning for testing
	if event.is_action_pressed("ui_select"):  # Spacebar
		_on_spawn_timer_timeout()

# Signal handler for when MissionManager requests a deliverable to be spawned
func _on_request_spawn_deliverable(mission_id: String, position: Vector3) -> void:
	# Create the deliverable instance using MissionManager
	var deliverable = MissionManager.create_deliverable_instance(mission_id, position)
	if deliverable:
		# Add the instance to the scene tree
		add_child(deliverable)
	else:
		print("LevelTest03: Failed to create deliverable instance for mission: " + mission_id)

# Find NPCs in the scene to use as mission targets
func _find_mission_targets():
	# Look specifically for the BoomGuy
	boomguy = get_node_or_null("Boomguy")
	
	# Add boomguy to mission targets if found
	if boomguy:
		mission_targets.append(boomguy)
	
	# Find any other NPCs
	var npcs = get_tree().get_nodes_in_group("NPC")
	for npc in npcs:
		if not mission_targets.has(npc):
			mission_targets.append(npc)
	
	# If we still don't have enough targets, look for enemy dummies
	if mission_targets.size() < 2:
		var enemies = get_tree().get_nodes_in_group("Enemy")
		for enemy in enemies:
			if not mission_targets.has(enemy):
				mission_targets.append(enemy)

# Create test missions for the level
func _create_test_missions():
	if mission_targets.size() <= 0:
		return
	
	# Wait a bit to ensure UI is fully ready
	await get_tree().create_timer(0.5).timeout
	
	# Create first mission with first target
	var target1 = mission_targets[0]
	var mission1 = MissionManager.create_delivery_mission(
		"mission_1", 
		"Ammo Delivery: " + target1.name,
		"Deliver bullets to " + target1.name + " for testing.",
		"Bullets",
		target1
	)
	
	# Start the first mission
	MissionManager.start_mission("mission_1")
