extends RigidBody3D

@onready var player_remote_transform: RemoteTransform3D = $player_remote_transform
@onready var col_wheel_front: CollisionShape3D = $"col wheel front"
@onready var mesh_wheel_front: MeshInstance3D = $"mesh wheel front"
@onready var marker_front: Marker3D = $"mesh wheel front/marker front"
@onready var marker_back: Marker3D = $"mesh wheel front/marker back"

@export var move_speed_fb: float = 15
@export var move_speed_lr: float = 1
@export var turn_speed: float = 0.05

var is_controlled: bool = false
var player_ref: Node3D
var wish_dir: Vector3
var turn_smoothed: float = 0

func _physics_process(delta: float) -> void:
	self.linear_velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	if is_controlled and player_ref != null:
		var input_dir = Input.get_vector("left", "right", "up", "down") #.normalized()
		turn_smoothed = lerp(turn_smoothed, input_dir.x, 0.1)
		var camera_rotation = player_ref.camera.nodeRotate.rotation.y
		col_wheel_front.rotation.y = turn_smoothed #camera_rotation
		mesh_wheel_front.rotation.y = turn_smoothed #camera_rotation
		wish_dir = self.basis * Vector3(input_dir.x * move_speed_lr, 0.0, input_dir.y * move_speed_fb)
		#self.velocity.x = lerp(self.velocity.x, wish_dir.x, 0.05)
		#self.velocity.z = lerp(self.velocity.z, wish_dir.z, 0.05)
		#col_wheel_front.rotation.y = PI * input_dir.x
		#mesh_wheel_front.rotation.y = PI * input_dir.x
		#self.rotation.y += self.velocity.z * turn_speed * turn_smoothed #camera_rotation
		#print(self.rotation.y)
		#var view_rotation = Quaternion(self.basis.y, -0.1 * self.velocity.z * turn_speed * turn_smoothed)
		#self.basis = Basis(self.basis.get_rotation_quaternion() * view_rotation.normalized())
		var front_wheel_pos = col_wheel_front.global_position - self.global_position
		var steer_vec = marker_front.global_position - marker_back.global_position
		apply_force(steer_vec * 2 * input_dir.y * move_speed_fb, front_wheel_pos)
