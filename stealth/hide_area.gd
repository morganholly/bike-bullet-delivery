extends Area3D


enum Visibility {
	DefaultYes_1No_2Maybe,
	DefaultYes_1Maybe_2No,
	DefaultNo_1Yes_2Maybe,
	DefaultNo_1Maybe_2Yes,
	DefaultMaybe_1Yes_2No,
	DefaultMaybe_1No_2Yes
}
@export var visibility: Visibility = Visibility.DefaultYes_1No_2Maybe

var player_ref: Node3D
var is_player_inside: bool = false
var override_1_has_colliders: bool = false
var override_2_has_colliders: bool = false

@onready var override_1: Area3D = $Override1

## not checked if in 1
@onready var override_2: Area3D = $Override2

func _ready() -> void:
	for ch in override_1.get_children():
		if ch is CollisionShape3D:
			override_1_has_colliders = true
			break
	for ch in override_2.get_children():
		if ch is CollisionShape3D:
			override_2_has_colliders = true
			break


func _on_body_entered(body: Node3D) -> void:
	is_player_inside = true
	player_ref = body

func _on_body_exited(body: Node3D) -> void:
	is_player_inside = false
	player_ref = null


func _physics_process(delta: float) -> void:
	if is_player_inside:
		var views = get_tree().get_nodes_in_group("ViewCheck")
		if visibility == Visibility.DefaultYes_1No_2Maybe:
			# if no override colliders, it's always yes if in sight range
			if (not override_1_has_colliders) and (not override_2_has_colliders):
				for node in views:
					node.in_sight_range(player_ref.position)
					node.set_target(player_ref)
			for node in views:
				# check each for the override colliders
				if override_1_has_colliders and override_1.overlaps_area(node):
					node.clear_target()
				elif override_2_has_colliders and override_2.overlaps_area(node):
					node.in_sight_range(player_ref.position)
					node.set_target(player_ref)
				else:
					node.in_sight_range(player_ref.position)
					node.set_target(player_ref)
		elif visibility == Visibility.DefaultYes_1Maybe_2No:
			# if no override colliders, it's always yes if in sight range
			if (not override_1_has_colliders) and (not override_2_has_colliders):
				for node in views:
					node.in_sight_range(player_ref.position)
					node.set_target(player_ref)
			for node in views:
				# check each for the override colliders
				if override_1_has_colliders and override_1.overlaps_area(node):
					node.in_sight_range(player_ref.position)
					node.set_target(player_ref)
				elif override_2_has_colliders and override_2.overlaps_area(node):
					node.clear_target()
				else:
					node.in_sight_range(player_ref.position)
					node.set_target(player_ref)
		elif visibility == Visibility.DefaultNo_1Yes_2Maybe:
			# if no override colliders, it's always no
			if override_1_has_colliders or override_2_has_colliders:
				for node in views:
					# check each for the override colliders
					if override_1_has_colliders and override_1.overlaps_area(node):
						node.clear_target()
					elif override_2_has_colliders and override_2.overlaps_area(node):
						node.in_sight_range(player_ref.position)
						node.set_target(player_ref)
					else:
						node.in_sight_range(player_ref.position)
						node.set_target(player_ref)
		elif visibility == Visibility.DefaultNo_1Maybe_2Yes:
			# if no override colliders, it's always no
			if override_1_has_colliders or override_2_has_colliders:
				for node in views:
					# check each for the override colliders
					if override_1_has_colliders and override_1.overlaps_area(node):
						node.clear_target()
					elif override_2_has_colliders and override_2.overlaps_area(node):
						node.in_sight_range(player_ref.position)
						node.set_target(player_ref)
					else:
						node.in_sight_range(player_ref.position)
						node.set_target(player_ref)
		elif visibility == Visibility.DefaultMaybe_1Yes_2No:
			for node in views:
				# check each for the override colliders
				if override_1_has_colliders and override_1.overlaps_area(node):
					node.in_sight_range(player_ref.position)
					node.set_target(player_ref)
				elif override_2_has_colliders and override_2.overlaps_area(node):
					node.clear_target()
				else:
					node.in_sight_range(player_ref.position)
					node.set_target(player_ref)
		elif visibility == Visibility.DefaultMaybe_1No_2Yes:
			for node in views:
				# check each for the override colliders
				if override_1_has_colliders and override_1.overlaps_area(node):
					node.clear_target()
				elif override_2_has_colliders and override_2.overlaps_area(node):
					node.in_sight_range(player_ref.position)
					node.set_target(player_ref)
				else:
					node.in_sight_range(player_ref.position)
					node.set_target(player_ref)
