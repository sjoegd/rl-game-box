extends Node3D
class_name Game

@export var human_override_mode := false

@onready var players := $Players.get_children()
@onready var ball := $Ball as Ball
@onready var arena := $Arena as Arena

@onready var player_transforms = players.map(func(p: Player): return p.transform)
@onready var ball_transform = ball.transform

@onready var max_distance_player_ball = Utility.calculate_max_distance_player_ball(arena)
@onready var max_distance_ball_goal = Utility.calculate_max_distance_ball_goal(arena)

var goals: Array[String] = []
var ball_touches := {}

var needs_reset := false

func _ready():
	for player in players:
		player.init(self)
		player.human_override = human_override_mode
		player.needs_reset.connect(_on_player_needs_reset)
		ball_touches[player.name] = 0

func _physics_process(_delta):
	for player in players:
		give_rewards(player)
		ball_touches[player.name] = 0
	if needs_reset:
		reset()
	goals.clear()

func give_rewards(player: Player):
	# GOAL
	for goal in goals:
		var goal_reward = -1 if goal == player.color else 1
		player.controller.give_reward("GOAL", goal_reward)
	
	# DISTANCE_BALL
	var distance_ball = 1 - (
		Utility.calculate_distance_player_ball(player, ball) /
		max_distance_player_ball
	)
	player.controller.give_reward("DISTANCE_BALL", distance_ball)
	
	# DISTANCE_BALL_GOAL
	var distance_ball_goal = (
		Utility.calculate_distance_ball_goal(ball, arena, Utility.get_enemy_color(player.color)) /
		max_distance_ball_goal
	)
	var distance_ball_goal_reward = 2*exp(-5*distance_ball_goal)
	player.controller.give_reward("DISTANCE_BALL_GOAL", distance_ball_goal_reward)
	
	# TOUCH_BALL
	var player_ball_touches = ball_touches[player.name]
	player.controller.give_reward("TOUCH_BALL", player_ball_touches)

func game_over():
	for player in players:
		player.game_over()

func reset():
	needs_reset = false
	goals.clear()
	for i in range(len(players)):
		ball_touches[players[i].name] = 0
		players[i].reset(player_transforms[i])
	ball.reset(ball_transform)

func get_enemy_player(player: Player) -> Player:
	var not_player = players.filter(func(p: Player): return p != player)
	return not_player[0]

func _on_player_needs_reset():
	needs_reset = true

func _on_goal_ball_entered(goal: String):
	goals.append(goal)
	game_over()

func _on_ball_touch_player(player):
	ball_touches[player.name] += 1
