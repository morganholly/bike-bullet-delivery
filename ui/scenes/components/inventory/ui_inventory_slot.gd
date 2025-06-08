extends Control

@onready var frame: Sprite2D = $Frame
@onready var background: Sprite2D = $Background
@onready var slot_number: Label = $SlotNumber
@onready var active_bar = $ActiveBar
@onready var passive_bar = $PassiveBar

#update the ammo
#@onready var checklabel =$Checklabel #TIDYUP

var slotnumber = 0 #TIDYUP
var isgun = false #TIDYUP
var is_selected: bool = false
var passive_texture = preload("res://ui/assets/ui_elements/small slot border@2x.png")
var active_texture = preload("res://ui/assets/ui_elements/selected slot border@2x.png")

var active_bg = preload("res://ui/assets/ui_elements/bg selected slot.png")
var passive_bg = preload("res://ui/assets/ui_elements/bg small slot.png")

var active_width = 150
var passive_width = 70

var x_offset = 40
var y_offset = 30

var bg_offset_x = 40
var bg_offset_y = 25

var number_offset_x = 82
var number_offset_y = 20

var old_mag=0 #TIDYUP

func _ready() -> void:
	# Initialize with default state
	set_selected(false)
	UIManager.bullet_count_changed.connect(_on_bullets_updated)#TIDYUP
	$ActiveBar/Top/SpriteAmmo.hide()
	$ActiveBar/Top/CurrentAmmo.hide()
	$ActiveBar/Top/Seperator.hide()
	$ActiveBar/Top/MaxAmmo.hide()
	$ActiveBar/Bot/SpritePistol.hide()
	$ActiveBar/Bot/SpriteFlare.hide()
	$ActiveBar/Bot/SpriteObject.hide()
	#$ActiveBar/Bot/Label.hide()
	$PassiveBar/SpriteAmmo.hide()
	$PassiveBar/SpritePistol.hide()
	$PassiveBar/SpriteFlare.hide()
	$PassiveBar/Label.hide()

func _on_bullets_updated(mag_count, reserve_count):
	#TIDYUP	
	if mag_count==-2:
		mag_count=old_mag
	old_mag=mag_count
	
	if UIManager.pistolindex == slotnumber:
		if !isgun:
			$ActiveBar/Top/SpriteAmmo.show()
			$ActiveBar/Top/CurrentAmmo.show()
			$ActiveBar/Top/Seperator.show()
			$ActiveBar/Top/MaxAmmo.show()
			$ActiveBar/Bot/SpritePistol.show()
			$ActiveBar/Bot/SpriteFlare.hide()
			$ActiveBar/Bot/SpriteObject.hide()
			#$ActiveBar/Bot/Label.show()
			$PassiveBar/SpriteAmmo.show()
			$PassiveBar/SpritePistol.show()
			$PassiveBar/SpriteFlare.hide()
			$PassiveBar/Label.show()
			isgun = true
			
		$PassiveBar/Label.text=str(mag_count+reserve_count)
		var magpadding=""
		if mag_count<10:
			magpadding = "0"

		var respadding=""
		if reserve_count<10:
			respadding = "0"
		elif reserve_count<100:
			respadding = "0"	

		
		if mag_count == -1:
			$ActiveBar/Top/CurrentAmmo.text=" RELOAD"
			$ActiveBar/Top/MaxAmmo.text=""
			$ActiveBar/Top/Seperator.hide()
		else:
			$ActiveBar/Top/CurrentAmmo.text= magpadding + str(mag_count)
			$ActiveBar/Top/MaxAmmo.text = respadding + str(reserve_count)
			$ActiveBar/Top/Seperator.show()
		
		pass
	elif UIManager.flareindex == slotnumber:
		if !isgun:
			$ActiveBar/Top/SpriteAmmo.show()
			$ActiveBar/Top/CurrentAmmo.show()
			$ActiveBar/Top/Seperator.show()
			$ActiveBar/Top/MaxAmmo.show()
			$ActiveBar/Bot/SpritePistol.hide()
			$ActiveBar/Bot/SpriteFlare.show()
			$ActiveBar/Bot/SpriteObject.hide()
			#$ActiveBar/Bot/Label.show()
			$PassiveBar/SpriteAmmo.show()
			$PassiveBar/SpritePistol.hide()
			$PassiveBar/SpriteFlare.show()
			$PassiveBar/Label.show()
			isgun = true
			
		$PassiveBar/Label.text=str(mag_count+reserve_count)
		var magpadding=""
		if mag_count<10:
			magpadding = "0"

		var respadding=""
		if reserve_count<10:
			respadding = "0"
		elif reserve_count<100:
			respadding = "0"	

		
		if mag_count == -1:
			$ActiveBar/Top/CurrentAmmo.text=" RELOAD"
			$ActiveBar/Top/MaxAmmo.text=""
			$ActiveBar/Top/Seperator.hide()
		else:
			$ActiveBar/Top/CurrentAmmo.text= magpadding + str(mag_count)
			$ActiveBar/Top/MaxAmmo.text = respadding + str(reserve_count)
			$ActiveBar/Top/Seperator.show()
		
		pass


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
		if UIManager.pistolindex != slotnumber and UIManager.flareindex != slotnumber:
			$ActiveBar/Bot/SpriteObject.show()
			
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
		
