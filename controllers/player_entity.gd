extends Entity



func _ready() -> void:
	
	current_state = Entity_States.Idle
	pass
	#sprite_3d = $AnimatedSprite3D
	

func _process(delta: float) -> void:
	look_at($"..".global_position+$"..".velocity.normalized()*100)
