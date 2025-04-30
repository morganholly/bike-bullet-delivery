extends CanvasLayer

@onready var bullet_count_label: Label = $UIBullet/UIButtonLabel
@onready var inventory_container: HBoxContainer = $UIInventory/HBoxContainer
@onready var missions_ui: Control = $UIMissions
@onready var prompt_label: Control = $UIPromptLabel

# Reference to the inventory slot scene
var inventory_slot_scene = preload("res://ui/ui_inventory_slot.tscn")
var mission_indicator_scene = preload("res://ui/mission_indicators/mission_objective_indicator.tscn")
var inventory_slots: Array[Control] = []
var initial_mission_item: Control
var mission_indicator_layer: CanvasLayer

func _ready() -> void:
	print(self)
	# Connect to the UI manager's signals when ready
	UIManager.bullet_count_changed.connect(_on_bullet_count_changed)
	UIManager.reload_state_changed.connect(_on_reload_state_changed)
	update_bullet_count(0, 0)
	
	# Add mission indicator layer
	_setup_mission_indicators()
	
	# Wait a frame to make sure the player is fully initialized
	await get_tree().process_frame
	_setup_inventory_slots()
	
	# Connect to slot selection signal if it exists
	if UIManager.has_signal("slot_selected"):
		UIManager.slot_selected.connect(_on_slot_selected)
	
	# Check if prompt label exists and is accessible
	if prompt_label:
		print("Prompt label found and set up")
	else:
		print("Prompt label not found in the scene")
	
	# NOTE: We don't need to add a "no missions" message here as it's already handled in ui_missions.gd
	# The UIMissions control will show this message on its own
	
	# Remove the timer that was creating duplicate mission items
	# var timer = get_tree().create_timer(5.0)
	# timer.timeout.connect(_on_mission_timer_timeout)

func _setup_inventory_slots() -> void:
	# Clear any existing slots first
	for child in inventory_container.get_children():
		child.queue_free()
	
	inventory_slots.clear()
	
	# Find the player node
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_node("HoldContainer"):
		var hold_container = player.get_node("HoldContainer")
		var num_slots = 0
		
		# Count the number of hold_system nodes
		for child in hold_container.get_children():
			if child.is_in_group("hold_system"):
				num_slots += 1
		
		# Create the visual inventory slots
		for i in range(num_slots):
			var slot = inventory_slot_scene.instantiate()
			inventory_container.add_child(slot)
			inventory_slots.append(slot)
			
			# Set the slot number
			if slot.has_node("SlotNumber"):
				var number = i + 1
				if number == 10:
					number = 0  # 0 key represents slot 10
				slot.get_node("SlotNumber").text = str(number)
		
		# Highlight the currently selected slot
		if hold_container.selected_slot >= 0 and hold_container.selected_slot < inventory_slots.size():
			_highlight_slot(hold_container.selected_slot)

func _on_slot_selected(slot_index: int) -> void:
	_highlight_slot(slot_index)

func _highlight_slot(slot_index: int) -> void:
	# Remove highlight from all slots
	for i in range(inventory_slots.size()):
		if inventory_slots[i].has_method("set_selected"):
			inventory_slots[i].set_selected(i == slot_index)


func update_bullet_count(mag_count: int, reserve_count: int = -1) -> void:
	return
	if reserve_count == -1:
		# Only show magazine count
		bullet_count_label.text = str(mag_count)
	else:
		# Show both magazine and reserve
		bullet_count_label.text = str(mag_count) + "/" + str(reserve_count)

func _on_bullet_count_changed(mag_count: int, reserve_count: int = -1) -> void:
	update_bullet_count(mag_count, reserve_count)

func _on_reload_state_changed(is_reloading: bool) -> void:
	pass

# Called every frame to update the UI based on the player's current state
func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_node("HoldContainer"):
		var hold_container = player.get_node("HoldContainer")
		
		# Update selected slot highlight if it changed
		if hold_container.selected_slot >= 0 and hold_container.selected_slot < inventory_slots.size():
			_highlight_slot(hold_container.selected_slot)

# This function is no longer needed since we removed the timer
# func _on_mission_timer_timeout() -> void:
# 	pass

# Setup mission indicators
func _setup_mission_indicators() -> void:
	# Check if we already have the mission indicator layer in the scene
	mission_indicator_layer = get_node_or_null("MissionObjectiveIndicator")
	
	# If not, instantiate and add it
	if mission_indicator_layer == null:
		mission_indicator_layer = mission_indicator_scene.instantiate()
		add_child(mission_indicator_layer)
		print("Created mission indicator layer dynamically")
	else:
		print("Using mission indicator layer from scene")

# Method to show the rollerblade prompt when level is ready
func show_rollerblade_prompt() -> void:
	UIManager.show_rollerblade_prompt()
