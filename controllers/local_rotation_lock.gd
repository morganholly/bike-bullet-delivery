extends RigidBody3D


@export var lock_x: bool
@export var lock_y: bool
@export var lock_z: bool

@export_range(-180, 180, 1, "radians_as_degrees") var lock_x_to: float
@export_range(-180, 180, 1, "radians_as_degrees") var lock_y_to: float
@export_range(-180, 180, 1, "radians_as_degrees") var lock_z_to: float

func _ready() -> void:
	self.custom_integrator = true

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var step = state.step
	var lv = state.linear_velocity
	lv += state.total_gravity
	
	var linear_damp = 1 - step * state.total_linear_damp
	if linear_damp < 0: linear_damp = 0
	
	lv *= linear_damp
	
	var av = state.angular_velocity
	
	var angular_damp = 1 - step * state.total_angular_damp
	if angular_damp < 0: angular_damp = 0
	
	av *= angular_damp

	if lock_x: av.x = lock_x_to
	if lock_y: av.y = lock_y_to
	if lock_z: av.z = lock_z_to
	
	state.linear_velocity = lv
	state.angular_velocity = av
