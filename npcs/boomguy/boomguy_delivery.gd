extends Node

# This script adds a delivery area to Boomguy
# It doesn't modify any existing Boomguy functionality

var delivery_area: Area3D
var feedback_label: Label3D
var boomguy: Node3D  # Reference to parent Boomguy node
var delivered_bullets = []  # Track bullets that have been delivered

func _ready():
	# Wait a frame to ensure parent is ready
	await get_tree().process_frame
	
	# Store reference to parent Boomguy
	boomguy = get_parent()
	
	# Add to NPC group for missions
	add_to_group("NPC")
	
	# Setup the delivery area
	setup_delivery_area()
	
	# Add a label to show mission info
	setup_feedback_label()
	
	print("BoomguyDelivery: Initialized delivery area")

func setup_delivery_area():
	# Create the area node - make it a direct child of the scene root
	# so its position can be managed independently
	delivery_area = Area3D.new()
	delivery_area.name = "BoomguyDeliveryArea"
	get_tree().root.add_child(delivery_area)
	
	# Set collision properties - detect deliverable bullets (layer 1 and 9)
	delivery_area.collision_layer = 0
	delivery_area.collision_mask = 257  # Layer 1 and 9 (Normal Geo and ExtraPickupArea)
	
	# Set initial position to match Boomguy
	update_delivery_area_position()
	
	# Create the sphere shape with 3m radius
	var shape = SphereShape3D.new()
	shape.radius = 3.0
	
	# Create the collision shape
	var collision = CollisionShape3D.new()
	collision.shape = shape
	delivery_area.add_child(collision)
	
	# Connect signals
	delivery_area.connect("body_entered", _on_delivery_area_body_entered)
	
	# Optional: Add a visual indicator for debugging
	var visual = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 3.0
	sphere_mesh.height = 6.0
	visual.mesh = sphere_mesh
	
	# Make it transparent
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.0, 1.0, 0.0, 0.2)  # Green, transparent
	visual.material_override = material
	delivery_area.add_child(visual)

func setup_feedback_label():
	# Create a 3D label above Boomguy - add to scene root for independent control
	feedback_label = Label3D.new()
	feedback_label.name = "BoomguyFeedbackLabel"
	feedback_label.text = ""
	feedback_label.font_size = 36  # Larger, more visible font
	feedback_label.modulate = Color.WHITE
	feedback_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	feedback_label.no_depth_test = true  # Ensure it's always visible
	feedback_label.fixed_size = true  # Consistent size regardless of distance
	
	# Add outline for better visibility
	feedback_label.outline_size = 3
	feedback_label.outline_modulate = Color.BLACK
	
	# Add to scene root so we can control it independently
	get_tree().root.add_child(feedback_label)
	
	# Position will be updated in _process
	update_feedback_label_position()

# Update delivery area position to match Boomguy
func update_delivery_area_position():
	if delivery_area and boomguy:
		delivery_area.global_position = boomguy.global_position

# Update feedback label position
func update_feedback_label_position():
	if feedback_label and boomguy:
		# Position above Boomguy's head
		feedback_label.global_position = boomguy.global_position + Vector3(0, 3.5, 0)

# Process function to update position every frame
func _process(_delta):
	update_delivery_area_position()
	update_feedback_label_position()
	
	# Handle bullet cleanup
	handle_delivered_bullets()

# Handle cleanup of delivered bullets
func handle_delivered_bullets():
	var bullets_to_remove = []
	
	for bullet in delivered_bullets:
		if is_instance_valid(bullet):
			# Check if the bullet is no longer being held
			var can_remove = true
			
			if bullet.get_parent() and (bullet.get_parent().is_in_group("IsHeld") or bullet.is_in_group("IsHeld")):
				# Still being held, can't remove yet
				can_remove = false
				
				# Try to detach it from the player's hold
				if bullet.get_parent().has_method("drop_held"):
					bullet.get_parent().drop_held()
				elif bullet.has_method("queue_release"):
					bullet.queue_release()
			
			if can_remove:
				# Safe to remove now
				bullet.queue_free()
				bullets_to_remove.append(bullet)
		else:
			# Already freed or invalid
			bullets_to_remove.append(bullet)
	
	# Remove processed bullets from the list
	for bullet in bullets_to_remove:
		delivered_bullets.erase(bullet)

# Make sure to clean up when this node is removed
func _exit_tree():
	if delivery_area:
		delivery_area.queue_free()
	if feedback_label:
		feedback_label.queue_free()

func _on_delivery_area_body_entered(body):
	
	# Check if it's a deliverable bullet
	if body.is_in_group("Deliverable"):
		print("BoomguyDelivery: Deliverable entered area")
		
		# Check if it has the expected script
		if body.has_method("get_mission_id"):
			var mission_id = body.get_mission_id()
			
			if mission_id != "":
				print("BoomguyDelivery: Mission bullet entered delivery area: " + mission_id)
				
				# Deliver to this NPC and check if it was successful
				var delivery_successful = body.deliver_to_target(get_parent())
				
				# Only process the bullet if delivery was successful
				if delivery_successful:
					# Show feedback - Make it more noticeable
					feedback_label.text = "Delivery Received!"
					feedback_label.modulate = Color(0.0, 1.0, 0.2)  # Bright green
					
					# Make it bigger temporarily for emphasis
					feedback_label.scale = Vector3(1.5, 1.5, 1.5)
					
					# Create a timer to reset label
					var timer = get_tree().create_timer(2.0)
					timer.timeout.connect(func(): 
						feedback_label.text = ""
						feedback_label.scale = Vector3(1, 1, 1)
					)
					
					# Mark bullet for delayed removal instead of trying to free it immediately
					if not delivered_bullets.has(body):
						delivered_bullets.append(body)
						
						# Make it invisible to indicate it's been delivered
						if body.has_node("MeshInstance3D"):
							body.get_node("MeshInstance3D").visible = false
				else:
					# Delivery was rejected
					feedback_label.text = "You need to use rollerblades first!"
					feedback_label.modulate = Color.RED
					
					# Create a timer to reset label
					var timer = get_tree().create_timer(2.0)
					timer.timeout.connect(func(): 
						feedback_label.text = ""
					)
	
	# If it's a player, show a hint
	elif body.is_in_group("Player"):
		feedback_label.text = "Bring mission items here!"
		feedback_label.modulate = Color.YELLOW
		
		# Clear after 2 seconds
		var timer = get_tree().create_timer(2.0)
		timer.timeout.connect(func(): 
			if feedback_label.text == "Bring mission items here!":
				feedback_label.text = ""
		) 
