extends StaticBody2D

signal ball_entered()

func _on_net_body_entered(_body):
	ball_entered.emit()
