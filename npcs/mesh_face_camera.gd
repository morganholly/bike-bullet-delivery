extends MeshInstance3D


func _process(delta: float) -> void:
	var cam_pos = get_viewport().get_camera_3d().global_transform.origin
	self.global_basis = self.global_basis.looking_at(cam_pos)
