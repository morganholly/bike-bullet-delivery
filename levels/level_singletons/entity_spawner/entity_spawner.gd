extends Node


var demon_scene = load("res://npcs/demon.tscn")
var ammo_scene = load("res://npcs/ammo_box.tscn")

func spawn_enemy():
	var demon = demon_scene.instantiate()
	return demon

func spawn_ammo():
	var ammo = ammo_scene.instantiate()
	return ammo
