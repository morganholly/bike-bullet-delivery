extends Node

# A global script that creates and manages mission indicators
# This can be autoloaded as an alternative to adding the system to the UI layer

var mission_indicator_scene = preload("res://ui/mission_indicators/mission_objective_indicator.tscn")
var mission_indicator_instance: CanvasLayer = null

func _ready():
	print("Global Mission Indicator Manager initialized")
	
	# Wait a frame to ensure other systems are initialized
	await get_tree().process_frame
	
	# Create the indicator instance
	ensure_indicator_exists()

func ensure_indicator_exists():
	# Check if we already have a mission indicator in the scene tree
	var existing = get_tree().get_nodes_in_group("MissionIndicator")
	
	if existing.size() > 0:
		# Use existing indicator
		mission_indicator_instance = existing[0]
		print("Using existing mission indicator")
	else:
		# Create new indicator instance
		mission_indicator_instance = mission_indicator_scene.instantiate()
		get_tree().root.add_child(mission_indicator_instance)
		mission_indicator_instance.add_to_group("MissionIndicator")
		print("Created global mission indicator")

# Public API - can be used to control indicator behavior
func set_max_visible_indicators(count: int):
	if mission_indicator_instance and mission_indicator_instance.has_method("set"):
		mission_indicator_instance.set("max_visible_indicators", count)

func set_show_distance(enabled: bool):
	if mission_indicator_instance and mission_indicator_instance.has_method("set"):
		mission_indicator_instance.set("show_distance", enabled)

func set_update_interval(interval: float):
	if mission_indicator_instance and mission_indicator_instance.has_method("set"):
		mission_indicator_instance.set("update_interval", interval) 