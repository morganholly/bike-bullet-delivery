extends Node

# Signal for bullet count changes
signal bullet_count_changed(mag_count: int, reserve_count: int)
# Separate signal for reload state
signal reload_state_changed(is_reloading: bool)
# Signal for inventory slot selection
signal slot_selected(slot_index: int)

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
