#extends Control
#@onready var sub_viewport: SubViewport = $"Screen Space Shader/SubViewport"
extends SubViewportContainer
@onready var sub_viewport: SubViewport = $SubViewport
var push_events: bool = false

@export var pick_scene: bool = false
@export var scenes: Array = [
	preload("res://levels/level/level.tscn"),
	preload("res://levels/level/level_old.tscn"),
	preload("res://levels/testing/test01.tscn"),
	preload("res://levels/testing/test02.tscn"),
	preload("res://levels/testing/test03.tscn"),
]

@onready var control_2: Control = $CanvasLayer/Control/Control2
@onready var level_select_v_box: VBoxContainer = $CanvasLayer/Control/Control2/VBoxContainer
#@onready var template_button: Button = $CanvasLayer/Control/Control2/HBoxContainer/button
var button = preload("res://screen_space_shading/level_pick_button.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not pick_scene:
		control_2.hide()
		push_events = true
		sub_viewport.add_child(scenes[0].instantiate())
	else:
		var index = 0
		for sc in scenes:
			var button_node = button.instantiate()
			var sc_path = sc.get_path()
			button_node.text = sc_path.right(-sc_path.rfind("/") - 1).left(-5)
			button_node.name = button_node.text
			button_node.connect("pressed", on_button_pressed.bind(index))
			level_select_v_box.add_child(button_node)
			index += 1

func on_button_pressed(index: int):
	push_events = true
	control_2.hide()
	sub_viewport.add_child(scenes[index].instantiate())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent):
	if pick_scene and event is InputEventKey and event.is_pressed() and event.keycode == KEY_BACKSLASH:
		push_events = false
		sub_viewport.get_child(0).queue_free()
		control_2.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if push_events:
		sub_viewport.push_input(event)
