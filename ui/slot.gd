extends ColorRect

var ammo = load("res://textures/Mockups/AmmoBox.png")
var gun = load("res://textures/Mockups/Sprite-0001.png")

func refresh_slot(slotInfo, currentSlot):
	
	$TextureRect2.show()
	$Label.show()
	
	match slotInfo["type"]:
		"ammo":
			$TextureRect2.texture = ammo
		"gun":
			$TextureRect2.texture = gun
		"empty":
			$TextureRect2.hide()
			$Label.hide()

	$Label.text = str(slotInfo["amount"])
	
	if currentSlot:
		$".".color = Color(114, 114, 114, 0.35)	
	else: 
		$".".color = Color(0, 0, 0, 0.35)
	
	
