@tool
extends Node3D


@export_group("Dimensions")
var recalc_area: bool = true
@export var min_y: float = -10:
	set(value):
		min_y = value
		recalc_area = true
@export var max_y: float = 10:
	set(value):
		max_y = value
		recalc_area = true
@export var min_x: float = -100:
	set(value):
		min_x = value
		recalc_area = true
@export var max_x: float = 100:
	set(value):
		max_x = value
		recalc_area = true
@export var min_z: float = -100:
	set(value):
		min_z = value
		recalc_area = true
@export var max_z: float = 100:
	set(value):
		max_z = value
		recalc_area = true


@onready var collision_shape_3d: CollisionShape3D = $"Valid Area/CollisionShape3D"
@onready var things: Node3D = $Things


@export_group("Things")
@export var scenes: Array[PackedScene]
var could_fit_items: int = 100
@export var num_items: int = 100:
	set(value):
		num_items = value
		could_fit_items = value
var current_num_items: int = 0

var counter_use_could_fit: int = 0

@export_group("Checking")
@export_range(1, 6000, 1) var frames_per_spawn_in_game: int = 1
var frame_counter: int = 0
@export_flags_3d_physics var collision_hit: int = 1
@export_flags_3d_physics var collision_place: int = 1
@export var desired_normal: Vector3 = Vector3.UP
@export_range(-1, 1, 0.01) var normal_dot_threshold: float = -1
@export var height_up_raycast: float = 200
@export var height_up_place: float = 0.1
enum CheckMode {
	PlainRandom,
	PoissonDart,
	PoissonGridDart, # partially implemented
	#PoissonDwork
}
## [b]PlainRandom[/b] does not check distance, and should be the fastest but worst looking option, and usable for anything. [br][br]
## [b]PoissonDart[/b] is suitable for moving objects, taking distance into account, but is much slower as all other things must be checked for distance. [br][br]
## [unfinished] [b]PoissonGridDark[/b] is better for static objects, and [i]unsuitable for moving objects[/i], since it only needs to check a 3x3 section of a grid that contains the objects. [br][br]
@export var check_mode = CheckMode.PlainRandom:
	set(value):
		check_mode = value
		for child in things.get_children():
			child.free()
		_ready()
@export_range(5, 40, 1) var poisson_tries: int = 20
var poisson_dist_sq: float = 4
@export var poisson_distance: float = 2:
	set(value):
		poisson_distance = value
		poisson_dist_sq = value * value
@export var poisson_grid_object_count: int = 20

@export_group("Shape Fitting")
@export var check_shape_fit: bool = true
@export var shape_fit: Shape3D
var check_shapes: Array[Dictionary]

@export_group("Player")
@export var editor_no_respawn_near_player: bool = true
## when running
@export var no_respawn_near_player: bool = true
var respawn_player_dist_sq: float = 50 * 50
@export var respawn_player_distance: float = 50:
	set(value):
		respawn_player_distance = value
		respawn_player_dist_sq = value * value

@export_group("")
## turn off if you generate ahead of time and tweak placement of indestructable or immovable objects
@export var continually_check: bool = true
@export var place_in_editor: bool = false

func remove():
	things_list.clear()
	for child in things.get_children():
		child.free()
	_ready()

## removes nodes without removing grid nodes
@export_tool_button("remove") var remove_all = remove

#@export var things_list: Array[Node3D]
@export var things_list: Array[Dictionary]

func make_grid(min_x: float, width_x: float, min_z: float, width_z: float):
	var bins_per_axis: int = int(ceil(sqrt(num_items) / sqrt(poisson_grid_object_count)))
	var x_step: float = width_x / bins_per_axis
	var z_step: float = width_z / bins_per_axis
	
	#TODO needs to be positioned
	for x in range(0, bins_per_axis):
		var x_row = Node3D.new()
		x_row.position = Vector3(min_x + x * x_step, 0, 0)
		x_row.name = "row_" + str(x)
		for z in range(0, bins_per_axis):
			var z_grid = Node3D.new()
			z_grid.position = Vector3(0, 0, min_x + x * x_step)
			z_grid.name = "grid_" + str(x)
			x_row.add_child(z_grid)
		things.add_child(x_row)

func extract_shapes(node3d: Node3D) -> Dictionary[String, Array]:
	var shapes: Array[Shape3D]
	var masks: Array[int]
	var transforms: Array[Transform3D]
	for c1 in node3d.get_children():
		if c1.is_in_group(&"SpawnerExclusionArea"):
			#shapes.append()
			for c2 in c1.get_children():
				if c2 is CollisionShape3D:
					shapes.append(c2.shape)
					masks.append(c1.collision_mask)
					transforms.append(c2.global_transform)
	var result: Dictionary[String, Array]
	result["shapes"] = shapes
	result["masks"] = masks
	result["transforms"] = transforms
	return result

func remove_shapes(node3d: Node3D):
	for c1 in node3d.get_children():
		if c1.is_in_group(&"SpawnerExclusionAreaRemovable"):
			c1.free()

func check_shape_set(shape_dict: Dictionary[String, Array]) -> bool:
	for i in range(0, len(shape_dict.shapes)):
		var query = PhysicsShapeQueryParameters3D.new()
		query.collision_mask = shape_dict.masks[i]
		query.shape = shape_dict.shapes[i]
		query.transform = shape_dict.transforms[i]
		var result = get_world_3d().direct_space_state.intersect_shape(query, 1)
		if len(result) > 0:
			return false
	return true

func _ready():
	if not Engine.is_editor_hint():
		$"Valid Area".queue_free()
	if shape_fit == null:
		check_shape_fit = false
	if check_shape_fit:
		for i in range(0, len(scenes)):
			check_shapes[i] = extract_shapes(scenes[i].instantiate())
	
	var avg_y: float = (max_y + min_y) / 2
	var width_y: float = abs(max_y - min_y)
	
	var avg_x: float = (max_x + min_x) / 2
	var width_x: float = abs(max_x - min_x)
	
	var avg_z: float = (max_z + min_z) / 2
	var width_z: float = abs(max_z - min_z)
	
	var uniform_density = num_items / (width_x * width_z)
	var min_density = 1 / (poisson_dist_sq)
	
	if check_mode == CheckMode.PoissonGridDart or check_mode == CheckMode.PoissonDart:
		if uniform_density > min_density:
			num_items = floor(float(num_items) * min_density / uniform_density)
	
	if check_mode == CheckMode.PoissonGridDart:
		make_grid(min(min_x, max_x), width_x, min(min_z, max_z), width_z)
	
	print(things.get_child_count(), " ", len(things_list))
	if things.get_child_count() < len(things_list):
		for child in things.get_children():
			#child.free()
			things.remove_child(child)
		for thing in things_list:
			var instance = thing.node.instantiate()
			instance.position = thing.position
			if instance is RigidBody3D:
				instance.sleeping = true
				#instance.set_deferred("sleeping", true)
			remove_shapes(instance)
			things.add_child(instance)
	print(things.get_child_count(), " ", len(things_list))

func test_point(from: Vector3, to: Vector3) -> Array:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to, collision_hit)
	var result = space_state.intersect_ray(query)
	if not result:
		return [false, Vector3.ZERO, Vector3.ZERO]
	# is result position vertically within the area bounds
	if (result.position.y >= (self.global_position.y + min_y)) and (result.position.y <= (self.global_position.y + max_y)):
		# are any place bits set in layer of collider
		if result.collider.collision_layer & collision_place > 0:
			# is normal pointing in enough the right direction
			if result.normal.dot(desired_normal) > normal_dot_threshold:
				return [true, result.position, result.normal]
	return [false, Vector3.ZERO, Vector3.ZERO]

func _physics_process(delta: float) -> void:
	var place: bool = false
	var check_player_dist: bool = false
	if Engine.is_editor_hint():
		if editor_no_respawn_near_player:
			check_player_dist = true
		if place_in_editor:
			place = true
		if recalc_area:
			recalc_area = false
			
			var avg_y: float = (max_y + min_y) / 2
			var width_y: float = abs(max_y - min_y)
			
			var avg_x: float = (max_x + min_x) / 2
			var width_x: float = abs(max_x - min_x)
			
			var avg_z: float = (max_z + min_z) / 2
			var width_z: float = abs(max_z - min_z)
			
			collision_shape_3d.position = Vector3(avg_x, avg_y, avg_z)
			collision_shape_3d.shape.size = Vector3(width_x, width_y, width_z)
	else:
		place = true
		if no_respawn_near_player:
			check_player_dist = true
	if place:
		frame_counter -= 1
		if frame_counter <= 0 or Engine.is_editor_hint():
			frame_counter = frames_per_spawn_in_game
			current_num_items = things.get_child_count()
			var diff = (num_items if counter_use_could_fit <= 0 else could_fit_items) - current_num_items
			counter_use_could_fit = max(0, counter_use_could_fit - 1)
			#print(diff)
			if diff > 0:
				match check_mode:
					CheckMode.PlainRandom:
						var new_pos: Vector3
						var found_pos: bool = true
						for i in range(0, poisson_tries):
							new_pos = Vector3(randf_range(min_x, max_x), 0, randf_range(min_z, max_z)) + self.global_position
							found_pos = true
							var scene_idx: int = randi_range(0, len(scenes) - 1)
							if check_player_dist:
								var check_pos = (new_pos + self.global_position) * Vector3(1, 0, 1)
								var check_player = GlobalPlayerData.player_position * Vector3(1, 0, 1)
								if check_pos.distance_squared_to(check_player) < respawn_player_dist_sq:
									found_pos = false
							if check_shape_fit:
								if not check_shape_set(check_shapes[scene_idx]):
									found_pos = false
							if found_pos:
								var new_packed_scene = scenes[scene_idx]
								var from_pos = new_pos + self.global_position + Vector3(0, max_y + height_up_raycast, 0)
								new_pos += self.global_position + Vector3(0, min_y, 0)
								var result = test_point(from_pos, new_pos)
								if result[0]:
									#var array_scene = new_packed_scene.instantiate()
									#array_scene.position = result[1]# + Vector3(0, 50, 0)
									#Basis.looking_at()
									if Engine.is_editor_hint():
										var inst_info: Dictionary
										inst_info["node"] = new_packed_scene
										inst_info["position"] = result[1] + Vector3(0, height_up_place, 0)
										things_list.append(inst_info)
									var node_scene = new_packed_scene.instantiate()
									node_scene.position = result[1] + Vector3(0, height_up_place, 0)
									remove_shapes(node_scene)
									things.add_child(node_scene)
									break
								else:
									found_pos = false
					CheckMode.PoissonDart:
						var new_pos: Vector3
						var found_pos: bool = true
						for i in range(0, poisson_tries):
							new_pos = Vector3(randf_range(min_x, max_x), 0, randf_range(min_z, max_z)) + self.global_position
							found_pos = true
							var new_global_pos = (new_pos + self.global_position)
							if check_player_dist:
								if new_global_pos.distance_squared_to(GlobalPlayerData.player_position) > respawn_player_dist_sq:
									found_pos = false
							if found_pos:
								for ch in things.get_children():
									if new_global_pos.distance_squared_to(ch.position) > poisson_dist_sq:
										found_pos = false
										break
							if found_pos:
								var new_packed_scene = scenes[randi_range(0, len(scenes) - 1)]
								var new_scene = new_packed_scene.instantiate()
								var from_pos = new_global_pos + Vector3(0, max_y + height_up_raycast, 0)
								new_global_pos += Vector3(0, min_y, 0)
								var result = test_point(from_pos, new_global_pos)
								if result[0]:
									new_scene.position = result[1]
									#Basis.looking_at()
									things.add_child(new_scene)
									break
								else:
									found_pos = false
					CheckMode.PoissonGridDart:
						pass
						# when spawning items, place them into the appropriate grid node
						# filling should check instead quantity per grid node
				for i in diff:
					pass
			elif diff < 0:
				pass
				# implement optional deleting
			if diff == 1:
				print("last placed")
			if Engine.is_editor_hint() and diff == 0:
				place_in_editor = false
			if diff > 0:
				var new_diff = num_items - things.get_child_count()
				if new_diff / diff > 0.6:
					could_fit_items = things.get_child_count()
					# wait 10 seconds to try again in full
					counter_use_could_fit = 600
