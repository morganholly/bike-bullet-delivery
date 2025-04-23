extends Entity

class_name Civilian


#var gunsSprite = load("res://textures/Mockups/civwithgun.png")

func _ready() -> void:
	current_state = Entity_States.Disabled
	pass

func _on_body_entered(body: Node) -> void:
	#print("_on_body_entered")
	if (body.is_in_group("projectile")):
		recieve_damage(100)
		body.queue_free()
		#pass
	elif (body.is_in_group("pickable")):
		#print("_on_body_entered")$Sprite3D
		$Sprite3D.texture = load("res://textures/Mockups/civwithgun.png");
		get_tree().get_root().get_node("ScreenSpaceShader/CanvasLayer").recive_money(100) 
		body.queue_free()
		pass
	
	pass # Replace with function body.
