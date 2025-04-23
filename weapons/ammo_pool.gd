extends Node

#var gun_stats = preload("res://weapons/gun_stats.gd")

@export var free_ammo: Dictionary[GunStats.BulletType, int]
@export var full_mags: Dictionary[GunStats.BulletType, int]

func reload(bullet_type: GunStats.BulletType, mag_size: int, mag_replace_time: float, mag_fill_time: float) -> Dictionary:
	var result: Dictionary
	if full_mags[bullet_type] > 0:
		full_mags[bullet_type] -= 1
		result["mag_count"] = mag_size
		result["reload_timer"] = mag_replace_time
	else:
		if free_ammo[bullet_type] > 0:
			result["mag_count"] = free_ammo[bullet_type]
			free_ammo[bullet_type] = max(0, free_ammo[bullet_type] - mag_size)
			result["reload_timer"] = mag_fill_time
		else:
			result["mag_count"] = 0
			result["reload_timer"] = 0.0
	return result

func load_mag(bullet_type: GunStats.BulletType, mag_size: int) -> int:
	var num_mags = floor(free_ammo[bullet_type] / mag_size)
	full_mags[bullet_type] += num_mags
	free_ammo[bullet_type] -= num_mags * mag_size
	return num_mags
