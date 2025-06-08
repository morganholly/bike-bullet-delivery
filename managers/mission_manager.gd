extends Node

# Import the Mission class
const MissionResource = preload("res://managers/mission_resource.gd")
# Make Mission available in this scope
const Mission = MissionResource
# Preload the deliverable bullets scene
const DeliverableBulletsScene = preload("res://weapons/guns/deliverable_bullets.tscn")
const DeliverableBulletsScene2 = preload("res://weapons/guns/deliverable_bullets2.tscn")

# Name dictionaries for Boomguys
var first_names = [
	"Mike", "Johnny", "Frank", "Dave", "Steve", "Tony", "Rick", "Jimmy", 
	"Bobby", "Chuck", "Max", "Jack", "Sam", "Pete", "Ray", "Vinny", 
	"Spike", "Duke", "Mack", "Hank", "Nathan"
]

var last_names = [
	"Bullétblast", "Boomguy", "Bang", "Powder", "Buckshot", "Trigger", "Gunner", 
	"Cannon", "Shells", "Thunder", "Nitro", "Slugger", "Smoke", "Ammo", 
	"Bullet", "Caliber", "Recoil", "Flash", "Barrel", "Shrapnel"
]

# Track Boomguy names
var boomguy_names = {}

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
var max_active_missions = 4  # Maximum number of active missions allowed at once
var tutorial = true


func _ready():

	# Connect our own signals to handle UI updates
	mission_started.connect(_on_mission_started)
	mission_completed.connect(_on_mission_completed)
	mission_phase_completed.connect(_on_mission_phase_completed)
	

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
	#print("MISSION: _on_mission_started")
	if mission_id in active_missions:
		var mission = active_missions[mission_id]
		
		# Update the UI to show this mission
		# Adding mission to UI: " + mission_id + " - " + mission.title
		if mission.has_phases:
			print("mission has phases")
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
	print("MISSION: (mission manager) _on_mission_completed")
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
		
	#the tutorial mission is over
		tutorial=false

func _on_mission_phase_completed(mission_id: String, phase_index: int) -> void:
	#print("MISSION: _on_mission_phase_completed")
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

# Generate a random name by combining a first and last name
func generate_random_name() -> String:
	var first_name = first_names[randi() % first_names.size()]
	var last_name = last_names[randi() % last_names.size()]
	return first_name + " " + last_name

# Assign random names to all Boomguys in the level
func assign_random_names_to_boomguys() -> void:
	var boomguys = get_tree().get_nodes_in_group("Boomguy")
	
	for boomguy in boomguys:
		var random_name = generate_random_name()
		# Store using the node name as the key instead of the object reference
		boomguy_names[boomguy.name] = random_name
		# We don't change the actual node name to avoid breaking references
	print(boomguy_names)

# Create a special 3-part mission for getting ammo, rollerblading, and delivery
func create_rollerblade_delivery_mission(id: String, title: String, target_npc) -> Mission:
	#print("MISSION: create_rollerblade_delivery_mission")
	# Get target name (use random name if it's a Boomguy)
	#var target_name = target_npc.name
	#if target_npc.is_in_group("Boomguy") and target_npc.name in boomguy_names:
	var target_name = "Boomguy"
	boomguy_names[target_npc.name]= "Nathan Boomguy"
	target_name = boomguy_names[target_npc.name]

			
	
	# Include target name in the mission title
	var mission_title = "Tutorial Delivery to " + target_name
	
	var mission = Mission.new(id, mission_title, "", "Bullets", target_npc)
	
	# Setup the three phases with clearer text
	var phases: Array[String] = [
		"Step 1: Pick up these special ammo boxes.",
		"Step 2: Press B for rollerblade speed delivery.",
		"Step 3: Deliver to " + target_name + "."
	]
	mission.setup_phases(phases)
	
	register_mission(mission)
	return mission

# Advance to the next phase of a mission
func advance_mission_phase(mission_id: String) -> bool:
	#print("MISSION: advance_mission_phase")
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
	#print("MISSION: _create_next_mission")
	# Check if we've reached the maximum number of active missions
	if active_missions.size() >= max_active_missions:
		if get_tree().get_first_node_in_group("Level") and get_tree().get_first_node_in_group("Level").debug_spawn_info:
			print("Mission limit reached (%d/%d), not creating new mission" % [active_missions.size(), max_active_missions])
		return
		
	# Generate a unique mission ID
	var mission_id = "mission_" + str(randi() % 1000)
	while is_mission_active(mission_id) or is_mission_completed(mission_id):
		mission_id = "mission_" + str(randi() % 1000)
	print("MISSION ID CREATED: ",mission_id)
	
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
	
	# Get target name (use random name if it's a Boomguy)
	var target_name = target.name
	if target.name in boomguy_names:
		target_name = boomguy_names[target.name]
	print("MISSION TARGET: ",target_name)
	
	# Create a standard delivery mission for all dynamically spawned missions
	var mission = create_delivery_mission(
		mission_id,
		"Ammo Delivery: " + target_name,
		"Deliver to " + target_name + ".",
		"Bullets",
		target
	)
	
	start_mission(mission_id)

# Core mission management functions
func register_mission(mission: Mission):
	print("MISSION: register_mission ", mission.id)
	if not mission in available_missions:
		available_missions.append(mission)

func start_mission(mission_id: String):
	#print("MISSION: start_mission")
	var mission = _get_mission_by_id(mission_id)
	if mission and mission not in active_missions.values():
		active_missions[mission_id] = mission
		# Starting mission: " + mission_id + " - " + mission.title
		emit_signal("mission_started", mission_id)
		return true
	return false

# Request a deliverable to be spawned - emits signal for level to handle
func request_deliverable_spawn(mission_id: String) -> void:
	#print("MISSION: request_deliverable_spawn")
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
	#print("MISSION: create_deliverable_instance")
	var mission = _get_mission_by_id(mission_id)
	if mission:
		var deliverable 
		if randi_range(1,3) ==1:
			deliverable= DeliverableBulletsScene.instantiate()
		else:
			deliverable= DeliverableBulletsScene2.instantiate()
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
	#print("DELIVERABLE PICKED UP")
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
	print("MISSION: complete_mission")
	
	var mission = active_missions[mission_id]
	mission.completed = true
	completed_missions.append(mission)
	active_missions.erase(mission_id)
	# Completing mission: " + mission_id
	emit_signal("mission_completed", mission_id)
	return true
	

# Called when player delivers to the target NPC
func deliver_to_npc(mission_id: String, npc: Node):
	#print("MISSION: deliver_to_npc")
	if mission_id in active_missions:
		print("BOOMGUY DELIVERY: in active missions")	
		var mission = active_missions[mission_id] #this is the culprit right here
		print("target: ",mission.target, "  targetid: ",mission.target_id, "npc: ",npc)
		# Check if this is the correct target
		if mission.target == npc or (mission.target_id != "" and mission.target_id == npc.name):
			print("BOOMGUY DELIVERY: checked boomguy is correct one")
			# For tutorial mission, reject delivery if player hasn't completed the rollerblade phase
			if mission_id == "mission_1" and mission.has_phases and mission.current_phase < 2:
				# Player tried to deliver before using rollerblades
				print("BOOMGUY DELIVERY: mission 1 rollerblades")
				return false
			
			# Successful delivery to target: " + npc.name + " for mission: " + mission_id
			deliverable_states[mission_id] = "delivered"
			emit_signal("delivery_made", mission_id, npc)
			
			# For phased missions, if we're in the delivery phase, complete the mission
			if mission_id == "mission_1" and mission.has_phases and mission.current_phase == 2:
				return complete_mission(mission_id)
			elif mission_id != "mission_1" and mission.has_phases and mission.current_phase == 1:
				print("BOOMGUY DELIVERY: phases")	
				return complete_mission(mission_id)
			elif not mission.has_phases:
				print("BOOMGUY DELIVERY: no phases")	
				return complete_mission(mission_id)
			return true #TIDYUP
	
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
	#print("MISSION: create_delivery_mission")
	var mission = Mission.new(id, title, description, deliverable, target_npc)
	
	# Get target name (use random name if it's a Boomguy)
	var target_name = target_npc.name
	if target_npc.is_in_group("Boomguy") and target_npc.name in boomguy_names:
		target_name = boomguy_names[target_npc.name]
	
	# Setup as a two-part mission (pickup and deliver, no rollerblade)
	var phases: Array[String] = [
		"Pick up ammo for delivery.",
		"Deliver to " + target_name + "."
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
	target = npcs[0]
	
	# Create the rollerblade delivery mission
	var mission_id = "rollerblade_test"
	var mission = create_rollerblade_delivery_mission(
		mission_id,
		"Special Delivery: " + target.name,
		target
	)
	
	# Start the mission
	start_mission(mission_id)

# Reset all mission state on game over
func reset_mission_state() -> void:
	#print("MISSION: reset_mission_state")
	# Clean up any existing deliverables
	for mission_id in mission_deliverables.keys():
		for deliverable in mission_deliverables[mission_id]:
			if is_instance_valid(deliverable):
				deliverable.queue_free()
	
	# Clear all mission data
	active_missions.clear()
	mission_deliverables.clear()
	deliverable_states.clear()
	waiting_for_rollerblade = false
	
	# Reset all available missions to their initial state
	for mission in available_missions:
		mission.completed = false
		mission.current_phase = 0
		# Reset all phase completion statuses
		if mission.has_phases:
			for i in range(mission.phase_completed.size()):
				mission.phase_completed[i] = false
	
	# We don't clear completed_missions as that's a historical record,
	# but we do need to clear it for proper game restart
	completed_missions.clear()
	
	# Re-assign random names to Boomguys
	boomguy_names.clear()
	assign_random_names_to_boomguys()
	
	# Hide any UI prompts related to missions
	UIManager.hide_prompt()
	
	# UI cleanup is handled by UIManager
