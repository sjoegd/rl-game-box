class_name PartPos

var pos: Vector3i = Vector3i.ZERO
var part: TrackPart = null

func _init(new_pos: Vector3i, new_part: TrackPart):
	pos = new_pos
	part = new_part

func update_position():
	pos = part.next_position(pos)

func update_part(new_part: TrackPart):
	part = new_part

func fill_grid_map(track_grid_map: GridMap, finish_grid_map: GridMap):
	track_grid_map.set_cell_item(pos, part.mesh_index)
	if part.finish_mesh_index != -1:
		finish_grid_map.set_cell_item(pos, part.finish_mesh_index)
	empty_fill_grid_map(track_grid_map)

func empty_fill_grid_map(track_grid_map: GridMap):
	var empty_fills = part.get_empty_fills()
	for empty_fill in empty_fills:
		track_grid_map.set_cell_item(pos + empty_fill, TrackPart.fill_mesh_index)

func is_finish_line() -> bool:
	return part.finish_mesh_index != -1
