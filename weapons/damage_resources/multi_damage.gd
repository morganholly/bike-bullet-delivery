extends BaseDamage
class_name MultiDamage


@export var damages: Array[BaseDamage]
enum MultiDamageMode {
	Sequential,
	#Cycle, needs to save state somewhere for this
	Random,
}
@export var mode: MultiDamageMode


func damage(calling_node: Node, health_manager: Node):
	match mode:
		MultiDamageMode.Sequential:
			for i in range(0, len(damages)):
				damages[i].damage(calling_node, health_manager)
		MultiDamageMode.Random:
			damages[health_manager.randi_range_wrapper(0, len(damages) - 1)].damage(calling_node, health_manager)
