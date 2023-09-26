extends Node2D

var ball_scene = preload("res://scenes/objects/ball.tscn")

@onready var player1: Player = $Players/Player1 as Player
@onready var player2: Player = $Players/Player2 as Player
var ball: Ball 

var player1_color: String = "red"
var player2_color: String = "blue"

var team1_score: int = 0
var team2_score: int = 0

func _ready():
	player1.set_color(player1_color)
	player2.set_color(player2_color)
	reset()

func _on_left_goal_scored():
	team2_score += 1
	reset()

func _on_right_goal_scored():
	team1_score += 1
	reset()

func reset():
	update_ui_score()
	player1.reset()
	if ball:
		ball.call_deferred("queue_free")
	ball = create_new_ball()
	$Timers/StartTime.start()
	$UI.start_countdown($Timers/StartTime)
	get_tree().paused = true

func update_ui_score():
	$UI.set_score(team1_score, team2_score)

func create_new_ball():
	var new_ball = ball_scene.instantiate()
	new_ball.position = $BallSpawnPoint.position
	call_deferred("add_child", new_ball)
	return new_ball
	
func _on_start_time_timeout():
	get_tree().paused = false

func _on_player_2_reset_game():
	reset()
