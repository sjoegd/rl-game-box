extends Node2D

signal right_goal_scored
signal left_goal_scored

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE

func get_left_goal_position() -> Vector2:
	return $Goals/Left.global_position

func get_right_goal_position() -> Vector2:
	return $Goals/Right.global_position

func _on_left_goal_ball_entered():
	left_goal_scored.emit()

func _on_right_goal_ball_entered():
	right_goal_scored.emit()
