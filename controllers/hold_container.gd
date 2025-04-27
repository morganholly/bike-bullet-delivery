extends Node3D

var num_slots: int
var slots: Array[Node3D]
var selected_slot: int = 0
var flip_scroll_ud: bool
var flip_scroll_rl: bool
var ammo_pool: Node


func _ready() -> void:
	for child in self.get_children():
		if child.is_in_group(&"hold_system"):
			num_slots += 1
			slots.append(child)
		if child.is_in_group(&"AmmoPool"):
			ammo_pool = child
	if ammo_pool != null:
		for hs in slots:
			hs.ammo_pool = ammo_pool
	
	# Update UI with initial selected slot
	UIManager.update_selected_slot(selected_slot)


func _input(event: InputEvent) -> void:
	var was_handled = false
	if event is InputEventKey and event.is_pressed():
		var key_idx = event.keycode - KEY_0
		if key_idx >= 0 and key_idx <= 9:
			slots[selected_slot].make_inactive()
			key_idx -= 1
			if key_idx == -1:
				key_idx = 9
			selected_slot = min(key_idx, num_slots - 1)
			slots[selected_slot].make_active()
			# Update UI with new selected slot
			UIManager.update_selected_slot(selected_slot)
			was_handled = true
	elif event is InputEventMouseButton and event.is_pressed():
		var slot_offset: int
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				slot_offset = -1 if flip_scroll_ud else 1
			MOUSE_BUTTON_WHEEL_DOWN:
				slot_offset = 1 if flip_scroll_ud else -1
			MOUSE_BUTTON_WHEEL_RIGHT:
				slot_offset = -1 if flip_scroll_ud else 1
			MOUSE_BUTTON_WHEEL_LEFT:
				slot_offset = 1 if flip_scroll_ud else -1
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT, MOUSE_BUTTON_WHEEL_LEFT:
				slots[selected_slot].make_inactive()
				selected_slot += slot_offset
				slots[selected_slot].make_active()
				# Update UI with new selected slot
				UIManager.update_selected_slot(selected_slot)
				was_handled = true
	if not was_handled:
		slots[selected_slot].active_slot_input(event)
