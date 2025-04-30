extends Entity

@onready var camera: Node3D = $"../Camera"
@onready var player_sprite: AnimatedSprite3D = $player_sprite


func _ready() -> void:
	
	current_state = Entity_States.Idle
	pass
	#sprite_3d = $AnimatedSprite3D
	

func _process(delta: float) -> void:
	player_sprite.disable_rotation_to_camera = not camera.third_person_select
	if camera.third_person_select:
		look_at(camera.global_position+$"..".velocity.normalized()*100)
