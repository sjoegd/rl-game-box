extends Node2D

# Reward Function:
#	TODO - 10.0000 * Goal Reward (-1 | 0 | 1) 
#	TODO - 0.00500 * Ball Touch (-1 | 0 | 1)
#	TODO - 0.00125 * Distance Player to Ball (0 -> 1) TODO
#	TODO - 0.01000 * Distance Ball to Goal (0 -> 1) TODO
#	TODO - 0.00500 * -Current Timestep / Max Timesteps (0 -> -1) TODO
#	TODO - 0.00250 * Ball Velocity (0 -> 1) TODO
#	TODO - 0.00125 * Post hit (-1 | 0 | 1) TODO

var ball_scene = preload("res://scenes/objects/ball.tscn")
var ball: Ball

func _ready():
	$Player1.set_color("red")
	$Player2.set_color("blue")
	ball = create_new_ball()

func _on_left_goal_scored():
	on_goal_scored(true)

func _on_right_goal_scored():
	on_goal_scored(false)

func on_goal_scored(is_left_goal: bool):
	if $Player1.has_method("add_reward"):
		$Player1.add_reward(-1 if is_left_goal else 1)
	if $Player2.has_method("add_reward"):
		$Player2.add_reward(1 if is_left_goal else -1)
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
	call_deferred("add_child", new_ball) # TODO: Check if deferred is necessary
	return new_ball

