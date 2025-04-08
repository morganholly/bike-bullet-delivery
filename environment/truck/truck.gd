extends RigidBody3D

signal spawn_ammo

func _on_timer_timeout() -> void:
	emit_signal("spawn_ammo", self)
