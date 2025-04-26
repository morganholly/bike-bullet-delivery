extends Resource
class_name GunStats

enum HitType {
	Hitscan
	# i'd like to add an area mode that takes into account travel time, but not needed for the jam
}
@export var hit_type: HitType = HitType.Hitscan
@export var bullet_speed: float = 350
enum BulletType {
	_9MM,
	_223_556,
	_22LR,
	_12Gauge,
	_308_762x51,
	_556x45
}
@export var bullet_id: BulletType = BulletType._9MM
@export var shot_damage: BaseDamage
@export var infinite_ammo: bool = false
@export var mag_capacity: int = 11
@export var reload_time: float = 3
@export var partial_refill_time: float = 10
@export var can_auto_fire: bool = false
@export var shots_per_second: float = 10
