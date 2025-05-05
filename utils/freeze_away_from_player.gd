extends Node3D


@onready var timer: Timer = $Timer


@export var active_distance: float = 50:
	set(value):
		active_distance = value
		active_dist_sq = value * value
var active_dist_sq: float = 50 * 50
var is_active: bool
@export var see_distance: float = 100:
	set(value):
		see_distance = value
		see_dist_sq = value * value
		inv_diff = 1 / (slow_dist_sq - see_dist_sq)
var see_dist_sq: float = 100 * 100
var is_seen: bool
@export var slow_check_distance: float = 200:
	set(value):
		slow_check_distance = value
		slow_dist_sq = value * value
		inv_diff = 1 / (slow_dist_sq - see_dist_sq)
var slow_dist_sq: float = 200 * 200

var inv_diff = 1 / (slow_dist_sq - see_dist_sq)

@export var fast_time: float = 2
@export var slow_time: float = 20
##uses randomness to disperse checks over time
@export var rand_scale: float = 1.5


enum ActiveType {
	RigidFreeze,
}
@export var active_type: ActiveType = ActiveType.RigidFreeze


func switch_active(active: bool):
	match active_type:
		ActiveType.RigidFreeze:
			if self.get_parent() and self.get_parent() is RigidBody3D:
				self.get_parent().freeze = not active

func _ready() -> void:
	timer.wait_time = randf_range(fast_time, fast_time * rand_scale)
	switch_active(false)

func _on_timer_timeout() -> void:
	var distance = GlobalPlayerData.player_position.distance_to(self.global_position)
	var dist_factor = max(0, distance - see_distance) * inv_diff
	var time = lerp(fast_time, slow_time, dist_factor)
	timer.wait_time = randf_range(time, time * rand_scale)
	switch_active(distance < active_distance)
