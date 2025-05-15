extends Node2D

# Configuration parameters
@export_group("Bullet Properties")
@export var min_scale: float = 0.5
@export var max_scale: float = 2.0
@export var min_speed: float = 100.0
@export var max_speed: float = 300.0
@export var min_spawn_time: float = 0.1
@export var max_spawn_time: float = 0.5
@export var max_bullets: int = 20

@export_group("Trail Properties")
@export var min_trail_duration: float = 1.0
@export var max_trail_duration: float = 3.0
@export var min_line_width: float = 10 
@export var max_line_width: float = 20
@export var trail_color: Color = Color(0.427451, 0.101961, 0.239216, 1)

# Preloaded scenes and resources
var bullet_scene: PackedScene
var spawn_timer: Timer
var bullets: Array[Node2D] = []

func _ready():
	# Create the bullet scene if it doesn't exist
	bullet_scene = preload("res://menus/start_menu/bullet.tscn")
	
	# Setup spawn timer
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	
	# Start spawning bullets
	spawn_timer.start(_get_random_spawn_time())

func _process(delta: float) -> void:
	# Clean up invalid bullets first
	cleanup_bullets()
	
	# Update all remaining valid bullets
	for bullet in bullets:
		bullet.move(delta)

func cleanup_bullets() -> void:
	var i = bullets.size() - 1
	while i >= 0:
		var bullet = bullets[i]
		if bullet == null or !is_instance_valid(bullet) or !bullet.is_inside_tree():
			bullets.remove_at(i)
		i -= 1

func _get_random_spawn_time() -> float:
	return randf_range(min_spawn_time, max_spawn_time)

func _on_spawn_timer_timeout() -> void:
	# Clean up before checking max bullets
	cleanup_bullets()
	
	if bullets.size() < max_bullets:
		spawn_bullet()
	spawn_timer.start(_get_random_spawn_time())

func spawn_bullet() -> void:
	var bullet = bullet_scene.instantiate()
	add_child(bullet)
	
	# Set random properties
	var scale = randf_range(min_scale, max_scale)
	#bullet.scale = Vector2(scale, scale)
	bullet.speed = randf_range(min_speed, max_speed)
	bullet.trail_duration = randf_range(min_trail_duration, max_trail_duration)
	bullet.min_line_width = min_line_width
	bullet.max_line_width = max_line_width
	
	# Set random starting position
	var viewport_size = get_viewport_rect().size
	bullet.position.x = randf_range(0, viewport_size.x)
	bullet.position.y = viewport_size.y + 50  # Start below screen
	
	bullets.append(bullet) 
