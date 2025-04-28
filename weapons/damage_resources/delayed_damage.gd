extends BaseDamage
class_name DelayedDamage


@export var damage_res: BaseDamage
@export var wait_time: float = 1.0


func damage(calling_node: Node, health_manager: Node):
	var tween_timer = calling_node.get_tree().create_tween()
	tween_timer.bind_node(calling_node)
	tween_timer.tween_callback(damage_res.damage.bind(calling_node, health_manager)).set_delay(wait_time)
