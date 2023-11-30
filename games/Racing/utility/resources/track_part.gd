extends Resource
class_name TrackPart

static var encode_ids: Array[String] = ["straight", "left_small", "right_small", "left_big", "right_big"]

@export var id: String
@export var encode_id: String
@export var mesh_index: int = 0
@export var finish_mesh_index: int = -1
@export var position_update: Vector3i = Vector3i.ZERO
@export var successors: Array[String] = []
@export var finish_successor: String = ""
@export var checkpoint_rotation: Vector3 = Vector3.ZERO
@export var checkpoint_position: Vector3 = Vector3.ZERO

func next_position(position: Vector3i):
	return position + position_update

func get_one_hot_encode() -> Array:
	var one_hot_encode = []
	for _encode_id in TrackPart.encode_ids:
		one_hot_encode.append(float(_encode_id == encode_id))
	return one_hot_encode

static func create_empty_one_hot_encode():
	var empty = []
	empty.resize(TrackPart.encode_ids.size())
	empty.fill(0)
	return empty
