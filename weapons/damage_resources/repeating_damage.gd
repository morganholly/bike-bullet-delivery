extends BaseDamage
class_name RepeatingDamage


@export var damage_res: BaseDamage
@export var times: int = 1
@export var forever: bool = false
@export var time: float = 1.0
enum TimeMode {
	Interval,
	Hertz
}
@export var time_mode: TimeMode = TimeMode.Interval


func damage(calling_node: Node, health_manager: Node):
	var tween_timer = calling_node.get_tree().create_tween()
	tween_timer.bind_node(calling_node)
	var loop_times = max(1, times)
	if forever:
		loop_times = 0
	tween_timer.set_loops(loop_times)
	tween_timer.tween_callback(damage_res.damage.bind(calling_node, health_manager)).set_delay(1)
