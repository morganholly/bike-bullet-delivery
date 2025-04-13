extends CanvasLayer


var money = 100;



func _ready():
	$Label.text = "$"+str(money)
	
	$HFlowContainer.clear()
	$HFlowContainer.recive_message("I NEED AMMO")



func recive_money(amount):
	money += amount
	refresh()


func refresh():
	$Label.text = "$"+str(money)
