extends Node


var demon_scene = load("res://npcs/demon.tscn")
var ammo_scene = load("res://npcs/ammo_box.tscn")
var gun_scene = load("res://npcs/gun_pickable.tscn")

func spawn_enemy():
	var demon = demon_scene.instantiate()
	return demon

func spawn_ammo():
	var ammo = ammo_scene.instantiate()
	return ammo
	


func spawn_gun():
	var gun = gun_scene.instantiate()
	return gun
