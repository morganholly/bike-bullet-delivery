extends Resource
class_name Mission

# Basic delivery mission properties
@export var id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var deliverable: String = ""
# Store target information
@export var target_path: NodePath
@export var target_id: String = ""  # Fallback ID for serialization

# Mission state
@export var completed: bool = false
@export var has_phases: bool = false
@export var current_phase: int = 0
@export var total_phases: int = 1
var phase_descriptions: Array[String] = []
var phase_completed: Array[bool] = []

# Cached target reference
var target: Node = null

func _init(p_id: String = "", p_title: String = "", p_description: String = "", p_deliverable: String = "", p_target = null):
	id = p_id
	title = p_title
	description = p_description
	deliverable = p_deliverable
	
	# Handle target based on type
	if p_target is String:
		target_id = p_target
	elif p_target is NodePath:
		target_path = p_target
	elif p_target is Node:
		# We store the reference but only temporarily
		target = p_target
		target_id = p_target.name

# Setup phases for this mission
func setup_phases(descriptions: Array[String]) -> void:
	if descriptions.size() > 0:
		has_phases = true
		phase_descriptions = descriptions
		total_phases = descriptions.size()
		phase_completed = []
		
		# Initialize all phases as incomplete
		for i in range(total_phases):
			phase_completed.append(false)

# Complete the current phase and advance to the next
func complete_current_phase() -> bool:
	if current_phase < total_phases:
		phase_completed[current_phase] = true
		current_phase += 1
		
		# If all phases are complete, mark mission as completed
		if current_phase >= total_phases:
			completed = true
			return true
	
	return false

# Get the description for the current phase
func get_current_phase_description() -> String:
	if has_phases and current_phase < phase_descriptions.size():
		return phase_descriptions[current_phase]
	return description

# Check if the given deliverable matches what this mission requires
func is_valid_deliverable(deliverable_obj: Node) -> bool:
	# Check the deliverable is valid for this mission
	if deliverable_obj.is_in_group("Deliverable"):
		if deliverable_obj.has_method("get_mission_id") and deliverable_obj.get_mission_id() == id:
			return true
		
		# If it's a general deliverable and the type matches
		if deliverable_obj.name.contains(deliverable):
			return true
			
	return false 
