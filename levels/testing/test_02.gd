extends Node3D


func _on_timer_timeout() -> void:
	var enemy = EntitySpawner.spawn_enemy()
	$Enemies.add_child(enemy)


func _on_truck_spawn_ammo(truck) -> void:
	var ammo = EntitySpawner.spawn_ammo()
	add_child(ammo)
	ammo.position = truck.position + Vector3(2,2,2)
