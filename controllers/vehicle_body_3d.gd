extends VehicleBody3D


@export var steer_smooth_coef = 0.1
@export var steer_limit = 0.4
@export var brake_strength = 2.0
@export var engine_strength := 0.5

@onready var player_remote_transform: RemoteTransform3D = $player_remote_transform
var is_controlled: bool = false
var player_ref: Node3D

var previous_speed := linear_velocity.length()
var steer_target := 0.0

func _physics_process(delta: float):
	var fwd_mps := (linear_velocity * transform.basis).x

	steer_target = Input.get_axis(&"right", &"left")
	steer_target *= steer_limit
	
	engine_force = Input.get_axis(&"down", &"up")
	if engine_force < 0:
		engine_force *= brake_strength * Input.get_action_strength(&"down")
	else:
		engine_force *= engine_strength * Input.get_action_strength(&"up")
	
	steering = lerp(steering, steer_target, steer_smooth_coef)


func _input(event: InputEvent) -> void:
	if event.is_action("upright_rideable"):
		var upright_impulse_strength: float = 10
		self.apply_impulse(upright_impulse_strength * Vector3.DOWN, Vector3(0, 0, -2))
		self.apply_impulse(upright_impulse_strength * Vector3.DOWN)
		self.apply_impulse(2 * upright_impulse_strength * Vector3.UP, Vector3(0, 2, -1))
		self.global_rotation = Vector3.ZERO
