extends Node3D


@onready var camera: Node3D = $"../../Camera"
@onready var character_body_3d: CharacterBody3D = $"../.."


enum ActionState {EMPTY, HOLDITEM, GUN, MELEEITEM}
var current_action_state: ActionState = ActionState.EMPTY
var holding: Object
var go_to: Vector3 = Vector3.ZERO
var last_go_to: Vector3 = Vector3.ZERO
var last_pos_delta: Vector3 = Vector3.ZERO
var holding_old_contact_monitor: bool = false
var holding_contacts_avg: float = 0
var holding_old_gravity_scale: float = 0
var holding_old_collision_mask: int = 0
var debounce_gun_hold_swap: float = 0.5
var smoothed_aim_basis: Basis
var ammo_pool: Node
var gun_state_slot_inactive: bool = false

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


func make_active() -> void:
	match current_action_state:
		ActionState.EMPTY:
			pass
		ActionState.HOLDITEM:
			camera.hands_mode = camera.HandsMode.Hold
			holding.collision_mask = holding_old_collision_mask
			holding.visible = true
		ActionState.GUN:
			camera.hands_mode = camera.HandsMode.GunNormal
			holding.get_node("gun_action").reparent(camera.gun_position_r)
			camera.gun_position_r.get_node("gun_action").visible = true
			gun_state_slot_inactive = false
		ActionState.MELEEITEM:
			pass

func make_inactive() -> void:
	camera.hands_mode = camera.HandsMode.Empty
	match current_action_state:
		ActionState.EMPTY:
			pass
		ActionState.HOLDITEM:
			holding_old_collision_mask = holding.collision_mask
			holding.collision_mask = 0
			holding.visible = false
		ActionState.GUN:
			gun_state_slot_inactive = true
			camera.gun_position_r.get_node("gun_action").visible = false
			camera.gun_position_r.get_node("gun_action").reparent(holding)
		ActionState.MELEEITEM:
			pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	debounce_gun_hold_swap = max(0, debounce_gun_hold_swap - delta)


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
	match current_action_state:
		ActionState.EMPTY:
			pass
		ActionState.HOLDITEM:
			go_to = camera.hold_position.global_position
			if (holding != null):
				_holdable_hold_update(holding)
		ActionState.GUN:
			go_to = camera.gun_position_r.global_position
			_holdable_hold_update(holding)
			smoothed_aim_basis = lerp(smoothed_aim_basis, Basis.looking_at(camera.gun_position_r.to_local(camera.aim_pos)), 0.1)
			if not gun_state_slot_inactive:
				camera.gun_position_r.get_node("gun_action").basis = smoothed_aim_basis
		ActionState.MELEEITEM:
			go_to = camera.gun_position_r.global_position
			pass
	last_go_to = go_to


func gun_tween_to_hold():
	var tween_pos = get_tree().create_tween()
	tween_pos.set_ease(Tween.EASE_OUT)
	tween_pos.tween_property(camera.gun_position_r.get_node("gun_action"), "position", Vector3.ZERO, 0.5)
	
	var tween_face = get_tree().create_tween()
	tween_face.set_ease(Tween.EASE_IN)
	var facing_callable = func(weight: float):
		if camera.gun_position_r.has_node("gun_action") and camera.gun_position_r.get_node("gun_action") != null and camera.gun_position_r.global_basis != null:
			camera.gun_position_r.get_node("gun_action").global_basis = camera.gun_position_r.get_node("gun_action").global_basis.slerp(camera.gun_position_r.global_basis, weight * weight)
	tween_face.tween_method(facing_callable, 0.0, 1.0, 1.0)


func active_slot_input(event) -> void:
	match current_action_state:
		ActionState.EMPTY:
			if event is InputEventMouseButton and event.pressed:
				if camera.nodeRaycast.is_colliding():
					var obj_over = camera.get_collider()
					var could_holditem  = obj_over is RigidBody3D #PhysicsBody3D
					var could_gun       = obj_over.is_in_group("holdable_could_gun")
					var could_meleeitem = obj_over.is_in_group("holdable_could_melee")
					#var prefer_holditem  = obj_over.is_in_group("holdable_prefer_object")
					#var prefer_gun       = obj_over.is_in_group("holdable_prefer_gun")
					#var prefer_meleeitem = obj_over.is_in_group("holdable_prefer_melee")
					var should_switch_dialog_be_shown = false
					if could_holditem or could_gun or could_meleeitem:
						camera.nodeRaycast.collision_mask &= ~0b1_0000_0000
						camera.nodeRaycast.add_exception(obj_over)
						# i aint retyping all that
						#match [could_holditem, could_gun, could_meleeitem, prefer_holditem, prefer_gun, prefer_meleeitem]:
						obj_over.add_to_group(&"IsHeld")
						camera.hands_mode = camera.HandsMode.Hold
						match [could_holditem, could_gun, could_meleeitem]:
							[true, false, false]: # only hold
								#print("only hold")
								current_action_state = ActionState.HOLDITEM
							[_, true, false], [_, true, true]: # only gun, maybe hold
								#print("only gun, maybe hold")
								holding_old_collision_mask = obj_over.collision_mask
								obj_over.collision_mask = 0
								obj_over.get_node("gun_action").stash_extra_mags(ammo_pool)
								obj_over.get_node("gun_action").reparent(camera.gun_position_r)
								# if obj_over.gun_component.ammo_counter > 0:
								# 	# use as gun
								# else:
								#	# use as melee
								
								camera.hands_mode = camera.HandsMode.GunNormal
								gun_tween_to_hold()
								
								current_action_state = ActionState.GUN
							[_, false, true]: # only melee, maybe hold
								#print("only melee, maybe hold")
								current_action_state = ActionState.MELEEITEM
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
			if event.is_action_pressed("gun_hold_swap") and debounce_gun_hold_swap < 0.1:
				if holding.is_in_group("holdable_could_gun"):
					debounce_gun_hold_swap = 0.5
					#print("to gun hold")
					holding_old_collision_mask = holding.collision_mask
					holding.collision_mask = 0
					holding.get_node("gun_action").reparent(camera.gun_position_r)
					
					gun_tween_to_hold()
					
					# Update UI when switching to gun
					var gun_node = camera.gun_position_r.get_node("gun_action")
					gun_node.update_ui_ammo_display(ammo_pool)
					
					camera.hands_mode = camera.HandsMode.GunNormal
					
					current_action_state = ActionState.GUN
			if event is InputEventMouseButton and event.pressed:
				if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
					current_action_state = ActionState.EMPTY
					if holding != null:  # Add null check
						holding.gravity_scale = holding_old_gravity_scale
						if event.button_index == MOUSE_BUTTON_LEFT:
							holding.linear_velocity += 20 * (camera.hold_position.global_position - camera.global_position) / sqrt(holding.mass)
						var vel_clamped = 20 * (1 - (1 / (1 + 0.05 * holding.linear_velocity.length())))
						holding.linear_velocity = holding.linear_velocity.normalized() * vel_clamped
						camera.nodeRaycast.remove_exception(holding)
						camera.nodeRaycast.collision_mask |= 0b1_0000_0000
						holding.remove_from_group(&"IsHeld")
						holding = null
					camera.hands_mode = camera.HandsMode.Empty
		ActionState.GUN:
			if event.is_action_pressed("gun_hold_swap") and debounce_gun_hold_swap < 0.1:
				debounce_gun_hold_swap = 0.5
				#print("to item hold")
				holding.collision_mask = holding_old_collision_mask
				camera.gun_position_r.get_node("gun_action").reparent(holding)
				#holding.get_node("gun_action").position = Vector3.ZERO
				var tween_pos = get_tree().create_tween()
				tween_pos.set_ease(Tween.EASE_OUT)
				tween_pos.tween_property(holding.get_node("gun_action"), "position", Vector3.ZERO, 0.5)
				current_action_state = ActionState.HOLDITEM
				camera.hands_mode = camera.HandsMode.Hold
			elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				camera.gun_sprite_firing(true)
				camera.gun_position_r.get_node("gun_action").shoot(ammo_pool, 1)
				var tween_delay_end_firing_sprite = get_tree().create_tween()
				tween_delay_end_firing_sprite.tween_callback(camera.gun_sprite_firing.bind(false)).set_delay(randf_range(0.2, 0.3))
		ActionState.MELEEITEM:
			pass
