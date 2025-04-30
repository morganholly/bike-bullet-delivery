extends Control

# UI sizing variables
@export var top_section_height: int = 70
@export var bottom_margin: int = 30
@export var gap_height: int = 10
@export var min_item_height: int = 55  # Minimum height for items

@onready var vbox_container: VBoxContainer = $MarginContainer/VBoxContainer
@onready var margin_container: MarginContainer = $MarginContainer

# Reference to the mission item scene
var mission_item_scene = preload("res://ui/scenes/components/mission/ui_mission_item.tscn")
var mission_items: Array[Control] = []
var mission_map = {}  # Maps mission_ids to UI mission items
var no_missions_item: Control = null

func _ready() -> void:
	# Set the top margin for the title section
	margin_container.add_theme_constant_override("margin_top", top_section_height)
	margin_container.add_theme_constant_override("margin_bottom", bottom_margin)
	
	# Set the gap between mission items
	vbox_container.add_theme_constant_override("separation", gap_height)
	
	# Connect to UIManager mission signals
	# Initial resize with no missions
	resize_container()
	
	# Show "No Missions" message initially
	# Make sure there's only one call to this function
	call_deferred("show_no_missions_message")

# Debug function to check signal connections
func _debug_check_signal_connections() -> void:
	# Test emitting a debug mission
	if UIManager.has_method("debug_mission_ui"):
		UIManager.debug_mission_ui()

# Handler for when a mission is added
func _on_mission_added(mission_id: String, title: String, description: String) -> void:
	# Remove ALL "no missions" items
	# Find and remove any existing "No Active Missions" item
	if "no_mission" in mission_map:
		var no_mission_item = mission_map["no_mission"]
		if no_mission_item != null:
			remove_mission_item(no_mission_item)
			mission_map.erase("no_mission")
	
	# Also check stored reference
	if no_missions_item != null:
		if mission_items.has(no_missions_item):
			remove_mission_item(no_missions_item)
		no_missions_item = null
	
	# Add the new mission item
	var item = add_mission_item_sync(title, description)
	mission_map[mission_id] = item
	
	# Register this item with the UIManager
	UIManager.register_mission_ui_item(mission_id, item)

# Handler for when a mission is removed
func _on_mission_removed(mission_id: String) -> void:
	if mission_id in mission_map:
		var item = mission_map[mission_id]
		remove_mission_item(item)
		mission_map.erase(mission_id)
		
		# If no missions left, show the "no missions" message
		if mission_map.is_empty():
			show_no_missions_message()

# Handler for when a mission is updated
func _on_mission_updated(mission_id: String, title: String, description: String) -> void:
	if mission_id in mission_map:
		var item = mission_map[mission_id]
		
		# Update mission data
		if item.has_node("MarginContainer/VBoxContainer/Title"):
			item.get_node("MarginContainer/VBoxContainer/Title").text = title
		if item.has_node("MarginContainer/VBoxContainer/Label"):
			item.get_node("MarginContainer/VBoxContainer/Label").text = description

# Non-coroutine version for signal handlers
func add_mission_item_sync(title: String, description: String) -> Control:
	var item = mission_item_scene.instantiate()
	vbox_container.add_child(item)
	mission_items.append(item)
	
	# Set mission data
	if item.has_node("MarginContainer/VBoxContainer/Title"):
		item.get_node("MarginContainer/VBoxContainer/Title").text = title
	if item.has_node("MarginContainer/VBoxContainer/Label"):
		item.get_node("MarginContainer/VBoxContainer/Label").text = description
	
	# Resize the container
	call_deferred("resize_container")
	
	return item

# Remove a mission item from the container
func remove_mission_item(item: Control) -> void:
	if mission_items.has(item):
		mission_items.erase(item)
		item.queue_free()
		
		# Resize the container after a frame to allow layout to update
		call_deferred("resize_container")

# Clear all mission items
func clear_mission_items() -> void:
	for item in mission_items:
		item.queue_free()
	
	mission_items.clear()
	mission_map.clear()
	resize_container()

# Show the 'no missions' message
func show_no_missions_message() -> void:
	# First, clean up any existing "no missions" items
	if "no_mission" in mission_map:
		var existing_item = mission_map["no_mission"]
		if existing_item != null:
			remove_mission_item(existing_item)
	
	if no_missions_item != null:
		if mission_items.has(no_missions_item):
			remove_mission_item(no_missions_item)
		no_missions_item = null
	
	# Then create a new one
	no_missions_item = add_mission_item_sync("No Active Missions", "Check back later for new missions")
	mission_map["no_mission"] = no_missions_item

# Get the height of a mission item based on its content
func get_item_height(item: Control) -> float:
	# Force the item to update its minimum size
	if item.has_node("MarginContainer/VBoxContainer"):
		var vbox = item.get_node("MarginContainer/VBoxContainer")
		var content_height = vbox.get_combined_minimum_size().y
		var margin_height = 14  # Top and bottom margins
		return max(content_height + margin_height, min_item_height)
	
	return min_item_height

# Update the height of each mission item based on its content
func update_mission_item_heights() -> void:
	for item in mission_items:
		var height = get_item_height(item)
		item.custom_minimum_size.y = height

# Resize the container based on mission items
func resize_container() -> void:
	if mission_items.size() <= 0:
		# Set a minimum size when no items are present
		custom_minimum_size.y = top_section_height + bottom_margin + 20
	else:
		# Update each item's height first
		update_mission_item_heights()
		
		# Calculate the total height
		var total_height = top_section_height + bottom_margin
		
		for item in mission_items:
			total_height += item.custom_minimum_size.y
		
		# Add gaps between items
		total_height += gap_height * (mission_items.size() - 1)
		
		custom_minimum_size.y = total_height
	
	# Request a layout update
	size = custom_minimum_size
	reset_size()
