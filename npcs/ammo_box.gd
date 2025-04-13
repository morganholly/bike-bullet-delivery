extends RigidBody3D


var slotInfo = { 
		"type": "ammo",
		"amount": 5,
}



func set_slot_info(newSlotInfo):
	slotInfo = newSlotInfo.duplicate()
