extends Node3D
class_name Field

signal goal_scored(side: String)

func _on_goal_left_body_entered(body):
	if body is Ball:
		goal_scored.emit("left")

func _on_goal_right_body_entered(body):
	if body is Ball:
		goal_scored.emit("right")
