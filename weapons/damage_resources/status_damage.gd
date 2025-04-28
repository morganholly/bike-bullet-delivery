extends BaseDamage
class_name StatusDamage


@export var damage_start: BaseDamage
@export var damage_timer: BaseDamage
@export var damage_end: BaseDamage
@export var status_name: String
enum ReapplyMode {
	Reset,
	Extend
}
@export var reapply_mode: ReapplyMode = ReapplyMode.Extend
@export var damage_timer_time: float = 1.0
enum TimeMode {
	Interval,
	Hertz
}
@export var time_mode: TimeMode = TimeMode.Interval
## update effect check timer if this is too unreliable
@export var effect_timeout: float = 1:
	set(value):
		effect_timeout = value
		effect_timeout_usec = value * 1e6
var effect_timeout_usec = 1

var time_applied_usec: float

var tween_timer: Tween

var called_node: Node

func damage(calling_node: Node, health_manager: Node):
	if not health_manager.status_effects.has(status_name):
		health_manager.status_effects[status_name] = self.duplicate()
		health_manager.status_effects[status_name].called_node = calling_node
		health_manager.status_effects[status_name].tween_timer = calling_node.get_tree().create_tween()
		health_manager.status_effects[status_name].tween_timer.bind_node(health_manager.status_effects[status_name].called_node)
		health_manager.status_effects[status_name].tween_timer.set_loops(0)
		var wait_time = damage_timer_time
		if time_mode == TimeMode.Hertz:
			wait_time = 1 / damage_timer_time
		damage_start.damage(calling_node, health_manager)
		health_manager.status_effects[status_name].time_applied_usec = Time.get_ticks_usec()
		health_manager.status_effects[status_name].tween_timer.tween_callback(damage_timer.damage.bind(health_manager.status_effects[status_name].called_node, health_manager)).set_delay(wait_time)
		health_manager.status_effect_check_timer.paused = false
	else:
		#print("already has effect")
		match reapply_mode:
			ReapplyMode.Reset:
				health_manager.status_effects.erase(status_name)
				damage(calling_node, health_manager)
			ReapplyMode.Extend:
				health_manager.status_effects[status_name].time_applied_usec = Time.get_ticks_usec()

func end_effect(health_manager: Node):
	health_manager.status_effects[status_name].tween_timer.stop()
	damage_end.damage(health_manager.status_effects[status_name].called_node, health_manager)
