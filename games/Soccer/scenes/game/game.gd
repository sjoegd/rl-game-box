extends Node2D
class_name Game

@onready var ball_scene: PackedScene = preload("res://scenes/ball/ball.tscn")
@onready var ball_spawn: Marker2D = $BallSpawn
@onready var ball: Ball = create_ball()

func create_ball():
	var new_ball = ball_scene.instantiate() as Ball
	new_ball.position = ball_spawn.position
	add_child(new_ball)
	return new_ball
