extends Node2D
class_name Game

@onready var ball_scene: PackedScene = preload("res://scenes/ball/ball.tscn")
@onready var ball_spawn: Marker2D = $BallSpawn
@onready var ball: Ball = create_ball()

@onready var player1 = $Player1 as Player
@onready var player2 = $Player2 as Player

@onready var field = $Field as Field

var left_score: int = 0
var right_score: int = 0

var needs_reset: bool = false

var max_distance_ball_goal = Vector2.ZERO.distance_to(Vector2(1280, 360))
var max_distance_player_ball = Vector2.ZERO.distance_to(Vector2(1280, 720))

func _physics_process(_delta):
	if needs_reset:
		reset()
		return
	
	var ball_velocity = ball.linear_velocity.length() / ball.max_velocity
	calculate_player_reward(player1, ball_velocity, field.get_right_goal_position())
	calculate_player_reward(player2, ball_velocity, field.get_left_goal_position())
	
func reset():
	needs_reset = false
	player1.reset()
	player2.reset()
	if ball:
		ball.call_deferred("queue_free")
	ball = create_ball()

func calculate_player_reward(player: Player, ball_velocity: float, enemy_goal_position: Vector2):
	# Ball velocity
	player.controller.on_ball_velocity_reward(ball_velocity)
	
	# Distance ball goal
	var distance_ball_goal_reward = exp(
		-3 * (enemy_goal_position.distance_to(ball.global_position) / max_distance_ball_goal)
	)
	player.controller.on_distance_ball_goal_reward((distance_ball_goal_reward*2) - 1)
	
	# Distance player ball
	var distance_player_ball_reward = 1 - (
		player.global_position.distance_to(ball.global_position) / max_distance_player_ball
	)
	player.controller.on_distance_player_ball_reward((distance_player_ball_reward*2) - 1)

func _on_player_1_touched_ball():
	player1.controller.on_ball_touched_reward(1)
	player2.controller.on_ball_touched_reward(-1)

func _on_player_2_touched_ball():
	player1.controller.on_ball_touched_reward(-1)
	player2.controller.on_ball_touched_reward(1)

func create_ball():
	var new_ball = ball_scene.instantiate() as Ball
	new_ball.position = ball_spawn.position
	new_ball.linear_velocity = Vector2.ZERO
	add_child(new_ball)
	return new_ball

func _on_left_goal_ball_entered():
	goal_scored(true)
	
func _on_right_goal_ball_entered():
	goal_scored(false)

func goal_scored(is_left_goal: bool):
	if is_left_goal:
		right_score += 1
		player1.controller.on_goal_scored_reward(-1)
		player2.controller.on_goal_scored_reward(1)
	else:
		left_score += 1
		player1.controller.on_goal_scored_reward(1)
		player2.controller.on_goal_scored_reward(-1)
	game_over()

func game_over():
	player1.game_over()
	player2.game_over()

func _on_player_1_needs_reset():
	needs_reset = true

func _on_player_2_needs_reset():
	needs_reset = true
