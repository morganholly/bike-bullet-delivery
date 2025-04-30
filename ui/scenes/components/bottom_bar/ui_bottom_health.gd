extends Control

@onready var current_health_label: Label = $CurrentHealth
@onready var max_health_label: Label = $MaxHealth

func _ready():
	# Connect to UI manager signals
	UIManager.health_updated.connect(_on_health_updated)
	
	# Initialize with current values
	_on_health_updated(UIManager.current_health, UIManager.max_health)

func _on_health_updated(current: float, maximum: float):
	print("Health updated: ", current, maximum)
	current_health_label.text = str(round(current))
	max_health_label.text = str(round(maximum)) 
