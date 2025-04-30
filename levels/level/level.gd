extends Node3D

# References to NPCs that will be mission targets
var boomguy: Node3D
var mission_targets = []

# Enemy spawning configuration
@export var min_spawn_interval: float = 0.5  # Minimum time between spawns (high intensity)
@export var max_spawn_interval: float = 10.0  # Maximum time between spawns (low intensity)
@export var max_enemies: int = 100  # Maximum number of enemies to have at once
@export var enemy_types: Array[PackedScene] = []  # Types of enemies to spawn
@export var debug_spawn_info: bool = true  # Print detailed spawn information

# Mission spawning configuration
@export var min_mission_interval: float = 5.0  # Minimum time between missions (high intensity)
@export var max_mission_interval: float = 10.0  # Maximum time between missions (low intensity)
@export var mission_spawn_timer: Timer
var last_mission_spawn_time: float = 3.0
var empty_task_list_timer: Timer  # Timer for 5-second rule when task list is empty

# Game intensity tracking
var game_intensity: float = 0.0  # Ranges from 0.0 to 1.0
@export var passive_intensity_increase_interval: float = 5.0  # Seconds between passive intensity increases
@export var passive_intensity_step: float = 0.05  # Amount to increase intensity by each step
var passive_intensity_timer: Timer

# Spawn area detector reference
var spawn_detector: Node
var spawn_count: int = 0  # Count of enemies spawned
var spawn_timer: Timer

var last_manual_spawn_time: float = 0.0
var manual_spawn_cooldown: float = 1.0  # 1 second cooldown between manual spawns

func _ready():
	# Connect to MissionManager signals for deliverable spawning
	MissionManager.request_spawn_deliverable.connect(_on_request_spawn_deliverable)
	MissionManager.mission_completed.connect(_on_mission_completed)
	
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
	
	# Start mission spawning timer
	_start_mission_spawning()
	
	# Start passive intensity increase
	_start_passive_intensity_increase()
	

func _setup_spawn_detector() -> void:
	# First check if spawn detector exists as an autoload
	spawn_detector = get_node_or_null("/root/SpawnAreaDetector")
	
	# Then check if it exists as a child of this node
	if not spawn_detector:
		spawn_detector = get_node_or_null("SpawnAreaDetector")
	
	# If not found anywhere, create it
	if not spawn_detector:
		var spawn_detector_script = load("res://managers/spawn_area_detector.gd")
		if spawn_detector_script:
			# Create an instance of the detector
			spawn_detector = Node.new()
			spawn_detector.set_script(spawn_detector_script)
			spawn_detector.name = "SpawnAreaDetector"
			
			# Add it to the scene
			add_child(spawn_detector)
			print("Created new SpawnAreaDetector as child of level")
		else:
			push_error("Failed to load spawn_area_detector.gd script")
			return
	
	# Load enemy types if not set
	if enemy_types.size() == 0:
		enemy_types = [
			load("res://npcs/alien/Alien.tscn"),
			load("res://npcs/demon/demon.tscn"),
			load("res://npcs/zombie/zombie.tscn")
		]
	
	# Explicitly call initialize if not already initialized
	if not spawn_detector.is_initialized:
		print("Explicitly calling initialize() on SpawnAreaDetector")
		spawn_detector.initialize()
	
	# Wait for initialization to complete with timeout
	var init_timeout = 10.0 # 10 seconds timeout
	var start_time = Time.get_ticks_msec() / 1000.0
	
	while not spawn_detector.is_ready() and (Time.get_ticks_msec() / 1000.0 - start_time) < init_timeout:
		await get_tree().process_frame
	
	if not spawn_detector.is_ready():
		push_error("SpawnAreaDetector failed to initialize within timeout")
		# Force initialize critical systems anyway to prevent game from breaking
		print("Forcing SpawnAreaDetector initialization")
		spawn_detector.is_initialized = true
		spawn_detector.current_state = 2 # Should correspond to READY state

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
	
	# Create first mission with first target - special rollerblade mission
	var target1 = mission_targets[0]
	var mission1 = MissionManager.create_rollerblade_delivery_mission(
		"mission_1", 
		"Special Delivery: " + target1.name,
		target1
	)
	
	# Start the first mission
	MissionManager.start_mission("mission_1")
	
	if debug_spawn_info:
		print("Created special rollerblade mission as first mission")

func _start_mission_spawning():
	mission_spawn_timer = Timer.new()
	mission_spawn_timer.wait_time = max_mission_interval
	mission_spawn_timer.one_shot = false
	add_child(mission_spawn_timer)
	mission_spawn_timer.timeout.connect(_on_mission_spawn_timer_timeout)
	mission_spawn_timer.start()  # Explicitly start the timer
	
	# Create timer for empty task list rule
	empty_task_list_timer = Timer.new()
	empty_task_list_timer.wait_time = 5.0
	empty_task_list_timer.one_shot = true
	add_child(empty_task_list_timer)
	empty_task_list_timer.timeout.connect(_on_empty_task_list_timeout)

func _on_mission_spawn_timer_timeout():
	MissionManager._create_next_mission()

	
	# Update timer interval for next cycle based on intensity
	mission_spawn_timer.wait_time = lerp(min_mission_interval, max_mission_interval, 1.0 - game_intensity)
	
	if debug_spawn_info:
		print("Mission spawn timer interval updated to: ", mission_spawn_timer.wait_time)

func _on_empty_task_list_timeout():
	# Only spawn if there are still no missions
	if MissionManager.active_missions.size() == 0:
		MissionManager._create_next_mission()
		# Update timer interval for next cycle based on intensity
		mission_spawn_timer.wait_time = lerp(min_mission_interval, max_mission_interval, 1.0 - game_intensity)
		mission_spawn_timer.start()  # Restart the timer with new interval

func _on_mission_completed(mission_id: String) -> void:
	# Decrease intensity by two steps (0.1 each step)
	game_intensity = max(0.0, game_intensity - 0.2)
	
	# Get player position
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		# Spawn two enemies near player using spawn detector
		for i in range(2):
			var spawn_point = spawn_detector.get_spawn_point_near(player.global_position)
			if spawn_point != Vector3.ZERO:
				_spawn_enemy(enemy_types[randi() % enemy_types.size()], spawn_point)
		
		# Get the mission target
		var mission = MissionManager._get_mission_by_id(mission_id)
		var mission_target = mission.target if mission else null
		
		# Move non-target boomguys to far locations
		var boomguys = get_tree().get_nodes_in_group("Boomguy")
		for boomguy in boomguys:
			if boomguy != player and boomguy != mission_target:  # Don't move player or mission target
				# Get a random far point
				var far_point = spawn_detector.get_spawn_point_away(player.global_position)
				if far_point != Vector3.ZERO:
					boomguy.global_position = far_point
	
	# Start the 5-second timer when a mission is completed and there are no other active missions
	if MissionManager.active_missions.size() == 0:
		empty_task_list_timer.start()

func _start_passive_intensity_increase():
	passive_intensity_timer = Timer.new()
	passive_intensity_timer.wait_time = passive_intensity_increase_interval
	passive_intensity_timer.autostart = true
	passive_intensity_timer.one_shot = false
	add_child(passive_intensity_timer)
	passive_intensity_timer.timeout.connect(_on_passive_intensity_increase)

func _on_passive_intensity_increase():
	# Increase intensity by the step amount, but don't exceed 1.0
	game_intensity = min(game_intensity + passive_intensity_step, 1.0)
	
	if debug_spawn_info:
		print("Passive intensity increase: ", game_intensity)
	
	# Don't update the timer's wait time here - it will be updated when the timer times out
