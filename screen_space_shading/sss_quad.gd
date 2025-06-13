extends MeshInstance3D


func _ready() -> void:
	if not OS.has_feature("web"):
		self.show()
	#self.show()
	pass
