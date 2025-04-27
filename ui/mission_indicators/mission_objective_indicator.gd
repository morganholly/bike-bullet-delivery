extends CanvasLayer

# Configuration parameters
@export var arrow_size: Vector2 = Vector2(32, 32)
@export var edge_offset: float = 20.0
@export var in_view_vertical_offset: float = 50.0
@export var min_distance_scale: float = 0.5
@export var max_distance: float = 100.0
@export var update_interval: float = 0.05  # Seconds between updates (20fps)
@export var show_distance: bool = true  # Show distance labels
@export var max_visible_indicators: int = 3  # Max number of indicators to show at once

# References
var arrow_texture = preload("res://ui/ui_arrow.png")
var mission_manager
var current_camera: Camera3D
var red_arrow_texture: ImageTexture
var update_timer: Timer

# Mission target tracking
var mission_indicators = {}  # All indicators by mission_id (both deliverable and target)
var mission_states = {}  # Track mission state: "need_pickup" or "need_delivery"

func _ready():
	# Add to group for easy identification
	add_to_group("MissionIndicator")
	
	# Create update timer for optimization
	setup_update_timer()
	
	# Get reference to mission manager
	mission_manager = get_node_or_null("/root/MissionManager")
	if mission_manager == null:
		push_error("MissionManager not found. Mission objective indicators will not work.")
		return
	
	# Connect to mission signals
	if mission_manager.has_signal("mission_started"):
		mission_manager.mission_started.connect(_on_mission_started)
	if mission_manager.has_signal("mission_completed"):
		mission_manager.mission_completed.connect(_on_mission_completed)
	if mission_manager.has_signal("deliverable_spawned"):
		mission_manager.deliverable_spawned.connect(_on_deliverable_spawned)
	if mission_manager.has_signal("deliverable_picked_up"):
		mission_manager.deliverable_picked_up.connect(_on_deliverable_picked_up)
	
	# Connect to UI manager signals
	if UIManager.has_signal("mission_target_updated"):
		UIManager.mission_target_updated.connect(_on_mission_target_updated)
	
	# Connect to player inventory
	_connect_to_player_inventory()

func _connect_to_player_inventory():
	# Wait a moment to make sure everything is initialized
	await get_tree().create_timer(1.0).timeout
	
	# Connect to player inventory system or hold container if available
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_node("HoldContainer"):
		var hold_container = player.get_node("HoldContainer")
		
		# Connect to signals that indicate item pickup
		if hold_container.has_signal("item_picked_up"):
			hold_container.item_picked_up.connect(_on_item_picked_up)
		
		if hold_container.has_signal("item_dropped"):
			hold_container.item_dropped.connect(_on_item_dropped)

func _on_item_picked_up(item):
	# Check if this item is a deliverable
	if item.is_in_group("Deliverable") and item.has_method("get_mission_id"):
		var mission_id = item.get_mission_id()
		if mission_id != "":
			# Update mission state to delivery phase
			_set_mission_state(mission_id, "need_delivery")

func _on_item_dropped(item):
	# Check if this item is a deliverable
	if item.is_in_group("Deliverable") and item.has_method("get_mission_id"):
		var mission_id = item.get_mission_id()
		if mission_id != "":
			# Update mission state back to pickup phase
			_set_mission_state(mission_id, "need_pickup")

func _on_deliverable_spawned(deliverable, mission_id):
	# Set initial mission state if not set
	if !mission_id in mission_states:
		_set_mission_state(mission_id, "need_pickup")
	
	# Connect to the deliverable's signals if it has them
	if deliverable.has_signal("bullet_pickup_completed"):
		deliverable.bullet_pickup_completed.connect(func(): _on_deliverable_picked_up(mission_id))
	
	# Make sure we have both indicators created
	_ensure_indicators_exist(mission_id, deliverable)

func _on_deliverable_picked_up(mission_id):
	_set_mission_state(mission_id, "need_delivery")

func _on_mission_started(mission_id):
	# Set default state
	if !mission_id in mission_states:
		_set_mission_state(mission_id, "need_pickup")

func _on_mission_completed(mission_id):
	# Clean up indicators
	if mission_id in mission_indicators:
		if mission_indicators[mission_id].has("deliverable") and is_instance_valid(mission_indicators[mission_id]["deliverable"]):
			mission_indicators[mission_id]["deliverable"].queue_free()
		
		if mission_indicators[mission_id].has("target") and is_instance_valid(mission_indicators[mission_id]["target"]):
			mission_indicators[mission_id]["target"].queue_free()
		
		mission_indicators.erase(mission_id)
	
	# Clean up mission state
	mission_states.erase(mission_id)

func _on_mission_target_updated(mission_id, target):
	_ensure_indicators_exist(mission_id, null, target)

func _set_mission_state(mission_id, state):
	var old_state = mission_states.get(mission_id, "")
	if old_state != state:
		mission_states[mission_id] = state
		_update_indicators_for_mission(mission_id)

func _ensure_indicators_exist(mission_id, deliverable = null, target = null):
	# Initialize mission indicator dictionary if needed
	if !mission_id in mission_indicators:
		mission_indicators[mission_id] = {}
	
	# Create deliverable indicator if needed and deliverable is provided
	if deliverable != null and (!mission_indicators[mission_id].has("deliverable") or !is_instance_valid(mission_indicators[mission_id]["deliverable"])):
		var container = _create_indicator(Color(1, 0, 0))  # Red for deliverable
		mission_indicators[mission_id]["deliverable"] = container
		mission_indicators[mission_id]["deliverable_target"] = deliverable
	
	# Create target indicator if needed and target is provided
	if target != null and (!mission_indicators[mission_id].has("target") or !is_instance_valid(mission_indicators[mission_id]["target"])):
		var container = _create_indicator(Color(0, 1, 0))  # Green for target
		mission_indicators[mission_id]["target"] = container
		mission_indicators[mission_id]["target_object"] = target
	
	# Update visibility based on current state
	_update_indicators_for_mission(mission_id)

# Create an indicator with specified color
func _create_indicator(color):
	var container = Control.new()
	var indicator = TextureRect.new()
	
	container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	container.visible = false  # Hidden by default
	
	indicator.texture = arrow_texture
	indicator.custom_minimum_size = arrow_size
	indicator.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	indicator.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	indicator.modulate = color
	
	container.add_child(indicator)
	
	# Add distance label if enabled
	if show_distance:
		var label = Label.new()
		label.name = "DistanceLabel"
		label.add_theme_color_override("font_color", color)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		label.add_theme_constant_override("outline_size", 2)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.position = Vector2(0, arrow_size.y + 2)
		label.text = "0m"
		container.add_child(label)
	
	add_child(container)
	return container

func _update_indicators_for_mission(mission_id):
	if !mission_id in mission_indicators:
		return
	
	var state = mission_states.get(mission_id, "need_pickup")
	var indicators = mission_indicators[mission_id]
	
	# Update visibility based on state
	if indicators.has("deliverable") and is_instance_valid(indicators["deliverable"]):
		var should_be_visible = (state == "need_pickup")
		indicators["deliverable"].visible = should_be_visible
	
	if indicators.has("target") and is_instance_valid(indicators["target"]):
		var should_be_visible = (state == "need_delivery")
		indicators["target"].visible = should_be_visible

func setup_update_timer():
	update_timer = Timer.new()
	update_timer.wait_time = update_interval
	update_timer.autostart = true
	update_timer.one_shot = false
	add_child(update_timer)
	update_timer.timeout.connect(_on_update_timer_timeout)

func _on_update_timer_timeout():
	# Update all indicator positions on timer
	if current_camera == null or !is_instance_valid(current_camera):
		current_camera = get_viewport().get_camera_3d()
		if current_camera == null:
			return
	
	# Update all indicators
	for mission_id in mission_indicators:
		var indicators = mission_indicators[mission_id]
		
		# Update deliverable indicator
		if indicators.has("deliverable") and is_instance_valid(indicators["deliverable"]) and indicators["deliverable"].visible:
			if indicators.has("deliverable_target") and is_instance_valid(indicators["deliverable_target"]):
				update_indicator_position(indicators["deliverable"], indicators["deliverable_target"])
		
		# Update target indicator
		if indicators.has("target") and is_instance_valid(indicators["target"]) and indicators["target"].visible:
			if indicators.has("target_object") and is_instance_valid(indicators["target_object"]):
				update_indicator_position(indicators["target"], indicators["target_object"])

func update_indicator_position(container, target):
	if !is_instance_valid(target) or !is_instance_valid(current_camera):
		return
	
	# Get target's position in world space
	var target_pos = target.global_position
	
	# Get the viewport size
	var viewport_size = get_viewport().size
	var viewport_rect = Rect2(Vector2.ZERO, viewport_size)
	
	# Convert 3D position to 2D screen coordinates
	var screen_pos = current_camera.unproject_position(target_pos)
	
	# Get indicator from container
	var indicator = container.get_child(0)
	
	# Calculate direction to target from camera
	var cam_forward = -current_camera.global_transform.basis.z.normalized()
	var direction_to_target = (target_pos - current_camera.global_position).normalized()
	var dot_product = cam_forward.dot(direction_to_target)
	
	# Distance to target (for scaling)
	var distance = current_camera.global_position.distance_to(target_pos)
	var scale_factor = clamp(1.0 - (distance / max_distance), min_distance_scale, 1.0)
	indicator.scale = Vector2(scale_factor, scale_factor)
	
	# Update distance label if it exists
	if show_distance and container.has_node("DistanceLabel"):
		var label = container.get_node("DistanceLabel")
		label.text = str(int(distance)) + "m"
	
	# Check if target is in front of the camera
	if dot_product > 0:
		# Target is in front of camera
		if viewport_rect.has_point(screen_pos):
			# Target is visible on screen, position arrow above it
			container.position = Vector2(screen_pos) - Vector2(indicator.size.x / 2, indicator.size.y + in_view_vertical_offset)
			indicator.rotation = 0 # Point down
		else:
			# Target is outside screen, position arrow at screen edge
			position_at_screen_edge(container, indicator, screen_pos, viewport_size)
	else:
		# Target is behind camera, position arrow at screen edge
		var behind_screen_pos = Vector2(viewport_size.x / 2, viewport_size.y)
		position_at_screen_edge(container, indicator, behind_screen_pos, viewport_size)

func position_at_screen_edge(container, indicator, screen_pos, viewport_size):
	# Ensure we're working with Vector2
	screen_pos = Vector2(screen_pos)
	viewport_size = Vector2(viewport_size)
	
	# Calculate direction from screen center to target
	var screen_center = viewport_size / 2
	var direction = (screen_pos - screen_center).normalized()
	
	# Find intersection with screen edge
	var edge_point = find_edge_intersection(screen_center, direction, viewport_size)
	
	# Apply edge offset
	edge_point -= direction * edge_offset
	
	# Position the container
	container.position = edge_point - Vector2(indicator.size.x / 2, indicator.size.y / 2)
	
	# Rotate indicator to point towards target
	var angle = direction.angle()
	indicator.rotation = angle

func find_edge_intersection(screen_center, direction, viewport_size):
	# Ensure we're working with Vector2
	screen_center = Vector2(screen_center)
	direction = Vector2(direction)
	viewport_size = Vector2(viewport_size)
	
	var half_width = viewport_size.x / 2
	var half_height = viewport_size.y / 2
	
	# Check horizontal edges
	var scale_h = abs(half_height / direction.y) if direction.y != 0 else INF
	var horz_intersection = screen_center + direction * scale_h
	
	# Check vertical edges
	var scale_v = abs(half_width / direction.x) if direction.x != 0 else INF
	var vert_intersection = screen_center + direction * scale_v
	
	# Use the closer intersection
	var use_horizontal = (abs(scale_h) < abs(scale_v))
	
	if use_horizontal:
		var y_value = viewport_size.y if direction.y > 0 else 0
		return Vector2(horz_intersection.x, y_value)
	else:
		var x_value = viewport_size.x if direction.x > 0 else 0
		return Vector2(x_value, vert_intersection.y)

func create_red_arrow_texture():
	# If we already have the original arrow texture, create a red version
	if arrow_texture:
		# Create a new ImageTexture
		red_arrow_texture = ImageTexture.create_from_image(arrow_texture.get_image())
		
		# We can't directly modify the pixels efficiently in GDScript
		# So we'll just use modulate on the TextureRect instead
	else:
		# Fallback if the arrow texture isn't available
		print("Warning: Could not create red arrow texture, original texture not found")
