extends Control

@onready var prompt_label: Label = $PromptLabel

var is_visible_prompt: bool = false

func _ready() -> void:
	# Hide the prompt by default
	self.visible = false
	
	# Connect to UI manager signal for prompt visibility and text changes
	if UIManager.has_signal("prompt_visibility_changed"):
		UIManager.prompt_visibility_changed.connect(_on_prompt_visibility_changed)
	if UIManager.has_signal("prompt_text_changed"):
		UIManager.prompt_text_changed.connect(_on_prompt_text_changed)

func _on_prompt_visibility_changed(is_visible: bool) -> void:
	is_visible_prompt = is_visible
	self.visible = is_visible

func _on_prompt_text_changed(text: String) -> void:
	prompt_label.text = text
	
func get_text() -> String:
	return prompt_label.text
	
func set_text(text: String) -> void:
	prompt_label.text = text 