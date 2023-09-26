extends Node2D

var ball_scene = preload("res://scenes/objects/ball.tscn")
var ball: Ball

func _ready():
	$Player1.set_color("red")
	$Player2.set_color("blue")
	ball = create_new_ball()

func _on_left_goal_scored():
	if $Player1.has_method("add_reward"):
		$Player1.add_reward(-1)
	if $Player2.has_method("add_reward"):
		$Player2.add_reward(1)
	reset()

func _on_right_goal_scored():
	if $Player1.has_method("add_reward"):
		$Player1.add_reward(1)
	if $Player2.has_method("add_reward"):
		$Player2.add_reward(-1)
	reset()

func reset():
	$Player1.reset()
	$Player2.reset()
	ball = create_new_ball()	

func create_new_ball():
	if ball: 
		ball.queue_free()
	var new_ball: Ball = ball_scene.instantiate()
	new_ball.position = $BallSpawnPoint.position
	call_deferred("add_child", new_ball)
	return new_ball

