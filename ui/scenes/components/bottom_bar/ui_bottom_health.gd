extends Control

@onready var current_health_label: Label = $CurrentHealth
@onready var max_health_label: Label = $MaxHealth

func _ready():
	# Connect to UI manager signals
	UIManager.health_updated.connect(_on_health_updated)
	
	# Initialize with current values
	_on_health_updated(UIManager.current_health, UIManager.max_health)

func _on_health_updated(current: float, maximum: float):
	current_health_label.text = str(int(current))
	print("Health: ", current_health_label.text)
	max_health_label.text = str(int(maximum)) 
