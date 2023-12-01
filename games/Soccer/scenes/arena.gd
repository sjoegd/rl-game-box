extends StaticBody3D
class_name Arena

signal goal_scored(side: String)

func _on_red_goal_entered(body):
	if body is Ball:
		goal_scored.emit("red")

func _on_blue_goal_entered(body):
	if body is Ball:
		goal_scored.emit("blue")
