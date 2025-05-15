extends Control

@export var slides: Array[SlideData]
@export var next_scene_path: String = "res://screen_space_shading/sss_viewport.tscn"
#9a826b label color
var current_slide_index: int = 0
var current_text_entry_index: int = 0
var is_typing: bool = false
var current_text: String = ""
var typing_speed: float = 0.05
var typing_timer: float = 0.0
var visible_text_entries: Array[Dictionary] = []  # Array of dictionaries containing text entry data and labels

@onready var background: TextureRect = $Background
@onready var name_label: Label = $NameLabel
@onready var text_label: Label = $TextLabel
@onready var continue_label: Label = $ContinueLabel
@onready var loading_label: Label = $ContinueLabel

# Panel styling constants
const PANEL_COLOR := Color(0, 0, 0, 0.5)
const PANEL_MARGIN := 20.0

const TEXT_COLOR = Color(0.784314, 0.784314, 0.627451, 1.0)  # Light beige color

func _ready():
	# Make sure the mouse is visible during cutscenes
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	ResourceLoader.load_threaded_request(next_scene_path)
	
	if slides.size() > 0:
		show_current_slide()
	else:
		queue_free()
	
	# Hide template labels as they're only used for copying properties
	name_label.hide()
	text_label.hide()

func _process(delta):
	if is_typing:
		typing_timer += delta
		if typing_timer >= typing_speed:
			typing_timer = 0
			var current_entry = visible_text_entries[-1]
			if current_entry.text_label.text.length() < current_entry.full_text.length():
				current_entry.text_label.text = current_entry.full_text.substr(0, current_entry.text_label.text.length() + 1)
			else:
				is_typing = false
				continue_label.show()

func _input(event):
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		if is_typing:
			# Show full text immediately
			var current_entry = visible_text_entries[-1]
			current_entry.text_label.text = current_entry.full_text
			is_typing = false
			continue_label.show()
		else:
			# Check if there are more text entries in the current slide
			if current_text_entry_index < slides[current_slide_index].text_entries.size() - 1:
				current_text_entry_index += 1
				show_current_text_entry()
			# Check if there are more slides
			elif current_slide_index < slides.size() - 1:
				current_slide_index += 1
				current_text_entry_index = 0
				clear_text_entries()  # Clear text entries only when changing slides
				show_current_slide()
			else:
				#$"loading spinner".show()
				# Make sure the mouse remains visible before changing scene
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				# End of slideshow, transition to next scene
				#get_tree().change_scene_to_file(next_scene_path)
				continue_label.hide()
				loading_label.show()
				var next_scene = ResourceLoader.load_threaded_get(next_scene_path)
				get_tree().change_scene_to_packed(next_scene)

func clear_text_entries():
	# Remove all text entries and their containers
	for entry in visible_text_entries:
		entry.name_container.queue_free()
		entry.text_container.queue_free()
	visible_text_entries.clear()

func show_current_slide():
	var slide = slides[current_slide_index]
	background.texture = slide.background_texture
	show_current_text_entry()

func create_panel(size: Vector2, position: Vector2) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = size
	panel.position = position
	panel.modulate = PANEL_COLOR
	return panel

func show_current_text_entry():
	var text_entry = slides[current_slide_index].text_entries[current_text_entry_index]
	
	# Create new labels for this text entry
	var new_name_label = Label.new()
	var new_text_label = Label.new()
	
	# Create containers for proper layout
	var name_container = Control.new()
	var text_container = Control.new()
	
	# Setup name container with exact position from text entry
	name_container.custom_minimum_size = Vector2(800, 50)
	name_container.position = text_entry.position
	print(name_container.position)	# Setup text container slightly below name
	text_container.custom_minimum_size = Vector2(1200, 200)
	text_container.position = text_entry.position + Vector2(0, 60)  # Text appears 60px below the name
	
	# Copy properties from template labels
	new_name_label.add_theme_font_size_override("font_size", name_label.get_theme_font_size("font_size"))
	new_name_label.horizontal_alignment = name_label.horizontal_alignment
	new_name_label.vertical_alignment = name_label.vertical_alignment
	new_name_label.autowrap_mode = name_label.autowrap_mode
	new_name_label.add_theme_color_override("font_color", TEXT_COLOR)
	
	new_text_label.add_theme_font_size_override("font_size", text_label.get_theme_font_size("font_size"))
	new_text_label.horizontal_alignment = text_label.horizontal_alignment
	new_text_label.vertical_alignment = text_label.vertical_alignment
	new_text_label.autowrap_mode = text_label.autowrap_mode
	new_text_label.add_theme_color_override("font_color", TEXT_COLOR)
	
	# Set anchors and layout
	new_name_label.anchor_right = 1.0
	new_name_label.anchor_bottom = 1.0
	new_name_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	new_name_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	new_text_label.anchor_right = 1.0
	new_text_label.anchor_bottom = 1.0
	new_text_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	new_text_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	# Add labels to containers
	name_container.add_child(new_name_label)
	text_container.add_child(new_text_label)
	
	# Add containers to scene
	add_child(name_container)
	add_child(text_container)
	
	# Set initial text
	new_name_label.text = text_entry.character_name
	new_text_label.text = ""
	
	# Store entry data
	visible_text_entries.append({
		"name_label": new_name_label,
		"text_label": new_text_label,
		"full_text": text_entry.dialogue_text,
		"name_container": name_container,
		"text_container": text_container
	})
	
	# Start typing effect
	is_typing = true
	continue_label.hide() 
