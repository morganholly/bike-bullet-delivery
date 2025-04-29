extends Entity


class_name Enemy


var target = null
var follow_strength = 15

#@export var come : bool = 

@export var projectile_prefab : PackedScene = preload("res://npcs/alien/AlienProjectile.tscn")

@export var shoot_range : float = 15
@export var retreat_range : float = 10
@export var melee_range : float = 8
@export var melee_animation_range : float = 3

@export var stun_delay : float = 0.3
@export var shoot_delay : float = 0.3

var cur_stun_delay = 0
var cur_shoot_delay = 0

@onready var uniform_health: Node = $UniformHealth

func damaged_set_state():
	print("ow!")
	current_state = Entity_States.Damaged 
	cur_stun_delay = stun_delay
	if target == null:
		target = get_tree().get_nodes_in_group("Player")[0]
	

func death_set_state():
	print("aughh")
	current_state = Entity_States.Death 
	cur_stun_delay = 1000
	await get_tree().create_timer(0.75).timeout
	queue_free()

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
	Entity_States.Damaged : "damaged",
	Entity_States.Walk : "walk_front",
	Entity_States.Shoot : "shoot_front",
	Entity_States.Death : "death",
}

func _physics_process(delta):
	
	if (cur_stun_delay > 0):
		cur_stun_delay -= delta;
		return;
	
	if target:
		# Target exists, move toward it
		
		var target_position = target.global_transform.origin
		
		var direction = (target_position - global_transform.origin).normalized()
		look_at(target_position)
		
		#print(global_transform.origin.distance_to(target_position))
		if (
			global_transform.origin.distance_to(target_position) > shoot_range || 
			global_transform.origin.distance_to(target_position) < melee_range):
			
			apply_central_force(direction * follow_strength)
			current_state = Entity_States.Walk
		elif (global_transform.origin.distance_to(target_position) < retreat_range):
			#var direction = (target_position - global_transform.origin).normalized()
			apply_central_force(-direction * follow_strength)
			current_state = Entity_States.Walk
		else:
			if cur_shoot_delay > 0:
				cur_shoot_delay -= delta;
				current_state = Entity_States.Shoot
				if cur_shoot_delay <= 0:
					cur_shoot_delay = shoot_delay
					shoot(direction)
			else:
				cur_shoot_delay = shoot_delay
				current_state = Entity_States.Shoot
		
		if global_transform.origin.distance_to(target_position) < melee_animation_range:
			current_state = Entity_States.Shoot
	else:
		current_state = Entity_States.Idle
		
	


func _on_Area3D_body_entered(body):
	if body.is_in_group("Player") and target == null:
		print("Player detected!")
		target = body

func _on_Area3D_body_exited(body):
	if body == target:
		target = null


func _on_body_entered(body: Node) -> void:
	print("_on_body_entered")
	if (body.is_in_group("projectile")):
		#recieve_damage(100)
		uniform_health.damage(100)
		body.queue_free()
	pass # Replace with function body.


func shoot(direction):
	var clone = projectile_prefab.instantiate()
	clone.position = self.position
	add_sibling(clone)
	clone.global_position += direction * 2 + Vector3(0, 1.7, 0) 
	clone.apply_central_force(direction * 1000)
	pass

#func _on_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	#print("_on_body_entered")
	#if (body.is_in_group("projectile")):
		#recieve_damage(100)
		#body.queue_free()
	#
	#pass # Replace with function body.
