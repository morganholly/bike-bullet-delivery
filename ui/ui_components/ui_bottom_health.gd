extends Control

@onready var current_health_label: Label = $CurrentHealth
@onready var max_health_label: Label = $MaxHealth

func _on_health_updated(current_health: float, max_health: float) -> void:
	# [Health UI] Updating health display: ", current_health, "/", max_health
	current_health_label.text = str(int(current_health))
	max_health_label.text = str(int(max_health)) 