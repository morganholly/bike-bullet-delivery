extends Control



var slotsInfo = [
	{ 
		"type": "empty",
		"amount": 0,
		#"current": true
	},
	{ 
		"type": "empty",
		"amount": 0,
		#"current": false
	},
	{ 
		"type": "empty",
		"amount": 0,
		#"current": false
	}
	
]
var UISlots = []
var curSlotIndex = 0

func _ready() -> void:
	UISlots.append($ColorRect3)
	UISlots.append($ColorRect4)
	UISlots.append($ColorRect5)
	refresh()
	pass
	
	
func refresh():
	for i in range(UISlots.size()):
		UISlots[i].refresh_slot(slotsInfo[i], (i == curSlotIndex))
		


func pick_up_item(pickedSlotInfo) -> bool:
	print(slotsInfo[curSlotIndex])
	if (slotsInfo[curSlotIndex]["type"] == "empty"):
		#slotsInfo[curSlotIndex]["type"] = pickedSlotInfo["type"]
		slotsInfo[curSlotIndex] = pickedSlotInfo
		refresh()
		return true
		#pass
	#else:
		#for i in range(slotsInfo.size()):
			#if slotsInfo[i]["type"] == "empty":
				#slotsInfo[i]["type"] = pickedSlotInfo["type"]
				#slotsInfo[i]["amount"] = pickedSlotInfo["amount"]
				#refresh()
				#return true
				#break
				#pass
	#refresh()
	return false



func get_current_slotInfo():
	return slotsInfo[curSlotIndex]
	
func get_by_type_slotInfo(type):
	for i in range(slotsInfo.size()):
		if (type == slotsInfo[i]["type"]):
			return slotsInfo[i]
	
	return;
		#UISlots[i].refresh_slot(slotsInfo[i], (i == curSlotIndex))
