extends Control

@onready var frame: Sprite2D = $Frame
@onready var background: Sprite2D = $Background
@onready var slot_number: Label = $SlotNumber
@onready var active_bar = $ActiveBar
@onready var passive_bar = $PassiveBar

var is_selected: bool = false
var passive_texture = preload("res://ui/small slot border@2x.png")
var active_texture = preload("res://ui/selected slot border@2x.png")

var active_bg = preload("res://ui/bg selected slot.png")
var passive_bg = preload("res://ui/bg small slot.png")

var active_width = 150
var passive_width = 70

var x_offset = 40
var y_offset = 30

var bg_offset_x = 40
var bg_offset_y = 25

var number_offset_x = 82
var number_offset_y = 20

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
		frame.texture = active_texture
		background.texture = active_bg
		size.x = active_width
		custom_minimum_size.x = active_width
		frame.position.x += x_offset
		frame.position.y += y_offset
		background.position.x += bg_offset_x
		background.position.y += bg_offset_y
		$ActiveBar.visible = true
		$PassiveBar.visible = false
		slot_number.position.x += number_offset_x
		slot_number.position.y += number_offset_y
	
	else:
		# Switch to passive sprite
		frame.texture = passive_texture
		background.texture = passive_bg
		size.x = passive_width
		custom_minimum_size.x = passive_width
		frame.position.x -= x_offset
		frame.position.y -= y_offset
		background.position.x -= bg_offset_x
		background.position.y -= bg_offset_y
		$ActiveBar.visible = false
		$PassiveBar.visible = true
		slot_number.position.x -= number_offset_x
		slot_number.position.y -= number_offset_y
