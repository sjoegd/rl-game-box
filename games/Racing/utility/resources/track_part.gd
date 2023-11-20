extends Resource
class_name TrackPart

"""
	Right
		- index 6 +z
	Left
		- index 6 -z
	Up
		- index 7 +x
	Down
		- index 7 -x
	RightDown
		- index 1 -x
	RightUp
		- index 3 +x
	LeftDown
		- index 0 -x
	LeftUp
		- index 2 +x
	DownRight
		- index 2 +z
	DownLeft
		- index 3 -z
	UpRight
		- index 0 +z
	UpLeft
		- index 1 -z
"""

@export var id: String
@export var mesh_index: int = 0
@export var finish_mesh_index: int = -1
@export var position_update: Vector3i = Vector3i.ZERO
@export var successors: Array[String] = []

func next_position(position: Vector3i):
	return position + position_update
