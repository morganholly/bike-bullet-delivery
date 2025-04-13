extends RigidBody3D  # Or CharacterBody3D

class_name Entity

@export var speed = 5.0

@export var hp = 100
#@export var hp = 100


func recieve_damage(amount):
	hp -= amount;
	
	if (hp <= 0):
		queue_free()
	
	pass
