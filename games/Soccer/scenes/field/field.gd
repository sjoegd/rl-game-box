extends TileMap
class_name Field

signal left_goal_ball_entered
signal right_goal_ball_entered

func _on_left_goal_ball_entered():
	left_goal_ball_entered.emit()

func _on_right_goal_ball_entered():
	right_goal_ball_entered.emit()
