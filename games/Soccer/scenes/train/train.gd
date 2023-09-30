extends Node2D

var ball_scene = preload("res://scenes/objects/ball.tscn")
var ball: Ball

# TODO: Instead of having an extra Test scene, give this a player overwrite option

# TODO: Update so that it maybe pulls width and height
var max_player_to_ball_distance: float = Vector2.ZERO.distance_to(Vector2(1280, 720))
var max_ball_to_goal_distance: float = Vector2.ZERO.distance_to(Vector2(1280, 360))

var n_steps: int = 0
var max_steps: int = 1000

var need_reset: bool = false

func _ready():
	$Player1.set_color("red")
	$Player2.set_color("blue")
	ball = create_new_ball()

func set_done():
	$Player1.controller.done = true
	$Player2.controller.done = true

func reset():
	n_steps = 0	
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
	
	handle_player_rewards($Player1)
	handle_player_rewards($Player2)
	
	n_steps += 1
	if n_steps > max_steps:
		set_done()

func handle_player_rewards(player: BotPlayer):
	var player_to_ball_distance = 1 - (
		player.position.distance_to(ball.position) 
		/ max_player_to_ball_distance
	)
	var ball_to_goal_distance = ( 
		ball.position.distance_to(
			$Field.get_right_goal_position() if player.is_left_team 
			else $Field.get_left_goal_position()
		) / max_ball_to_goal_distance 
	)
	var ball_velocity = ball.linear_velocity.length() / ball.max_linear_velocity
	
	player.controller.call_distance_player_to_ball_reward(player_to_ball_distance)
	player.controller.call_distance_ball_to_goal_reward(
		exp(3 * -ball_to_goal_distance)
	)
	player.controller.call_ball_velocity_reward(ball_velocity)

func _on_left_goal_scored():
	on_goal_scored(true)

func _on_right_goal_scored():
	on_goal_scored(false)

func on_goal_scored(is_left_goal: bool):
	$Player1.controller.call_goal_reward(
		-1 if is_left_goal else 1
	)
	$Player2.controller.call_goal_reward(
		1 if is_left_goal else -1
	)
	set_done()

func _on_player_1_need_reset():
	need_reset = true

func _on_player_2_need_reset():
	need_reset = true

func _on_player_1_touched_ball():
	$Player1.controller.call_ball_touch_reward(1)
	$Player2.controller.call_ball_touch_reward(-1)

func _on_player_2_touched_ball():
	$Player1.controller.call_ball_touch_reward(-1)
	$Player1.controller.call_ball_touch_reward(1)
