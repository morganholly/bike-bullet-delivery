extends RigidBody3D

@onready var player_remote_transform: RemoteTransform3D = $player_remote_transform
@onready var wheel_back: Node3D = $wheel_back
@onready var wheel_front: Node3D = $wheel_front
@onready var wheel_back_2: Node3D = $wheel_back2
@onready var wheel_front_2: Node3D = $wheel_front2

var is_controlled: bool = false
var player_ref: Node3D
var wish_dir: Vector3
var turn_smoothed: float = 0

@export var upright_impulse_strength: float = 10

func _ready() -> void:
	wheel_back.collide_shape.reparent(self)
	wheel_front.collide_shape.reparent(self)
	wheel_back_2.collide_shape.reparent(self)
	wheel_front_2.collide_shape.reparent(self)

func _input(event: InputEvent) -> void:
	if event.is_action("upright_rideable"):
		self.apply_impulse(upright_impulse_strength * Vector3.DOWN, Vector3(0, 0, -2))
		self.apply_impulse(upright_impulse_strength * Vector3.DOWN)
		self.apply_impulse(2 * upright_impulse_strength * Vector3.UP, Vector3(0, 2, -1))
		self.global_rotation = Vector3.ZERO

func _physics_process(delta: float) -> void:
	self.apply_central_force(Vector3.DOWN * ProjectSettings.get_setting("physics/3d/default_gravity"))
	#if is_controlled and player_ref != null:
		#var input_dir = Input.get_vector("left", "right", "up", "down") #.normalized()
		#turn_smoothed = lerp(turn_smoothed, input_dir.x, 0.1)
		##var camera_rotation = player_ref.camera.nodeRotate.rotation.y
	wheel_back.shapecast_forces(delta)
	wheel_front.shapecast_forces(delta)
	wheel_back_2.shapecast_forces(delta)
	wheel_front_2.shapecast_forces(delta)
	self.apply_force(wheel_back.center_force)
	self.apply_force(wheel_front.center_force)
	self.apply_force(wheel_back_2.center_force)
	self.apply_force(wheel_front_2.center_force)
	#wheel_back.update_forces(delta, 0.1)
	#wheel_front.update_forces(delta, 0.1)
	#wheel_back_2.update_forces(delta, 0.1)
	#wheel_front_2.update_forces(delta, 0.1)
	#for i in range(0, len(wheel_back.raycast_list)):
		#self.apply_force(wheel_back.forces[i], wheel_back.position + wheel_back.marker_list[i].position)
		#self.apply_force(wheel_front.forces[i], wheel_front.position + wheel_front.marker_list[i].position)
		#self.apply_force(wheel_back_2.forces[i], wheel_back_2.position + wheel_back_2.marker_list[i].position)
		#self.apply_force(wheel_front_2.forces[i], wheel_front_2.position + wheel_front_2.marker_list[i].position)
