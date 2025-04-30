extends Node

# Import the Mission class
const MissionResource = preload("res://managers/mission_resource.gd")
# Make Mission available in this scope
const Mission = MissionResource
# Preload the deliverable bullets scene
const DeliverableBulletsScene = preload("res://weapons/guns/deliverable_bullets.tscn")

# Signal declarations
signal mission_started(mission_id)
signal mission_completed(mission_id)
signal delivery_made(mission_id, npc)
signal deliverable_spawned(deliverable, mission_id)
signal request_spawn_deliverable(mission_id, position)  # New signal for requesting deliverable spawning
signal deliverable_picked_up(mission_id)  # Signal when deliverable is picked up

# Variables to track missions
var active_missions = {}
var completed_missions = []
var available_missions = []
var mission_deliverables = {}  # Track deliverables for each mission
var deliverable_states = {}  # Track state of deliverables: "spawned", "picked_up", "delivered"

func _ready():
	# Connect our own signals to handle UI updates
	mission_started.connect(_on_mission_started)
	mission_completed.connect(_on_mission_completed)
	
	# MissionManager initialized

# Event handlers for mission state changes
func _on_mission_started(mission_id: String) -> void:
	if mission_id in active_missions:
		var mission = active_missions[mission_id]
		
		# Update the UI to show this mission
		# Adding mission to UI: " + mission_id + " - " + mission.title
		UIManager.add_mission_to_ui(mission_id, mission.title, mission.description)
		
		# Notify the UI about the mission target for indicators
		if mission.target != null:
			UIManager.update_mission_target(mission_id, mission.target)
		
		# Request a deliverable to be spawned when mission starts
		request_deliverable_spawn(mission_id)

func _on_mission_completed(mission_id: String) -> void:
	# Remove the mission from UI when completed
	# Removing mission from UI: " + mission_id
	UIManager.remove_mission_from_ui(mission_id)
	
	# Set up a timer to create a new mission after 3 seconds
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 3.0
	add_child(timer)
	
	# Connect the timer to a function that creates a new mission
	timer.timeout.connect(func():
		# Create a new mission with a unique ID
		_create_next_mission()
		timer.queue_free()  # Clean up the timer
	)
	
	# Start the timer
	timer.start()

# Create a new mission with a unique ID
func _create_next_mission() -> void:
	# Generate a unique mission ID
	var mission_id = "mission_" + str(randi() % 1000)
	while is_mission_active(mission_id) or is_mission_completed(mission_id):
		mission_id = "mission_" + str(randi() % 1000)
	
	# Find all Boomguys
	var boomguys = get_tree().get_nodes_in_group("Boomguy")
	var target = null
	
	if boomguys.size() > 0:
		# Randomly select a boomguy
		target = boomguys[randi() % boomguys.size()]
	else:
		# If no Boomguys found, find any NPC
		var npcs = get_tree().get_nodes_in_group("NPC")
		if npcs.size() > 0:
			target = npcs[randi() % npcs.size()]
	
	# If no targets found, create a dummy target
	if target == null:
		target = Node3D.new()
		target.name = "DeliveryTarget"
		get_tree().root.add_child(target)
		
		# Position it somewhere reasonable
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			target.global_position = player.global_position + Vector3(10, 0, 10)
	
	# Create and start the delivery mission
	var mission = create_delivery_mission(
		mission_id,
		"Ammo Delivery: " + target.name,
		"Deliver bullets to " + target.name + ".",
		"Bullets",
		target
	)
	
	start_mission(mission_id)
	# Created and started new Boomguy delivery mission: " + mission_id

# Core mission management functions
func register_mission(mission: Mission):
	if not mission in available_missions:
		available_missions.append(mission)

func start_mission(mission_id: String):
	var mission = _get_mission_by_id(mission_id)
	if mission and mission not in active_missions.values():
		active_missions[mission_id] = mission
		# Starting mission: " + mission_id + " - " + mission.title
		emit_signal("mission_started", mission_id)
		return true
	return false

# Request a deliverable to be spawned - emits signal for level to handle
func request_deliverable_spawn(mission_id: String) -> void:
	# Find player
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		# Position 5m in front of player
		var forward_vector = -player.global_transform.basis.z.normalized()
		var spawn_position = player.global_position + (forward_vector * 5) + Vector3.UP
		
		# Emit signal for level to handle spawning
		# Requesting spawn of deliverable for mission: " + mission_id
		emit_signal("request_spawn_deliverable", mission_id, spawn_position)

# Create a deliverable bullet instance - Level script should call this and handle adding to tree
func create_deliverable_instance(mission_id: String, position: Vector3) -> Node:
	var mission = _get_mission_by_id(mission_id)
	if mission:
		var deliverable = DeliverableBulletsScene.instantiate()
		deliverable.set_mission(mission_id)
		deliverable.global_position = position
		
		# Connect to the deliverable pickup signal
		deliverable.bullet_pickup_completed.connect(func(): _on_deliverable_picked_up(mission_id))
		
		# Track this deliverable
		if not mission_id in mission_deliverables:
			mission_deliverables[mission_id] = []
		mission_deliverables[mission_id].append(deliverable)
		
		# Set initial deliverable state
		deliverable_states[mission_id] = "spawned"
		
		# Notify about the new deliverable
		emit_signal("deliverable_spawned", deliverable, mission_id)
		
		# Also notify UI about the target for this mission
		# This ensures the indicator system can create both indicators right away
		if mission.target != null:
			UIManager.update_mission_target(mission_id, mission.target)
			
		return deliverable
	return null

# Handle deliverable pickup event
func _on_deliverable_picked_up(mission_id: String) -> void:
	if mission_id in active_missions:
		deliverable_states[mission_id] = "picked_up"
		emit_signal("deliverable_picked_up", mission_id)
		
		# Update UI about target immediately after pickup
		var mission = active_missions[mission_id]
		if mission.target != null:
			UIManager.update_mission_target(mission_id, mission.target)

func complete_mission(mission_id: String):
	if mission_id in active_missions:
		var mission = active_missions[mission_id]
		mission.completed = true
		completed_missions.append(mission)
		active_missions.erase(mission_id)
		# Completing mission: " + mission_id
		emit_signal("mission_completed", mission_id)
		return true
	return false

# Called when player delivers to the target NPC
func deliver_to_npc(mission_id: String, npc: Node):
	if mission_id in active_missions:
		var mission = active_missions[mission_id]
		
		# Check if this is the correct target
		if mission.target == npc or (mission.target_id != "" and mission.target_id == npc.name):
			# Successful delivery to target: " + npc.name + " for mission: " + mission_id
			deliverable_states[mission_id] = "delivered"
			emit_signal("delivery_made", mission_id, npc)
			return complete_mission(mission_id)
	
	return false

func is_mission_active(mission_id: String):
	return mission_id in active_missions

func is_mission_completed(mission_id: String):
	for mission in completed_missions:
		if mission.id == mission_id:
			return true
	return false

func get_active_missions():
	return active_missions.values()

func get_completed_missions():
	return completed_missions

func get_available_missions():
	return available_missions

func _get_mission_by_id(mission_id: String) -> Mission:
	for mission in available_missions:
		if mission.id == mission_id:
			return mission
	return null

# Mission creation helper
func create_delivery_mission(id: String, title: String, description: String, deliverable: String, target_npc) -> Mission:
	var mission = Mission.new(id, title, description, deliverable, target_npc)
	register_mission(mission)
	return mission

# Get target NPC for a mission
func get_mission_target(mission_id: String) -> Node:
	var mission = _get_mission_by_id(mission_id)
	if mission:
		return mission.target
	return null

# Direct method to test UI integration
func debug_create_test_mission() -> void:
	# Create a dummy target
	var node = Node3D.new()
	node.name = "TestTarget"
	get_tree().root.add_child(node)
	
	# Create a test mission
	var mission = create_delivery_mission(
		"test_mission", 
		"Debug Mission", 
		"This is a test mission to verify UI integration",
		"TestBullets",
		node
	)
	
	# Start the mission - this will trigger the request_spawn_deliverable signal
	start_mission("test_mission")
	# Created and started test mission
