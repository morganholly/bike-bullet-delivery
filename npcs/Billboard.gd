extends Sprite3D

#$"."


func _physics_process(delta: float) -> void:
	var cam_pos = get_viewport().get_camera_3d().global_position
	var targetPos;
	targetPos = Vector3(cam_pos.x, global_position.y-(global_position.y-cam_pos.y)/3, cam_pos.z)
	#if (global_position.y+1 < cam_pos.y):
		#targetPos = Vector3(cam_pos.x, cam_pos.y/2, cam_pos.z)
	#else:
		#targetPos = Vector3(cam_pos.x, cam_pos.y, cam_pos.z)
	look_at(targetPos)
