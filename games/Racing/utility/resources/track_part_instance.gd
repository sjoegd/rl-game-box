class_name TrackPartInstance

var checkpoint_scene: PackedScene = preload("res://scenes/checkpoint.tscn") as PackedScene

var part: TrackPart
var pos: Vector3i
var global_pos: Vector3
var checkpoint: CheckPoint
var index: int
var parent: Node3D
var cb: Callable
var on_checkpoint: Callable

func _init(_part: TrackPart, _pos: Vector3i, _global_pos: Vector3, _index: int, _parent: Node3D, _cb: Callable):
	part = _part
	pos = _pos
	global_pos = _global_pos
	index = _index
	parent = _parent
	cb = _cb
	create_checkpoint()

func create_checkpoint():
	checkpoint = checkpoint_scene.instantiate() as CheckPoint
	on_checkpoint = func(car: Car):
		cb.call(car, index)
	checkpoint.position = global_pos + part.checkpoint_position
	checkpoint.rotation_degrees = part.checkpoint_rotation
	if should_connect_checkpoint():
		checkpoint.car_detected.connect(on_checkpoint)
	parent.add_child(checkpoint)

func clear():
	if should_connect_checkpoint():
		checkpoint.car_detected.disconnect(on_checkpoint)
	parent.remove_child(checkpoint)
	checkpoint.queue_free()

func should_connect_checkpoint() -> bool:
	return not (part.id.contains("start") or part.id.contains("finish"))
