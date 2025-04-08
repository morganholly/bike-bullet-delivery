extends Node3D


@onready var camera: Node3D = $"../Camera"
@onready var character_body_3d: CharacterBody3D = $".."
@onready var object_sprite: Node3D = $"../Camera/Rotate/Flip/FirstPerson/CameraFirstPerson/Sprite3D2"


enum ActionState {EMPTY, HOLDITEM, GUN, MELEEITEM}
var current_action_state: ActionState = ActionState.EMPTY
var holding: Object
var go_to: Vector3 = Vector3.ZERO
var last_go_to: Vector3 = Vector3.ZERO
var last_pos_delta: Vector3 = Vector3.ZERO
var holding_old_contact_monitor: bool = false
var holding_contacts_avg: float = 0
var holding_old_gravity_scale: float = 0

var pick_up_range: float = 6

#var hold_filt_coefs: Array[float] = [0, 0, 0, 0, 0]
#var hold_filt_dx: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
#var hold_filt_dy: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
#
#func make_biquad_lpf_coefs(freq_ratio: float, q: float) -> Array[float]:
	#var inv_tan: float = 1 / tan(PI * freq_ratio)
	#var res: Array[float] = [0, 0, 0, 0, 0]
	#res[0] = 1 / (1 + q * inv_tan + inv_tan * inv_tan)
	#res[1] = 2 * res[0]
	#res[2] = res[0]
	#res[3] = 2 * (inv_tan * inv_tan - 1) * res[0]
	#res[4] = -(1 - q * inv_tan + inv_tan * inv_tan) * res[0]
	#return res
#
#func calc_biquad(coefs: Array[float], dx: Array[Vector3], dy: Array[Vector3], val: Vector3) -> Vector3:
	#var out = coefs[0] * val + coefs[1] * dx[0] + coefs[2] * dx[1] + coefs[3] * dy[0] + coefs[4] * dy[1]
	#dx[1] = dx[0]
	#dx[0] = val
	#dy[1] = dy[0]
	#dy[0] = out
	#return out

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#hold_filt_coefs = make_biquad_lpf_coefs(0.5, 1)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _holdable_hold_update(obj: RigidBody3D) -> void:
	var cur_pos = obj.global_position
	##var moving_at = obj.linear_velocity
	var pos_delta = go_to - cur_pos
	##var new_force = 1 * pos_delta + 5 * (pos_delta - last_pos_delta)
	###print("hold update ", go_to, " ", cur_pos, " ", moving_at, " ", pos_delta, " ", new_force)
	##print(go_to - last_go_to, " ", pos_delta, " ", pos_delta - last_pos_delta)
	##obj.apply_central_impulse(new_force)
	##obj.linear_velocity *= 0.95
	##obj.apply_central_impulse(2 * (go_to - last_go_to))
	#if pos_delta.length() > 0.1:
		#obj.apply_central_impulse(0.95 * pos_delta + 1.1 * (go_to - last_go_to) + 0.5 * (pos_delta - last_pos_delta))
	#else:
		#obj.linear_velocity *= 0.5
	#holding_contacts_avg = lerp(holding_contacts_avg, float(holding.get_contact_count()), 0.25)
	#var hold_strength: float = 1 / (1 + holding_contacts_avg)
	#print(holding.get_contact_count(), hold_strength)
	#obj.linear_velocity = lerp(obj.linear_velocity * 0.5, (3 * pos_delta - 3 * (pos_delta - last_pos_delta) + 6 * (go_to - last_go_to)) * obj.mass, hold_strength)
	obj.linear_velocity = (3 * pos_delta - 3 * (pos_delta - last_pos_delta) + 6 * (go_to - last_go_to)) * 5 # * obj.mass
	last_pos_delta = pos_delta
	#var cur_pos = obj.global_position
	#var new_pos: Vector3 = calc_biquad(hold_filt_coefs, hold_filt_dx, hold_filt_dy, go_to)
	#obj.linear_velocity += new_pos - cur_pos
	##obj.apply_central_impulse(new_pos - cur_pos)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	go_to = camera.hold_position.global_position
	match current_action_state:
		ActionState.EMPTY:
			pass
		ActionState.HOLDITEM:
			_holdable_hold_update(holding)
		ActionState.GUN:
			pass
		ActionState.MELEEITEM:
			pass
	last_go_to = go_to


func _input(event) -> void:
	match current_action_state:
		ActionState.EMPTY:
			
			# call the zoom function
		# zoom out
			
			
			if event is InputEventKey and event.pressed:
				if event.keycode == KEY_G:
					if (object_sprite.visible):
						drop_item();
			
			if event is InputEventKey and event.pressed and event.keycode == KEY_E:
				if camera.nodeRaycast.is_colliding():
					var obj_over = camera.nodeRaycast.get_collider()
					if !((global_position - obj_over.global_position).length() < pick_up_range): 
						return;
						
					if (obj_over is RigidBody3D and obj_over.is_in_group("pickable")):
						obj_over.remove_from_group("pickable")
						pick_up_item(obj_over)
					#if (obj_over.is_in_group("holdable_could_gun")):
					
			
			if event is InputEventMouseButton and event.pressed:
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					scroll_inventory_down() #it's intended to be the other way around
				
				if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					scroll_inventory_up()
				
				if event.button_index == MOUSE_BUTTON_LEFT and camera.nodeRaycast.is_colliding():
					var obj_over = camera.nodeRaycast.get_collider()
					
					if !((global_position - obj_over.global_position).length() < pick_up_range): 
						return;
						
					var could_holditem  = obj_over is RigidBody3D #PhysicsBody3D
					var could_gun       = obj_over.is_in_group("holdable_could_gun")
					var could_meleeitem = obj_over.is_in_group("holdable_could_melee")
					#var prefer_holditem  = obj_over.is_in_group("holdable_prefer_object")
					#var prefer_gun       = obj_over.is_in_group("holdable_prefer_gun")
					#var prefer_meleeitem = obj_over.is_in_group("holdable_prefer_melee")
					var should_switch_dialog_be_shown = false
					if could_holditem or could_gun or could_meleeitem:
						# i aint retyping all that
						#match [could_holditem, could_gun, could_meleeitem, prefer_holditem, prefer_gun, prefer_meleeitem]:
						match [could_holditem, could_gun, could_meleeitem]:
							[true, false, false]: # only hold
								#print("only hold")
								current_action_state = ActionState.HOLDITEM
							[_, true, false]: # only gun, maybe hold
								#print("only gun, maybe hold")
								current_action_state = ActionState.GUN
							[_, false, true]: # only melee, maybe hold
								#print("only melee, maybe hold")
								current_action_state = ActionState.MELEEITEM
							[_, true, true]: # gun and melee, maybe hold
								#print("gun and melee, maybe hold")
								current_action_state = ActionState.GUN
								# if obj_over.gun_component.ammo_counter > 0:
								# 	# use as gun
								# else:
								#	# use as melee
							# i aint retyping all that
							#[true, true, _, _, true, _]: # item or gun, prefer gun, but show dialog box to switch
								#should_switch_dialog_be_shown = true
								#print("could multiple")
							#[true, true, _, true, false, _]: # item or gun, prefer item, but show dialog box to switch
								#should_switch_dialog_be_shown = true
								#print("could multiple")
							#[true, _, true, _, _, true]: # item or melee, prefer melee, but show dialog box to switch
								#should_switch_dialog_be_shown = true
								#print("could multiple")
							#[true, _, true, true, _, false]: # item or melee, prefer item, but show dialog box to switch
								#should_switch_dialog_be_shown = true
								#print("could multiple")
							#[_, true, true, _, _, _]: # gun or melee, equip as gun if it has ammo, otherwise melee, but show dialog box to switch
								#should_switch_dialog_be_shown = true
								#print("could multiple")
							#[true, true, true, _, _, _]: # anything, equip as gun if it has ammo, otherwise melee, but show dialog box to switch
								#should_switch_dialog_be_shown = true
								#print("could multiple")
						holding_old_gravity_scale = obj_over.gravity_scale
						obj_over.gravity_scale = 0
						#hold_filt_dx[0] = obj_over.global_position
						#hold_filt_dx[1] = obj_over.global_position
						#hold_filt_dy[0] = obj_over.global_position
						#hold_filt_dy[1] = obj_over.global_position
						#holding_old_contact_monitor = obj_over.contact_monitor
						#obj_over.contact_monitor = true
						holding = obj_over
		ActionState.HOLDITEM:
			if event is InputEventMouseButton and event.pressed:
				if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
					current_action_state = ActionState.EMPTY
					holding.gravity_scale = holding_old_gravity_scale
					if event.button_index == MOUSE_BUTTON_LEFT:
						holding.linear_velocity += 20 * (camera.hold_position.global_position - camera.global_position) / sqrt(holding.mass)
					var vel_clamped = 20 * (1 - (1 / (1 + 0.05 * holding.linear_velocity.length())))
					holding.linear_velocity = holding.linear_velocity.normalized() * vel_clamped
					holding = null
		ActionState.GUN:
			pass
		ActionState.MELEEITEM:
			pass


func pick_up_item(obj_over) -> void:
	#print("Item picked up")
	
	var slot_inventory = get_tree().get_root().get_node("ScreenSpaceShader/CanvasLayer/Control");
	if (slot_inventory.pick_up_item({ 
		"type": "ammo",
		"amount": 120,
	})):
		obj_over.queue_free()
		object_sprite.show()
		obj_over.add_to_group("pickable")
	
	pass


func drop_item() -> void:
	#print("Thrown object")
	#obj_over.queue_free()
	var slot_inventory = get_tree().get_root().get_node("ScreenSpaceShader/CanvasLayer/Control");
	if (!slot_inventory.get_current_slotInfo()["type"] == "empty"):
		slot_inventory.get_current_slotInfo()["type"] = "empty";
		slot_inventory.get_current_slotInfo()["amount"] = 0;
		slot_inventory.refresh()
		var scene = load("res://npcs/ammo_box.tscn")
		var object = scene.instantiate()
		get_tree().get_root().get_node("ScreenSpaceShader/SubViewport/test02").add_child(object)
		object.global_position = Vector3(global_position) + global_position.direction_to(camera.hold_position.global_position) * 1.5
		object_sprite.hide()

	pass

func scroll_inventory_up():
	var slot_inventory = get_tree().get_root().get_node("ScreenSpaceShader/CanvasLayer/Control");
	slot_inventory.curSlotIndex += 1;
	if slot_inventory.curSlotIndex >= slot_inventory.UISlots.size():
		slot_inventory.curSlotIndex = 0
	slot_inventory.refresh()
	if (slot_inventory.get_current_slotInfo()["type"] == "empty"):
		object_sprite.hide()
	else:
		object_sprite.show()
	pass
	
	

func scroll_inventory_down():
	var slot_inventory = get_tree().get_root().get_node("ScreenSpaceShader/CanvasLayer/Control");
	slot_inventory.curSlotIndex -= 1;
	if slot_inventory.curSlotIndex < 0:
		slot_inventory.curSlotIndex = slot_inventory.UISlots.size()-1
	slot_inventory.refresh()
	if (slot_inventory.get_current_slotInfo()["type"] == "empty"):
		object_sprite.hide()
	else:
		object_sprite.show()
	pass
