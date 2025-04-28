extends Node3D

# References to NPCs that will be mission targets
var boomguy: Node3D
var mission_targets = []

func _ready():
	print("LevelTest03: Initializing...")
	
	# Connect to MissionManager signals for deliverable spawning
	MissionManager.request_spawn_deliverable.connect(_on_request_spawn_deliverable)
	print("LevelTest03: Connected to MissionManager signals")
	
	# Give the scene a moment to initialize
	await get_tree().create_timer(2.0).timeout
	
	# Find NPCs in the scene to use as mission targets
	_find_mission_targets()
	
	# Create test missions
	_create_test_missions()
	
	# Set up debug key
	print("Press F12 to create a debug mission directly from MissionManager")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F12:
			print("F12 pressed - creating debug mission")
			MissionManager.debug_create_test_mission()

# Signal handler for when MissionManager requests a deliverable to be spawned
func _on_request_spawn_deliverable(mission_id: String, position: Vector3) -> void:
	print("LevelTest03: Handling deliverable spawn request for mission: " + mission_id)
	
	# Create the deliverable instance using MissionManager
	var deliverable = MissionManager.create_deliverable_instance(mission_id, position)
	if deliverable:
		# Add the instance to the scene tree
		add_child(deliverable)
		print("LevelTest03: Spawned deliverable at position " + str(position))
	else:
		print("LevelTest03: Failed to create deliverable instance for mission: " + mission_id)

# Find NPCs in the scene to use as mission targets
func _find_mission_targets():
	print("LevelTest03: Finding mission targets...")
	
	# Look specifically for the BoomGuy
	boomguy = get_node_or_null("Boomguy")
	if not boomguy:
		# Try using get_node_in_group to find the boomguy
		var boomguys = get_tree().get_nodes_in_group("Boomguy")
		if boomguys.size() > 0:
			boomguy = boomguys[0]
	
	# Add boomguy to mission targets if found
	if boomguy:
		mission_targets.append(boomguy)
		print("LevelTest03: Found Boomguy: " + boomguy.name)
	
	# Find any other NPCs
	var npcs = get_tree().get_nodes_in_group("NPC")
	for npc in npcs:
		if not mission_targets.has(npc):
			mission_targets.append(npc)
			print("LevelTest03: Found NPC: " + npc.name)
	
	# If we still don't have enough targets, look for enemy dummies
	if mission_targets.size() < 2:
		var enemies = get_tree().get_nodes_in_group("Enemy")
		for enemy in enemies:
			if not mission_targets.has(enemy):
				mission_targets.append(enemy)
				print("LevelTest03: Found Enemy: " + enemy.name)
	
	print("LevelTest03: Total mission targets found: " + str(mission_targets.size()))

# Create test missions for the level
func _create_test_missions():
	print("LevelTest03: Creating test missions...")
	
	if mission_targets.size() <= 0:
		print("LevelTest03: No mission targets found! Cannot create missions.")
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
	print("LevelTest03: Started mission 1: Deliver to " + target1.name)
	
