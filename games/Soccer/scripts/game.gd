extends Node3D
class_name Game

@export var human_override := false
@export var swap_player_origins_on_reset := true

@onready var field := $Field
@onready var ball := $Ball
@onready var red_team := $"Players/Red".get_children()
@onready var blue_team := $"Players/Blue".get_children()

var needs_reset := false

func _ready():
	for player in _get_every_player():
		player.init(self)
		player.needs_reset.connect(_on_player_needs_reset)
		player.human_override = human_override

func _reset():
	needs_reset = false
	ball.reset()
	if swap_player_origins_on_reset:
		_swap_player_origins(red_team[0], red_team[1])
		_swap_player_origins(blue_team[0], blue_team[1])
	for player in _get_every_player():
		player.reset()

func _physics_process(_delta):
	for player in _get_every_player():
		_handle_extra_player_rewards(player)
	if needs_reset:
		_reset()

func _handle_extra_player_rewards(player: Player):
	var enemy_color = _get_enemy_team_color(player.color)
	var ball_position = ball.global_position
	var player_position = player.global_position
	# Ball Distance Goal
	var ball_distance_reward = 1 - field.get_distance_to_goal(enemy_color, ball_position)
	player.controller.give_reward("ball_distance_goal", (2 * ball_distance_reward) - 1)
	# Player Distance Ball
	var player_distance_reward = 1 - field.get_distance_to_ball(player_position, ball_position)
	player.controller.give_reward("player_distance_ball", player_distance_reward)
	# Time step
	player.controller.give_reward("time_step", 1)
	
func _on_player_needs_reset():
	needs_reset = true

func _on_goal_scored(team_color: String):
	for player in _get_every_player():
		var goal_reward = -1 if team_color == player.color else 1
		player.controller.give_reward("goal_scored", goal_reward)
		player.game_over()

func _get_enemy_team_color(team_color: String):
	return "blue" if team_color == "red" else "red"

func _team_color_to_team(team_color: String):
	if team_color == "red":
		return red_team
	if team_color == "blue":
		return blue_team

func _get_team_and_enemy(team_color: String):
	var enemy_team_color = _get_enemy_team_color(team_color)
	return [
		_team_color_to_team(team_color), 
		_team_color_to_team(enemy_team_color)
	]

func _get_every_player():
	return (red_team + blue_team)

func _swap_player_origins(player1: Player, player2: Player):
	var temp_origin = player1.base_transform.origin
	player1.base_transform.origin = player2.base_transform.origin
	player2.base_transform.origin = temp_origin

func _on_ball_player_collision(player: Player):
	player.controller.give_reward("ball_touch", 1)
