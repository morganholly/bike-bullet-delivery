extends Node

# Signal for bullet count changes
signal bullet_count_changed(mag_count: int, reserve_count: int)
# Separate signal for reload state
signal reload_state_changed(is_reloading: bool)
# Signal for inventory slot selection
signal slot_selected(slot_index: int)
# Mission-related signals
signal mission_added(mission_id: String, title: String, description: String)
signal mission_removed(mission_id: String)
signal mission_updated(mission_id: String, title: String, description: String)
signal mission_target_updated(mission_id: String, target: Node)

# Dictionary to keep track of mission UI items
var mission_ui_items = {}

func _ready():
	# UIManager initialized
	pass

# Method to broadcast bullet count updates from anywhere
# mag_count = -1 means reloading, reserve_count = -1 means don't show reserve
func update_bullet_display(mag_count: int, reserve_count: int = -1) -> void:
	bullet_count_changed.emit(mag_count, reserve_count)

# Method to broadcast reload state changes
func set_reload_state(is_reloading: bool) -> void:
	reload_state_changed.emit(is_reloading)

# Method to update the selected inventory slot in the UI
func update_selected_slot(slot_index: int) -> void:
	slot_selected.emit(slot_index)

# Method to add a mission to the UI
func add_mission_to_ui(mission_id: String, title: String, description: String) -> void:
	# UIManager: Adding mission to UI: " + mission_id + " - " + title
	mission_added.emit(mission_id, title, description)

# Method to remove a mission from the UI
func remove_mission_from_ui(mission_id: String) -> void:
	# UIManager: Removing mission from UI: " + mission_id
	mission_removed.emit(mission_id)

# Method to update mission details in the UI
func update_mission_in_ui(mission_id: String, title: String, description: String) -> void:
	# UIManager: Updating mission in UI: " + mission_id
	mission_updated.emit(mission_id, title, description)

# Method to register a mission's UI element for later reference
func register_mission_ui_item(mission_id: String, ui_item: Control) -> void:
	mission_ui_items[mission_id] = ui_item
	# UIManager: Registered UI item for mission: " + mission_id

# Method to get a mission's UI element
func get_mission_ui_item(mission_id: String) -> Control:
	if mission_id in mission_ui_items:
		return mission_ui_items[mission_id]
	return null

# Method to update a mission target for indicators
func update_mission_target(mission_id: String, target: Node) -> void:
	# UIManager: Updated target for mission: " + mission_id
	mission_target_updated.emit(mission_id, target)

# Debug method to test UI integration
func debug_mission_ui():
	# UIManager Debug: Signal connections:
	#   - mission_added connected to: " + str(mission_added.get_connections().size()) + " objects"
	#   - mission_removed connected to: " + str(mission_removed.get_connections().size()) + " objects"
	#   - mission_updated connected to: " + str(mission_updated.get_connections().size()) + " objects"
	
	# Test emit a mission
	# UIManager Debug: Emitting test mission signal
	add_mission_to_ui("debug_mission", "Debug Test Mission", "This mission is emitted directly from UIManager.")
