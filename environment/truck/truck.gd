extends RigidBody3D

class_name truck

signal spawn_ammo

func _ready() -> void:
	$Timer.stop()

func _on_timer_timeout() -> void:
	emit_signal("spawn_ammo", self)


func order():
	if ($Timer.time_left != 0):
		return
	
	var player_ui = get_tree().get_root().get_node("ScreenSpaceShader/CanvasLayer")
	if (player_ui.money-30 >= 0):
		if ($Timer.time_left != 0):
			return
		print(str($Timer.time_left))
		player_ui.recive_money(-30)
		$Timer.start(0.2)
		player_ui.refresh()
