extends Node

# A simple test script to validate the mission objective indicator system
# Attach this to an empty node in your test scene

func _ready() -> void:
	# Mission Indicator Test script loaded
	
	# Wait a moment to ensure everything is initialized
	await get_tree().create_timer(1.0).timeout
	
	# Call the testing function in MissionManager
	call_debug_function()

func _unhandled_input(event):
	# Press 'I' key to test the indicator system
	if event is InputEventKey and event.pressed and event.keycode == KEY_I:
		call_debug_function()
	
	# Press 'R' key to test the rollerblade mission
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		test_rollerblade_mission()

func call_debug_function():
	var mission_manager = get_node("/root/MissionManager")
	if mission_manager and mission_manager.has_method("debug_test_mission_indicators"):
		# Calling test function
		mission_manager.debug_test_mission_indicators()
	else:
		# Could not find MissionManager or debug function
		print("Could not find MissionManager or debug function")

func test_rollerblade_mission():
	var mission_manager = get_node("/root/MissionManager")
	if mission_manager and mission_manager.has_method("debug_test_rollerblade_mission"):
		print("Testing rollerblade mission")
		mission_manager.debug_test_rollerblade_mission()
	else:
		print("Could not find MissionManager or debug_test_rollerblade_mission function") 