extends TileMap
class_name Field

signal left_goal_ball_entered
signal right_goal_ball_entered

func get_left_goal_position():
	return $LeftGoal.global_position

func get_right_goal_position():
	return $RightGoal.global_position

func _on_left_goal_ball_entered():
	left_goal_ball_entered.emit()

func _on_right_goal_ball_entered():
	right_goal_ball_entered.emit()
