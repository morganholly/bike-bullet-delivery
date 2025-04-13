extends Entity


class_name Enemy


var target = null
var follow_strength = 17.0

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

		#print(position)

func _on_Area3D_body_entered(body):
	if body.is_in_group("Player") and target == null:
		print("Player detected!")
		target = body

func _on_Area3D_body_exited(body):
	if body == target:
		target = null





func _on_body_entered(body: Node) -> void:
	print("_on_body_entered")
	if (body.is_in_group("projectile")):
		recieve_damage(100)
		body.queue_free()
	
	pass # Replace with function body.


#func _on_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	#print("_on_body_entered")
	#if (body.is_in_group("projectile")):
		#recieve_damage(100)
		#body.queue_free()
	#
	#pass # Replace with function body.
