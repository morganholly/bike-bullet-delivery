extends CharacterBody3D

@onready var camera: Node3D = $Camera
@onready var collision_shape_3d: CollisionShape3D = $capsule_collider
@onready var raycast_below: RayCast3D = $RaycastBelow
@onready var rotate: Node3D = $Rotate
@onready var raycast_stairs_ahead: RayCast3D = $Rotate/RaycastStairsAhead
@onready var orig_capsule_height: float = $capsule_collider.shape.height
@onready var capsule_view_mesh: MeshInstance3D = $WorldModel/capsule_view_mesh
@onready var hat: Node3D = $WorldModel/hat
@onready var stair_climb_area: Area3D = $Rotate/stair_climb_area
@onready var hold_container: Node3D = $HoldContainer
@onready var uniform_health: Node = $UniformHealth
@onready var footsteps: Node3D = $Footsteps


@export var is_player: bool = true
@export var can_move: bool = true
@export var is_rollerblade: bool = false

@export_group("Air")
@export var air_speed_control: float = 0.075

@export_group("Jump")
@export var jump_velo: float = 7.0
@export var auto_bhop: bool = true
@export var jump_accel: float = 0.5
@export var jump_accel_recharge: float = 0.1
@export var jump_speedup: float = 0.05
@export var coyote_time: float = 0.1

@export_group("Climb")
@export var climb_speed: float = 3

@export_group("Crouch")
@export var cr_h_reduce: float = 0.7
@export var cr_jump_raise_scale: float = 0.9
@export var cr_walk_scale: float = 0.8

var is_crouched: bool = false

@export_group("Walk")
@export var walk_speed: float = 7.0
@export var sprint_speed: float = 10
@export var ground_smooth: float = 0.1
@export var ground_friction: float = 0.7

@export_group("Rollerblade")
@export var rb_turn_rate: float = 1
@export var rb_max_speed: float = 25
@export var rb_air_speed_control: float = 0.05

@export_group("Camera")
@export var camera_y_smooth: float = 20
@export var camera_height: float = 2

var camera_actual_height = camera_height

var wish_dir := Vector3.ZERO

var jump_recharge_inv: float = 0
var jump_recharge_inv_wgrab: float = 0
var was_on_floor_last_frame: bool = false
var speed_scale: float = 1
var coyote_timer: float = 0

var max_step_height: float = 0.5
var snapped_to_stairs_last_frame: bool = false
var pframes_since_on_floor: int = -INF

var inertial_velocity := Vector3.ZERO

var last_rotation: float = 0
var smoothed_rotation_abs_delta: float = 0

var is_riding: bool = false
var riding_node: Node3D

var rollerblade_direction: Vector3
var rb_delta_accum: float
var rb_actual_speed: float
var rb_accel_timer: float

var landed_jump: bool = false
var last_air_y_vel: float = 0

func exp_decay(a: float, b: float, d: float, delta: float) -> float:
	return b + (a - b) * exp(-d * delta)

func death_callback():
	# this will probably glitch out the camera
	self.is_player = false

func _ready() -> void:
	# could add automatic world model hiding here
	camera.is_active = is_player
	camera.add_raycast_exception(self)
	uniform_health.death_callback = death_callback


func _process(delta: float) -> void:
	if is_player:
		var last_y = camera.global_position.y
		camera.global_position = self.global_position
		camera.global_position.y = exp_decay(last_y, self.global_position.y + camera_actual_height, camera_y_smooth, delta)
	capsule_view_mesh.mesh.height = (orig_capsule_height - cr_h_reduce) if is_crouched else orig_capsule_height
	capsule_view_mesh.position.y = capsule_view_mesh.mesh.height * 0.5
	hat.position.y = capsule_view_mesh.mesh.height


func is_surface_too_steep(normal: Vector3) -> bool:
	return normal.angle_to(Vector3.UP) > deg_to_rad(50)

func _run_body_test_motion(from: Transform3D, motion: Vector3, result = null) -> bool:
	if not result: result = PhysicsTestMotionResult3D.new()
	var params = PhysicsTestMotionParameters3D.new()
	params.from = from
	params.motion = motion
	return PhysicsServer3D.body_test_motion(self.get_rid(), params, result)

func get_velo_at_pos(rid: RID, at: Vector3) -> Vector3:
	return PhysicsServer3D.body_get_direct_state(rid).get_velocity_at_local_position(at)

func get_collision_velo() -> Vector3:
	if get_slide_collision_count() > 0:
		var avg_velo := Vector3.ZERO
		for i in range(0, get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var avg_velo_for_collision := Vector3.ZERO
			for j in range(0, collision.get_collision_count()):
				avg_velo_for_collision += get_velo_at_pos(collision.get_collider_rid(j), collision.get_position(j))
			avg_velo_for_collision /= collision.get_collision_count()
			avg_velo += avg_velo_for_collision
		avg_velo /= get_slide_collision_count()
		return avg_velo
	else:
		return Vector3.ZERO

func get_move_speed(is_action_crouching: bool, is_action_sprint: bool) -> float:
	var res = walk_speed
	if is_action_crouching:
		res *= cr_walk_scale
	else:
		if is_action_sprint:
			res = sprint_speed
	return speed_scale * res

func _air_physics_process(delta: float, is_action_crouching: bool, is_action_sprint: bool, speed: float, air_control: float) -> void:
	#print(self.velocity.y)
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	self.velocity.x = lerp(self.velocity.x, wish_dir.x * speed, air_control)
	self.velocity.z = lerp(self.velocity.z, wish_dir.z * speed, air_control)

func _walkrun_physics_process(delta: float, is_action_crouching: bool, is_action_sprint: bool) -> void:
	var speed = get_move_speed(is_action_crouching, is_action_sprint)
	var y_vel = self.velocity.y
	var xz_vel = Vector3(1, 0, 1) * self.velocity
	var vel_norm = xz_vel.normalized()
	xz_vel = lerp(xz_vel, wish_dir * speed, ground_smooth)
	if xz_vel.length() > speed:
		var over = xz_vel.length() - speed
		xz_vel = (over * ground_friction + speed) * xz_vel.normalized()
	self.velocity = xz_vel
	self.velocity.y = y_vel

func _rollerblade_physics_process(delta: float, is_action_crouching: bool, is_action_sprint: bool, walk_dir: Vector3) -> void:
	var y_vel = self.velocity.y
	var xz_vel = Vector3(1, 0, 1) * self.velocity
	var turn_scale = 1 / (1 + (xz_vel.length() * 0.05 / rb_turn_rate) ** 2)
	
	rollerblade_direction = rollerblade_direction.slerp(walk_dir, turn_scale * delta)
	
	var desired_speed_01 = 0.2
	if is_action_sprint:
		desired_speed_01 = 1
	if is_action_crouching:
		desired_speed_01 = 0.1
	desired_speed_01 *= walk_dir.length()
	if desired_speed_01 > rb_accel_timer:
		rb_accel_timer = move_toward(rb_accel_timer, desired_speed_01, delta * 1/40)
	else:
		rb_accel_timer = move_toward(rb_accel_timer, desired_speed_01, delta * 1/15)
	rb_actual_speed = rb_max_speed * (1.0333 - 1.0333 / (rb_accel_timer * rb_accel_timer * 30 + 1))
	
	self.velocity = rollerblade_direction * rb_actual_speed / (rb_delta_accum + 1)
	self.velocity.y = y_vel

func _crouch_physics_process(delta: float) -> void:
	pass

func _snap_down_to_stairs_check() -> void:
	var did_snap: bool = false
	var floor_below: bool = raycast_below.is_colliding() and not is_surface_too_steep(raycast_below.get_collision_normal())
	var flew_off_this_frame: bool = pframes_since_on_floor == 1
	if not is_on_floor() and velocity.y <= 0 and (flew_off_this_frame or snapped_to_stairs_last_frame) and floor_below:
		var body_test_result = PhysicsTestMotionResult3D.new()
		if _run_body_test_motion(self.global_transform, Vector3(0, -max_step_height, 0), body_test_result):
			var translate_y = body_test_result.get_travel().y
			self.position.y += translate_y
			apply_floor_snap()
			did_snap = true
	snapped_to_stairs_last_frame = did_snap

func _snap_up_stairs_check(delta: float) -> bool:
	if not is_on_floor() and not snapped_to_stairs_last_frame:
		return false
	var expected_move_motion = self.velocity * Vector3(1,0,1) * delta
	var step_pos_with_clearance = self.global_transform.translated(expected_move_motion + Vector3(0, max_step_height * 2, 0))
	var down_check_result = PhysicsTestMotionResult3D.new()
	if _run_body_test_motion(step_pos_with_clearance, Vector3(0, max_step_height * -2, 0), down_check_result):
		var collider = down_check_result.get_collider()
		if collider.is_class("StaticBody3D") or collider.is_class("CSGShape3D"):
			var step_height = ((step_pos_with_clearance.origin + down_check_result.get_travel()) - self.global_position).y
			if step_height > max_step_height or step_height < 0.01 or (down_check_result.get_collision_point() - self.global_position).y > max_step_height:
				return false
			raycast_stairs_ahead.global_position = (down_check_result.get_collision_point() + Vector3(0, max_step_height, 0) + expected_move_motion.normalized() * 0.1)
			raycast_stairs_ahead.force_raycast_update()
			if raycast_stairs_ahead.is_colliding() and not is_surface_too_steep(raycast_stairs_ahead.get_collision_normal()):
				var last_pos = self.global_position
				self.global_position = step_pos_with_clearance.origin + down_check_result.get_travel()
				apply_floor_snap()
				snapped_to_stairs_last_frame = true
				return true
	return false

func _handle_crouch(delta: float, is_action_crouching: bool) -> void:
	var was_crouched_last_frame: bool = is_crouched
	if is_action_crouching:
		is_crouched = true
	elif is_crouched and not self.test_move(self.global_transform, Vector3(0, cr_h_reduce, 0)):
		is_crouched = false
	
	var translate_y_if_possible: float = 0
	if was_crouched_last_frame != is_crouched and not is_on_floor() and not snapped_to_stairs_last_frame:
		translate_y_if_possible = cr_h_reduce * cr_jump_raise_scale * (1 if is_crouched else -1)
	
	if translate_y_if_possible != 0:
		var result = KinematicCollision3D.new()
		self.test_move(self.global_transform, Vector3(0, translate_y_if_possible, 0), result)
		self.position.y += result.get_travel().y
	
	camera_actual_height = camera_height - cr_h_reduce if is_crouched else camera_height
	collision_shape_3d.shape.height = (orig_capsule_height - cr_h_reduce) if is_crouched else orig_capsule_height
	collision_shape_3d.position.y = collision_shape_3d.shape.height * 0.5

func _physics_process(delta: float) -> void:
	if not is_riding:
		if is_player and can_move:
			_internal_physics_process(delta,
				Input.is_action_pressed("crouch"),
				Input.is_action_pressed("sprint"),
				Input.is_action_pressed("jump"),
				Input.is_action_just_pressed("jump"),
				Input.get_vector("left", "right", "up", "down").normalized(),
				0
			)
		else:
			pass
			# call same function with different inputs

func _internal_physics_process(delta: float,
								is_action_crouching: bool,
								is_action_sprint: bool,
								is_action_jump: bool,
								just_action_jump: bool,
								input_dir: Vector2, # world space for npc
								npc_rotation: float) -> void:
	if is_player:
		rotate.basis = camera.nodeRotate.basis
		wish_dir = camera.nodeRotate.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	else:
		rotate.rotation.y = npc_rotation
		wish_dir = Vector3(input_dir.x, 0.0, input_dir.y)
	var was_on_floor_at_start_of_frame: bool = is_on_floor()
	var did_jump: bool = false
	
	if not is_rollerblade:
		rollerblade_direction = wish_dir.normalized()
		
		_handle_crouch(delta, is_action_crouching)
		
	if was_on_floor_at_start_of_frame:
		coyote_timer = 0
	
	if (coyote_timer <= coyote_time) or was_on_floor_at_start_of_frame or snapped_to_stairs_last_frame:
		if (coyote_timer <= coyote_time) and not is_on_floor():
			self.velocity.y *= 0.5
		if (auto_bhop and is_action_jump) or just_action_jump:
			footsteps.is_walking = false
			did_jump = true
			self.velocity.y = 0 # otherwise jumping in coyote time seems very weak
			var y_jump: float = jump_velo * (1 - jump_recharge_inv)
			if not (was_on_floor_at_start_of_frame or snapped_to_stairs_last_frame):
				self.velocity += Vector3(0, y_jump, 0)
			else:
				self.velocity += get_floor_normal() * y_jump
			var actual_jump_accel = 1 + jump_accel * (1 - jump_recharge_inv) * speed_scale
			self.velocity.x *= actual_jump_accel
			self.velocity.z *= actual_jump_accel
			jump_recharge_inv = 1 # lerp(jump_recharge_inv, 1.0, 0.5)
			coyote_timer = coyote_time
	if not is_rollerblade:
		if was_on_floor_at_start_of_frame or snapped_to_stairs_last_frame: # after implementing crouching, switch based on crouch state
			if landed_jump:
				last_air_y_vel = -last_air_y_vel
				#print(last_air_y_vel)
				var air_vel_sq: float = last_air_y_vel * last_air_y_vel
				var first_step_strength = 2 + (1 - (1 / (air_vel_sq * last_air_y_vel * 0.0015 + 1))) * 8
				var second_step_strength = 2 + (1 - (1 / (air_vel_sq * air_vel_sq * 0.00005 + 1))) * 8
				print(first_step_strength, " ", second_step_strength)
				footsteps.play_now_with_strength(
					first_step_strength, 2,
					randf_range(0.05, 0.5),
					second_step_strength, 2)
			_walkrun_physics_process(delta, is_action_crouching, is_action_sprint)
			#floor_max_angle = deg_to_rad(50)
			pframes_since_on_floor = 0
			#was_on_floor_last_frame = true
			jump_recharge_inv_wgrab = 0
			#print((self.velocity * Vector3(1, 0, 1)).length())
				#play_now_with_strength()
			landed_jump = false
			if (self.velocity * Vector3(1, 0, 1)).length() > 0:
				footsteps.is_walking = true
				var step_strength: float = 2
				var step_time_jitter: float = 0.25
				if is_action_crouching:
					step_strength = 1.0
					step_time_jitter = 0.5
				else:
					if is_action_sprint:
						step_strength = 4.0
						step_time_jitter = 0.05
				footsteps.time = lerp(footsteps.time, 0.25 * (self.velocity * Vector3(1, 0, 1)).length(), 0.2)
				footsteps.step_strength = lerp(footsteps.step_strength, step_strength, 0.15)
				footsteps.time_jitter = lerp(footsteps.time_jitter, step_time_jitter, 0.15)
			else:
				footsteps.is_walking = false
		else:
			landed_jump = true
			footsteps.is_walking = false
			floor_max_angle = deg_to_rad(80)
			_air_physics_process(delta, is_action_crouching, is_action_sprint, get_move_speed(is_action_crouching, is_action_sprint), air_speed_control)
			last_air_y_vel = self.velocity.y
			#self.velocity += ground_velo
			pframes_since_on_floor += 1
			#was_on_floor_last_frame = false
		
		#it would be nice to have some better way of combining forward and up movement. it should probably be mainly up, but forward would be super cool for wall jumping
		if stair_climb_area.has_overlapping_bodies():
			if is_action_jump:
				self.velocity *= Vector3(0, 0.5, 0.5)
				self.velocity += (climb_speed * Vector3.UP)
				jump_recharge_inv = 0
		if not _snap_up_stairs_check(delta):
			move_and_slide()
			_snap_down_to_stairs_check()
		else:
			self.velocity.y = 0 # prevents jump accumulating during stair up snapping
	else:
		var rb_dir_cache = rollerblade_direction
		if was_on_floor_at_start_of_frame: # after implementing crouching, switch based on crouch state
			_rollerblade_physics_process(delta, is_action_crouching, is_action_sprint, wish_dir)
			#floor_max_angle = deg_to_rad(50)
			pframes_since_on_floor = 0
			#was_on_floor_last_frame = true
			jump_recharge_inv_wgrab = 0
		else:
			rollerblade_direction = lerp(rollerblade_direction, wish_dir.normalized(), 0.05).normalized()
			floor_max_angle = deg_to_rad(80)
			_air_physics_process(delta, is_action_crouching, is_action_sprint, rb_actual_speed / (rb_delta_accum + 1), rb_air_speed_control)
			#self.velocity += ground_velo
			pframes_since_on_floor += 1
			#was_on_floor_last_frame = false
		move_and_slide()
		rb_delta_accum += rb_dir_cache.distance_to(rollerblade_direction)
		#print(rb_delta_accum)
		rb_delta_accum = max(0, rb_delta_accum - 0.02)
	
	# i don't think the inertia is needed for this
	#var turn_amount = camera.nodeRotate.basis.get_euler().y - last_rotation
	#smoothed_rotation_abs_delta = lerp(smoothed_rotation_abs_delta, abs(turn_amount), 0.1)
	#var turn_speed_inv: float = 0.1 / (smoothed_rotation_abs_delta + 0.0000001)
	#var vel_turn_factor: float = 1 - (1 / (1 + turn_speed_inv))
	#vel_turn_factor *= vel_turn_factor
	##print(vel_turn_factor)
	
	#var velo_no_y = self.velocity * Vector3(1, 0, 1)
	
	#var vel_len: float = velo_no_y.length()
	#var vel_norm: Vector3 = velo_no_y.normalized()
	#var vel_norm_rot: Vector3 = vel_norm.rotated(Vector3.UP, turn_amount)
	##var vel_norm_rot: Vector3 = camera.nodeRotate.basis * vel_norm
	#velo_no_y = lerp(vel_norm, vel_norm_rot, vel_turn_factor).normalized() * vel_len
	#self.velocity = velo_no_y + Vector3(0, self.velocity.y, 0)
	
	# i don't think the inertia is needed for this
	#var ine_vel_len: float = inertial_velocity.length() * min(1, 0.02 * vel_turn_factor + 0.99)
	#var ine_vel_norm: Vector3 = inertial_velocity.normalized()
	#var ine_vel_norm_rot: Vector3 = ine_vel_norm.rotated(Vector3.UP, turn_amount) # either seems to turn too little or too much
	##var ine_vel_norm_rot: Vector3 = camera.nodeRotate.basis * ine_vel_norm
	#inertial_velocity = lerp(ine_vel_norm, ine_vel_norm_rot, vel_turn_factor).normalized() * ine_vel_len
	
	#last_rotation = camera.nodeRotate.basis.get_euler().y
	
	#if inertial_velocity.length() > 0.0001:
		#camera.vector_pointer.look_at(camera.hold_position.global_position + inertial_velocity)
	if rollerblade_direction.length() > 0.0001:
		camera.vector_pointer.look_at(camera.hold_position.global_position + rollerblade_direction)
	camera.vector_pointer.scale.z = rollerblade_direction.length()
	#if wish_dir.length() > 0.0001:
		#camera.vector_pointer.look_at(camera.hold_position.global_position + wish_dir)
	#camera.vector_pointer.scale.z = wish_dir.length()
	
	floor_max_angle = deg_to_rad(50 + 45 * (1 - (1 / ((self.velocity * Vector3(1, 0, 1)).length() * 0.1 + 1))))
	jump_recharge_inv *= 1 - jump_accel_recharge
	coyote_timer += delta

# fall prevention (crouching or in some areas)

# detect nearby ledges with a line of raycasts in the movement direction (maybe spaced out more at higher speeds)
# if not jumping (also implement coyote time with raycaststairsbelow, maybe rename that), calculate at each's angle what a flat plane's distance would be
# if the distance exceeds that projected plane, at any spot, find the closest drop, and concentrate the stack to focus on that for a better distance estimate
# apply a force to slow the player down, but if the player is moving sideways to it, turn their movement vector instead

# alternatively, have 8 invisible colliders around the player each with their own raycast
# when their distance is within some margin of the player's foot position, move them outwards up to some maximum distance
# if their distance indicates a drop off, use the players movement delta to update the new position (if the player moves +z a units towards a dropoff, the +z wall moves relatively -a, and the diagonal +z walls move `sqrt(2*a*a)`)
# the player will then collide with the walls and no longer fall off
# this however is very absolute, rather than a more invisible nudge


@onready var can_ride: Area3D = $can_ride
@onready var can_ride_collider: CollisionShape3D = $can_ride/can_ride_collider
var trying_to_ride: bool = false
var retry_ride_wait: bool = false

func reset_trying_to_ride():
	trying_to_ride = false

func reset_retry_ride_wait():
	retry_ride_wait = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("rollerblade") and event.is_pressed():
		is_rollerblade = not is_rollerblade
		if is_rollerblade:
			if rollerblade_direction.length() < 0.01:
				rollerblade_direction = camera.nodeRotate.basis * Vector3(0, 0, -1)
			var xz_vel = Vector3(1, 0, 1) * self.velocity
			rb_accel_timer = sqrt(((1.0333 / (1.0333 - (xz_vel.length() / rb_max_speed))) - 1) / 30)
		#print("rollerblading: ", is_rollerblade, " ", event)
	elif event.is_action("ride") and event.is_pressed() and not trying_to_ride and not retry_ride_wait:
		if not is_riding:
			print("get in loser we're going riding")
			trying_to_ride = true
			can_ride_collider.shape.radius = 0.01
			var ride_check_tween = get_tree().create_tween()
			ride_check_tween.tween_property(can_ride_collider.shape, "radius", 4.0, 1.0)
			ride_check_tween.tween_callback(reset_trying_to_ride)
		else:
			print("this is my stop")
			riding_node.player_remote_transform.remote_path = ""
			riding_node.player_remote_transform.force_update_cache()
			riding_node.is_controlled = false
			riding_node.player_ref = null
			riding_node.remove_collision_exception_with(self)
			is_riding = false
			riding_node = null
			retry_ride_wait = true
			var ride_check_tween = get_tree().create_tween()
			ride_check_tween.tween_interval(1.0)
			ride_check_tween.tween_callback(reset_retry_ride_wait)
			self.global_rotation = Vector3.ZERO

func _on_can_ride_body_entered(body: Node3D) -> void:
	if trying_to_ride and not retry_ride_wait:
		if body.is_in_group("Rideable"):
			print("here's my whip")
			is_riding = true
			trying_to_ride = false
			riding_node = body#.get_parent()
			riding_node.add_collision_exception_with(self)
			can_ride_collider.shape.radius = 0.01
			#body.player_remote_transform.remote_path = body.get_path_to(self)
			riding_node.player_remote_transform.remote_path = self.get_path()
			riding_node.player_remote_transform.force_update_cache()
			riding_node.is_controlled = true
			riding_node.player_ref = self

func _on_can_ride_body_exited(body: Node3D) -> void:
	pass # Replace with function body.
