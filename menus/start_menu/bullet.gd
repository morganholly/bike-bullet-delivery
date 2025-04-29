extends Node2D

@export var speed: float = 200.0
@export var trail_duration: float = 2.0
@export var min_line_width: float = 10.0
@export var max_line_width: float = 20.0

@onready var trail: ColorRect = $Trail
@onready var sprite: Sprite2D = $Sprite2D
var start_position: Vector2
var time_alive: float = 0.0
var is_first_bullet: bool = false
var max_trail_height: float = 0.0
var is_off_screen: bool = false
var viewport_size: Vector2

func _ready():
	# Check if this is the first bullet
	is_first_bullet = get_tree().get_nodes_in_group("bullet").size() == 0
	add_to_group("bullet")
	
	# Get viewport size
	viewport_size = get_viewport_rect().size
	
	# Setup trail
	var line_width = randf_range(min_line_width, max_line_width)
	trail.size = Vector2(line_width, 100)  # Start with a visible height
	
	# Calculate bullet dimensions
	var bullet_height = sprite.texture.get_height() * sprite.scale.y
	
	# Position trail at the top of the bullet and center horizontally
	trail.position = Vector2(-line_width/2, -bullet_height/2)
	
	# Set z-index to ensure proper layering
	z_index = 1  # Set the Node2D's z-index
	trail.z_index = 0  # Trail behind the bullet
	sprite.z_index = 2  # Bullet in front
	
	# Set position at bottom of screen
	position = Vector2(randf_range(100, viewport_size.x - 100), viewport_size.y + bullet_height/2)
	
	# Store start position at screen bottom
	start_position = Vector2(position.x, viewport_size.y)
	
	# Debug print only for first bullet
	if is_first_bullet:
		print("First bullet created:")
		print("Trail width: ", line_width)
		print("Trail position: ", trail.position)
		print("Trail size: ", trail.size)
		print("Bullet height: ", bullet_height)
		print("Start position:", start_position)
		print("Viewport size: ", viewport_size)

func _process(delta: float) -> void:
	time_alive += delta
	
	# Move bullet upward
	position.y -= speed * delta
	
	# Get current top position of bullet
	var bullet_height = sprite.texture.get_height() * sprite.scale.y
	var current_top = position - Vector2(0, bullet_height/2)
	
	# Calculate trail height from screen bottom to current top position
	var current_trail_height = abs(current_top.y - start_position.y)
	max_trail_height = max(max_trail_height, current_trail_height)
	
	# Always use the maximum trail height reached
	trail.size.y = max_trail_height
	
	# Check if bullet is off screen
	if position.y < -bullet_height:
		is_off_screen = true
	
	# If bullet is off screen, start fading out the trail
	if is_off_screen:
		# Keep trail at maximum height until it fades out
		trail.modulate.a = max(0, trail.modulate.a - delta)
		if trail.modulate.a <= 0:
			queue_free()
	
	# Debug print only for first bullet
	if is_first_bullet and int(time_alive) % 1 == 0:
		print("First bullet update:")
		print("Current trail height: ", current_trail_height)
		print("Max trail height: ", max_trail_height)
		print("Bullet top: ", current_top)
		print("Is off screen: ", is_off_screen)

func move(delta: float) -> void:
	_process(delta) 
