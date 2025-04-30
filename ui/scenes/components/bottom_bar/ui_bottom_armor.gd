extends Control

@onready var current_armor_label: Label = $MaxHealth  # First label
@onready var max_armor_label: Label = $MaxHealth2    # Second label

func _ready():
	# Connect to UI manager signals
	UIManager.armor_updated.connect(_on_armor_updated)
	
	# Initialize with current values
	_on_armor_updated(UIManager.current_armor, UIManager.max_armor)

func _on_armor_updated(current: float, maximum: float):
	current_armor_label.text = str(round(current))
	max_armor_label.text = str(round(maximum)) 
