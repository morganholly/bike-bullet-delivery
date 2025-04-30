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
signal mission_phase_completed(mission_id, phase_index)
signal mission_phase_updated(mission_id, phase_index, description)
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
var waiting_for_rollerblade = false  # Flag to track if we're waiting for the player to press B

func _ready():
	# Connect our own signals to handle UI updates
	mission_started.connect(_on_mission_started)
	mission_completed.connect(_on_mission_completed)
	mission_phase_completed.connect(_on_mission_phase_completed)
	
	# We don't need to change input accumulation globally
	# Input.set_use_accumulated_input(false)

func _input(event):
	# Handle 'B' key input for rollerblade phase
	if waiting_for_rollerblade and event.is_action_pressed("rollerblade"):
		handle_rollerblade_input()

func handle_rollerblade_input():
	# Only handle rollerblade input for the tutorial mission
	if "mission_1" in active_missions:
		var mission = active_missions["mission_1"]
		if mission.has_phases and mission.current_phase == 1:  # The rollerblade phase
			# Hide the prompt
			UIManager.hide_prompt()
			waiting_for_rollerblade = false
			
			# Complete this phase
			advance_mission_phase("mission_1")
			return

# Event handlers for mission state changes
func _on_mission_started(mission_id: String) -> void:
	if mission_id in active_missions:
		var mission = active_missions[mission_id]
		
		# Update the UI to show this mission
		# Adding mission to UI: " + mission_id + " - " + mission.title
		if mission.has_phases:
			var current_description = mission.get_current_phase_description()
			UIManager.add_mission_to_ui(mission_id, mission.title, current_description)
			
			# If this is phase 1 (rollerblade phase) of the tutorial mission, show the prompt
			if mission.current_phase == 1 and mission_id == "mission_1":  # The rollerblade phase of tutorial
				UIManager.show_rollerblade_prompt()
				waiting_for_rollerblade = true
		else:
			UIManager.add_mission_to_ui(mission_id, mission.title, mission.description)
		
		# Notify the UI about the mission target for indicators
		if mission.target != null:
			UIManager.update_mission_target(mission_id, mission.target)
		
		# Request a deliverable to be spawned when mission starts if we're in the first phase
		if mission.has_phases == false or mission.current_phase == 0:
			request_deliverable_spawn(mission_id)

func _on_mission_completed(mission_id: String) -> void:
	# Remove the mission from UI when completed
	# Removing mission from UI: " + mission_id
	UIManager.remove_mission_from_ui(mission_id)
	
	# Clean up any remaining deliverables
	if mission_id in mission_deliverables:
		for deliverable in mission_deliverables[mission_id]:
			if is_instance_valid(deliverable):
				deliverable.queue_free()
		mission_deliverables.erase(mission_id)
	
	# Clean up deliverable state
	if mission_id in deliverable_states:
		deliverable_states.erase(mission_id)

func _on_mission_phase_completed(mission_id: String, phase_index: int) -> void:
	if mission_id in active_missions:
		var mission = active_missions[mission_id]
		
		if mission.has_phases:
			# Update the mission description with the new phase
			if mission.current_phase < mission.total_phases:
				var new_description = mission.get_current_phase_description()
				UIManager.update_mission_in_ui(mission_id, mission.title, new_description)
				
				# Handle special behavior for specific phases
				if mission.current_phase == 1 and mission_id == "mission_1":  # The rollerblade phase, only for tutorial mission
					UIManager.show_rollerblade_prompt()
					waiting_for_rollerblade = true
				elif mission.current_phase == 2 and mission_id == "mission_1":  # Final delivery phase for tutorial
					# If we have a target, update it
					if mission.target != null:
						UIManager.update_mission_target(mission_id, mission.target)
				elif mission.current_phase == 1:  # Final delivery phase for regular missions
					# If we have a target, update it
					if mission.target != null:
						UIManager.update_mission_target(mission_id, mission.target)

# Create a special 3-part mission for getting ammo, rollerblading, and delivery
func create_rollerblade_delivery_mission(id: String, title: String, target_npc) -> Mission:
	var mission = Mission.new(id, title, "", "Bullets", target_npc)
	
	# Setup the three phases with clearer text
	var phases: Array[String] = [
		"Step 1: Pick up these special ammo boxes.",
		"Step 2: Press B to rollerblade for faster delivery.",
		"Step 3: Deliver the ammo to " + target_npc.name + "."
	]
	mission.setup_phases(phases)
	
	register_mission(mission)
	return mission

# Advance to the next phase of a mission
func advance_mission_phase(mission_id: String) -> bool:
	if mission_id in active_missions:
		var mission = active_missions[mission_id]
		
		if mission.has_phases:
			var previous_phase = mission.current_phase
			var completed = mission.complete_current_phase()
			
			# Emit the phase completed signal
			emit_signal("mission_phase_completed", mission_id, previous_phase)
			
			if completed:
				# Mission is fully completed
				complete_mission(mission_id)
				return true
			
			return true
	
	return false

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
	
	# Create a standard delivery mission for all dynamically spawned missions
	var mission = create_delivery_mission(
		mission_id,
		"Ammo Delivery: " + target.name,
		"Deliver bullets to " + target.name + ".",
		"Bullets",
		target
	)
	
	start_mission(mission_id)

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
		
		var mission = active_missions[mission_id]
		
		# For phased missions, picking up deliverable completes the first phase
		if mission.has_phases and mission.current_phase == 0:
			advance_mission_phase(mission_id)
		
		# Update UI about target immediately after pickup
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
			
			# For phased missions, if we're in the delivery phase, complete the mission
			if mission.has_phases and mission.current_phase == 2:
				return complete_mission(mission_id)
			elif not mission.has_phases:
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
	
	# Setup as a two-part mission (pickup and deliver, no rollerblade)
	var phases: Array[String] = [
		"Pick up ammo for delivery.",
		"Deliver ammo to " + target_npc.name + "."
	]
	mission.setup_phases(phases)
	
	register_mission(mission)
	return mission

# Get target NPC for a mission
func get_mission_target(mission_id: String) -> Node:
	var mission = _get_mission_by_id(mission_id)
	if mission:
		return mission.target
	return null

# Direct method to test UI integration
func debug_test_mission_indicators():
	pass

# Debug method to test our three-part rollerblade mission
func debug_test_rollerblade_mission():
	# Find a target
	var npcs = get_tree().get_nodes_in_group("NPC")
	var target = null
	
	if npcs.size() > 0:
		target = npcs[0]
	else:
		# Create a dummy target
		target = Node3D.new()
		target.name = "TestTarget"
		get_tree().root.add_child(target)
		
		# Position it somewhere reasonable
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			target.global_position = player.global_position + Vector3(10, 0, 10)
	
	# Create the rollerblade delivery mission
	var mission_id = "rollerblade_test"
	var mission = create_rollerblade_delivery_mission(
		mission_id,
		"Special Delivery: " + target.name,
		target
	)
	
	# Start the mission
	start_mission(mission_id)
