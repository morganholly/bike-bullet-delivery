extends BaseDamage
class_name NormalDamage


@export var normal_damage: float = 10


func damage(calling_node: Node, health_manager: Node):
	health_manager.damage(normal_damage)
