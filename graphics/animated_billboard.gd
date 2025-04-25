extends AnimatedSprite3D

#$"."
var disable_rotation_to_camera = false;
@export var designated_parent: Node;


var added_pos;

func _ready() -> void:
	if (designated_parent != null):
		added_pos = global_position

func _physics_process(delta: float) -> void:
	if (designated_parent != null):
		global_position = designated_parent.global_position + added_pos
	
	if (!get_viewport().get_camera_3d()):
		return
	var cam_pos = get_viewport().get_camera_3d().global_position
	var targetPos;
	targetPos = Vector3(cam_pos.x, global_position.y-(global_position.y-cam_pos.y)/3, cam_pos.z)
	#if (global_position.y+1 < cam_pos.y):
		#targetPos = Vector3(cam_pos.x, cam_pos.y/2, cam_pos.z)
	#else:
		#targetPos = Vector3(cam_pos.x, cam_pos.y, cam_pos.z)
	if !(disable_rotation_to_camera):
		look_at(targetPos)
