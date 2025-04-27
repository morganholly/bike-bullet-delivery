extends RigidBody3D

class_name DeliverableBullets

# Mission related properties
@export var mission_id: String = ""
@export var delivery_id: String = ""  # Unique identifier for this specific deliverable

# Signal when delivered
signal delivered_to_target(deliverable, target)

# Called when the BulletPickup component transfers ammo to a player
func _on_bullet_pickup_ammo_transferred():
	# If this bullet is part of a mission, notify MissionManager it was picked up
	if mission_id != "":
		if get_parent().is_in_group("IsHeld") and mission_id in MissionManager.active_missions:
			print("Deliverable for mission %s picked up" % mission_id)

# Called when delivering to the target
func deliver_to_target(target_npc: Node):
	if mission_id in MissionManager.active_missions:
		print("Delivering %s to %s for mission %s" % [delivery_id, target_npc.name, mission_id])
		MissionManager.deliver_to_npc(mission_id, target_npc)
		emit_signal("delivered_to_target", self, target_npc)
		return true
	return false

# Function to set mission association after creation
func set_mission(id: String):
	mission_id = id
	delivery_id = "%s_%s" % [id, randi() % 1000]  # Create somewhat unique ID
	
# Get the mission ID this deliverable is for
func get_mission_id() -> String:
	return mission_id 