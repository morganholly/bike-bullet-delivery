extends Node

#@export var gun_mesh: PackedScene
@export var gun_stats: GunStats

@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var red_arrow: MeshInstance3D = $red_arrow

@export_range(0, 1, 0.05) var mag_fill_percent: float = 0.5
var mag_count: int = 0
var reload_timer: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#var instance = gun_mesh.instantiate()
	#add_child(instance)
	ray_cast_3d.enabled = gun_stats.hit_type == GunStats.HitType.Hitscan
	mag_count = round(mag_fill_percent * gun_stats.mag_capacity)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if ray_cast_3d.is_colliding():
		if ray_cast_3d.get_collider().get_collision_layer() & 0b00000100 > 0:
			aim_show_entity(ray_cast_3d.get_collider())
		else:
			red_arrow.hide()
	reload_timer -= delta
	reload_timer = max(0, reload_timer)

func shoot(ammo_pool: Node) -> void:
	match gun_stats.hit_type:
		[GunStats.HitType.Hitscan]:
			if ray_cast_3d.is_colliding():
				if ray_cast_3d.get_collider().get_collision_layer() & 0b01000100 > 0:
					if ray_cast_3d.get_collider().is_in_group(&"Damageable"):
						var parent_object = ray_cast_3d.get_collider()
						var health_manager: Node
						for child in parent_object.get_children() :
							if child.is_in_group(&"HealthManager") :
								health_manager = child
								break
						if not gun_stats.infinite_ammo:
							if mag_count > 0 and reload_timer <= 0:
								mag_count -= 1
								health_manager.damage(gun_stats.shot_damage)
							else:
								var reload_result: Dictionary = ammo_pool.reload(gun_stats.bullet_id, gun_stats.mag_capacity, gun_stats.reload_time, gun_stats.partial_refill_time)
								mag_count = reload_result.mag_count
								reload_timer = reload_result.reload_timer
						else:
							health_manager.damage(gun_stats.shot_damage)
				# could add else here to spawn bullet hole decal


func aim_show_entity(over: Node3D, up: float = 2) -> void:
	var pos: Vector3 = over.global_position + Vector3(0, up, 0)
	for child in over.get_children():
		if child.name == &"aim_show_point" :
			pos = child.global_position
			break
	red_arrow.global_position = pos
	red_arrow.show()


#func looking_at(pos: Vector3) -> void:
	##TODO add tween using quaternion blending
	#self.global_basis = self.global_basis.looking_at(pos, Vector3.UP, true)


# make equipped gun hold mode like the normal hold item mode
# but maybe a bit stiffer and also spring lock rotation
