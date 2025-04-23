extends StaticBody3D

@onready var uniform_health: Node = $UniformHealth
@onready var health_text: MeshInstance3D = $health_text
@onready var armor_text: MeshInstance3D = $armor_text
@onready var mesh_main: MeshInstance3D = $mesh_main

func dead() -> void:
	mesh_main.mesh.surface_get_material(0).albedo_color = Color("ff4221")

func _ready() -> void:
	mesh_main.mesh.surface_get_material(0).albedo_color = Color("1232a0")
	uniform_health.death_callback = dead

func _process(delta: float) -> void:
	health_text.mesh.text = str(roundf(uniform_health.current_health * 10) / 10) + " / " + str(uniform_health.max_health)
	armor_text.mesh.text = str(roundf(uniform_health.current_armor * 10) / 10) + " / " + str(uniform_health.max_armor)
