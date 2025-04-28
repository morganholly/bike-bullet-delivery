extends Node3D


var redo_weights: bool = true
@export_range(1, 10, 0.01) var step_strength: float = 1:
	set(value):
		step_strength = value
		redo_weights = true
@export_range(1, 4, 0.01) var strength_variance: float = 1:
	set(value):
		strength_variance = value
		redo_weights = true


var step_timeout_usec:float = 1
var last_step_time_usec: float = 0

@export var time: float = 1.0:
	set(value):
		time = value
		
		var wait_time = time
		if time_mode == TimeMode.Hertz:
			wait_time = 1 / time
		#step_timeout_usec = wait_time * 1e6
		#if timer:
			#timer.wait_time = wait_time
			#if is_walking:
				#timer.start()
enum TimeMode {
	Interval,
	Hertz
}
@export var time_mode: TimeMode = TimeMode.Hertz

var randomize_time: bool = false
## generates a random value in this to negative this. if positive, multiplies by 1 + that, if negative, divides by 1 + that
@export_range(0, 4, 0.01) var time_jitter: float = 0:
	set(value):
		time_jitter = value
		randomize_time = value > 0.001

@export var is_walking: bool = false#:
	#set(value):
		#is_walking = value
		#if value and timer:
			#timer.start()

@export var always_update_weights: bool = false

#@onready var timer: Timer = $Timer

@onready var play_now_second_timer: Timer = $PlayNowSecondTimer
#var normal_weights_backup: Array[float] = [1, 0, 0, 0, 0, 0, 0, 0, 0, 0]
#var play_now_second_foot_weights: Array[float] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
var second_foot_strength: float = 1

@onready var thumps: AudioStreamPlayer3D = $thumps
@onready var landing_thumps: AudioStreamPlayer3D = $landing_thumps

func spread_cos(x: float) -> float:
	if x >= 1:
		return 0
	elif x <= -1:
		return 0
	else:
		return 0.5 * (1 + cos(PI * x))

func update_weights():#use_backup: bool = false):
	#if not use_backup:
	var temp_weights: Array[float] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	var total: float = 0
	for i in range(0, thumps.stream.streams_count):
		temp_weights[i] = spread_cos((i - step_strength) / strength_variance)
		total += temp_weights[i]
	var total_inv = 1 / total
	for i in range(0, thumps.stream.streams_count):
		thumps.stream.set_stream_probability_weight(i, temp_weights[i] * total_inv)
	redo_weights = false
	#else:
		#for i in range(0, thumps.stream.streams_count):
			#thumps.stream.set_stream_probability_weight(i, normal_weights_backup[i])

func play_now_with_strength(step_strength_now: float, strength_variance_now: float, wait_second: float, step_strength_second: float = -1, strength_variance_second: float = -1):
	## backup
	#for i in range(0, thumps.stream.streams_count):
		#normal_weights_backup[i] = thumps.stream.get_stream_probability_weight(i)
	
	var temp_weights: Array[float] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	var total: float = 0
	for i in range(0, landing_thumps.stream.streams_count):
		temp_weights[i] = spread_cos((i - step_strength_now) / strength_variance_now)
		total += temp_weights[i]
	var total_inv = 1 / total
	for i in range(0, landing_thumps.stream.streams_count):
		landing_thumps.stream.set_stream_probability_weight(i, temp_weights[i] * total_inv)
	landing_thumps.volume_db = lerp(-24, 0, clampf((step_strength_now - 1) / 9, 0, 1))
	print(step_strength_now, " ", landing_thumps.volume_db)
	landing_thumps.play()
	
	# restore
	#for i in range(0, thumps.stream.streams_count):
		#thumps.stream.set_stream_probability_weight(i, normal_weights_backup[i])
	
	# second step
	if step_strength_second < 1:
		step_strength_second = step_strength_now
	if strength_variance_second < 1:
		strength_variance_second = strength_variance_now
	for i in range(0, landing_thumps.stream.streams_count):
		temp_weights[i] = spread_cos((i - step_strength_second) / strength_variance_second)
		total += temp_weights[i]
	total_inv = 1 / total
	for i in range(0, landing_thumps.stream.streams_count):
		landing_thumps.stream.set_stream_probability_weight(i, temp_weights[i] * total_inv)
		#play_now_second_foot_weights[i] = temp_weights[i] * total_inv
	second_foot_strength = step_strength_second
	play_now_second_timer.wait_time = wait_second

func _ready() -> void:
	var wait_time = time
	if time_mode == TimeMode.Hertz:
		wait_time = 1 / time
	step_timeout_usec = wait_time * 1e6
	#timer.wait_time = wait_time
	#if is_walking:
		#timer.start()

#func _on_timer_timeout() -> void:
	##print("footstep")
	#if randomize_time:
		#var wait_time = time
		#var rand_time = randf_range(-time_jitter, time_jitter)
		#if rand_time >= 0:
			#wait_time *= 1 + rand_time
		#else:
			#wait_time /= 1 + rand_time
		#if time_mode == TimeMode.Hertz:
			#wait_time = 1 / wait_time
		#timer.wait_time = wait_time
	#if always_update_weights or redo_weights:
		#update_weights()
		##for i in range(0, thumps.stream.streams_count):
			##print(thumps.stream.get_stream_probability_weight(i))
	#thumps.play()
	#if not is_walking:
		#timer.stop()


func _process(delta: float) -> void:
	if is_walking:
		var current_time_usec = Time.get_ticks_usec()
		if last_step_time_usec < current_time_usec - step_timeout_usec:
			if randomize_time:
				var wait_time = time
				var rand_time = randf_range(-time_jitter, time_jitter)
				if rand_time >= 0:
					wait_time *= 1 + rand_time
				else:
					wait_time /= 1 + rand_time
				if time_mode == TimeMode.Hertz:
					wait_time = 1 / wait_time
				step_timeout_usec = wait_time * 1e6
			if always_update_weights or redo_weights:
				update_weights()
			thumps.volume_db = lerp(-24, -12, clampf((step_strength - 1) / 9, 0, 1))
			print(step_strength, " ", thumps.volume_db)
			thumps.play()
			last_step_time_usec = current_time_usec


func _on_play_now_second_timer_timeout() -> void:
	#for i in range(0, thumps.stream.streams_count):
		#landing_thumps.stream.set_stream_probability_weight(i, play_now_second_foot_weights[i])
	landing_thumps.volume_db = lerp(-24, 0, clampf((second_foot_strength - 1) / 9, 0, 1))
	print(second_foot_strength, " ", landing_thumps.volume_db)
	landing_thumps.play()
	#for i in range(0, landing_thumps.stream.streams_count):
		#landing_thumps.stream.set_stream_probability_weight(i, normal_weights_backup[i])
