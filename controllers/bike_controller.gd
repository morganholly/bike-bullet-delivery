extends Node3D

@onready var player_remote_transform: RemoteTransform3D = $frame/player_remote_transform
@onready var front_wheel: RigidBody3D = $"front wheel"
@onready var back_wheel: RigidBody3D = $"back wheel"
@onready var marker_front: Marker3D = $"front wheel/marker front"
@onready var marker_back: Marker3D = $"front wheel/marker back"
@onready var marker_front_wheel_ground: Marker3D = $"front wheel/marker center"
@onready var marker_back_wheel_ground: Marker3D = $"back wheel/marker center ground"
@onready var marker_up: Marker3D = $"back wheel/marker center up"

@export var move_speed_fb: float = 15
@export var move_speed_lr: float = 1
@export var turn_speed: float = 0.05

var is_controlled: bool = false
var player_ref: Node3D
var wish_dir: Vector3
var turn_smoothed: float = 0

#func _physics_process(delta: float) -> void:
	##self.linear_velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	#if is_controlled and player_ref != null:
		#var input_dir = Input.get_vector("left", "right", "up", "down") #.normalized()
		#turn_smoothed = lerp(turn_smoothed, input_dir.x, 0.1)
		#var camera_rotation = player_ref.camera.nodeRotate.rotation.y
		#front_wheel.rotation.y = turn_smoothed #camera_rotation
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
