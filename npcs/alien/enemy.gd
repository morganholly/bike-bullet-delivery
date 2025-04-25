extends Entity


class_name Enemy

var target = null
var follow_strength = 15

var shoot_range = 15
var too_close_range = 8

@export var stun_delay : float = 0.2
@export var shoot_delay : float = 0.3

var cur_stun_delay = 0
var cur_shoot_delay = 0

@onready var uniform_health: Node = $UniformHealth

func damaged_set_state():
	print("ow!")
	current_state = Entity_States.Damaged

func death_set_state():
	print("aughh")
	queue_free()

func _ready():
	#$Area3D.connect("body_entered", self._on_Area3D_body_entered)
	#$Area3D.connect("body_exited", self._on_Area3D_body_exited)
	$Area3D.collision_mask = $Area3D.collision_mask | 2
	current_state = Entity_States.Idle
	uniform_health.damaged_callback = damaged_set_state
	uniform_health.death_callback = death_set_state

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
		if (global_transform.origin.distance_to(target_position) > shoot_range):
			
			apply_central_force(direction * follow_strength)
			current_state = Entity_States.Walk
		elif (global_transform.origin.distance_to(target_position) < too_close_range):
			#var direction = (target_position - global_transform.origin).normalized()
			apply_central_force(-direction * follow_strength)
			current_state = Entity_States.Walk
		else:
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
		current_state = Entity_States.Damaged 
		cur_stun_delay = stun_delay
	pass # Replace with function body.


#func _on_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	#print("_on_body_entered")
	#if (body.is_in_group("projectile")):
		#recieve_damage(100)
		#body.queue_free()
	#
	#pass # Replace with function body.
