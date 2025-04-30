extends Node3D

# References to NPCs that will be mission targets
var boomguy: Node3D
var mission_targets = []

# Enemy spawning configuration
@export var min_spawn_interval: float = 1.0  # Minimum time between spawns (high intensity)
@export var max_spawn_interval: float = 30.0  # Maximum time between spawns (low intensity)
@export var max_enemies: int = 10  # Maximum number of enemies to have at once
@export var enemy_types: Array[PackedScene] = []  # Types of enemies to spawn
@export var debug_spawn_info: bool = true  # Print detailed spawn information

# Game intensity tracking
var game_intensity: float = 0.0  # Ranges from 0.0 to 1.0

# Spawn area detector reference
var spawn_detector: Node
var spawn_count: int = 0  # Count of enemies spawned
var spawn_timer: Timer

var last_manual_spawn_time: float = 0.0
var manual_spawn_cooldown: float = 1.0  # 1 second cooldown between manual spawns

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
	await _setup_spawn_detector()
	
	# Start enemy spawning timer
	_start_enemy_spawning()
	
	# Start intensity updates
	_start_intensity_tracking()

func _setup_spawn_detector() -> void:
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
	
	# Wait for initialization to complete
	await spawn_detector.initialize()
	
	

func _start_intensity_tracking():
	# Create a timer to update spawn interval based on current intensity
	var intensity_timer = Timer.new()
	intensity_timer.name = "IntensityTimer"
	intensity_timer.wait_time = 1.0  # Update every second
	intensity_timer.one_shot = false
	intensity_timer.timeout.connect(_update_spawn_interval)
	add_child(intensity_timer)
	intensity_timer.start()

func _update_spawn_interval():
	if not spawn_timer:
		return
		
	# Use exponential decay function for non-linear progression
	# This creates a curve that starts at max_interval and approaches min_interval
	var current_interval = max_spawn_interval * pow(min_spawn_interval / max_spawn_interval, game_intensity)
	
	# Update the timer's wait time
	spawn_timer.wait_time = current_interval
	
	if debug_spawn_info:
		print("Updated spawn interval: ", current_interval, " (intensity: ", game_intensity, ")")

func _start_enemy_spawning():
	# Create a timer for periodic spawning
	spawn_timer = Timer.new()
	spawn_timer.name = "EnemySpawnTimer"
	spawn_timer.wait_time = max_spawn_interval  # Start at maximum interval
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start()

func _on_spawn_timer_timeout():
	# Check if we've reached the maximum number of enemies
	var current_enemies = get_tree().get_nodes_in_group("Enemies").size()
	if current_enemies >= max_enemies:
		return
	
	# Get player position for spawn point selection
	var player = get_tree().get_first_node_in_group("Player")
	var spawn_point = Vector3.ZERO
	
	if player:
		# For regular enemy spawning, we want them to spawn away from the player
		spawn_point = spawn_detector.get_spawn_point_away(player.global_position)
	else:
		# If no player, just get a random spawn point
		spawn_point = spawn_detector.get_spawn_point()
	
	if spawn_point == Vector3.ZERO:
		if debug_spawn_info:
			print("Failed to get valid spawn point")
		return
	
	# Choose a random enemy type
	var enemy_type = enemy_types[randi() % enemy_types.size()]
	
	# Spawn the enemy
	_spawn_enemy(enemy_type, spawn_point)

func _spawn_enemy(enemy_scene: PackedScene, position: Vector3):
	# Create the enemy instance
	var enemy = enemy_scene.instantiate()
	
	# Set position with a small vertical offset to prevent ground clipping
	enemy.global_position = position + Vector3(0, 0.5, 0)  # Add 0.5 units up
	
	# Add to scene
	add_child(enemy)
	
	# Increment spawn count
	spawn_count += 1
	
	if debug_spawn_info:
		print("Spawned enemy #", spawn_count, " at position: ", position, " (current enemies: ", get_tree().get_nodes_in_group("Enemies").size(), ")")

func _input(event):
	pass

# Signal handler for when MissionManager requests a deliverable to be spawned
func _on_request_spawn_deliverable(mission_id: String, position: Vector3) -> void:
	var spawn_point = Vector3.ZERO
	var player = get_tree().get_first_node_in_group("Player")
	
	# For the first mission, spawn in front of player
	if mission_id == "mission_1" and player:
		# Get a point in front of the player
		var forward = -player.global_transform.basis.z
		spawn_point = player.global_position + (forward * 3.0)  # 3 units in front
		spawn_point.y += 5.0  # Lift it up more to prevent underground spawning
	else:
		# For other missions, get a random spawn point
		spawn_point = spawn_detector.get_spawn_point()
		if spawn_point == Vector3.ZERO:
			print("Level: Failed to get valid spawn point for deliverable")
			return
		spawn_point.y += 2.0  # Lift it up more to prevent underground spawning
	
	if debug_spawn_info:
		print("Spawning deliverable for mission ", mission_id, " at position: ", spawn_point)
	
	# Create the deliverable instance using MissionManager
	var deliverable = MissionManager.create_deliverable_instance(mission_id, spawn_point)
	if deliverable:
		# Add the instance to the scene tree
		add_child(deliverable)
	else:
		print("Level: Failed to create deliverable instance for mission: " + mission_id)

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
