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

# Mission state (active or completed)
@export var completed: bool = false

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