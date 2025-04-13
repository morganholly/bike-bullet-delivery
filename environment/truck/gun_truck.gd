extends truck

signal spawn_gun


func _on_timer_timeout() -> void:
	emit_signal("spawn_gun", self)
