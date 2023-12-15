extends Resource
class_name TrackPart

static var encode_ids: Array[String] = ["straight", "left_small", "right_small", "left_big", "right_big"]
static var fill_mesh_index := 24

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

func get_empty_fills() -> Array:
	if position_update.x == 2:
		return [Vector3i(1, 0, 0), Vector3i(2, 0, 0), Vector3i(2, 0, position_update.z)]
	elif position_update.z == 2:
		return [Vector3i(0, 0, 1), Vector3i(0, 0, 2), Vector3i(position_update.x, 0, 2)]
	elif position_update.x == -2:
		return [Vector3i(-1, 0, 0), Vector3i(-2, 0, 0), Vector3i(-2, 0, position_update.z)]
	elif position_update.z == -2:
		return [Vector3i(0, 0, -1), Vector3i(0, 0, -2), Vector3i(position_update.x, 0, -2)]
	return []

static func create_empty_one_hot_encode():
	var empty = []
	empty.resize(TrackPart.encode_ids.size())
	empty.fill(0)
	return empty
