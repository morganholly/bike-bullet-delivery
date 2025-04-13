extends Node3D

@onready var player_remote_transform: RemoteTransform3D = $frame/player_remote_transform

@onready var marker_front: Marker3D = $"front wheel/marker front"
@onready var marker_back: Marker3D = $"front wheel/marker back"
@onready var marker_front_wheel_ground: Marker3D = $"front wheel/marker center"
@onready var marker_back_wheel_ground: Marker3D = $"back wheel/marker center ground"
@onready var marker_up: Marker3D = $"back wheel/marker center up"

@onready var front_wheel: RigidBody3D = $"front wheel"
@onready var back_wheel: RigidBody3D = $"back wheel"
#@onready var front_hinge: RigidBody3D = $"front hinge"
#@onready var back_hinge: RigidBody3D = $"back hinge"

@onready var frame: RigidBody3D = $frame
#@onready var back_spring: JoltSliderJoint3D = $"back spring"
#@onready var front_spring: JoltSliderJoint3D = $"front spring"
#@onready var back_spin: JoltHingeJoint3D = $"back spin"
#@onready var front_spin: JoltHingeJoint3D = $"front spin"
@onready var back_joint_r: JoltGeneric6DOFJoint3D = $"frame/back joint r"
@onready var front_joint_r: JoltGeneric6DOFJoint3D = $"frame/front joint r"
@onready var back_joint_l: JoltGeneric6DOFJoint3D = $"frame/back joint l"
@onready var front_joint_l: JoltGeneric6DOFJoint3D = $"frame/front joint l"

@export var move_speed_fb: float = 5
@export var move_speed_lr: float = 1
@export var turn_speed: float = 0.05

@export var upright_impulse_strength: float = 10

var is_controlled: bool = false
var player_ref: Node3D
var wish_dir: Vector3
var turn_smoothed: float = 0

func _input(event: InputEvent) -> void:
	if event.is_action("upright_rideable"):
		front_wheel.apply_impulse(upright_impulse_strength * Vector3.DOWN, Vector3(0, 0, -2))
		back_wheel.apply_impulse(upright_impulse_strength * Vector3.DOWN)
		frame.apply_impulse(2 * upright_impulse_strength * Vector3.UP, Vector3(0, 2, -1))

func _physics_process(delta: float) -> void:
	##self.linear_velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	if is_controlled and player_ref != null:
		var input_dir = Input.get_vector("left", "right", "up", "down") #.normalized()
		turn_smoothed = lerp(turn_smoothed, input_dir.x, 0.1)
		#var camera_rotation = player_ref.camera.nodeRotate.rotation.y
		front_wheel.rotation.y = self.rotation.y + deg_to_rad(90) - turn_smoothed #camera_rotation
		#wish_dir = self.basis * Vector3(input_dir.x * move_speed_lr, 0.0, input_dir.y * move_speed_fb)
		##self.velocity.x = lerp(self.velocity.x, wish_dir.x, 0.05)
		##self.velocity.z = lerp(self.velocity.z, wish_dir.z, 0.05)
		##col_wheel_front.rotation.y = PI * input_dir.x
		##mesh_wheel_front.rotation.y = PI * input_dir.x
		##self.rotation.y += self.velocity.z * turn_speed * turn_smoothed #camera_rotation
		##print(self.rotation.y)
		##var view_rotation = Quaternion(self.basis.y, -0.1 * self.velocity.z * turn_speed * turn_smoothed)
		##self.basis = Basis(self.basis.get_rotation_quaternion() * view_rotation.normalized())
		#var front_wheel_pos = marker_front_wheel_ground.global_position - marker_back_wheel_ground.global_position
		#var steer_vec = marker_front.global_position - marker_back.global_position
		##apply_force(steer_vec * 2 * input_dir.y * move_speed_fb, front_wheel_pos)
		##apply_force(front_wheel_pos * 0.5 * input_dir.y * move_speed_fb, front_wheel_pos)
		back_joint_r.set_angular_motor_x_target_velocity(-input_dir.y * move_speed_fb)
		front_joint_r.set_angular_motor_x_target_velocity(-input_dir.y * move_speed_fb)
		back_joint_l.set_angular_motor_x_target_velocity(-input_dir.y * move_speed_fb)
		front_joint_l.set_angular_motor_x_target_velocity(-input_dir.y * move_speed_fb)
