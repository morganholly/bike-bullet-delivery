extends Node

#@export var gun_mesh: PackedScene
@export var gun_stats: GunStats

@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var red_arrow: MeshInstance3D = $red_arrow

#@export_range(0, 1, 0.05) var mag_fill_percent: float = 0.5
@export var mag_rand_fill_min: int = 0
@export var mag_rand_fill_max: int = 10
var bullets_in_mag: int = 0
@export var extra_mag_rand_min: int = 0
@export var extra_mag_rand_max: int = 2
var extra_mags: int = 0
var reload_timer: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#var instance = gun_mesh.instantiate()
	#add_child(instance)
	ray_cast_3d.enabled = gun_stats.hit_type == GunStats.HitType.Hitscan
	#bullets_in_mag = round(mag_fill_percent * gun_stats.mag_capacity)
	bullets_in_mag = randi_range(mag_rand_fill_min, min(mag_rand_fill_max, gun_stats.mag_capacity))
	extra_mags = randi_range(extra_mag_rand_min, extra_mag_rand_max)
	ray_cast_3d.add_exception(self.get_parent())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if ray_cast_3d.is_colliding():
		if ray_cast_3d.get_collider() and ray_cast_3d.get_collider().get_collision_layer() & 0b00000100 > 0:
			aim_show_entity(ray_cast_3d.get_collider())
		else:
			red_arrow.hide()
	reload_timer -= delta
	reload_timer = max(0, reload_timer)

func stash_extra_mags(ammo_pool: Node) -> void:
	ammo_pool.full_mags[gun_stats.bullet_id] += extra_mags
	extra_mags = 0

## returns if entering reload time
func shoot(ammo_pool: Node, shots: int = 1) -> bool:
	#print("shoot", gun_stats.hit_type)
	match gun_stats.hit_type:
		GunStats.HitType.Hitscan:
			#print("is hitscan gun")
			if ray_cast_3d.is_colliding():
				print("hit!")
				if ray_cast_3d.get_collider().get_collision_layer() & 0b01000100 > 0:
					#print("has right coll mask")
					if ray_cast_3d.get_collider().is_in_group(&"Damageable"):
						#print("is damageable")
						var parent_object = ray_cast_3d.get_collider()
						var health_manager: Node
						for child in parent_object.get_children():
							if child.is_in_group(&"HealthManager"):
								health_manager = child
								break
						if not gun_stats.infinite_ammo:
							var can_shoot = min(shots, bullets_in_mag)
							if can_shoot > 0 and reload_timer <= 0:
								bullets_in_mag -= can_shoot
								#health_manager.damage(gun_stats.shot_damage * can_shoot)
								gun_stats.shot_damage.damage(parent_object, health_manager)
								print("bang, bullets left: ", bullets_in_mag)
								if bullets_in_mag > 0:
									return false
								else:
									var reload_result: Dictionary = ammo_pool.reload(gun_stats.bullet_id, gun_stats.mag_capacity, gun_stats.reload_time, gun_stats.partial_refill_time)
									bullets_in_mag = reload_result.mag_count
									reload_timer = reload_result.reload_time
									print("reloading, bullets left: ", bullets_in_mag)
									return true
							elif reload_timer <= 0:
								var reload_result: Dictionary = ammo_pool.reload(gun_stats.bullet_id, gun_stats.mag_capacity, gun_stats.reload_time, gun_stats.partial_refill_time)
								bullets_in_mag = reload_result.mag_count
								reload_timer = reload_result.reload_time
								print("reloading, bullets left: ", bullets_in_mag)
								return true
							else:
								print("wait for reload timer, time: ", reload_timer)
								return true
						else:
							#health_manager.damage(gun_stats.shot_damage * shots)
							gun_stats.shot_damage.damage(parent_object, health_manager)
							return false
				# could add else here to spawn bullet hole decal
			else:
				print("missed!")
				if not gun_stats.infinite_ammo:
					var can_shoot = min(shots, bullets_in_mag)
					if can_shoot > 0 and reload_timer <= 0:
						bullets_in_mag -= can_shoot
						print("bang, bullets left: ", bullets_in_mag)
						if bullets_in_mag > 0:
							return false
						else:
							var reload_result: Dictionary = ammo_pool.reload(gun_stats.bullet_id, gun_stats.mag_capacity, gun_stats.reload_time, gun_stats.partial_refill_time)
							bullets_in_mag = reload_result.mag_count
							reload_timer = reload_result.reload_time
							print("reloading, bullets left: ", bullets_in_mag)
							return true
					elif reload_timer <= 0:
						var reload_result: Dictionary = ammo_pool.reload(gun_stats.bullet_id, gun_stats.mag_capacity, gun_stats.reload_time, gun_stats.partial_refill_time)
						bullets_in_mag = reload_result.mag_count
						reload_timer = reload_result.reload_time
						print("reloading, bullets left: ", bullets_in_mag)
						return true
					else:
						print("wait for reload timer, time: ", reload_timer)
						return true
	return false


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
	#self.global_basis = self.global_basis.looking_at(pos, Vector3.UP, false)


# make equipped gun hold mode like the normal hold item mode
# but maybe a bit stiffer and also spring lock rotation
