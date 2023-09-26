extends Node2D

signal right_goal_scored
signal left_goal_scored

func _on_left_goal_ball_entered():
	left_goal_scored.emit()

func _on_right_goal_ball_entered():
	right_goal_scored.emit()
