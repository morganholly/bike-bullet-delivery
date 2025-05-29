extends RigidBody3D

class_name DeliverableBullets

# Mission related properties
@export var mission_id: String = ""
@export var delivery_id: String = ""  # Unique identifier for this specific deliverable

# Signal when delivered
signal delivered_to_target(deliverable, target)
# Signal when picked up
signal bullet_pickup_completed

# Variable to track if we're being held
var was_held = false

func _ready():
	# Make sure we're in the right group
	if !is_in_group("Deliverable"):
		add_to_group("Deliverable")

func _process(_delta):
	# Check if we've been picked up into the player's inventory
	if is_in_group("IsHeld") and !was_held:
		was_held = true
		_on_physically_picked_up()
	elif !is_in_group("IsHeld") and was_held:
		was_held = false

# Called when the object is physically picked up (added to IsHeld group)
func _on_physically_picked_up():
	if mission_id != "" and mission_id in MissionManager.active_missions:
		emit_signal("bullet_pickup_completed")
		# Also notify MissionManager directly
		if MissionManager.has_method("_on_deliverable_picked_up"):
			MissionManager._on_deliverable_picked_up(mission_id)

# This is the old BulletPickup signal handler - no longer primary detection method
func _on_bullet_pickup_ammo_transferred():
	pass  # Not used for mission tracking

# Called when delivering to the target
func deliver_to_target(target_npc: Node):
	print("BOOMGUY DELIVERY: ",mission_id)
	if mission_id in MissionManager.active_missions:
		print("mission identified")
		var delivery_successful = MissionManager.deliver_to_npc(mission_id, target_npc)
		emit_signal("delivered_to_target", self, target_npc)
		return delivery_successful
	return false

# Function to set mission association after creation
func set_mission(id: String):
	mission_id = id
	delivery_id = "%s_%s" % [id, randi() % 1000]  # Create somewhat unique ID
	
# Get the mission ID this deliverable is for
func get_mission_id() -> String:
	return mission_id 
