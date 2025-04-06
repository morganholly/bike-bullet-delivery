extends Resource
class_name GunStats

enum HitType {
	Hitscan
}
@export var hit_type: HitType = HitType.Hitscan
@export var bullet_speed: float = 1000
