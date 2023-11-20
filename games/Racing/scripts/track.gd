extends Node3D

@export var track_parts: Array[TrackPart] = [] # should be preconfigured in the editor
@export var starting_block_length: int = 5
@export var track_length: int = 50

@onready var grid_map: GridMap = $GridMap as GridMap

var id_to_track_part: Dictionary = {}

func _ready():
	for part in track_parts:
		id_to_track_part[part.id] = part
	generate_track()

func get_track_part(id: String) -> TrackPart:
	return id_to_track_part[id]

func generate_track():
	clear_track()

	var current_pos = Vector3i.ZERO
	var current_part = get_track_part("right")

	current_pos = generate_starting_block(current_pos, current_part)

	for i in range(track_length):
		grid_map.set_cell_item(current_pos, current_part.mesh_index)
		current_pos = current_part.next_position(current_pos)
		var valid_successor_parts = get_valid_track_part_successors(current_pos, current_part)
		if valid_successor_parts.is_empty() or (i == track_length - 1):
			break
		current_part = valid_successor_parts.pick_random()

	generate_finish_line(current_pos, current_part)

func generate_starting_block(current_pos: Vector3i, current_part: TrackPart) -> Vector3i:
	for i in range(starting_block_length):
		grid_map.set_cell_item(current_pos, current_part.mesh_index)
		current_pos = current_part.next_position(current_pos)
	return current_pos

func generate_finish_line(current_pos: Vector3i, current_part: TrackPart):
	current_part = (
		current_part.successors
		.map(func(id): return get_track_part(id))
		.filter(func(part): return part.finish_mesh_index != -1)
	).pick_random()
	grid_map.set_cell_item(current_pos, current_part.finish_mesh_index)

func clear_track():
	for pos in grid_map.get_used_cells():
		grid_map.set_cell_item(pos, grid_map.INVALID_CELL_ITEM)

func get_valid_track_part_successors(pos: Vector3i, part: TrackPart) -> Array[TrackPart]:
	return (
		part.successors
		.map(func(id): return get_track_part(id))
		.filter(func(part): return is_chunk_empty_for_part(pos, part, 3))
	)

func is_chunk_empty_for_part(pos: Vector3i, part: TrackPart, chunk_size: int) -> bool:
	# Apply position update chunk_size times
	for i in range(chunk_size):
		pos = part.next_position(pos)

	# Check if all cells in the chunk around the new position are empty
	for x in range(-chunk_size, chunk_size):
		for z in range(-chunk_size, chunk_size):
			if grid_map.get_cell_item(pos + Vector3i(x, 0, z)) != grid_map.INVALID_CELL_ITEM:
				return false

	return true


