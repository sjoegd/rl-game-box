extends Node3D
class_name Field

signal goal_scored(color: String)

@onready var width = $Markers/Width.global_position.length()
@onready var length = $Markers/Length.global_position.length()
@onready var height = $Markers/Height.global_position.length()
@onready var corner_to_goal_length = Vector2(width, length*2).distance_to(Vector2.ZERO)
@onready var corner_to_corner_length = Vector2(width*2, length*2).distance_to(Vector2.ZERO)

func _on_goal_red_body_entered(body):
	if body is Ball:
		goal_scored.emit("red")

func _on_goal_blue_body_entered(body):
	if body is Ball:
		goal_scored.emit("blue")

func get_distance_to_goal(color: String, _position: Vector3):
	var goal = _get_goal(color)
	var distance = _position.distance_to(goal.global_position) / corner_to_goal_length
	return clamp(distance, -1.0, 1.0)

func get_distance_to_ball(_position: Vector3, ball_position: Vector3):
	var distance = _position.distance_to(ball_position) / corner_to_corner_length
	return clamp(distance, -1.0, 1.0)

func get_normalized_position(_position: Vector3):
	var x = _position.x / width
	var y = _position.y / height
	var z = _position.z / length
	return Vector3(x, y, z)

func _get_goal(color: String):
	return $GoalRed if color == "red" else $GoalBlue
