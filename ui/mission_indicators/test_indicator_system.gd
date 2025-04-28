extends Node

# A simple test script to validate the mission objective indicator system
# Attach this to an empty node in your test scene

func _ready():
	print("Mission Indicator Test script loaded")
	
	# Wait a moment to ensure everything is initialized
	await get_tree().create_timer(1.0).timeout
	
	# Call the testing function in MissionManager
	call_debug_function()

func _unhandled_input(event):
	# Press 'I' key to test the indicator system
	if event is InputEventKey and event.pressed and event.keycode == KEY_I:
		call_debug_function()

func call_debug_function():
	var mission_manager = get_node("/root/MissionManager")
	if mission_manager and mission_manager.has_method("debug_test_mission_indicators"):
		print("Calling test function")
		mission_manager.debug_test_mission_indicators()
	else:
		print("Could not find MissionManager or debug function") 