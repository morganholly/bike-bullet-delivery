extends Node


var alien_scene = load("res://npcs/Alien.tscn")

var ammo_scene = load("res://npcs/ammo_box.tscn")
var gun_scene = load("res://npcs/gun_pickable.tscn")

func spawn_enemy():
	var alien = alien_scene.instantiate()
	return alien

func spawn_ammo():
	var ammo = ammo_scene.instantiate()
	return ammo
	


func spawn_gun():
	var gun = gun_scene.instantiate()
	return gun
