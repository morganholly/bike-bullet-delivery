extends Node3D

class_name Mothership

@export var projectile_prefab : PackedScene = preload("res://npcs/alien/AlienProjectile.tscn")
var target1
var twistcw=true
var countdown=5
var xpos

func _ready():
	hide()
	xpos=$gun_target.position.x
	pass

func startshooting():
	print("startshooting")
	$Timer.start()
	pass

func uncloak():
	show()
	startshooting()
	pass

func shoot(direction,zoffset):
	var bullet = projectile_prefab.instantiate()
	add_sibling(bullet)
	bullet.transform = $gun.global_transform
	bullet.position.z+=zoffset
	#bullet.global_position += direction * 2 
	bullet.apply_central_force(-direction * 1000)
	pass

func _on_timer_timeout() -> void:
	$gun.look_at($gun_target.global_position)
	shoot($gun.global_transform.basis.z,-3)
	$gun_target.position.x += randi_range(-3,3)
	$gun_target.position.z += randi_range(-3,3)
	shoot($gun.global_transform.basis.z,3)
	$gun_target.position.x = xpos+randi_range(-3,3)
	countdown+= -1
	if twistcw == true:
		$gun_target.position.z+=5
		if countdown<0:
			twistcw=false
	else:
		$gun_target.position.z+=-5
		if countdown<0:
			twistcw=true
	if countdown<0:
		countdown=10
	pass # Replace with function body.
