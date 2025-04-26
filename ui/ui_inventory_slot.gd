extends Control

@onready var sprite: Sprite2D = $Sprite2D
@onready var slot_number: Label = $SlotNumber

var is_selected: bool = false
var passive_texture = preload("res://ui/ui_inventory_slot_passive.png")
var active_texture = preload("res://ui/ui_inventory_slot_active.png")

# Colors for the slot number
var passive_number_color: Color = Color(1, 1, 1, 1) 
var active_number_color: Color = Color(1, 0.9, 0, 1)  # Brighter gold for the number

func _ready() -> void:
	# Initialize with default state
	set_selected(false)

# Set the slot as selected or not
func set_selected(selected: bool) -> void:
	if is_selected == selected:
		return  # No change needed
	
	is_selected = selected
	
	if is_selected:
		# Switch to active sprite
		sprite.texture = active_texture
		# Change number color to active
		slot_number.add_theme_color_override("font_color", active_number_color)
	else:
		# Switch to passive sprite
		sprite.texture = passive_texture
		# Change number color back to passive
		slot_number.add_theme_color_override("font_color", passive_number_color) 