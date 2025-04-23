extends Resource
class_name GunStats

enum HitType {
	Hitscan,
	Projectile
}
@export var hit_type: HitType = HitType.Hitscan

@export var bullets_per_second: float =  1
@export var pellets_per_shot: int = 1
@export var bullet_damage: float =  1


@export var bullet_speed: float = 1000
@export var bullet_size: float =  1
