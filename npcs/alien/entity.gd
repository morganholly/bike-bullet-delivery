extends RigidBody3D  # Or CharacterBody3D

class_name Entity

enum Entity_States {
	Disabled,
	Idle,
	Walk,
	Damaged,
	Shoot
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
	
	match current_state:
		Entity_States.Idle:
			if (!get_viewport().get_camera_3d()):
				return
			var cam_pos = get_viewport().get_camera_3d().global_position
			#var targetPos;
			var vector = global_position - cam_pos
			
			var direction = global_position.direction_to(cam_pos)
			var forward = get_global_transform().basis.z
			var left = get_global_transform().basis.x
			#print(direction)
			#print(forward.dot(direction))
			
			if (forward.dot(direction) < -0.6):
				sprite_3d.play("idle_front")
			elif (forward.dot(direction) > 0.6):
				sprite_3d.play("idle_back")
			else:
				if left.dot(direction) < 0: 
					sprite_3d.play("idle_right")
				else: 
					sprite_3d.play("idle_left")
			
			#print(direction)
			#targetPos = Vector3(cam_pos.x, global_position.y-(global_position.y-cam_pos.y)/3, cam_pos.z)
			
			pass
		
		Entity_States.Walk:
			sprite_3d.play("walk_front")
			pass
		Entity_States.Damaged:
			sprite_3d.play("damaged")
			pass
		Entity_States.Shoot:
			sprite_3d.play("shoot_front")
			pass
	pass
