extends Control

func _ready():
	# Hide by default
	visible = false
	
	# Connect to UIManager game over signal
	UIManager.game_over_visibility_changed.connect(_on_game_over_visibility_changed)

func _on_game_over_visibility_changed(is_visible: bool):
	visible = is_visible
	
func _input(event):
	if visible and (event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)):
		# Transition to outro cutscene when user clicks after game over
		get_tree().change_scene_to_file("res://cutscenes/slideshow/outro_slideshow.tscn") 
