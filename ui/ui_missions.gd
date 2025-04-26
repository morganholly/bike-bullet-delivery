extends Control

# UI sizing variables
@export var top_section_height: int = 70
@export var bottom_margin: int = 30
@export var gap_height: int = 10
@export var min_item_height: int = 55  # Minimum height for items

@onready var vbox_container: VBoxContainer = $MarginContainer/VBoxContainer
@onready var margin_container: MarginContainer = $MarginContainer

# Reference to the mission item scene
var mission_item_scene = preload("res://ui/ui_mission_item.tscn")
var mission_items: Array[Control] = []

func _ready() -> void:
	# Set the top margin for the title section
	margin_container.add_theme_constant_override("margin_top", top_section_height)
	margin_container.add_theme_constant_override("margin_bottom", bottom_margin)
	
	# Set the gap between mission items
	vbox_container.add_theme_constant_override("separation", gap_height)
	
	# Initial resize with no missions
	resize_container()

# Add a mission item to the container
func add_mission_item(title: String, description: String) -> Control:
	var item = mission_item_scene.instantiate()
	vbox_container.add_child(item)
	mission_items.append(item)
	
	# Set mission data
	if item.has_node("MarginContainer/VBoxContainer/Title"):
		item.get_node("MarginContainer/VBoxContainer/Title").text = title
	if item.has_node("MarginContainer/VBoxContainer/Label"):
		item.get_node("MarginContainer/VBoxContainer/Label").text = description
	
	# Wait a frame for the layout to update before resizing
	await get_tree().process_frame
	
	# Resize the container
	resize_container()
	
	return item

# Remove a mission item from the container
func remove_mission_item(item: Control) -> void:
	if mission_items.has(item):
		mission_items.erase(item)
		item.queue_free()
		
		# Resize the container after a frame to allow layout to update
		await get_tree().process_frame
		resize_container()

# Clear all mission items
func clear_mission_items() -> void:
	for item in mission_items:
		item.queue_free()
	
	mission_items.clear()
	resize_container()

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
