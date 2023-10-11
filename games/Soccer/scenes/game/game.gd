extends Node2D
class_name Game

@export var random_start_positions: bool = false

@onready var ball_scene: PackedScene = preload("res://scenes/ball/ball.tscn")
@onready var center_point: Marker2D = $CenterPoint as Marker2D
@onready var ball: Ball = create_ball()

@onready var player1 = $Player1 as Player
@onready var player2 = $Player2 as Player

@onready var field = $Field as Field

var left_score: int = 0
var right_score: int = 0

var needs_reset: bool = false

var game_width: float = 1280
var game_height: float = 720

var max_distance_ball_goal = Vector2.ZERO.distance_to(Vector2(game_width, game_height/2))
var max_distance_player_ball = Vector2.ZERO.distance_to(Vector2(game_width, game_height))
@onready var min_ball_velocity: float = ball.max_velocity * 0.1

func _ready():
	player1.init(self)
	player2.init(self)
	reset()

func _physics_process(_delta):
	if needs_reset:
		reset()
		return
	
	var ball_velocity = ball.linear_velocity.length() 
	calculate_player_reward(player1, ball_velocity, field.get_right_goal_position())
	calculate_player_reward(player2, ball_velocity, field.get_left_goal_position())
	
func reset():
	var player1_offset = Vector2.ZERO
	var player2_offset = Vector2.ZERO
	var ball_offset = Vector2.ZERO

	if random_start_positions:
		var width_border = (game_width / 2) * 0.9
		var height_border = (game_height / 2) * 0.9
		player1_offset = Vector2(randi_range(-width_border, width_border), randi_range(-height_border, height_border)) + center_point.global_position
		player2_offset = Vector2(randi_range(-width_border, width_border), randi_range(-height_border, height_border)) + center_point.global_position
		ball_offset = Vector2(randi_range(-width_border, width_border), randi_range(-height_border, height_border))

	needs_reset = false
	player1.reset(player1_offset)
	player2.reset(player2_offset)
	if ball:
		ball.call_deferred("queue_free")
	ball = create_ball(ball_offset)

func calculate_player_reward(player: Player, ball_velocity: float, enemy_goal_position: Vector2):
	# Min ball velocity
	if ball_velocity < min_ball_velocity:
		player.controller.on_min_ball_velocity_reward(-1)

	# Ball velocity
	player.controller.on_ball_velocity_reward(ball_velocity / ball.max_velocity)
	
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

func create_ball(position_offset: Vector2 = Vector2.ZERO):
	var new_ball = ball_scene.instantiate() as Ball
	new_ball.position = center_point.global_position + position_offset
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
