extends Node

# Signal for bullet count changes
signal bullet_count_changed(mag_count: int, reserve_count: int)
# Separate signal for reload state
signal reload_state_changed(is_reloading: bool)
# Signal for inventory slots
signal slot_selected(slot_index: int)
#signal slot_update(slot_index:int, slot_type:String, slot_ammo: int)#TIDYUP
# Health and armor signals
signal health_updated(current_health: float, max_health: float)
signal armor_updated(current_armor: float, max_armor: float)
# Mission-related signals
signal mission_added(mission_id: String, title: String, description: String)
signal mission_removed(mission_id: String)
signal mission_updated(mission_id: String, title: String, description: String)
signal mission_target_updated(mission_id: String, target: Node)
# Prompt label signals
signal prompt_visibility_changed(is_visible: bool)
signal prompt_text_changed(text: String)
# Game over signal
signal game_over_visibility_changed(is_visible: bool)

# Dictionary to keep track of mission UI items
var mission_ui_items = {}

# Health and armor state
var current_health: float = 0
var current_armor: float = 0
var max_health: float = 0
var max_armor: float = 0

# Prompt label state
var prompt_text: String = ""
var is_prompt_visible: bool = false

# Game over state
var is_game_over_visible: bool = false

# gun stuff
var pistolindex=-1 #TIDYUP
var pistolreloading=false
var flareindex=-1 #TIDYUP

func _ready():
	pass

# Health and armor update methods
func update_health(health: float, max_hp: float) -> void:
	current_health = health
	max_health = max_hp
	emit_signal("health_updated", current_health, max_health)

func update_armor(armor: float, max_arm: float) -> void:
	current_armor = armor
	max_armor = max_arm
	emit_signal("armor_updated", current_armor, max_armor)

# Method to broadcast bullet count updates from anywhere
# mag_count = -1 means reloading, 
# mag_count = -2 mean use previous mag count for display
# reserve_count = -1 means don't show reserve
func update_bullet_display(mag_count: int, reserve_count: int = -1) -> void:
	if pistolreloading == true:
		mag_count = -1
	bullet_count_changed.emit(mag_count, reserve_count)
	#print("UPDATE BULLET",mag_count,",",reserve_count)

# Method to broadcast reload state changes
func set_reload_state(is_reloading: bool) -> void:
	pistolreloading=is_reloading
	reload_state_changed.emit(is_reloading)

# Method to update the selected inventory slot in the UI
func update_selected_slot(slot_index: int) -> void:
	slot_selected.emit(slot_index)

func update_slots(slot_index:int, slot_type:String, slot_ammo: int):
	#TIDYUP
	#print("UPDATE SLOTS: UIMANAGER")
	#$UILayer.update_slots()
	#slot_update.emit(1,"",10) #index, gun, ammo
	pass

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

# Prompt label methods
func show_prompt(text: String = "") -> void:
	if text != "":
		prompt_text = text
		prompt_text_changed.emit(prompt_text)
	is_prompt_visible = true
	prompt_visibility_changed.emit(is_prompt_visible)

func hide_prompt() -> void:
	is_prompt_visible = false
	prompt_visibility_changed.emit(is_prompt_visible)

func set_prompt_text(text: String) -> void:
	prompt_text = text
	prompt_text_changed.emit(prompt_text)

func show_rollerblade_prompt() -> void:
	show_prompt("Press B to rollerblade")

# Game over method
func show_game_over() -> void:
	# Reset all manager variables
	current_health = 0
	current_armor = 0
	is_prompt_visible = false
	
	# Clear mission data
	for mission_id in mission_ui_items.keys():
		if mission_ui_items[mission_id] != null:
			mission_removed.emit(mission_id)
	mission_ui_items.clear()
	
	# Reset state in MissionManager
	MissionManager.reset_mission_state()
	
	# Show the game over UI first, transition to cutscene on click will be handled in ui_game_over.gd
	is_game_over_visible = true
	game_over_visibility_changed.emit(is_game_over_visible)

func hide_game_over() -> void:
	is_game_over_visible = false
	game_over_visibility_changed.emit(is_game_over_visible)

# Debug method to test UI integration
func debug_mission_ui():
	# Test emit a mission
	add_mission_to_ui("debug_mission", "Debug Test Mission", "This mission is emitted directly from UIManager.")
