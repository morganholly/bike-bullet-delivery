extends Node2D

@export var speed: float = 200.0
@export var trail_duration: float = 2.0
@export var min_line_width: float = 10.0
@export var max_line_width: float = 20.0

@onready var trail: ColorRect = $Trail
@onready var sprite: AnimatedSprite2D = $Sprite2D
var start_position: Vector2
var time_alive: float = 0.0
var is_first_bullet: bool = false
var max_trail_height: float = 0.0
var is_off_screen: bool = false
var viewport_size: Vector2
var bullet_height: int = 30

func _ready():
	# Check if this is the first bullet
	is_first_bullet = get_tree().get_nodes_in_group("bullet").size() == 0
	add_to_group("bullet")
	
	# Get viewport size
	viewport_size = get_viewport_rect().size

	# pick a random bullet
	var r1 = randi_range(1,4)
	if r1 == 1:
		sprite.animation = "huge"
		bullet_height=99
		trail.size = Vector2(30, 100)
		z_index = 6
	elif r1 == 2:
		sprite.animation = "big"
		bullet_height=69
		trail.size = Vector2(25, 100)
		z_index = 3
	elif r1 == 3:
		sprite.animation = "medium"
		bullet_height=40
		trail.size = Vector2(15, 100)
		z_index = 2
	else:
		sprite.animation = "small"
		bullet_height=23
		trail.size = Vector2(10, 100)
		z_index = 1
	
	# Setup trail
	#var line_width = randf_range(min_line_width, max_line_width)
	#trail.size = Vector2(line_width, 100)  # Start with a visible height
	
	# Calculate bullet dimensions
	bullet_height = 30
	

	# Position trail at the top of the bullet and center horizontally
	#trail.position = Vector2(-line_width/2, -bullet_height/2)
	trail.position = Vector2(-(trail.size.x/2), 0)
	
	# Set z-index to ensure proper layering
	  # Set the Node2D's z-index
	trail.z_index = 0  # Trail behind the bullet
	sprite.z_index = 2  # Bullet in front
	
	# Set position at bottom of screen
	#position = Vector2(randf_range(100, viewport_size.x - 100), viewport_size.y + bullet_height/2)
	position = Vector2(randf_range(100, viewport_size.x - 100), viewport_size.y + bullet_height/2)
	# Store start position at screen bottom
	#start_position = Vector2(position.x, viewport_size.y)
	start_position = Vector2(position.x, position.y)
	

func _process(delta: float) -> void:
	time_alive += delta
	
	# Move bullet upward
	position.y -= speed * delta
	
	# Get current top position of bullet
	var current_top = position - Vector2(0, bullet_height/2)
	
	# Calculate trail height from screen bottom to current top position
	var current_trail_height = abs(current_top.y - start_position.y)
	#max_trail_height = max(max_trail_height, current_trail_height)
	
	# Always use the maximum trail height reached
	#trail.size.y = max_trail_height
	trail.size.y = start_position.y-position.y
	# Check if bullet is off screen
	if position.y < -bullet_height:
		is_off_screen = true
	
	# If bullet is off screen, start fading out the trail
	if is_off_screen:
		# Keep trail at maximum height until it fades out
		trail.modulate.a = max(0, trail.modulate.a - .2*delta)
		if trail.modulate.a <= 0:
			queue_free()


func move(delta: float) -> void:
	_process(delta) 
