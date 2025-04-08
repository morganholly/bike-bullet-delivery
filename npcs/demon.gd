extends RigidBody3D  # Or CharacterBody3D

var target = null
var speed = 5.0
var follow_strength = 19.0

func _ready():
	$Area3D.connect("body_entered", self._on_Area3D_body_entered)
	$Area3D.connect("body_exited", self._on_Area3D_body_exited)

	$Area3D.collision_mask = $Area3D.collision_mask | 2

func _physics_process(delta):
	if target:
		# Target exists, move toward it
		var target_position = target.global_transform.origin
		var direction = (target_position - global_transform.origin).normalized()
		apply_central_force(direction * follow_strength)

		print(position)

func _on_Area3D_body_entered(body):
	if body.is_in_group("Player") and target == null:
		print("Player detected!")
		target = body

func _on_Area3D_body_exited(body):
	if body == target:
		target = null
