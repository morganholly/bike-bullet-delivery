extends Node3D


func _on_timer_timeout() -> void:
	var enemy = EntitySpawner.spawn_enemy()
	$Enemies.add_child(enemy)


func _on_truck_spawn_ammo(truck) -> void:
	var ammo = EntitySpawner.spawn_ammo()
	add_child(ammo)
	ammo.position = truck.position + Vector3(2,2,2)
	
	

func _on_truck_spawn_gun(truck) -> void:
	var gun = EntitySpawner.spawn_gun()
	add_child(gun)
	gun.position = truck.position + Vector3(2,2,2)
	pass # Replace with function body.


func _on_red_truck_spawn_gun(truck) -> void:
	_on_truck_spawn_gun(truck)
	pass # Replace with function body.


func _on_blue_truck_spawn_ammo(truck) -> void:
	_on_truck_spawn_ammo(truck)
	pass # Replace with function body.
