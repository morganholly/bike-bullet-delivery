extends RigidBody3D

@export var gun_mesh: PackedScene
@export var gun_stats: GunStats

@onready var ray_cast_3d: RayCast3D = $RayCast3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var instance = gun_mesh.instantiate()
	add_child(instance)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func shoot(from: Vector3, to: Vector3, ammo_pool: Node) -> void:
	if ray_cast_3d.is_colliding():
		if ray_cast_3d.get_collider().is_in_group(&"Damageable"):
			var parent_object = ray_cast_3d.get_collider()
			var health_manager: Node
			for child in parent_object.get_children() :
				if child.is_in_group(&"HealthManager") :
					health_manager = child
					break
			if not gun_stats.infinite_ammo:
				if ammo_pool.ammo_dict[gun_stats.bullet_id] > 0:
					ammo_pool.ammo_dict[gun_stats.bullet_id] -= 1
					health_manager.damage(gun_stats.shot_damage)
			else:
				health_manager.damage(gun_stats.shot_damage)
