extends HFlowContainer

var messageBullet = load("res://ui/message_bullet.tscn")

var messageList = []

func _ready() -> void:
	#recive_message("I NEED AMMO")
	pass
	

func clear():
	for message in $".".get_children():
		message.queue_free()
	pass

func recive_message(text):
	#messageBullet
	var object = messageBullet.instantiate()
	object.set_up_message(text)
	messageList.append(object)
	add_child(object)
	pass 
