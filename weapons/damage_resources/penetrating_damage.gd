extends BaseDamage
class_name PenetratingDamage


@export var health_damage: float = 10
@export var armor_damage: float = 10


func damage(calling_node: Node, health_manager: Node):
	health_manager.damage_penetrating(health_damage, armor_damage)
