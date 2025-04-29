extends Control

@onready var start_button = $VBoxContainer/StartButton

func _ready():
	start_button.pressed.connect(_on_start_button_pressed)

func _on_start_button_pressed():
	# Change to the main game scene
	get_tree().change_scene_to_file("res://screen_space_shading/sss_viewport.tscn") 