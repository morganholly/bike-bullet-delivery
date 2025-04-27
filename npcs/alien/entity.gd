extends RigidBody3D  # Or CharacterBody3D

class_name Entity

enum Entity_States {
	Disabled,
	Idle,
	Walk,
	Damaged,
	Death,
	Shoot
}

var AnimationDict = {
	Entity_States.Idle : [
		"idle_front",
		"idle_back",
		"idle_right",
		"idle_left",
		],
	Entity_States.Damaged : "damaged",
	Entity_States.Walk : "walk_front",
	Entity_States.Shoot : "shoot_front",
}

var current_state = Entity_States.Walk

@export var speed = 5.0

@onready var sprite_3d: AnimatedSprite3D = $Sprite3D

#@export var hp = 100
##@export var hp = 100
#
#
#func recieve_damage(amount):
	#hp -= amount;
	#
	#if (hp <= 0):
		#queue_free()
	#
	#pass

func _process(delta: float) -> void:
	if (current_state == Entity_States.Disabled):
		return
	
	if (AnimationDict[current_state] is String):
		sprite_3d.play(AnimationDict[current_state])
	elif (AnimationDict[current_state] is Array):
		if (AnimationDict[current_state].size() == 2):
			PlayAnimationTwoSides(AnimationDict[current_state])
		elif (AnimationDict[current_state].size() == 4):
			PlayAnimationFourSides(AnimationDict[current_state])
	
	return;


func PlayAnimationTwoSides(list):
	if (!get_viewport().get_camera_3d()):
		return
	var cam_pos = get_viewport().get_camera_3d().global_position
	#var targetPos;
	var vector = global_position - cam_pos
	
	var direction = global_position.direction_to(cam_pos)
	var forward = get_global_transform().basis.z
	var left = get_global_transform().basis.x
	
	if (forward.dot(direction) < 0):
		sprite_3d.play(list[0])
	elif (forward.dot(direction) > 0):
		sprite_3d.play(list[1])


func PlayAnimationFourSides(list):
	if (!get_viewport().get_camera_3d()):
		return
	var cam_pos = get_viewport().get_camera_3d().global_position
	#var targetPos;
	var vector = global_position - cam_pos
	
	var direction = global_position.direction_to(cam_pos)
	var forward = get_global_transform().basis.z
	var left = get_global_transform().basis.x
	
	if (forward.dot(direction) < -0.6):
		sprite_3d.play(list[0])
	elif (forward.dot(direction) > 0.6):
		sprite_3d.play(list[1])
	else:
		if left.dot(direction) < 0: 
			sprite_3d.play(list[2])
		else: 
			sprite_3d.play(list[3])
			
			
