extends StaticBody3D

@export var phrase1:String =""
@export var phrase2:String =""
@export var phrase3:String =""
@export var phrase4:String=""

func _ready():
	randomize()
	$Sprite3D/StatusText.hide()
	pass

func _on_area_3d_body_entered(_body: Node3D) -> void:
	print("TALK ENTERED")
	
	var r1=randi_range(1,4)
	if r1 ==1:
		$Sprite3D/StatusText.text=phrase1
	elif r1 ==2:
		$Sprite3D/StatusText.text=phrase2
	elif r1 ==3:
		$Sprite3D/StatusText.text=phrase3
	elif r1 ==4:
		$Sprite3D/StatusText.text=phrase4
		
	if $Sprite3D/StatusText.text!="":
		$Sprite3D/StatusText.show()
		
	$Area3D.monitoring=false
	$Timer.start()
	pass # Replace with function body.




func _on_timer_timeout() -> void:
	$Sprite3D/StatusText.hide()
	$Area3D.monitoring=true
	pass # Replace with function body.
