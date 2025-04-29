extends Node

@export var damage: BaseDamage
@export var damage_timeout: float = 1:
	set(value):
		damage_timeout = value
		dmg_timeout_usec = value * 1e6
var dmg_timeout_usec = 1

var collision_times: Dictionary[int, float]

enum CollCheckMode {
	RigidContactMonitor,
	#AreaNodePath,
	#AreaChildExpandedColliders
}
@export var collision_checking: CollCheckMode = CollCheckMode.RigidContactMonitor
var collision_callback: Callable


func _ready() -> void:
	print("ready")
	dmg_timeout_usec = damage_timeout * 1e6
	match collision_checking:
		CollCheckMode.RigidContactMonitor:
			self.get_parent().connect("body_entered", self._on_body_entered)
			self.get_parent().connect("body_exited", self._on_body_exited)
			self.get_parent().contact_monitor = true
			self.get_parent().max_contacts_reported = max(1, self.get_parent().max_contacts_reported)

func _on_body_entered(body: Node3D):
	print("contact")
	if body.is_in_group("Damageable"):
		print("damageable")
		var current_time_usec = Time.get_ticks_usec()
		if collision_times.get_or_add(body.get_instance_id(), current_time_usec - dmg_timeout_usec * 2) >= current_time_usec - dmg_timeout_usec:
			return
		print("damage timer up")
		var health_manager: Node
		var found_hm = false
		for child in body.get_children():
			if child.is_in_group(&"HealthManager"):
				health_manager = child
				found_hm = true
				break
		#if found_hm:
		damage.damage(body, health_manager)
		collision_times[body.get_instance_id()] = current_time_usec
	
	if collision_callback != null and collision_callback.is_valid():
		collision_callback.call(body)

func _on_body_exited(body: Node3D):
	if collision_times.has(body.get_instance_id()):
		if collision_times[body.get_instance_id()] < Time.get_ticks_usec() - dmg_timeout_usec * 2:
			collision_times.erase(body.get_instance_id())
