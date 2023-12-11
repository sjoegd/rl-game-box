extends Node3D
class_name Track

@export var track_parts: Array[TrackPart] = [] # should be preconfigured in the editor
@export var starting_block_length: int = 5
@export var track_length: int = 50
@export var check_chunk_size: int = 3

@onready var track_grid_map: GridMap = $TrackGridMap as GridMap
@onready var finish_grid_map: GridMap = $FinishGridMap as GridMap

@onready var track_part_ids: Array = track_parts.map(func(part): return part.id)

var id_to_track_part: Dictionary = {}
var car_to_latest_track_index: Dictionary = {}
var car_to_furthest_track_index: Dictionary = {}
var track_part_instances: Array[TrackPartInstance] = []

# TODO: Improve generation algorithm
# BUGFIX: Add filler parts for big corners so they can be seen by algorithm

func _ready():
	for part in track_parts:
		id_to_track_part[part.id] = part
	clear_track()
	generate_track()

func reset(rebuild_track: bool = false):
	if rebuild_track:
		clear_track()
		generate_track()
	car_to_latest_track_index.clear()
	car_to_furthest_track_index.clear()

func clear_track():
	track_grid_map.clear()
	finish_grid_map.clear()
	for instance in track_part_instances:
		instance.clear()
	track_part_instances.clear()

func generate_track():	
	var part_pos = generate_starting_block("right")

	for i in range(track_length):
		new_track_part_instance(part_pos)
		var valid_successor_parts = get_valid_track_part_successors(part_pos)
		if valid_successor_parts.is_empty() or (i == track_length - 1):
			break
		part_pos.update_part(valid_successor_parts.pick_random())

	generate_finish_line(part_pos)

func generate_starting_block(part_id: String) -> PartPos:
	var part_pos = PartPos.new(Vector3.ZERO, get_track_part(part_id + "_start"))
	for i in range(starting_block_length):
		new_track_part_instance(part_pos)
		part_pos.update_part(get_track_part(part_id))
	return part_pos

func generate_finish_line(part_pos: PartPos):
	while not part_pos.is_finish_line():
		part_pos.update_part(get_track_part(part_pos.part.finish_successor))
		new_track_part_instance(part_pos)

func get_track_part(id: String) -> TrackPart:
	return id_to_track_part[id]
		
func new_track_part_instance(part_pos: PartPos):
	track_part_instances.append(TrackPartInstance.new(
		part_pos.part,
		part_pos.pos,
		track_grid_map.map_to_local(part_pos.pos),
		track_part_instances.size(),
		track_grid_map,
		_on_checkpoint
	))
	part_pos.fill_grid_map(track_grid_map, finish_grid_map)
	part_pos.update_position()

func get_valid_track_part_successors(part_pos: PartPos) -> Array:
	return (
		part_pos.part.successors
		.map(func(id): return get_track_part(id))
		.filter(func(part): return is_chunk_empty_for_part(part_pos.pos, part, check_chunk_size))
	)

func is_chunk_empty_for_part(pos: Vector3i, part: TrackPart, chunk_size: int) -> bool:
	# Apply position update chunk_size times
	for i in range(chunk_size):
		if not is_position_update_empty(pos, part.position_update):
			return false
		pos = part.next_position(pos)
	# Check if all cells in the chunk around the new position are empty
	for x in range(-chunk_size, chunk_size):
		for z in range(-chunk_size, chunk_size):
			if track_grid_map.get_cell_item(pos + Vector3i(x, 0, z)) != track_grid_map.INVALID_CELL_ITEM:
				return false
	return true

func is_position_update_empty(pos: Vector3i, update: Vector3i):
	var updated_pos = pos + update	
	for x in range(pos.x, updated_pos.x + 1):
		for z in range(pos.z, updated_pos.z + 1):
			if track_grid_map.get_cell_item(Vector3i(x, pos.y, z)) != track_grid_map.INVALID_CELL_ITEM:
				return false
	return true

func _on_checkpoint(car: Car, index: int):
	car_to_latest_track_index[car] = index
	if index > get_car_furthest_track_index(car):
		car_to_furthest_track_index[car] = index

func is_car_going_to_future_checkpoint(car: Car, is_furthest: bool = false) -> bool:
	var future_track_instance = get_car_future_track_instance(car, is_furthest)
	return car.is_going_to_position(future_track_instance.global_pos)

func get_car_distance_to_future_checkpoint(car: Car, pos: Vector3, is_furthest: bool = true) -> float:
	var ignore_y = Vector3(1, 0, 1)
	var future_track_instance = get_car_future_track_instance(car, is_furthest)
	return (pos * ignore_y).distance_to(future_track_instance.checkpoint.global_position*ignore_y)

func get_car_nose_angle_to_future_checkpoint(car: Car, is_furthest: bool = false) -> float:
	var future_track_instance = get_car_future_track_instance(car, is_furthest)
	var angle = car.get_angle_nose_to_position(future_track_instance.checkpoint.global_position)
	return angle

func get_car_future_track_instance(car: Car, is_furthest: bool = true) -> TrackPartInstance:
	var index = get_car_furthest_track_index(car) if is_furthest else get_car_latest_track_index(car)
	index = get_next_track_index(index)
	return track_part_instances[index]

func get_car_furthest_track_index(car: Car) -> int:
	if not car_to_furthest_track_index.has(car):
		car_to_furthest_track_index[car] = 0
		return 0 
	return car_to_furthest_track_index[car] as int

func get_car_latest_track_index(car: Car) -> int:
	if not car_to_latest_track_index.has(car):
		car_to_latest_track_index[car] = 0
		return 0
	return car_to_latest_track_index[car] as int

func get_next_track_index(index: int) -> int:
	return clamp(index + 1, 0, track_part_instances.size() - 1)

func get_future_n_track_parts(car: Car, n: int) -> Array:
	var future_track_parts = []
	var current_index = get_car_latest_track_index(car)

	for i in range(n):
		if current_index + i >= track_part_instances.size():
			future_track_parts += TrackPart.create_empty_one_hot_encode()
		else:
			future_track_parts += track_part_instances[current_index+i].part.get_one_hot_encode()
	
	return future_track_parts
