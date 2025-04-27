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

# Variables to track missions
var active_missions = {}
var completed_missions = []
var available_missions = []
var mission_deliverables = {}  # Track deliverables for each mission

func _ready():
	# Connect our own signals to handle UI updates
	mission_started.connect(_on_mission_started)
	mission_completed.connect(_on_mission_completed)
	
	print("MissionManager initialized")

# Event handlers for mission state changes
func _on_mission_started(mission_id: String) -> void:
	if mission_id in active_missions:
		var mission = active_missions[mission_id]
		
		# Update the UI to show this mission
		print("Adding mission to UI: " + mission_id + " - " + mission.title)
		UIManager.add_mission_to_ui(mission_id, mission.title, mission.description)
		
		# Request a deliverable to be spawned when mission starts
		request_deliverable_spawn(mission_id)

func _on_mission_completed(mission_id: String) -> void:
	# Remove the mission from UI when completed
	print("Removing mission from UI: " + mission_id)
	UIManager.remove_mission_from_ui(mission_id)

# Core mission management functions
func register_mission(mission: Mission):
	if not mission in available_missions:
		available_missions.append(mission)

func start_mission(mission_id: String):
	var mission = _get_mission_by_id(mission_id)
	if mission and mission not in active_missions.values():
		active_missions[mission_id] = mission
		print("Starting mission: " + mission_id + " - " + mission.title)
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
		print("Requesting spawn of deliverable for mission: " + mission_id)
		emit_signal("request_spawn_deliverable", mission_id, spawn_position)

# Create a deliverable bullet instance - Level script should call this and handle adding to tree
func create_deliverable_instance(mission_id: String, position: Vector3) -> Node:
	var mission = _get_mission_by_id(mission_id)
	if mission:
		var deliverable = DeliverableBulletsScene.instantiate()
		deliverable.set_mission(mission_id)
		deliverable.global_position = position
		
		# Track this deliverable
		if not mission_id in mission_deliverables:
			mission_deliverables[mission_id] = []
		mission_deliverables[mission_id].append(deliverable)
		
		# Notify about the new deliverable
		emit_signal("deliverable_spawned", deliverable, mission_id)
		return deliverable
	return null

func complete_mission(mission_id: String):
	if mission_id in active_missions:
		var mission = active_missions[mission_id]
		mission.completed = true
		completed_missions.append(mission)
		active_missions.erase(mission_id)
		print("Completing mission: " + mission_id)
		emit_signal("mission_completed", mission_id)
		return true
	return false

# Called when player delivers to the target NPC
func deliver_to_npc(mission_id: String, npc: Node):
	if mission_id in active_missions:
		var mission = active_missions[mission_id]
		
		# Check if this is the correct target
		if mission.target == npc or (mission.target_id != "" and mission.target_id == npc.name):
			print("Successful delivery to target: " + npc.name + " for mission: " + mission_id)
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
	print("Created and started test mission") 
