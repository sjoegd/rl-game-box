extends Resource
class_name TrackPart

@export var id: String
@export var mesh_index: int = 0
@export var finish_mesh_index: int = -1
@export var position_update: Vector3i = Vector3i.ZERO
@export var successors: Array[String] = []
@export var finish_successor: String = ""
@export var checkpoint_rotation: Vector3 = Vector3.ZERO
@export var checkpoint_position: Vector3 = Vector3.ZERO

func next_position(position: Vector3i):
	return position + position_update

func get_one_hot_encode(all_track_ids: Array):
	var one_hot = []
	for track_id in all_track_ids:
		one_hot.append(1 if track_id == id else 0)
	return one_hot

static func create_empty_one_hot_encode(n: int):
	var empty = []
	empty.resize(n)
	empty.fill(0)
	return empty
