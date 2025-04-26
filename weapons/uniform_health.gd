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
## curve of armor percent to chance of letting thru some percent of damage
@export var armor_condition_pass_scale: Curve

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
var hit_callback: Callable

var block_curve_is_01: bool
var pass_curve_is_01: bool

func _ready() -> void:
	current_health = max_health
	current_armor = max_armor
	if armor_condition_block_rate != null:
		armor_condition_block_rate.bake()
		block_curve_is_01 = abs(armor_condition_block_rate.min_domain) < 0.001 and abs(armor_condition_block_rate.min_value) < 0.001 and abs(armor_condition_block_rate.max_domain - 1) < 0.001 and abs(armor_condition_block_rate.max_value - 1) < 0.001
	if armor_condition_pass_scale != null:
		armor_condition_pass_scale.bake()
		pass_curve_is_01 = abs(armor_condition_pass_scale.min_domain) < 0.001 and abs(armor_condition_pass_scale.min_value) < 0.001 and abs(armor_condition_pass_scale.max_domain - 1) < 0.001 and abs(armor_condition_pass_scale.max_value - 1) < 0.001

func _process(delta: float) -> void:
	if not is_dead:
		current_health = min(current_health + delta * health_regen, max_health)
		current_armor = min(current_armor + delta * armor_regen, max_armor)

func get_block_chance(armor_percent: float) -> float:
	var chance: float
	if armor_condition_block_rate != null:
		if not block_curve_is_01:
			var block_curve_input = lerp(
				armor_condition_block_rate.min_domain,
				armor_condition_block_rate.max_domain,
				armor_percent)
			chance = armor_condition_block_rate.sample_baked(block_curve_input)
			chance -= armor_condition_block_rate.min_value
			chance /= armor_condition_block_rate.max_value - armor_condition_block_rate.min_value
		else:
			chance = armor_condition_block_rate.sample_baked(armor_percent)
	return chance

func get_pass_scale(armor_percent: float) -> float:
	var scale: float
	if armor_condition_pass_scale != null:
		if not pass_curve_is_01:
			var pass_curve_input = lerp(
				armor_condition_pass_scale.min_domain,
				armor_condition_pass_scale.max_domain,
				armor_percent)
			scale = armor_condition_pass_scale.sample_baked(pass_curve_input)
			scale -= armor_condition_pass_scale.min_value
			scale /= armor_condition_pass_scale.max_value - armor_condition_pass_scale.min_value
		else:
			scale = armor_condition_pass_scale.sample_baked(armor_percent)
	return scale

func damage(amount: float) -> void:
	var chance: float = get_block_chance(current_armor / max_armor)
	if randf() >= chance:
		#print("hitting")
		# do damage
		var did_health_damage: bool = false
		if current_armor >= amount:
			#print("armor block")
			var pass_scale = get_pass_scale(current_armor / max_armor)
			current_armor = max(0, current_armor - amount)
			current_health = max(0, current_health - pass_scale * amount)
			if pass_scale * amount > 0:
				did_health_damage = true
		else:
			#print("insufficient armor")
			did_health_damage = true
			var pass_scale = get_pass_scale(current_armor / max_armor)
			var remaining = amount - current_armor
			current_armor = 0
			current_health = max(0, current_health - remaining - pass_scale * amount)
			#print(current_health)
		if hit_callback != null and hit_callback.is_valid():
			hit_callback.call()
		if did_health_damage:
			if damaged_callback != null and damaged_callback.is_valid():
				damaged_callback.call()
		if current_health <= 0:
			is_dead = true
			if death_callback != null and death_callback.is_valid():
				death_callback.call()

func damage_penetrate(amount: float, damage_health: bool = true, damage_armor: bool = true) -> void:
	if damage_health or damage_armor:
		if damage_armor:
			current_armor = max(0, current_armor - amount)
		if damage_health:
			current_health = max(0, current_health - amount)
		
		if hit_callback != null and hit_callback.is_valid():
			hit_callback.call()
		if damage_health:
			if damaged_callback != null and damaged_callback.is_valid():
				damaged_callback.call()
		if current_health <= 0:
			is_dead = true
			if death_callback != null and death_callback.is_valid():
				death_callback.call()
