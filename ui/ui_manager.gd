extends Node

# Signal for bullet count changes
signal bullet_count_changed(mag_count: int, reserve_count: int)
# Separate signal for reload state
signal reload_state_changed(is_reloading: bool)
# Signal for inventory slot selection
signal slot_selected(slot_index: int)
# Health and armor signals
signal health_updated(current_health: float, max_health: float)
signal armor_updated(current_armor: float, max_armor: float)
# Mission-related signals
signal mission_added(mission_id: String, title: String, description: String)
signal mission_removed(mission_id: String)
signal mission_updated(mission_id: String, title: String, description: String)
signal mission_target_updated(mission_id: String, target: Node)

# Dictionary to keep track of mission UI items
var mission_ui_items = {}

# Health and armor state
var current_health: float = 0
var current_armor: float = 0
var max_health: float = 0
var max_armor: float = 0

func _ready():
	pass

# Health and armor update methods
func update_health(health: float, max_hp: float) -> void:
	print("asdsa", health, max_hp)
	current_health = health
	max_health = max_hp
	emit_signal("health_updated", current_health, max_health)

func update_armor(armor: float, max_arm: float) -> void:
	print("armor", armor, max_arm)
	current_armor = armor
	max_armor = max_arm
	emit_signal("armor_updated", current_armor, max_armor)

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
	mission_added.emit(mission_id, title, description)

# Method to remove a mission from the UI
func remove_mission_from_ui(mission_id: String) -> void:
	mission_removed.emit(mission_id)

# Method to update mission details in the UI
func update_mission_in_ui(mission_id: String, title: String, description: String) -> void:
	mission_updated.emit(mission_id, title, description)

# Method to register a mission's UI element for later reference
func register_mission_ui_item(mission_id: String, ui_item: Control) -> void:
	mission_ui_items[mission_id] = ui_item

# Method to get a mission's UI element
func get_mission_ui_item(mission_id: String) -> Control:
	if mission_id in mission_ui_items:
		return mission_ui_items[mission_id]
	return null

# Method to update a mission target for indicators
func update_mission_target(mission_id: String, target: Node) -> void:
	mission_target_updated.emit(mission_id, target)

# Debug method to test UI integration
func debug_mission_ui():
	# Test emit a mission
	add_mission_to_ui("debug_mission", "Debug Test Mission", "This mission is emitted directly from UIManager.")
