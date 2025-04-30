extends Node3D


@onready var nodeRotate: Node3D = $Rotate
@onready var flip: Node3D = $Rotate/Flip
@onready var nodeSpringarm: SpringArm3D = $Rotate/Flip/SpringArm3D
@onready var nodePointer: Node3D = $AimDebugPointer
@onready var nodeRaycast: RayCast3D = $Rotate/Flip/SpringArm3D/AimRaycast
@onready var first_person: Node3D = $Rotate/Flip/FirstPerson
@onready var camera_third_person: Camera3D = $Rotate/Flip/SpringArm3D/CameraThirdPerson
@onready var camera_first_person: Camera3D = $Rotate/Flip/FirstPerson/CameraFirstPerson

#@onready var listener_3p: AudioListener3D = $"Rotate/Flip/SpringArm3D/listener 3p"
#@onready var listener_1p: AudioListener3D = $"Rotate/Flip/FirstPerson/listener 1p"

@onready var hold_position: Node3D = $Rotate/Flip/FirstPerson/HoldPosition
@onready var gun_position_r: Marker3D = $Rotate/Flip/FirstPerson/GunPositionR

@onready var vector_pointer: Node3D = $Rotate/Flip/FirstPerson/HoldPosition/VectorPointer
@onready var aim_debug_pointer: Node3D = $AimDebugPointer


var next_distance: float = 10
var camera_distance: float = 10
var scale_in: float = 0.9
var scale_out: float = 1.2

var mouse_movement: Vector2 = Vector2(0,0)
var next_movement: Vector2 = Vector2(0,0)
var view_rotation: Quaternion = Quaternion()
var view_tilt: Quaternion = Quaternion()
var camera_transform: Transform3D

var aim_dist: float = 0
var aim_norm: Vector3 = Vector3(0, 0, 0)
var aim_pos: Vector3 = Vector3(0, 0, 0)

var look_speed_mult: float = 1
var zoom_speed_mult: float = 1
var capture: bool = true

var colliding: bool = false

enum LookMode {MOUSE_MOVE, MOUSE_MOVE_NOCAP, MENU_BG, FREEZE, MOUSE_DRAG}
var look_mode: LookMode = LookMode.MOUSE_MOVE
var middle_mouse_down: bool = false
var use_mouse_movement: bool = true

var process_aim: bool = true

var third_person_select: bool = false
var is_active: bool = true:
	set(value):
		is_active = value
		aim_debug_pointer.visible = value
		nodeRaycast.enabled = value
		camera_third_person.current = value
		camera_first_person.current = value
		if value:
			nodeRotate.process_mode = Node.PROCESS_MODE_INHERIT
		else:
			nodeRotate.process_mode = Node.PROCESS_MODE_DISABLED

# Called when the node enters the scene tree for the first time.
func _ready():
	scale_out = 1 / scale_in
	set_mode_menu()

func add_raycast_exception(col_obj: CollisionObject3D):
	nodeRaycast.add_exception(col_obj)

func get_collider():
	#print("get_collider()")
	if nodeRaycast.get_collider() is Area3D:
		return nodeRaycast.get_collider().get_parent()
	return nodeRaycast.get_collider()

func get_collider_shape():
	return nodeRaycast.get_collider_shape()


func set_mode_move():
	zoom_speed_mult = 1
	look_speed_mult = 1
	use_mouse_movement = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	look_mode = LookMode.MOUSE_MOVE

func set_mode_move_nocap():
	zoom_speed_mult = 1
	look_speed_mult = 1
	use_mouse_movement = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	look_mode = LookMode.MOUSE_MOVE_NOCAP

func set_mode_freeze():
	zoom_speed_mult = 0
	look_speed_mult = 0
	use_mouse_movement = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	look_mode = LookMode.FREEZE

func set_mode_menu():
	zoom_speed_mult = 0
	look_speed_mult = 0.1
	use_mouse_movement = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	look_mode = LookMode.MENU_BG

func set_mode_grab():
	zoom_speed_mult = 1
	look_speed_mult = 5
	use_mouse_movement = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	look_mode = LookMode.MOUSE_DRAG


func _input(event):
	if is_active:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
				next_distance *= lerp(1.0, scale_in, zoom_speed_mult)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
				next_distance *= lerp(1.0, scale_out, zoom_speed_mult)
			elif event.button_index == MOUSE_BUTTON_MIDDLE:
				middle_mouse_down = event.pressed
			if look_mode != LookMode.MOUSE_MOVE and look_mode != LookMode.MOUSE_DRAG:
				set_mode_move()
		elif event is InputEventMagnifyGesture:
			next_distance *= lerp(1.0, (1 / event.factor), zoom_speed_mult)
		elif event is InputEventMouseMotion and use_mouse_movement: # and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			next_movement = event.relative * look_speed_mult
		elif event is InputEventMouseMotion and look_mode == LookMode.MOUSE_DRAG and middle_mouse_down:
			next_movement = event.relative * look_speed_mult
		elif event is InputEventPanGesture:
			next_movement = event.delta * 300 * look_speed_mult
		#elif event is InputEventKey:
		#	if event.keycode == KEY_ESCAPE and event.pressed:
		#		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.is_action_pressed("swap_cameras"):
			if third_person_select:
				third_person_select = false
				camera_first_person.current = false and is_active
				camera_third_person.current = true and is_active
				nodeSpringarm.spring_length = camera_distance
				#listener_3p.current = false
				#listener_1p.current = true
			else:
				third_person_select = true
				camera_third_person.current = false and is_active
				camera_first_person.current = true and is_active
				nodeSpringarm.spring_length = 0
				#listener_3p.current = true
				#listener_1p.current = false
		elif event.is_action_pressed("release_mouse"):
			set_mode_menu()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_active:
		camera_distance = lerp(camera_distance, next_distance, 0.1)
		nodeSpringarm.spring_length = camera_distance
		mouse_movement = lerp(mouse_movement, next_movement, 0.5)
		view_tilt = Quaternion(nodeSpringarm.basis.x, -0.001 * mouse_movement.y)
		var tilt_up: float = nodeSpringarm.basis.y.y
		var m: float = min(max(2.5 * (tilt_up + 0.2), 0.0), 1.0)
		var tilt_fb_temp: float = -0.5 * tilt_up + 0.1
		var feedback: float = lerp(lerp(-tilt_up, tilt_fb_temp, m), lerp(tilt_fb_temp, 0.0, m), m)
		nodeSpringarm.basis = Basis(nodeSpringarm.basis.get_rotation_quaternion() * view_tilt.normalized() * Quaternion(nodeSpringarm.basis.x, nodeSpringarm.basis.y.z * -0.2 * feedback))
		first_person.basis = nodeSpringarm.basis
		view_rotation = Quaternion(nodeRotate.basis.y, -0.001 * mouse_movement.x)
		nodeRotate.basis = Basis(nodeRotate.basis.get_rotation_quaternion() * view_rotation.normalized())
		next_movement = Vector2(0, 0)
		if Input.is_action_pressed("flip_camera"):
			flip.basis = Basis(nodeRotate.basis.y, PI)
		else:
			flip.basis = Basis.IDENTITY
		
		if third_person_select:
			camera_transform = camera_third_person.global_transform
		else:
			camera_transform = camera_first_person.global_transform

		if process_aim:
			nodePointer.visible = true
			if(nodeRaycast.is_colliding()):
				colliding = true
				#nodePointer.visible = true
				aim_pos = nodeRaycast.get_collision_point()
				#nodePointer.global_transform.origin = aim_pos
				aim_dist = nodeRaycast.global_transform.origin.distance_to(aim_pos)
				aim_norm = nodeRaycast.get_collision_normal()
				#if aim_norm.is_equal_approx(Vector3(0, 1, 0)) or aim_norm.is_equal_approx(Vector3(0, -1, 0)):
					#nodePointer.global_transform.basis = Basis.looking_at(aim_norm, Vector3(1, 0, 0))
				#else:
					#nodePointer.global_transform.basis = Basis.looking_at(aim_norm)
			else:
				colliding = false
				#nodePointer.visible = false
				var hold_pos_global_vec = hold_position.global_position - self.global_position
				aim_pos = hold_pos_global_vec * 10 + self.global_position
				aim_dist = hold_pos_global_vec.length() * 10
				aim_norm = Vector3.UP
		#else:
			#nodePointer.visible = false
