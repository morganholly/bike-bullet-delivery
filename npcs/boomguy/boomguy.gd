extends Enemy
@onready var gun_sound: AudioStreamPlayer3D = $"gun sound"

var targets = []
var shooting: bool = false
var started_shooting: bool = false

func _ready():
	#$Area3D.connect("body_entered", self._on_Area3D_body_entered)
	#$Area3D.connect("body_exited", self._on_Area3D_body_exited)
	$Area3D.collision_mask = $Area3D.collision_mask | 2
	current_state = Entity_States.Idle
	uniform_health.damaged_callback = damaged_set_state
	uniform_health.death_callback = death_set_state
	AnimationDict = {
	Entity_States.Idle : [
		"idle_front",
		"idle_back",
		"idle_right",
		"idle_left",
		],
	Entity_States.Shoot : [
		"shoot_front",
		"shoot_back",
		"shoot_right",
		"shoot_left",
	],
}


func _physics_process(delta):
	#print(target)
	if targets.size() > 0:
		if not shooting:
			started_shooting = true
			shooting = true
		target = targets[0]
		var target_position = target.global_transform.origin
		var direction = (target_position - global_transform.origin).normalized()
		look_at(target_position)
		print("BOOMGUY SEES ENEMIES")
		if started_shooting:
			gun_sound.stream.loop_begin = 98400
			gun_sound.stream.loop_end = 208320
			gun_sound.stream.loop_mode = 1
			gun_sound.play(98400/48000)
			started_shooting = false
		current_state = Entity_States.Shoot
		
		if cur_shoot_delay > 0:
			cur_shoot_delay -= delta;
			current_state = Entity_States.Shoot
			if cur_shoot_delay <= 0:
				cur_shoot_delay = shoot_delay
				shoot(direction)
		else:
			cur_shoot_delay = shoot_delay
			current_state = Entity_States.Shoot
	else:
		shooting = false
		gun_sound.stream.loop_mode = 0
		current_state = Entity_States.Idle
		
		


func _on_Area3D_body_entered(body):
	if body.is_in_group("enemies_targetable_by_boomguy"):
		print("Enemy detected!")
		targets.append(body)

func _on_Area3D_body_exited(body):
	if targets.count(body) > 0:
		targets.erase(body)
		#target = null


func shoot(direction):
	var clone = projectile_prefab.instantiate()
	clone.position = self.position
	add_sibling(clone)
	clone.global_position += direction * 2 + Vector3(0, 1.7, 0) 
	clone.apply_central_force(direction * 1000)
	pass
