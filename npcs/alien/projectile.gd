extends RigidBody3D



func _ready() -> void:
	$CollisionDamage.collision_callback =  destroy_projectile

func destroy_projectile(body):
	if !body.is_in_group("projectile"):
		queue_free()
	pass
