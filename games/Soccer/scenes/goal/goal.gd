extends StaticBody2D
class_name Goal

signal ball_entered

func _on_area_2d_body_entered(body):
	if body is Ball:
		ball_entered.emit()
