extends Node


@export_group("Health")
@export var max_health: float = 20
## regen per second
@export var health_regen: float = 1

@export_group("Armor")
## condition of physical armor, reduced from damage
@export var max_armor: float = 20
## regen per second
@export var armor_regen: float = 0
## curve of armor percent to chance of fully blocking damage without reducing armor condition
@export var armor_condition_block_rate: Curve

#@export_group("Energy Armor")
### energy level available for blocking damage
#@export var max_energy_armor: float = 0
### energy level overall
#@export var max_energy: float = 0
### energy overall feed rate into energy available for blocking damage
#@export var energy_armor_recharge: float = 0
### energy overall recharge rate
#@export var energy_recharge: float = 0


var current_health: float
var current_armor: float

var is_dead: bool = false
var death_callback: Callable
var damaged_callback: Callable

var block_curve_is_01: bool

func _ready() -> void:
	current_health = max_health
	current_armor = max_armor
	armor_condition_block_rate.bake()

func _process(delta: float) -> void:
	current_health += delta * health_regen
	current_armor += delta * armor_regen
	block_curve_is_01 = abs(armor_condition_block_rate.min_domain) < 0.001 and abs(armor_condition_block_rate.min_value) < 0.001 and abs(armor_condition_block_rate.max_domain - 1) < 0.001 and abs(armor_condition_block_rate.max_value - 1) < 0.001

func damage(amount: float) -> void:
	var chance: float
	if not block_curve_is_01:
		var block_curve_input = lerp(
			armor_condition_block_rate.min_domain,
			armor_condition_block_rate.max_domain,
			current_armor / max_armor)
		chance = armor_condition_block_rate.sample_baked(block_curve_input)
		chance -= armor_condition_block_rate.min_value
		chance /= armor_condition_block_rate.max_value - armor_condition_block_rate.min_value
	else:
		chance = armor_condition_block_rate.sample_baked(current_armor / max_armor)
	if randf() > chance:
		# do damage
		if current_armor >= amount:
			current_armor -= amount
		else:
			var remaining = amount - current_armor
			current_armor = 0
			current_health -= remaining
			if current_health <= 0:
				is_dead = true
				if death_callback != null:
					death_callback.call()
		if damaged_callback != null:
			damaged_callback.call()
