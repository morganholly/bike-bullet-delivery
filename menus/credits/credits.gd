extends Control

# Dictionary to store credits data: name -> [roles]
var credits_data = {
	"AmberMechanic": [],
	"Henry": [],
	"Jktulord": [],
	"MancerDev": [],
	"Morgan": [],
}

@onready var credits_container: VBoxContainer = $CreditsPanel/VBoxContainer
@onready var back_button: Button = $BackButton

func _ready() -> void:
	# Connect back button signal
	back_button.pressed.connect(_on_back_pressed)
	
	# Populate credits
	_populate_credits()
	
	# Set initial focus
	back_button.grab_focus()

func _populate_credits() -> void:
	# Clear any existing children
	for child in credits_container.get_children():
		child.queue_free()
	
	# Add credits data
	for name in credits_data:
		# Create container for name and roles
		var name_container = HBoxContainer.new()
		name_container.alignment = BoxContainer.ALIGNMENT_CENTER
		credits_container.add_child(name_container)
		
		# Add name label
		var name_label = Label.new()
		name_label.text = name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		name_label.add_theme_font_size_override("font_size", 24)
		name_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		name_container.add_child(name_label)
		
		# Add separator
		var separator = Label.new()
		separator.text = " - "
		separator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		separator.add_theme_font_size_override("font_size", 24)
		name_container.add_child(separator)
		
		# Add roles label
		var roles_label = Label.new()
		roles_label.text = ", ".join(credits_data[name])
		roles_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		roles_label.add_theme_font_size_override("font_size", 24)
		name_container.add_child(roles_label)
		
		# Add spacing between entries
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 20)
		credits_container.add_child(spacer)

func _on_back_pressed() -> void:
	# Return to the main menu
	get_tree().change_scene_to_file("res://menus/start_menu/start_menu.tscn") 