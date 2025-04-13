extends RigidBody3D


var slotInfo: Dictionary = { 
		"type": "gun",
		"amount": 1,
		"ammo": 11,
}


func set_slot_info(newSlotInfo):
	slotInfo = newSlotInfo.duplicate()
	
	
