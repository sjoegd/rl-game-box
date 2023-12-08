extends StaticBody3D
class_name Arena

signal ball_entered(goal: String)

@onready var goals := $Goals
@onready var _width = $Markers/Width.position.length()
@onready var _length = $Markers/Length.position.length()
@onready var _height = $Markers/Height.position.length()

func _on_red_goal_body_entered(body):
	if body is Ball:
		ball_entered.emit("red")

func _on_blue_goal_body_entered(body):
	if body is Ball:
		ball_entered.emit("blue")

func get_goal_position(goal: String):
	goal = goal.capitalize()
	return goals.get_node(goal).global_position

func get_width():
	return _width

func get_length():
	return _length

func get_height():
	return _height
