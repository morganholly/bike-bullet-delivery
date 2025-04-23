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

@export var hp = 100
#@export var hp = 100


func recieve_damage(amount):
	hp -= amount;
	
	if (hp <= 0):
		queue_free()
	
	pass

func _process(delta: float) -> void:
	if (current_state == Entity_States.Disabled):
		return
	
	match current_state:
		Entity_States.Idle:
			$Sprite3D.play("idle_front")
			pass
		Entity_States.Walk:
			$Sprite3D.play("walk_front")
			pass
		Entity_States.Damaged:
			$Sprite3D.play("damaged")
			pass
		Entity_States.Shoot:
			$Sprite3D.play("shoot_front")
			pass
	pass
