extends "res://npcs/Billboard.gd"

var ammo = load("res://textures/Mockups/AmmoBox.png")
var gun = load("res://textures/Mockups/Sprite-0001.png")

func _ready() -> void:
	disable_rotation_to_camera = true

func refresh(slotInfo):
	match slotInfo["type"]:
		"ammo":
			show()
			texture = ammo
			pass
		"gun":
			show()
			texture = gun
			pass
		"empty":
			hide()
			pass
	pass
