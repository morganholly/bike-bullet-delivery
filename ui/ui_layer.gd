extends CanvasLayer

@onready var bullet_count_label: Label = $UIBullet/UIButtonLabel
@onready var reload_label: Label = $UIBullet/ReloadLabel  # Reference to the new reload label
@onready var inventory_container: HBoxContainer = $UIInventory/HBoxContainer

# Reference to the inventory slot scene
var inventory_slot_scene = preload("res://ui/ui_inventory_slot.tscn")
var inventory_slots: Array[Control] = []

func _ready() -> void:
	# Connect to the UI manager's signals when ready
	UIManager.bullet_count_changed.connect(_on_bullet_count_changed)
	UIManager.reload_state_changed.connect(_on_reload_state_changed)
	update_bullet_count(0, 0)
	reload_label.visible = false  # Hide reload label initially
	
	# Wait a frame to make sure the player is fully initialized
	await get_tree().process_frame
	_setup_inventory_slots()
	
	# Connect to slot selection signal if it exists
	if UIManager.has_signal("slot_selected"):
		UIManager.slot_selected.connect(_on_slot_selected)

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
		else:
			# Fallback if set_selected method doesn't exist
			inventory_slots[i].modulate = Color(1, 1, 1, 1) if i != slot_index else Color(1.2, 1.2, 0.8, 1)

func update_bullet_count(mag_count: int, reserve_count: int = -1) -> void:
	if reserve_count == -1:
		# Only show magazine count
		bullet_count_label.text = str(mag_count)
	else:
		# Show both magazine and reserve
		bullet_count_label.text = str(mag_count) + " / " + str(reserve_count)

func _on_bullet_count_changed(mag_count: int, reserve_count: int = -1) -> void:
	update_bullet_count(mag_count, reserve_count)

func _on_reload_state_changed(is_reloading: bool) -> void:
	# Show or hide the reload label based on reloading state
	reload_label.visible = is_reloading

# Called every frame to update the UI based on the player's current state
func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_node("HoldContainer"):
		var hold_container = player.get_node("HoldContainer")
		
		# Update selected slot highlight if it changed
		if hold_container.selected_slot >= 0 and hold_container.selected_slot < inventory_slots.size():
			_highlight_slot(hold_container.selected_slot)
