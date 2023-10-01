extends Node2D
class_name Game

@onready var ball_scene: PackedScene = preload("res://scenes/ball/ball.tscn")
@onready var player: Player = $Player as Player
@onready var ball: Ball = create_ball()

func create_ball():
	var new_ball = ball_scene.instantiate() as Ball
	new_ball.position = $BallSpawn.position
	new_ball.position.x += randf_range(-200, 200)
	add_child(new_ball)
	return new_ball

func reset():
	var player_position = $PlayerSpawn.position
	player_position.x += randf_range(-200, 200)
	player.reset(player_position)
	if ball:
		ball.call_deferred("queue_free")
	ball = create_ball()

func _on_player_need_reset():
	reset()

func _on_game_over_wall_body_entered(body):
	if body is Ball:
		player.game_over()
