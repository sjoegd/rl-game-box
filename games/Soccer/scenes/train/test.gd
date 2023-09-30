extends Node2D

var ball_scene = preload("res://scenes/objects/ball.tscn")
var ball: Ball

var need_reset: bool = false

func _ready():
	$Player1.set_color("red")
	$Player2.set_color("blue")
	ball = create_new_ball()

func reset():
	$Player1.reset()
	$Player2.reset()
	ball = create_new_ball()	
	need_reset = false

func create_new_ball():
	if ball: 
		ball.queue_free()
	var new_ball: Ball = ball_scene.instantiate()
	new_ball.position = $BallSpawnPoint.position
	add_child(new_ball)
	return new_ball

func _process(_delta):
	if need_reset:
		reset()

func _on_left_goal_scored():
	set_done()

func _on_right_goal_scored():
	set_done()

func set_done():
	$Player1.controller.done = true

func _on_player_1_need_reset():
	need_reset = true
